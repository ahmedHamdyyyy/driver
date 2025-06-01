import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Extensions/AppButtonWidget.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';

import '../components/ImageSourceDialog.dart';
import '../core/widget/appbar/back_app_bar.dart';
import '../model/DocumentListModel.dart';
import '../model/DriverDocumentList.dart';
import '../network/NetworkUtils.dart';
import '../network/RestApis.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Images.dart';
import 'DashboardScreen.dart';
import 'MainScreen.dart';

class DocumentsScreen extends StatefulWidget {
  final bool isShow;

  DocumentsScreen({this.isShow = false});

  @override
  DocumentsScreenState createState() => DocumentsScreenState();
}

class DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();

  List<DocumentModel> documentList = [];
  List<DriverDocumentModel> driverDocumentList = [];

  List<int> uploadedDocList = [];
  List<String> eAttachments = [];
  String? imagePath;
  int docId = 0;
  var compressedImg;

  int? isExpire;

  // Animation controllers
  late AnimationController _fadeController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // For staggered list animations
  final Duration _listAnimationDuration = Duration(milliseconds: 600);
  final double _listAnimationOffset = 100.0;

  // For empty state animation
  bool _showEmptyAnimation = false;

  // متغير لتخزين العنصر المحدد حاليًا
  DocumentModel? selectedDocument;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeController.forward();

    // تعيين القيم الافتراضية
    docId = 0;
    isExpire = 0;

    init();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // إظهار الصورة بشكل أكبر عند الضغط عليها
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // الصورة
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: commonCachedNetworkImage(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              // زر الإغلاق
              Positioned(
                top: 10,
                right: 10,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: primaryColor, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryColor,
            colorScheme: ColorScheme.light(primary: primaryColor),
            buttonTheme: ButtonThemeData(),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(),
            ),
            dialogBackgroundColor: Colors.white,
            datePickerTheme: DatePickerThemeData(
                backgroundColor: Colors.white,
                cancelButtonStyle: ButtonStyle(),
                headerBackgroundColor: Colors.white),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void init() async {
    afterBuildCreated(() async {
      appStore.setLoading(true);
      await getDocument();
      await driverDocument();
    });
  }

  Future<void> _refreshData() async {
    // Reset UI state first
    setState(() {
      selectedDocument = null;
      docId = 0;
      isExpire = 0;
    });

    await getDocument();
    await driverDocument();
    return Future.value();
  }

  ///Driver Document List
  Future<void> getDocument() async {
    appStore.setLoading(true);
    await getDocumentList().then((value) {
      documentList.clear(); // Clear the list first to avoid duplicates
      selectedDocument =
          null; // Reset selected document to avoid dropdown issues

      // تأكد من أن كل المستندات لديها قيمة فريدة
      Map<int, DocumentModel> uniqueDocuments = {};
      for (var doc in value.data!) {
        if (doc.id != null) {
          uniqueDocuments[doc.id!] = doc;
        }
      }

      documentList.addAll(uniqueDocuments.values.toList());

      // Reset docId to default value
      docId = 0;
      isExpire = 0;

      appStore.setLoading(false);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      toast(error.toString());
    });
  }

  ///Document List
  Future<void> driverDocument() async {
    appStore.setLoading(true);
    await getDriverDocumentList().then((value) {
      driverDocumentList.clear();
      driverDocumentList.addAll(value.data!);
      uploadedDocList.clear();
      driverDocumentList.forEach((element) {
        uploadedDocList.add(element.documentId!);
      });
      appStore.setLoading(false);

      // Trigger empty animation if needed
      setState(() {
        _showEmptyAnimation = driverDocumentList.isEmpty;
      });

      // Reset and forward the fade animation for smooth refresh
      if (mounted) {
        _fadeController.reset();
        _fadeController.forward();
      }
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  /// Add Documents
  addDocument(int? docId, int? isExpire,
      {int? updateId, DateTime? dateTime}) async {
    MultipartRequest multiPartRequest = await getMultiPartRequest(
        updateId == null
            ? 'driver-document-save'
            : 'driver-document-update/$updateId');
    multiPartRequest.fields['driver_id'] =
        sharedPref.getInt(USER_ID).toString();
    multiPartRequest.fields['document_id'] = docId.toString();
    multiPartRequest.fields['is_verified'] = '0';
    if (isExpire != null)
      multiPartRequest.fields['expire_date'] = dateTime.toString();
    if (imagePath != null) {
      multiPartRequest.files
          .add(await MultipartFile.fromPath("driver_document", imagePath!));
    }
    multiPartRequest.headers.addAll(buildHeaderTokens());
    appStore.setLoading(true);
    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        appStore.setLoading(false);
        await driverDocument();
      },
      onError: (error) {
        appStore.setLoading(false);
        // throw error;
        toast(error.toString(), print: true);
      },
    ).catchError((e) {
      appStore.setLoading(false);
      // throw e;
      toast(e.toString());
    });
  }

  Future<File> compressFile(File file) async {
    Directory d = await getTemporaryDirectory();
    FlutterImageCompress.validator.ignoreCheckExtName = true;
    try {
      Uint8List? result = await FlutterImageCompress.compressWithFile(
        file.path,
        minHeight: 512,
        minWidth: 512,
        quality: 100,
      );
      if (result == null) {
        return file;
      }
      File file2 = await File('${d.path}/image.png').create();
      file2.writeAsBytesSync(result);
      return file2;
    } catch (e) {
      log('فشل ضغط الملف: ${e.toString()}');
      return file;
    }
  }

  /// SelectImage
  getMultipleFile(int? docId, int? isExpire,
      {int? updateId, DateTime? dateTime}) async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(defaultRadius),
              topRight: Radius.circular(defaultRadius))),
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: ImageSourceDialog(
                onCamera: () async {
                  Navigator.pop(context);
                  try {
                    var result = await ImagePicker().pickImage(
                        source: ImageSource.camera, imageQuality: 100);
                    if (result != null) {
                      File result2 = await compressFile(File(result!.path));
                      int b = await result2.length();
                      double fileSizeInMB = b / (1024 * 1024);
                      if (fileSizeInMB > 2) {
                        return toast("حجم الملف يجب أن يكون أقل من 2 ميجابايت");
                      }
                      uploadFile(result2.path, docId, isExpire,
                          updateId: updateId);
                    }
                  } catch (e) {
                    toast(e.toString());
                    return;
                  }
                },
                onGallery: () async {
                  Navigator.pop(context);
                  var result = await ImagePicker().pickImage(
                      source: ImageSource.gallery, imageQuality: 100);
                  if (result != null) {
                    File result2 = await compressFile(File(result!.path));
                    int b = await result2.length();
                    double fileSizeInMB = b / (1024 * 1024);
                    if (fileSizeInMB > 2) {
                      return toast("حجم الملف يجب أن يكون أقل من 2 ميجابايت");
                    }
                    uploadFile(result.path, docId, isExpire,
                        updateId: updateId);
                  }
                },
                onFile: () async {
                  Navigator.pop(context);
                  FilePickerResult? filePickerResult = await FilePicker.platform
                      .pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
                          allowMultiple: false);
                  if (filePickerResult != null) {
                    int b = filePickerResult.files.first.size;
                    double fileSizeInMB = b / (1024 * 1024);
                    if (fileSizeInMB > 2) {
                      return toast("حجم الملف يجب أن يكون أقل من 2 ميجابايت");
                    }
                    uploadFile(
                        filePickerResult.files.first.path, docId, isExpire,
                        updateId: updateId);
                  }
                },
                isFile: true,
              ),
            );
          },
        );
      },
    );
  }

  void uploadFile(String? file, int? docId, int? isExpire, {int? updateId}) {
    if (file != null) {
      showConfirmDialogCustom(
        context,
        title: "هل تريد تحميل هذا الملف؟",
        onAccept: (BuildContext context) {
          setState(() {
            imagePath = file;
          });
          addDocument(docId, isExpire,
              dateTime: selectedDate, updateId: updateId);
        },
        positiveText: "نعم",
        negativeText: "لا",
        primaryColor: primaryColor,
      );
      if (isExpire == 1) selectDate(context);
    }
  }

  /// Delete Documents
  deleteDoc(int? id) {
    appStore.setLoading(true);
    deleteDeliveryDoc(id!).then((value) {
      toast(value.message, print: true);

      driverDocument();
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  Future<void> getDetailAPi() async {
    try {
      appStore.setLoading(true);

      // Add a small delay to prevent immediate surface destruction
      await Future.delayed(Duration(milliseconds: 100));

      await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
        appStore.setLoading(false);

        sharedPref.setInt(IS_Verified_Driver, value.data!.isVerifiedDriver!);
        if (value.data!.isDocumentRequired != 0) {
          if (mounted) toast("بعض المستندات المطلوبة لم يتم تحميلها");
        } else {
          if (sharedPref.getInt(IS_Verified_Driver) == 1) {
            // Show approval dialog
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "تم اعتماد المستندات",
                            style: boldTextStyle(size: 18),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "تمت مراجعة واعتماد المستندات الخاصة بك بنجاح! يمكنك الآن استخدام التطبيق.",
                            style: secondaryTextStyle(),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          AppButtonWidget(
                            text: "الذهاب إلى لوحة التحكم",
                            textStyle: boldTextStyle(color: Colors.white),
                            onTap: () {
                              Navigator.pop(context);
                              // Add a small delay before navigation
                              Future.delayed(Duration(milliseconds: 100), () {
                                if (mounted) {
                                  launchScreen(context, MainScreen(),
                                      isNewTask: true,
                                      pageRouteAnimation:
                                          PageRouteAnimation.Slide);
                                }
                              });
                            },
                            width: MediaQuery.of(context).size.width,
                            color: primaryColor,
                            elevation: 0,
                            shapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          } else {
            if (mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              color: primaryColor,
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "المستندات قيد المراجعة",
                            style: boldTextStyle(size: 18),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "المستندات الخاصة بك قيد المراجعة من قبل الإدارة. سيتم إشعارك بمجرد الموافقة عليها.",
                            style: secondaryTextStyle(),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          AppButtonWidget(
                            text: "موافق",
                            textStyle: boldTextStyle(color: Colors.white),
                            onTap: () {
                              Navigator.pop(context);
                            },
                            width: MediaQuery.of(context).size.width,
                            color: primaryColor,
                            elevation: 0,
                            shapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          }
        }
      }).catchError((error) {
        appStore.setLoading(false);
        log(error.toString());
        if (mounted) toast(error.toString());
      });
    } catch (e) {
      appStore.setLoading(false);
      log('Detail API error: ${e.toString()}');
      if (mounted) toast(e.toString());
    }
  }

  // Show document status dialog in Arabic
  void showDocumentStatusDialog(String status, {String? reason}) {
    String title = 'حالة المستند';
    String message = '';
    IconData icon;
    Color iconColor;

    // Determine message and icon based on status
    if (status == 'approved' || status == 'معتمد') {
      message = 'تمت الموافقة على المستند بنجاح';
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (status == 'rejected' || status == 'مرفوض') {
      message = reason != null && reason.isNotEmpty
          ? 'تم رفض المستند: $reason'
          : 'تم رفض المستند';
      icon = Icons.cancel;
      iconColor = Colors.red;
    } else {
      message = 'المستند قيد المراجعة من قبل الإدارة';
      icon = Icons.access_time;
      iconColor = Colors.orange;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  title,
                  style: boldTextStyle(size: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  message,
                  style: secondaryTextStyle(),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                AppButtonWidget(
                  text: "موافق",
                  textStyle: boldTextStyle(color: Colors.white),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  width: MediaQuery.of(context).size.width,
                  color: primaryColor,
                  elevation: 0,
                  shapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          return true;
        } else {
          SystemNavigator.pop();
          return false;
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              BackAppBar(
                title: "المستندات",
              ),
              RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshData,
                color: primaryColor,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "اختر المستند",
                                    style: boldTextStyle(size: 18),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border:
                                                Border.all(color: dividerColor),
                                          ),
                                          child: DropdownButtonFormField<
                                              DocumentModel>(
                                            hint: Text("اختر المستند",
                                                style: primaryTextStyle(
                                                    color:
                                                        textSecondaryColorGlobal)),
                                            decoration:
                                                InputDecoration.collapsed(
                                              hintText: null,
                                              focusColor: primaryColor,
                                            ),
                                            isExpanded: true,
                                            isDense: true,
                                            icon: Icon(Icons.arrow_drop_down,
                                                color: primaryColor),
                                            items: documentList.map((e) {
                                              return DropdownMenuItem(
                                                value: e,
                                                key: ValueKey(e.id),
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: e.name.validate(),
                                                    style: primaryTextStyle(),
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            '${e.isRequired == 1 ? ' *' : ''}',
                                                        style: boldTextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            value: selectedDocument,
                                            onChanged: (DocumentModel? val) {
                                              if (val != null) {
                                                setState(() {
                                                  selectedDocument = val;
                                                  docId = val.id!;
                                                  isExpire = val.hasExpiryDate!;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      if (docId != 0) SizedBox(width: 16),
                                      if (docId != 0)
                                        Visibility(
                                          visible:
                                              !uploadedDocList.contains(docId),
                                          child: InkWell(
                                            onTap: () {
                                              if (isExpire == 1) {
                                                getMultipleFile(docId,
                                                    isExpire == 0 ? null : 1,
                                                    dateTime: selectedDate);
                                              } else {
                                                getMultipleFile(docId,
                                                    isExpire == 0 ? null : 1);
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.add,
                                                      color: Colors.white,
                                                      size: 20),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    "إضافة مستند",
                                                    style: boldTextStyle(
                                                        color: Colors.white,
                                                        size: 14),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "* هذا مستند إلزامي",
                                    style: primaryTextStyle(
                                        color: Colors.red, size: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Documents list title
                      if (driverDocumentList.isNotEmpty)
                        Container(
                          child: Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              "المستندات",
                              style: boldTextStyle(size: 20),
                            ),
                          ),
                        ),

                      // Documents list
                      AnimationLimiter(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: driverDocumentList.length,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (_, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: _listAnimationDuration,
                              child: SlideAnimation(
                                horizontalOffset: _listAnimationOffset,
                                child: Card(
                                  elevation: 2,
                                  margin: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: primaryColor
                                                    .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                driverDocumentList[index]
                                                        .driverDocument!
                                                        .contains('.pdf')
                                                    ? Icons.picture_as_pdf
                                                    : Icons.file_copy,
                                                color: primaryColor,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                driverDocumentList[index]
                                                    .documentName!,
                                                style: boldTextStyle(size: 16),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: driverDocumentList[index]
                                                            .isVerified ==
                                                        1
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.orange
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                driverDocumentList[index]
                                                            .isVerified ==
                                                        1
                                                    ? "تم التحقق"
                                                    : "قيد الانتظار",
                                                style: boldTextStyle(
                                                  size: 12,
                                                  color:
                                                      driverDocumentList[index]
                                                                  .isVerified ==
                                                              1
                                                          ? Colors.green
                                                          : Colors.orange,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.grey
                                                    .withOpacity(0.3)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: driverDocumentList[index]
                                                    .driverDocument!
                                                    .contains('.pdf')
                                                ? InkWell(
                                                    onTap: () {
                                                      launchUrl(
                                                        Uri.parse(
                                                            driverDocumentList[
                                                                    index]
                                                                .driverDocument
                                                                .validate()),
                                                        mode: LaunchMode
                                                            .externalApplication,
                                                      );
                                                    },
                                                    child: Container(
                                                      color:
                                                          Colors.grey.shade50,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 20),
                                                      child: Column(
                                                        children: [
                                                          Image.asset(
                                                            ic_pdf,
                                                            fit: BoxFit.cover,
                                                            height: 50,
                                                            width: 50,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            driverDocumentList[
                                                                    index]
                                                                .driverDocument!
                                                                .split('/')
                                                                .last,
                                                            style:
                                                                primaryTextStyle(),
                                                          ),
                                                          SizedBox(height: 4),
                                                          Text(
                                                            "اضغط للفتح",
                                                            style: secondaryTextStyle(
                                                                color:
                                                                    primaryColor),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : InkWell(
                                                    onTap: () {
                                                      _showImagePreview(
                                                          driverDocumentList[
                                                                  index]
                                                              .driverDocument!
                                                              .validate());
                                                    },
                                                    child:
                                                        commonCachedNetworkImage(
                                                      driverDocumentList[index]
                                                          .driverDocument!,
                                                      height: 200,
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        if (driverDocumentList[index]
                                                .expireDate !=
                                            null)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today,
                                                    size: 18,
                                                    color: Colors.grey),
                                                SizedBox(width: 8),
                                                Text("تاريخ الانتهاء",
                                                    style: primaryTextStyle(
                                                        color: primaryColor)),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    driverDocumentList[index]
                                                        .expireDate
                                                        .toString(),
                                                    style: primaryTextStyle(
                                                        weight:
                                                            FontWeight.w600),
                                                    textAlign: TextAlign.end,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                if (isExpire == 1) {
                                                  getMultipleFile(
                                                    driverDocumentList[index]
                                                        .documentId,
                                                    driverDocumentList[index]
                                                                .expireDate !=
                                                            null
                                                        ? 1
                                                        : null,
                                                    dateTime: selectedDate,
                                                    updateId:
                                                        driverDocumentList[
                                                                index]
                                                            .id,
                                                  );
                                                } else {
                                                  getMultipleFile(
                                                    driverDocumentList[index]
                                                        .documentId,
                                                    driverDocumentList[index]
                                                                .expireDate !=
                                                            null
                                                        ? 1
                                                        : null,
                                                    updateId:
                                                        driverDocumentList[
                                                                index]
                                                            .id,
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: primaryColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: primaryColor),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.edit,
                                                        color: primaryColor,
                                                        size: 16),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "تعديل",
                                                      style: boldTextStyle(
                                                          color: primaryColor,
                                                          size: 14),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            InkWell(
                                              onTap: () async {
                                                showConfirmDialogCustom(
                                                  context,
                                                  title:
                                                      "هل أنت متأكد أنك تريد حذف هذا المستند؟",
                                                  onAccept: (BuildContext
                                                      context) async {
                                                    await deleteDoc(
                                                        driverDocumentList[
                                                                index]
                                                            .id);
                                                  },
                                                  positiveText: "نعم",
                                                  negativeText: "لا",
                                                  primaryColor: primaryColor,
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.red),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.delete,
                                                        color: Colors.red,
                                                        size: 16),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "حذف",
                                                      style: boldTextStyle(
                                                          color: Colors.red,
                                                          size: 14),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, index) {
                            return SizedBox(height: 12);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty state
              if (!appStore.isLoading && driverDocumentList.isEmpty)
                Center(
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'images/json_files/empty_documents.json',
                          width: 200,
                          height: 200,
                          repeat: true,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "لا توجد مستندات",
                          style: boldTextStyle(size: 18),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "الرجاء تحميل المستندات المطلوبة",
                          style: secondaryTextStyle(),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading indicator
              Observer(
                builder: (_) => Visibility(
                  visible: appStore.isLoading,
                  child: Center(
                    child: loaderWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: driverDocumentList.isNotEmpty
            ? Visibility(
                visible: widget.isShow,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: AppButtonWidget(
                    text: "الذهاب إلى لوحة التحكم",
                    textStyle: boldTextStyle(color: Colors.white),
                    onTap: () {
                      getDetailAPi();
                    },
                    width: MediaQuery.of(context).size.width,
                    color: primaryColor,
                    elevation: 0,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            : SizedBox(),
      ),
    );
  }
}
