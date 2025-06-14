import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:map_launcher/map_launcher.dart' as map;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/pages/chat_screen.dart';
import 'package:taxi_driver/utils/Extensions/Loader.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_driver/utils/Images.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../model/RideDetailModel.dart';
import '../model/RiderModel.dart';
import '../model/UserDetailModel.dart';
import '../network/RestApis.dart';
import '../screens/ChatScreen.dart';
import '../screens/MainScreen.dart';
import '../screens/DocumentsScreen.dart';
import '../screens/RidesListScreen.dart';
import 'Colors.dart';
import 'Constants.dart';
import 'Extensions/AppButtonWidget.dart';
import 'Extensions/app_common.dart';

Widget dotIndicator(list, i) {
  return SizedBox(
    height: 16,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        list.length,
        (ind) {
          return Container(
            height: 8,
            width: 8,
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: i == ind ? Colors.white : Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(defaultRadius)),
          );
        },
      ),
    ),
  );
}

InputDecoration inputDecoration(BuildContext context,
    {String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? counterText}) {
  return InputDecoration(
    focusColor: primaryColor,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    counterText: counterText,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: dividerColor)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: dividerColor)),
    disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: dividerColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: Colors.black)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: dividerColor)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultRadius),
        borderSide: BorderSide(color: Colors.red)),
    alignLabelWithHint: true,
    filled: false,
    isDense: true,
    labelText: label ?? "Sample Text",
    labelStyle: primaryTextStyle(),
  );
}

Widget printAmountWidget(
    {required String amount,
    double? size,
    Color? color,
    FontWeight? weight,
    required TextStyle textStyle}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: appStore.currencyPosition.toString().toLowerCase().trim() ==
            LEFT.toLowerCase().trim()
        ? [
            Text(
              "${appStore.currencyCode} ",
              // appStore.currencyPosition.toString().toLowerCase().trim() == LEFT.toLowerCase().trim() ? '${appStore.currencyCode}$amount' : '$amount ${appStore.currencyCode}',
              // textDirection: TextDirection.LTR,
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily),
            ),
            Text(
              "$amount",
              // appStore.currencyPosition.toString().toLowerCase().trim() == LEFT.toLowerCase().trim() ? '${appStore.currencyCode}$amount' : '$amount ${appStore.currencyCode}',
              // textDirection: TextDirection.LTR,
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily),
            ),
          ]
        : [
            Text(
              "$amount ",
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily),
            ),
            Text(
              "${appStore.currencyCode}",
              // appStore.currencyPosition.toString().toLowerCase().trim() == LEFT.toLowerCase().trim() ? '${appStore.currencyCode}$amount' : '$amount ${appStore.currencyCode}',
              // textDirection: TextDirection.LTR,
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily),
            ),
          ],
  );
}

extension BooleanExtensions on bool? {
  /// Validate given bool is not null and returns given value if null.
  bool validate({bool value = false}) => this ?? value;
}

EdgeInsets dynamicAppButtonPadding(BuildContext context) {
  return EdgeInsets.symmetric(vertical: 14, horizontal: 16);
}

Widget inkWellWidget({Function()? onTap, required Widget child}) {
  return InkWell(
      onTap: onTap,
      child: child,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent);
}

