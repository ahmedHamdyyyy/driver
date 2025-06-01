import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taxi_driver/components/OTPDialog.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/screens/DashboardScreen.dart';
import 'package:taxi_driver/screens/DocumentsScreen.dart';
import 'package:taxi_driver/screens/MainScreen.dart';
import 'package:taxi_driver/screens/SignInScreen.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/EditProfileScreen.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class AuthServices {
  Future<void> updateUserData(UserData user) async {
    userService.updateDocument({
      'player_id': sharedPref.getString(PLAYER_ID),
      'updatedAt': Timestamp.now(),
    }, user.uid);
  }

  Future<User?> createAuthUser(
      String? email, String? password, bool isOtpLogin) async {
    User? userCredential;
    try {
      if (!isOtpLogin) {
        await _auth
            .createUserWithEmailAndPassword(email: email!, password: password!)
            .then((value) {
          userCredential = value.user!;
        });
      } else {
        userCredential = _auth.currentUser;
      }
    } on FirebaseException catch (error) {
      if (error.code == "ERROR_EMAIL_ALREADY_IN_USE" ||
          error.code == "account-exists-with-different-credential" ||
          error.code == "email-already-in-use") {
        await _auth
            .signInWithEmailAndPassword(email: email!, password: password!)
            .then((value) {
          userCredential = value.user!;
        });
      } else {
        toast(getMessageFromErrorCode(error));
      }
    }
    return userCredential;
  }

  Future<void> signUpWithEmailPassword(
    context, {
    String? email,
    String? password,
    String? mobileNumber,
    String? fName,
    String? lName,
    String? userName,
    String? userType,
    bool isOtpLogin = false,
  }) async {
    try {
      if (email == null || email.isEmpty) {
        appStore.setLoading(false);
        if (context != null && context.mounted) toast('Email is required');
        return;
      }

      // Use Future.delayed to prevent immediate surface destruction
      await Future.delayed(Duration(milliseconds: 100));

      createAuthUser(email, password, isOtpLogin).then((user) async {
        if (user != null) {
          User currentUser = user;

          UserData userModel = UserData();

          /// Create user
          userModel.uid = currentUser.uid.validate();
          userModel.email = email;
          userModel.contactNumber = mobileNumber.validate();
          userModel.username = userName.validate();
          userModel.userType = userType.validate();
          userModel.displayName = fName.validate() + " " + lName.validate();
          userModel.firstName = fName.validate();
          userModel.lastName = lName.validate();
          userModel.createdAt = Timestamp.now().toDate().toString();
          userModel.updatedAt = Timestamp.now().toDate().toString();
          userModel.playerId = sharedPref.getString(PLAYER_ID).validate();
          sharedPref.setString(UID, user.uid.validate());

          await userService
              .addDocumentWithCustomId(currentUser.uid, userModel.toJson())
              .then((value) async {
            Map request = {
              "email": userModel.email,
              "password": password,
              "player_id": sharedPref.getString(PLAYER_ID).validate(),
              'user_type': DRIVER,
            };

            try {
              if (isOtpLogin) {
                appStore.setLoading(false);
                updateProfileUid();

                // Add a small delay before navigation
                await Future.delayed(Duration(milliseconds: 100));

                if (context != null && context.mounted) {
                  if (sharedPref.getInt(IS_Verified_Driver) == 1) {
                    launchScreen(context, MainScreen(), isNewTask: true);
                  } else {
                    launchScreen(context, DocumentsScreen(isShow: true),
                        pageRouteAnimation: PageRouteAnimation.Slide,
                        isNewTask: true);
                  }
                }
              } else {
                await logInApi(request).then((res) async {
                  appStore.setLoading(false);
                  updateProfileUid();

                  // Add a small delay before navigation
                  await Future.delayed(Duration(milliseconds: 100));

                  if (context != null && context.mounted) {
                    if (sharedPref.getInt(IS_Verified_Driver) == 1) {
                      launchScreen(context, MainScreen(), isNewTask: true);
                    } else {
                      launchScreen(context, DocumentsScreen(isShow: true),
                          pageRouteAnimation: PageRouteAnimation.Slide,
                          isNewTask: true);
                    }
                  }
                }).catchError((e) {
                  appStore.setLoading(false);
                  log(e.toString());
                  if (context != null && context.mounted) toast(e.toString());
                });
              }
            } catch (e) {
              appStore.setLoading(false);
              log('Navigation error: ${e.toString()}');
              if (context != null && context.mounted) toast(e.toString());
            }
          }).catchError((e) {
            appStore.setLoading(false);
            log(e.toString());
            if (context != null && context.mounted) toast(e.toString());
          });
        } else {
          appStore.setLoading(false);
          if (context != null && context.mounted) toast('User creation failed');
        }
      }).catchError((e) {
        appStore.setLoading(false);
        log(e.toString());
        if (context != null && context.mounted) toast(e.toString());
      });
    } /* on FirebaseException catch (error) {
      appStore.setLoading(false);
      if (context != null && context.mounted)
        toast(getMessageFromErrorCode(error));
    } */
    catch (e) {
      appStore.setLoading(false);
      log('Unexpected error: ${e.toString()}');
      if (context != null && context.mounted) toast(e.toString());
    }
  }

  Future<void> signInWithEmailPassword(context,
      {required String email, required String password}) async {
    await _auth
        .signInWithEmailAndPassword(email: email, password: password)
        .then((value) async {
      appStore.setLoading(true);
      final User user = value.user!;
      UserData userModel = await userService.getUser(email: user.email);
      await updateUserData(userModel);

      appStore.setLoading(true);
      //Login Details to SharedPreferences
      sharedPref.setString(UID, userModel.uid.validate());
      sharedPref.setString(USER_EMAIL, userModel.email.validate());
      sharedPref.setBool(IS_LOGGED_IN, true);

      //Login Details to AppStore
      appStore.setUserEmail(userModel.email.validate());
      appStore.setUId(userModel.uid.validate());

      //
    }).catchError((e) {
      toast(e.toString());
      log(e.toString());
    });
  }

  /*  Future<void> loginFromFirebaseUser(User currentUser,
      {LoginResponse? loginDetail,
      String? fullName,
      String? fName,
      String? lName}) async {
    UserData userModel = UserData();

    if (await userService.isUserExist(loginDetail!.data!.email)) {
      ///Return user data
      await userService.userByEmail(loginDetail.data!.email).then((user) async {
        userModel = user;
        appStore.setUserEmail(userModel.email.validate());
        appStore.setUId(userModel.uid.validate());

        await updateUserData(user);
      }).catchError((e) {
        log(e);
        throw e;
      });
    } else {
      /// Create user
      userModel.uid = currentUser.uid.validate();
      userModel.id = loginDetail.data!.id;
      userModel.email = loginDetail.data!.email.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.email = loginDetail.data!.email.validate();

      if (Platform.isIOS) {
        userModel.username = fullName;
      } else {
        userModel.username = loginDetail.data!.username.validate();
      }

      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.profileImage = loginDetail.data!.profileImage.validate();
      userModel.playerId = sharedPref.getString(PLAYER_ID);

      sharedPref.setString(UID, currentUser.uid.validate());
      log(sharedPref.getString(UID)!);
      sharedPref.setString(USER_EMAIL, userModel.email.validate());
      sharedPref.setBool(IS_LOGGED_IN, true);

      log(userModel.toJson());

      await userService
          .addDocumentWithCustomId(currentUser.uid, userModel.toJson())
          .then((value) {
        //
      }).catchError((e) {
        throw e;
      });
    }
  }

  Future<void> loginWithOTP(BuildContext context, String phoneNumber) async {
    return await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          toast('The provided phone number is not valid.');
          throw 'The provided phone number is not valid.';
        } else {
          toast(e.toString());
          // throw e.toString();
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        Navigator.pop(context);
        appStore.setLoading(false);
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
              content: OTPDialog(
                  verificationId: verificationId,
                  isCodeSent: true,
                  phoneNumber: phoneNumber)),
          barrierDismissible: false,
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        //
      },
    );
  }
 */
  Future deleteUserFirebase() async {
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.currentUser!.delete();
      await FirebaseAuth.instance.signOut();
    }
  }

  // إضافة دالة جديدة للتسجيل باستخدام API فقط
  Future<void> registerWithAPI(
    BuildContext context, {
    required Map requestData,
    required Function(LoginResponse) onSuccess,
    required Function(dynamic) onError,
  }) async {
    try {
      final signUpResponse = await signUpApi(requestData);

      if (signUpResponse != null) {
        // حفظ بيانات المستخدم في SharedPreferences
        await sharedPref.setString(
            TOKEN, signUpResponse.data!.apiToken.validate());
        await sharedPref.setString(
            USER_TYPE, signUpResponse.data!.userType.validate());
        await sharedPref.setString(
            FIRST_NAME, signUpResponse.data!.firstName.validate());
        await sharedPref.setString(
            LAST_NAME, signUpResponse.data!.lastName.validate());
        await sharedPref.setString(
            CONTACT_NUMBER, signUpResponse.data!.contactNumber.validate());
        await sharedPref.setString(
            USER_EMAIL, signUpResponse.data!.email.validate());
        await sharedPref.setString(
            USER_NAME, signUpResponse.data!.username.validate());
        if (signUpResponse.data!.address != null) {
          await sharedPref.setString(
              ADDRESS, signUpResponse.data!.address.validate());
        }
        await sharedPref.setInt(USER_ID, signUpResponse.data!.id ?? 0);
        if (signUpResponse.data!.gender != null) {
          await sharedPref.setString(
              GENDER, signUpResponse.data!.gender.validate());
        }
        await sharedPref.setInt(IS_ONLINE, signUpResponse.data!.isOnline ?? 0);
        if (signUpResponse.data!.uid != null) {
          await sharedPref.setString(UID, signUpResponse.data!.uid.validate());
        }
        await sharedPref.setString(
            LOGIN_TYPE, signUpResponse.data!.loginType.validate());
        await sharedPref.setInt(
            IS_Verified_Driver, signUpResponse.data!.isVerifiedDriver ?? 0);

        await appStore.setLoggedIn(true);
        await appStore.setUserEmail(signUpResponse.data!.email.validate());
        if (signUpResponse.data!.profileImage != null) {
          await appStore
              .setUserProfile(signUpResponse.data!.profileImage.validate());
        }

        onSuccess(signUpResponse);
      }
    } catch (error) {
      onError(error);
    }
  }

  // إضافة دالة جديدة لتسجيل الدخول باستخدام API فقط
  Future<void> loginWithAPI(
    BuildContext context, {
    required Map requestData,
    required Function(LoginResponse) onSuccess,
    required Function(dynamic) onError,
  }) async {
    try {
      final loginResponse = await logInApi(requestData);

      if (loginResponse != null) {
        onSuccess(loginResponse);
      }
    } catch (error) {
      onError(error);
    }
  }
}