Widget commonCachedNetworkImage(
  String? url, {
  double? height,
  double? width,
  BoxFit? fit,
  AlignmentGeometry? alignment,
  bool usePlaceholderIfUrlEmpty = true,
  double? radius,
}) {
  if (url == null || url.isEmpty) {
    return placeHolderWidget(
        height: height,
        width: width,
        fit: fit,
        alignment: alignment,
        radius: radius);
  } else if (url.validate().startsWith('http')) {
    try {
      // Fix missing slash after protocol
      if (url.startsWith('http:/') && !url.startsWith('http://')) {
        url = url.replaceFirst('http:/', 'http://');
      }
      if (url.startsWith('https:/') && !url.startsWith('https://')) {
        url = url.replaceFirst('https:/', 'https://');
      }

      // Fix double slash issue in URL but preserve protocol
      if (url.contains('//')) {
        String protocol = '';
        String remainingUrl = url;

        if (url.startsWith('http://')) {
          protocol = 'http://';
          remainingUrl = url.substring(7);
        } else if (url.startsWith('https://')) {
          protocol = 'https://';
          remainingUrl = url.substring(8);
        }

        // Fix any remaining double slashes in the path
        remainingUrl = remainingUrl.replaceAll('/+', '/');
        url = protocol + remainingUrl;
      }

      // Validate URL has a host
      Uri uri = Uri.parse(url);
      if (uri.host.isEmpty) {
        throw FormatException('No host specified in URI', url);
      }

      return CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: width,
        fit: fit,
        alignment: alignment as Alignment? ?? Alignment.center,
        errorWidget: (_, s, d) {
          log('Image Error: $url - $s');
          return placeHolderWidget(
              height: height,
              width: width,
              fit: fit,
              alignment: alignment,
              radius: radius);
        },
        placeholder: (_, s) {
          if (!usePlaceholderIfUrlEmpty) return SizedBox();
          return placeHolderWidget(
              height: height,
              width: width,
              fit: fit,
              alignment: alignment,
              radius: radius);
        },
        // Add memory and disk caching options
        memCacheHeight: (height?.toInt() ?? 512) * 2,
        memCacheWidth: (width?.toInt() ?? 512) * 2,
        maxHeightDiskCache: 1024,
        maxWidthDiskCache: 1024,
      );
    } catch (e) {
      log('URL Parse Error: $e');
      return placeHolderWidget(
          height: height,
          width: width,
          fit: fit,
          alignment: alignment,
          radius: radius);
    }
  } else {
    // Handle relative URLs by prepending the domain
    try {
      // Ensure proper URL construction without double slashes
      String cleanUrl = url.startsWith('/') ? url : '/$url';
      String fullUrl = '$DOMAIN_URL$cleanUrl';

      // Fix any potential double slashes in the constructed URL (except after protocol)
      if (fullUrl.startsWith('https://')) {
        String protocol = 'https://';
        String path = fullUrl.substring(8);
        path = path.replaceAll('/+', '/');
        fullUrl = protocol + path;
      } else if (fullUrl.startsWith('http://')) {
        String protocol = 'http://';
        String path = fullUrl.substring(7);
        path = path.replaceAll('/+', '/');
        fullUrl = protocol + path;
      } else {
        fullUrl = fullUrl.replaceAll('/+', '/');
      }

      return CachedNetworkImage(
        imageUrl: fullUrl,
        height: height,
        width: width,
        fit: fit,
        alignment: alignment as Alignment? ?? Alignment.center,
        errorWidget: (_, s, d) {
          log('Image Error: $fullUrl - $s');
          return placeHolderWidget(
              height: height,
              width: width,
              fit: fit,
              alignment: alignment,
              radius: radius);
        },
        placeholder: (_, s) {
          if (!usePlaceholderIfUrlEmpty) return SizedBox();
          return placeHolderWidget(
              height: height,
              width: width,
              fit: fit,
              alignment: alignment,
              radius: radius);
        },
        memCacheHeight: (height?.toInt() ?? 512) * 2,
        memCacheWidth: (width?.toInt() ?? 512) * 2,
        maxHeightDiskCache: 1024,
        maxWidthDiskCache: 1024,
      );
    } catch (e) {
      log('URL Parse Error (relative): $e');
      return placeHolderWidget(
          height: height,
          width: width,
          fit: fit,
          alignment: alignment,
          radius: radius);
    }
  }
}

Widget placeHolderWidget(
    {double? height,
    double? width,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    double? radius}) {
  return Image.asset(placeholder,
      height: height,
      width: width,
      fit: fit ?? BoxFit.cover,
      alignment: alignment ?? Alignment.center);
}

List<BoxShadow> defaultBoxShadow({
  Color? shadowColor,
  double? blurRadius,
  double? spreadRadius,
  Offset offset = const Offset(0.0, 0.0),
}) {
  return [
    BoxShadow(
      color: shadowColor ?? Colors.grey.withOpacity(0.2),
      blurRadius: blurRadius ?? 4.0,
      spreadRadius: spreadRadius ?? 1.0,
      offset: offset,
    )
  ];
}

/// Hide soft keyboard
void hideKeyboard(context) => FocusScope.of(context).requestFocus(FocusNode());

const double degrees2Radians = pi / 180.0;

double radians(double degrees) => degrees * degrees2Radians;

Future<bool> isNetworkAvailable() async {
  try {
    // Check connectivity status first
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    // Try to perform a basic DNS check as well
    try {
      // Try to ping Google's DNS as a test
      final result = await InternetAddress.lookup('8.8.8.8');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      // If DNS lookup fails, we'll try HTTP lookup as fallback
      try {
        // Try to connect to a reliable service with a short timeout
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(Duration(seconds: 5));
        return response.statusCode >= 200 && response.statusCode < 300;
      } catch (e) {
        print('Network connectivity issue: $e');
        // Return true anyway if we have connectivity but can't reach internet
        // This allows the app to attempt connections with custom retry logic
        return connectivityResult != ConnectivityResult.none;
      }
    }
  } catch (e) {
    print('Error checking network: $e');
    return false;
  }
}

String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}

Widget loaderWidget() {
  return Center(
    child: Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0.0, 0.0)),
        ],
      ),
      width: 50,
      height: 50,
      child: CircularProgressIndicator(strokeWidth: 3, color: primaryColor),
    ),
  );
}

void afterBuildCreated(Function()? onCreated) {
  makeNullable(SchedulerBinding.instance)!
      .addPostFrameCallback((_) => onCreated?.call());
}

T? makeNullable<T>(T? value) => value;

String printDate(String date) {
  print("DATEIS:::${date}");
  return DateFormat('dd MMM yyyy').format(DateTime.parse(date).toLocal()) +
      " at " +
      DateFormat('hh:mm a').format(DateTime.parse(date).toLocal());
}

Widget emptyWidget() {
  return Center(
    child: GestureDetector(
      onTap: () {
        launchScreen(getContext, MainScreen(), isNewTask: true);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 1500),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.2),
                      ),
                      child: Icon(
                        Icons.car_rental,
                        size: 80,
                        color: primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 40),
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 1000),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Text(
                        'لا توجد رحلات حالياً',
                        style: boldTextStyle(size: 20, color: primaryColor),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'اضغط هنا للعودة إلى الصفحة الرئيسية',
                        style: secondaryTextStyle(size: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            TweenAnimationBuilder(
              duration: Duration(milliseconds: 2000),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 32),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'تحديث',
                          style: boldTextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

buttonText({String? status}) {
  if (status == NEW_RIDE_REQUESTED) {
    return language.accepted;
  } else if (status == ACCEPTED || status == BID_ACCEPTED) {
    return language.arriving;
  } else if (status == IN_PROGRESS) {
    return language.endRide;
  } else if (status == CANCELED) {
    return language.cancelled;
  } else if (status == ARRIVING) {
    return language.arrived;
  } else if (status == ARRIVED) {
    return language.startRide;
  } else {
    return language.endRide;
  }
}

String statusTypeIcon({String? type}) {
  String icon = ic_history_img1;
  if (type == NEW_RIDE_REQUESTED) {
    icon = ic_history_img1;
  } else if (type == ACCEPTED || type == BID_ACCEPTED) {
    icon = ic_history_img2;
  } else if (type == ARRIVING) {
    icon = ic_history_img3;
  } else if (type == ARRIVED) {
    icon = ic_history_img4;
  } else if (type == IN_PROGRESS) {
    icon = ic_history_img5;
  } else if (type == CANCELED) {
    icon = ic_history_img6;
  } else if (type == COMPLETED) {
    icon = ic_history_img7;
  }
  return icon;
}

String statusTypeIconForButton({String? type}) {
  String icon = ic_history_img1;
  if (type == NEW_RIDE_REQUESTED) {
    icon = ic_history_img2;
  } else if (type == ACCEPTED || type == BID_ACCEPTED) {
    icon = ic_history_img3;
  } else if (type == ARRIVING) {
    icon = ic_history_img4;
  } else if (type == ARRIVED) {
    icon = ic_history_img5;
  } else if (type == IN_PROGRESS) {
    icon = ic_history_img7;
  } else if (type == CANCELED) {
    icon = ic_history_img7;
  } else if (type == COMPLETED) {
    // icon = ic_history_img7;
  }
  return icon;
}

bool get isRTL => rtlLanguage.contains(appStore.selectedLanguage);

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return (12742 * asin(sqrt(a))).toStringAsFixed(digitAfterDecimal).toDouble();
}

Widget totalCount(
    {String? title, num? amount, bool? isTotal = false, double? space}) {
  if (amount! > 0) {
    return Padding(
      padding: EdgeInsets.only(bottom: space ?? 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Text(title!,
                  style: isTotal == true
                      ? boldTextStyle(color: Colors.green, size: 18)
                      : secondaryTextStyle())),
          printAmountWidget(
              amount: amount!.toStringAsFixed(digitAfterDecimal),
              size: isTotal == true ? 18 : 14,
              color: isTotal == true ? Colors.green : textPrimaryColorGlobal,
              textStyle: boldTextStyle(size: 14))
          // Text(printAmount(amount!.toStringAsFixed(digitAfterDecimal)), style: isTotal == true ? boldTextStyle(color: Colors.green, size: 18) : boldTextStyle(size: 14)),
        ],
      ),
    );
  } else {
    return SizedBox();
  }
}