/* class GoogleAuthServices {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  AuthServices authService = AuthServices();

  Future<void> signInWithGoogle(BuildContext context) async {
    GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      final UserCredential authResult =
          await _auth.signInWithCredential(credential);
      final User user = authResult.user!;
      assert(!user.isAnonymous);
      final User currentUser = _auth.currentUser!;
      assert(user.uid == currentUser.uid);
      await googleSignIn.signOut();
      await loginFromFirebase(
          user, LoginTypeGoogle, googleSignInAuthentication.accessToken);
    } else {
      throw errorSomethingWentWrong;
    }
  }
}

/// Sign-In with Apple.
Future<void> appleLogIn() async {
  if (await TheAppleSignIn.isAvailable()) {
    AuthorizationResult result = await TheAppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);
    switch (result.status) {
      case AuthorizationStatus.authorized:
        final appleIdCredential = result.credential!;
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          accessToken:
              String.fromCharCodes(appleIdCredential.authorizationCode!),
        );
        final authResult = await _auth.signInWithCredential(credential);
        final user = authResult.user!;

        if (result.credential!.email != null) {
          await saveAppleData(result);
        }

        await loginFromFirebase(user, LoginTypeApple,
            String.fromCharCodes(appleIdCredential.authorizationCode!));
        break;
      case AuthorizationStatus.error:
        throw ("Sign in failed: ${result.error!.localizedDescription}");
      case AuthorizationStatus.cancelled:
        throw ('User cancelled');
    }
  } else {
    throw ('Apple SignIn is not available for your device');
  }
}


 */