Future<bool> checkPermission() async {
  // Request app level location permission
  LocationPermission locationPermission = await Geolocator.requestPermission();

  if (locationPermission == LocationPermission.whileInUse ||
      locationPermission == LocationPermission.always) {
    // Check system level location permission
    if (!await Geolocator.isLocationServiceEnabled()) {
      return await Geolocator.openLocationSettings()
          .then((value) => false)
          .catchError((e) => false);
    } else {
      return true;
    }
  } else {
    toast(language.pleaseEnableLocationPermission);

    // Open system level location permission
    await Geolocator.openAppSettings();

    return true;
  }
}

Future<bool> setValue(String key, dynamic value, {bool print1 = true}) async {
  if (print1) print('${value.runtimeType} - $key - $value');

  if (value is String) {
    return await sharedPref.setString(key, value.validate());
  } else if (value is int) {
    return await sharedPref.setInt(key, value.validate());
  } else if (value is bool) {
    return await sharedPref.setBool(key, value.validate());
  } else if (value is double) {
    return await sharedPref.setDouble(key, value);
  } else if (value is Map<String, dynamic>) {
    return await sharedPref.setString(key, jsonEncode(value));
  } else if (value is List<String>) {
    return await sharedPref.setStringList(key, value);
  } else {
    throw ArgumentError(
        'Invalid value ${value.runtimeType} - Must be a String, int, bool, double, Map<String, dynamic> or StringList');
  }
}

/// Handle error and loading widget when using FutureBuilder or StreamBuilder
Widget snapWidgetHelper<T>(AsyncSnapshot<T> snap,
    {Widget? errorWidget,
    Widget? loadingWidget,
    String? defaultErrorMessage,
    @Deprecated('Do not use this') bool checkHasData = false,
    Widget Function(String)? errorBuilder}) {
  if (snap.hasError) {
    log(snap.error);
    if (errorBuilder != null) {
      return errorBuilder.call(defaultErrorMessage ?? snap.error.toString());
    }
    return Center(
      child: errorWidget ??
          Text(
            defaultErrorMessage ?? snap.error.toString(),
            style: primaryTextStyle(),
          ),
    );
  } else if (!snap.hasData) {
    return loadingWidget ?? Loader();
  } else {
    return SizedBox();
  }
}

void showOnlyDropLocationsDialog({
  required BuildContext context,
  required List<MultiDropLocation> multiDropData,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          language.viewDropLocations,
          style: primaryTextStyle(size: 18, weight: FontWeight.w500),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: multiDropData.map((location) {
              return Padding(
                padding: EdgeInsets.only(bottom: 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(location.address ?? ''.validate(),
                                style: primaryTextStyle(size: 14),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2)),
                        mapRedirectionWidget(
                            latLong: LatLng(location.lat, location.lng))
                      ],
                    ),
                    Divider(
                      height: 10,
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              language.cancel,
              style: primaryTextStyle(),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}

String changeStatusText(String? status) {
  if (status == COMPLETED) {
    return language.completed;
  } else if (status == CANCELED) {
    return language.cancelled;
  }
  return '';
}

String changeGender(String? name) {
  if (name == MALE) {
    return language.male;
  } else if (name == FEMALE) {
    return language.female;
  } else if (name == OTHER) {
    return language.other;
  }
  return '';
}

String paymentStatus(String paymentStatus) {
  if (paymentStatus.toLowerCase() == PAYMENT_PENDING.toLowerCase()) {
    return language.pending;
  } else if (paymentStatus.toLowerCase() == PAYMENT_FAILED.toLowerCase()) {
    return language.failed;
  } else if (paymentStatus == PAYMENT_PAID) {
    return language.paid;
  } else if (paymentStatus == CASH) {
    return language.cash;
  } else if (paymentStatus == Wallet) {
    return language.wallet;
  }
  return language.pending;
}

Widget loaderWidgetLogIn() {
  return Center(
    child: Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      ),
    ),
  );
}

Widget earningWidget({String? text, String? image, num? totalAmount}) {
  return Container(
    width: 160,
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 10.0, spreadRadius: 0),
      ],
      color: primaryColor,
      borderRadius: BorderRadius.circular(defaultRadius),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text!, style: boldTextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text(totalAmount.toString(),
                style: boldTextStyle(color: Colors.white)),
          ],
        ),
        Expanded(
          child: SizedBox(width: 8),
        ),
        Container(
          margin: EdgeInsets.only(left: 2),
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(defaultRadius)),
          child: Image.asset(image!, fit: BoxFit.cover, height: 40, width: 40),
        )
      ],
    ),
  );
}

Widget earningText(
    {String? title,
    num? amount,
    bool? isTotal = false,
    bool? isRides = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title!,
          style:
              isTotal == true ? boldTextStyle(size: 18) : primaryTextStyle()),
      printAmountWidget(
          amount: amount!.toStringAsFixed(digitAfterDecimal),
          size: isTotal == true ? 22 : 18,
          weight: isTotal == true ? FontWeight.bold : FontWeight.normal,
          color: isTotal == true ? Colors.green : textPrimaryColorGlobal,
          textStyle: boldTextStyle(size: 14))
    ],
  );
}

String getMessageFromErrorCode(FirebaseException error) {
  switch (error.code) {
    case "ERROR_EMAIL_ALREADY_IN_USE":
    case "account-exists-with-different-credential":
    case "email-already-in-use":
      return "The email address is already in use by another account.";
    case "ERROR_WRONG_PASSWORD":
    case "wrong-password":
      return "Wrong email/password combination.";
    case "ERROR_USER_NOT_FOUND":
    case "user-not-found":
      return "No user found with this email.";
    case "ERROR_USER_DISABLED":
    case "user-disabled":
      return "User disabled.";
    case "ERROR_TOO_MANY_REQUESTS":
    case "operation-not-allowed":
      return "Too many requests to log into this account.";
    // case "ERROR_OPERATION_NOT_ALLOWED":
    case "operation-not-allowed":
      return "Server error, please try again later.";
    case "ERROR_INVALID_EMAIL":
    case "invalid-email":
      return "Email address is invalid.";
    default:
      return error.message.toString();
  }
}

Widget mapRedirectionWidget({required LatLng latLong}) {
  return inkWellWidget(
    onTap: () async {
      final availableMaps = await map.MapLauncher.installedMaps;
      if (availableMaps.length > 1) {
        return showDialog(
          context: getContext,
          builder: (context) {
            return AlertDialog(
              title: Text("${language.chooseMap}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (int i = 0; i < availableMaps.length; i++)
                    inkWellWidget(
                      onTap: () async {
                        await availableMaps[i].showDirections(
                          destination:
                              map.Coords(latLong.latitude, latLong.longitude),
                        );
                      },
                      child: Container(
                          padding: EdgeInsets.all(8),
                          margin: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                              border: Border.all(color: dividerColor),
                              color: appStore.isDarkMode
                                  ? scaffoldColorDark
                                  : scaffoldColorLight,
                              borderRadius:
                                  BorderRadius.circular(defaultRadius)),
                          child: Row(
                            children: [Text("${availableMaps[i].mapName}")],
                          )),
                    ),
                ],
              ),
              actions: [
                AppButtonWidget(
                    text: language.cancel,
                    textStyle: boldTextStyle(color: Colors.white),
                    color: primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                    }),
              ],
            );
          },
        );
      }
      await availableMaps.first.showDirections(
        destination: map.Coords(latLong.latitude, latLong.longitude),
      );
    },
    child: Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: !appStore.isDarkMode ? scaffoldColorLight : scaffoldColorDark,
          borderRadius: BorderRadius.all(radiusCircular(8)),
          border: Border.all(width: 1, color: dividerColor)),
      child: Image.asset(ic_map_icon),
      width: 30,
      height: 30,
    ),
  );
}