Future<void> saveAppleData(AuthorizationResult result) async {
  await sharedPref.setString('appleEmail', result.credential!.email.validate());
  await sharedPref.setString(
      'appleGivenName', result.credential!.fullName!.givenName.validate());
  await sharedPref.setString(
      'appleFamilyName', result.credential!.fullName!.familyName.validate());
}
/* 
Future<void> loginFromFirebase(
    User currentUser, String loginType, String? accessToken) async {
  String firstName = '';
  String lastName = '';
  if (loginType == LoginTypeGoogle) {
    if (currentUser.displayName != null &&
        currentUser.displayName!.trim().isNotEmpty) {
      if (currentUser.displayName.validate().split(' ').length >= 1)
        firstName = currentUser.displayName.splitBefore(' ');
      if (currentUser.displayName.validate().split(' ').length >= 2)
        lastName = currentUser.displayName.splitAfter(' ');
    } else {
      firstName = "Driver";
      lastName = "Anonymous";
    }
  } else {
    firstName = sharedPref.getString('appleGivenName').validate();
    lastName = sharedPref.getString('appleFamilyName').validate();
  }
  Map req = {
    "email": currentUser.email,
    "login_type": loginType,
    "user_type": DRIVER,
    "first_name": firstName,
    "last_name": lastName,
    "username": currentUser.email,
    "uid": currentUser.uid,
    'accessToken': accessToken,
    if (!currentUser.phoneNumber.isEmptyOrNull)
      'contact_number': currentUser.phoneNumber.validate(),
  };

  await logInApi(req, isSocialLogin: true).then((value) async {
    AuthServices authService = AuthServices();
    authService
        .loginFromFirebaseUser(currentUser,
            loginDetail: value, fullName: (firstName + lastName).toLowerCase())
        .then((value) {});
    Navigator.pop(getContext);
    sharedPref.setString(UID, currentUser.uid);
    await appStore.setUserProfile(currentUser.photoURL.toString());
    if (value.data!.contactNumber.isEmptyOrNull) {
      launchScreen(getContext, EditProfileScreen(isGoogle: true),
          isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
    } else {
      if (value.data!.uid.isEmptyOrNull) {
        File? imgFile;
        try {
          Directory tempDir = await getTemporaryDirectory();
          String filePath = '${tempDir.path}/downloaded_image.jpg';
          var response =
              await http.get(Uri.parse(currentUser.photoURL.toString()));
          if (response.statusCode == 200) {
            imgFile = File(filePath);
            await imgFile.writeAsBytes(response.bodyBytes);
            return imgFile;
          } else {
            imgFile = null;
          }
        } catch (e) {
          imgFile = null;
        }
        await updateProfile(
          uid: sharedPref.getString(UID).toString(),
          userEmail: currentUser.email.validate(),
          file: imgFile != null ? imgFile : null,
        ).then((value) {
          if (sharedPref.getInt(IS_Verified_Driver) == 1) {
            launchScreen(getContext, DashboardScreen(),
                isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          } else {
            launchScreen(getContext, DocumentsScreen(isShow: true),
                isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          }
        }).catchError((error) {
          log(error.toString());
        });
      } else if (value.data!.playerId.isEmptyOrNull) {
        await updatePlayerId().then((value) {
          if (sharedPref.getInt(IS_Verified_Driver) == 1) {
            launchScreen(getContext, DashboardScreen(),
                isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          } else {
            launchScreen(getContext, DocumentsScreen(isShow: true),
                isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          }
        }).catchError((error) {
          log(error.toString());
        });
      } else {
        if (sharedPref.getInt(IS_Verified_Driver) == 1) {
          launchScreen(getContext, DashboardScreen(),
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        } else {
          launchScreen(getContext, DocumentsScreen(isShow: true),
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        }
      }
    }
  }).catchError((e) {
    log(e.toString());
    throw e;
  });
}
 */