Widget chatCallWidget(IconData icon, {UserData? data}) {
  if (data != null && data.uid != null) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              border: Border.all(color: dividerColor),
              color:
                  appStore.isDarkMode ? scaffoldColorDark : scaffoldColorLight,
              borderRadius: BorderRadius.circular(defaultRadius)),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        StreamBuilder<int>(
            stream: chatMessageService.getUnReadCount(
                receiverId: "${data!.uid}",
                senderId: "${sharedPref.getString(UID)}"),
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data! > 0) {
                return Positioned(
                    top: -2,
                    right: 0,
                    child: Lottie.asset(messageDetect,
                        width: 18, height: 18, fit: BoxFit.cover));
              }
              return SizedBox();
            })
      ],
    );
  } else {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(color: dividerColor),
          color: appStore.isDarkMode ? scaffoldColorDark : scaffoldColorLight,
          borderRadius: BorderRadius.circular(defaultRadius)),
      child: Icon(icon, size: 18, color: primaryColor),
    );
  }
}

Color paymentStatusColor(String paymentStatus) {
  Color color = textPrimaryColor;

  switch (paymentStatus) {
    case PAYMENT_PAID:
      color = Colors.green;
    case PAYMENT_FAILED:
      color = Colors.red;
    case PAYMENT_PENDING:
      color = Colors.grey;
  }
  return color;
}

Future<void> updatePlayerId() async {
  Map req = {
    "player_id": sharedPref.getString(PLAYER_ID),
  };
  updateStatus(req).then((value) {
    log(value.message);
  }).catchError((error) {});
}

Future<void> exportedLog(
    {required String logMessage, required String file_name}) async {
  final downloadsDirectory = Directory('/storage/emulated/0/Download');
  if (!await downloadsDirectory.exists()) {
    await downloadsDirectory.create(recursive: true);
  }
  final filePath =
      '${downloadsDirectory.path}/${file_name + "${DateTime.now().hour}_${DateTime.now().minute}"}.txt';
  final file = File(filePath);
  try {
    await file.writeAsString(logMessage, mode: FileMode.append);
  } catch (e) {}
}

oneSignalSettings() async {
/*   await Permission.notification.request();
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Debug.setAlertLevel(OSLogLevel.none);
  OneSignal.consentRequired(false); */
  OneSignal.initialize(mOneSignalAppIdDriver);

  OneSignal.Location.setShared(false);
  OneSignal.Notifications.requestPermission(true).then((accepted) async {
    print("Accepted permission: $accepted");
    Future.delayed(Duration(seconds: 2));
    String? userId = await OneSignal.User.getOnesignalId();

    while (userId == null) {
      userId = await OneSignal.User.getOnesignalId();
      Future.delayed(Duration(seconds: 2));
    }

    print("OneSignalID: " + (userId));
    print("User ID Loaded.");
  });

  /*    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationOpened(event.notification);
    }); */
  /*  } */
/*   OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    event.preventDefault();
    event.notification.display();
  }); */

  saveOneSignalPlayerId();
  if (appStore.isLoggedIn) {
    updatePlayerId();
  }
  OneSignal.Notifications.addClickListener((notification) async {
    notification.notification;
    var notId = notification.notification.additionalData!["id"];
    log("$notId---" +
        notification.notification.additionalData!['type'].toString());
    var notType = notification.notification.additionalData!['type'];
    if (notType != null && !notId.toString().contains('CHAT')) {
      if (notType == "document_approved") {
        launchScreen(getContext, DocumentsScreen(isShow: true),
            isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        return;
      }
      await rideDetail(rideId: int.tryParse(notId.toString())).then((value) {
        RideDetailModel mRideModel = value;
        if (mRideModel.data!.driverId != null) {
          if (sharedPref.getInt(USER_ID) == mRideModel.data!.driverId) {
            if (mRideModel.data!.paymentStatus == "paid") {
              launchScreen(getContext, RidesListScreen(), isNewTask: true);
            } else {
              launchScreen(getContext, MainScreen(), isNewTask: true);
            }
          } else {
            toast("Sorry! You missed this ride");
          }
        }
      }).catchError((error) {
        appStore.setLoading(false);
        log('${error.toString()}');
      });
    }
    if (notId != null) {
      if (notId.toString().contains('CHAT')) {
        UserDetailModel user = await getUserDetail(
            userId: int.parse(notId.toString().replaceAll("CHAT_", "")));
      }
    }
  });
}

Future<void> saveOneSignalPlayerId() async {
  OneSignal.User.pushSubscription.addObserver((state) async {
    if (OneSignal.User.pushSubscription.id.validate().isNotEmpty)
      await sharedPref.setString(
          PLAYER_ID, OneSignal.User.pushSubscription.id.validate());
  });
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
