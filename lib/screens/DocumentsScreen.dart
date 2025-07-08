import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:async';

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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
import 'VehicleScreen.dart';
import '../model/ServiceModel.dart';
import '../model/UserDetailModel.dart';

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
  List<ServiceList> serviceList = [];
  int? selectedServiceId;
  UserData? userData;

  List<int> uploadedDocList = [];
  List<String> eAttachments = [];
  String? imagePath;
  int docId = 0;
  var compressedImg;

  int? isExpire;

  // New variables for 4 specific images - completely separate variables
  File? frontIdImage;
  File? backIdImage;
  File? frontLicenseImage;
  File? backLicenseImage;
  String? combinedFilePath;

  // Track which image is currently being selected
  String? currentlySelectingImageType;

  // NEW: Additional variables for the expanded form
  // Driver License Information
  TextEditingController driverLicenseNumberController = TextEditingController();
  TextEditingController driverLicenseExpiryController = TextEditingController();
  DateTime? driverLicenseExpiryDate;

  // Vehicle Information
  TextEditingController carTypeController = TextEditingController();
  TextEditingController carPlateNumberController = TextEditingController();
  TextEditingController carLicenseExpiryController = TextEditingController();
  TextEditingController carColorController = TextEditingController();
  DateTime? carLicenseExpiryDate;

  // Additional Images
  File? carFrontLicenseImage;
  File? carBackLicenseImage;
  File? carImage;

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  // NEW: PageView variables
  PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Add new variables for tracking document status
  bool hasPendingDocuments = false;
  bool hasApprovedDocuments = false;
  bool hasRejectedDocuments = false;
  String? rejectionReason;

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

    // NEW: Add lifecycle listener to detect when screen becomes visible again
    // Use multiple frame delays to ensure proper widget initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          _restoreScreenState();
        }
      });
    });
  }

  // NEW: Method to preserve screen state
  void _preserveScreenState() {
    // Store current state in shared preferences or local storage
    Map<String, dynamic> screenState = {
      'currentPage': _currentPage,
      'frontIdImagePath': frontIdImage?.path,
      'backIdImagePath': backIdImage?.path,
      'frontLicenseImagePath': frontLicenseImage?.path,
      'backLicenseImagePath': backLicenseImage?.path,
      'carFrontLicenseImagePath': carFrontLicenseImage?.path,
      'carBackLicenseImagePath': carBackLicenseImage?.path,
      'carImagePath': carImage?.path,
      'driverLicenseNumber': driverLicenseNumberController.text,
      'driverLicenseExpiry': driverLicenseExpiryController.text,
      'carType': carTypeController.text,
      'carPlateNumber': carPlateNumberController.text,
      'carLicenseExpiry': carLicenseExpiryController.text,
      'carColor': carColorController.text,
      'driverLicenseExpiryDate': driverLicenseExpiryDate?.toIso8601String(),
      'carLicenseExpiryDate': carLicenseExpiryDate?.toIso8601String(),
    };

    // Store in SharedPreferences
    sharedPref.setString('documents_screen_state', jsonEncode(screenState));
  }

  // NEW: Method to restore screen state
  void _restoreScreenState() {
    String? stateJson = sharedPref.getString('documents_screen_state');
    if (stateJson != null && stateJson.isNotEmpty) {
      try {
        Map<String, dynamic> screenState = jsonDecode(stateJson);

        setState(() {
          _currentPage = screenState['currentPage'] ?? 0;

          // Restore image files
          if (screenState['frontIdImagePath'] != null) {
            frontIdImage = File(screenState['frontIdImagePath']);
          }
          if (screenState['backIdImagePath'] != null) {
            backIdImage = File(screenState['backIdImagePath']);
          }
          if (screenState['frontLicenseImagePath'] != null) {
            frontLicenseImage = File(screenState['frontLicenseImagePath']);
          }
          if (screenState['backLicenseImagePath'] != null) {
            backLicenseImage = File(screenState['backLicenseImagePath']);
          }
          if (screenState['carFrontLicenseImagePath'] != null) {
            carFrontLicenseImage =
                File(screenState['carFrontLicenseImagePath']);
          }
          if (screenState['carBackLicenseImagePath'] != null) {
            carBackLicenseImage = File(screenState['carBackLicenseImagePath']);
          }
          if (screenState['carImagePath'] != null) {
            carImage = File(screenState['carImagePath']);
          }

          // Restore text fields
          driverLicenseNumberController.text =
              screenState['driverLicenseNumber'] ?? '';
          driverLicenseExpiryController.text =
              screenState['driverLicenseExpiry'] ?? '';
          carTypeController.text = screenState['carType'] ?? '';
          carPlateNumberController.text = screenState['carPlateNumber'] ?? '';
          carLicenseExpiryController.text =
              screenState['carLicenseExpiry'] ?? '';
          carColorController.text = screenState['carColor'] ?? '';

          // Restore dates
          if (screenState['driverLicenseExpiryDate'] != null) {
            driverLicenseExpiryDate =
                DateTime.parse(screenState['driverLicenseExpiryDate']);
          }
          if (screenState['carLicenseExpiryDate'] != null) {
            carLicenseExpiryDate =
                DateTime.parse(screenState['carLicenseExpiryDate']);
          }
        });

        // Navigate to the correct page after state restoration
        // Don't navigate immediately - let the widget build first
        if (_currentPage > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted && _pageController.hasClients) {
                try {
                  _pageController.jumpToPage(_currentPage);
                } catch (e) {
                  print('Error jumping to page $_currentPage: $e');
                  // Reset to first page if navigation fails
                  setState(() {
                    _currentPage = 0;
                  });
                }
              }
            });
          });
        }
      } catch (e) {
        print('Error restoring screen state: $e');
        // Clear corrupted state
        sharedPref.remove('documents_screen_state');
      }
    }
  }

  // NEW: Method to clear preserved state
  void _clearPreservedState() {
    sharedPref.remove('documents_screen_state');
  }

  @override
  void dispose() {
    // NEW: Preserve state before disposal unless form is completed
    if (!_isSubmissionCompleted()) {
      _preserveScreenState();
    }

    _fadeController.dispose();
    _pageController.dispose(); // NEW: Dispose page controller
    driverLicenseNumberController.dispose();
    driverLicenseExpiryController.dispose();
    carTypeController.dispose();
    carPlateNumberController.dispose();
    carLicenseExpiryController.dispose();
    carColorController.dispose(); // NEW: Dispose car color controller
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

  // NEW: Select driver license expiry date
  Future<void> selectDriverLicenseExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          driverLicenseExpiryDate ?? DateTime.now().add(Duration(days: 365)),
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
    if (picked != null) {
      setState(() {
        driverLicenseExpiryDate = picked;
        driverLicenseExpiryController.text = picked.toString().split(' ')[0];
      });
    }
  }

  // NEW: Select car license expiry date
  Future<void> selectCarLicenseExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          carLicenseExpiryDate ?? DateTime.now().add(Duration(days: 365)),
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
    if (picked != null) {
      setState(() {
        carLicenseExpiryDate = picked;
        carLicenseExpiryController.text = picked.toString().split(' ')[0];
      });
    }
  }

  // NEW: Validate all form fields
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Check required images
    if (frontIdImage == null || backIdImage == null) {
      toast("يجب تحديد صورتي بطاقة الهوية");
      return false;
    }

    if (frontLicenseImage == null || backLicenseImage == null) {
      toast("يجب تحديد صورتي رخصة القيادة");
      return false;
    }

    if (carFrontLicenseImage == null || carBackLicenseImage == null) {
      toast("يجب تحديد صورتي رخصة السيارة");
      return false;
    }

    if (carImage == null) {
      toast("يجب تحديد صورة السيارة");
      return false;
    }

    if (driverLicenseExpiryDate == null) {
      toast("يجب تحديد تاريخ انتهاء رخصة القيادة");
      return false;
    }

    if (carLicenseExpiryDate == null) {
      toast("يجب تحديد تاريخ انتهاء رخصة السيارة");
      return false;
    }

    // NEW: Check car color
    if (carColorController.text.trim().isEmpty) {
      toast("يجب تحديد لون السيارة");
      return false;
    }

    return true;
  }

  void init() async {
    afterBuildCreated(() async {
      appStore.setLoading(true);
      await fetchData();
      await getDocument();
      await driverDocument();

      // Check document status after loading data but don't show dialogs automatically
      checkDocumentStatus();
      appStore.setLoading(false);
    });
  }

  Future<void> fetchData() async {
    await Future.wait([
      getUserDetail(userId: sharedPref.getInt(USER_ID)),
      getServices(),
    ]).then((value) {
      final userDetailModel = value[0] as UserDetailModel;
      final serviceModel = value[1] as ServiceModel;

      userData = userDetailModel.data!;
      serviceList = serviceModel.data!;

      if (userData!.userDetail != null) {
        carTypeController.text = userData!.userDetail!.carModel ?? '';
        carColorController.text = userData!.userDetail!.carColor ?? '';
        carPlateNumberController.text =
            userData!.userDetail!.carPlateNumber ?? '';
        carLicenseExpiryController.text =
            userData!.userDetail!.carProductionYear ?? '';
      }
      selectedServiceId = userData!.serviceId;

      setState(() {});
    }).catchError((e) {
      log(e.toString());
    });
  }

  Future<void> _refreshData() async {
    // Reset UI state first
    setState(() {
      selectedDocument = null;
      docId = 0;
      isExpire = 0;
      frontIdImage = null;
      backIdImage = null;
      frontLicenseImage = null;
      backLicenseImage = null;
      combinedFilePath = null;
      currentlySelectingImageType = null;

      // Reset new fields
      driverLicenseNumberController.clear();
      driverLicenseExpiryController.clear();
      carTypeController.clear();
      carPlateNumberController.clear();
      carLicenseExpiryController.clear();
      carColorController.clear(); // NEW: Reset car color
      driverLicenseExpiryDate = null;
      carLicenseExpiryDate = null;
      carFrontLicenseImage = null;
      carBackLicenseImage = null;
      carImage = null;

      // Reset page view
      _currentPage = 0;
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

  Future<File> compressFile(File file, {String? documentType}) async {
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

      // Generate unique filename based on document type and timestamp
      String uniqueFileName = documentType != null
          ? '${documentType}_${DateTime.now().millisecondsSinceEpoch}.png'
          : 'image_${DateTime.now().millisecondsSinceEpoch}.png';

      File file2 = await File('${d.path}/$uniqueFileName').create();
      file2.writeAsBytesSync(result);

      print('💾 Compressed image saved to: ${file2.path}');
      return file2;
    } catch (e) {
      log('فشل ضغط الملف: ${e.toString()}');
      return file;
    }
  }

  // Function to combine images and details into a professional PDF
  Future<String?> combineImagesToPDF() async {
    if (frontIdImage == null ||
        backIdImage == null ||
        frontLicenseImage == null ||
        backLicenseImage == null) {
      toast("يجب تحديد جميع الصور الأربع");
      return null;
    }

    try {
      final pdf = pw.Document();
      Directory tempDir = await getTemporaryDirectory();

      // Compress all images first
      File compressedFrontId = await compressFile(frontIdImage!);
      File compressedBackId = await compressFile(backIdImage!);
      File compressedFrontLicense = await compressFile(frontLicenseImage!);
      File compressedBackLicense = await compressFile(backLicenseImage!);
      File? compressedCarFrontLicense = carFrontLicenseImage != null
          ? await compressFile(carFrontLicenseImage!)
          : null;
      File? compressedCarBackLicense = carBackLicenseImage != null
          ? await compressFile(carBackLicenseImage!)
          : null;
      File? compressedCarImage =
          carImage != null ? await compressFile(carImage!) : null;

      // Read image bytes
      Uint8List frontIdBytes = await compressedFrontId.readAsBytes();
      Uint8List backIdBytes = await compressedBackId.readAsBytes();
      Uint8List frontLicenseBytes = await compressedFrontLicense.readAsBytes();
      Uint8List backLicenseBytes = await compressedBackLicense.readAsBytes();
      Uint8List? carFrontLicenseBytes =
          compressedCarFrontLicense?.readAsBytesSync();
      Uint8List? carBackLicenseBytes =
          compressedCarBackLicense?.readAsBytesSync();
      Uint8List? carImageBytes = compressedCarImage?.readAsBytesSync();

      // Create professional PDF with cover page and proper layout

      // Professional Cover Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            final currentDate = DateTime.now();
            final referenceNumber = 'DOC-${currentDate.millisecondsSinceEpoch}';
            final formattedDate =
                '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

            return pw.Container(
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColors.blue50, PdfColors.white, PdfColors.grey50],
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                ),
              ),
              child: pw.Padding(
                padding: pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 40),

                    // Professional Header Badge
                    pw.Container(
                      padding:
                          pw.EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue800,
                        borderRadius: pw.BorderRadius.circular(25),
                      ),
                      child: pw.Text(
                        'Official Documents',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 40),

                    // Professional Logo Container
                    pw.Container(
                      width: 120,
                      height: 120,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        shape: pw.BoxShape.circle,
                        border:
                            pw.Border.all(color: PdfColors.blue800, width: 3),
                      ),
                    ),

                    pw.SizedBox(height: 30),

                    // Main Professional Title
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.all(30),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(20),
                        border:
                            pw.Border.all(color: PdfColors.blue100, width: 2),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Driver Official Documents',
                            style: pw.TextStyle(
                              fontSize: 32,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 15),
                          pw.Container(
                            height: 3,
                            width: 100,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue600,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                          ),
                          pw.SizedBox(height: 15),
                          pw.Text(
                            'Complete set of official documents and identification',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.normal,
                              color: PdfColors.blue600,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 40),

                    // Professional Document Info Cards
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: pw.EdgeInsets.all(20),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(15),
                              border: pw.Border.all(
                                  color: PdfColors.green200, width: 1.5),
                            ),
                            child: pw.Column(
                              children: [
                                pw.SizedBox(height: 10),
                                pw.Text(
                                  'Submission Date',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey600,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  formattedDate,
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    color: PdfColors.green800,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Container(
                            padding: pw.EdgeInsets.all(20),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(15),
                              border: pw.Border.all(
                                  color: PdfColors.orange200, width: 1.5),
                            ),
                            child: pw.Column(
                              children: [
                                pw.SizedBox(height: 10),
                                pw.Text(
                                  'Reference Number',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey600,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  referenceNumber,
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    color: PdfColors.orange800,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 40),

                    // Status Badge
                    pw.Container(
                      padding:
                          pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.yellow50,
                        borderRadius: pw.BorderRadius.circular(15),
                        border:
                            pw.Border.all(color: PdfColors.yellow200, width: 1),
                      ),
                      child: pw.Text(
                        'Under Review & Approval',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.yellow800,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),

                    pw.Spacer(),

                    // Security Notice
                    pw.Container(
                      padding: pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Text(
                        'Protected & Secure - For Official Use Only',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Professional Driver Information Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColors.blue50, PdfColors.white, PdfColors.grey50],
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                ),
              ),
              child: pw.Padding(
                padding: pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfHeader("driver information", context),
                    pw.SizedBox(height: 30),

                    // Driver License Details
                    _buildPdfSection(
                      "driver license details",
                      [
                        _buildPdfInfoRow("driver license number",
                            driverLicenseNumberController.text),
                        _buildPdfInfoRow("driver license expiry",
                            driverLicenseExpiryController.text),
                      ],
                    ),

                    // Vehicle Information
                    _buildPdfSection(
                      "car information",
                      [
                        _buildPdfInfoRow("car type", carTypeController.text),
                        _buildPdfInfoRow("car color", carColorController.text),
                        _buildPdfInfoRow(
                            "car plate number", carPlateNumberController.text),
                        _buildPdfInfoRow("car license expiry",
                            carLicenseExpiryController.text),
                      ],
                    ),

                    pw.Spacer(),
                    _buildPdfFooter(context),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Professional ID Documents Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColors.blue50, PdfColors.white, PdfColors.grey50],
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                ),
              ),
              child: pw.Padding(
                padding: pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfHeader("national documents", context),
                    pw.SizedBox(height: 30),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfImageContainer(
                            "front id",
                            frontIdBytes,
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: _buildPdfImageContainer(
                            "back id",
                            backIdBytes,
                          ),
                        ),
                      ],
                    ),
                    pw.Spacer(),
                    _buildPdfFooter(context),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Professional Driver License Documents Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColors.blue50, PdfColors.white, PdfColors.grey50],
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                ),
              ),
              child: pw.Padding(
                padding: pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfHeader("driver license", context),
                    pw.SizedBox(height: 30),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfImageContainer(
                            "front license",
                            frontLicenseBytes,
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: _buildPdfImageContainer(
                            "back license",
                            backLicenseBytes,
                          ),
                        ),
                      ],
                    ),
                    pw.Spacer(),
                    _buildPdfFooter(context),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Vehicle Documents Page
      if (carFrontLicenseBytes != null && carBackLicenseBytes != null) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPdfHeader("car documents", context),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildPdfImageContainer(
                          "car license",
                          carFrontLicenseBytes,
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: _buildPdfImageContainer(
                          "car license",
                          carBackLicenseBytes,
                        ),
                      ),
                    ],
                  ),
                  if (carImageBytes != null) ...[
                    pw.SizedBox(height: 20),
                    pw.Text(
                      "car picture",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPdfImageContainer(
                      " car picture",
                      carImageBytes,
                      isFullWidth: true,
                    ),
                  ],
                  pw.Spacer(),
                  _buildPdfFooter(context),
                ],
              );
            },
          ),
        );
      }

      // Save PDF to temporary file
      String pdfPath =
          '${tempDir.path}/driver_documents_${DateTime.now().millisecondsSinceEpoch}.pdf';
      File pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      return pdfPath;
    } catch (e) {
      log('failed to merge images: ${e.toString()}');
      toast('failed to merge images');
      return null;
    }
  }

  // Professional PDF header
  pw.Widget _buildPdfHeader(String title, pw.Context context) {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue800, PdfColors.blue600],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(15),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  height: 3,
                  width: 60,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFFFFF30'),
              borderRadius: pw.BorderRadius.circular(20),
              border: pw.Border.all(color: PdfColor.fromHex('#FFFFFF50')),
            ),
            child: pw.Text(
              'Page ${context.pageNumber}',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get proper titles
  String _getArabicTitle(String englishTitle) {
    switch (englishTitle.toLowerCase()) {
      case 'driver information':
        return 'Driver Information';
      case 'national documents':
        return 'National Documents';
      case 'driver license':
        return 'Driver License';
      case 'car documents':
        return 'Car Documents';
      default:
        return englishTitle;
    }
  }

  // Professional PDF section
  pw.Widget _buildPdfSection(String title, List<pw.Widget> content) {
    String arabicSectionTitle = _getArabicSectionTitle(title);

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(15),
        border: pw.Border.all(color: PdfColors.blue100, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section Header
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.blue50, PdfColors.blue100],
                begin: pw.Alignment.centerLeft,
                end: pw.Alignment.centerRight,
              ),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(15),
                topRight: pw.Radius.circular(15),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue600,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Icon(
                    _getSectionIcon(title),
                    size: 16,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text(
                  arabicSectionTitle,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          pw.Padding(
            padding: pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get section titles
  String _getArabicSectionTitle(String englishTitle) {
    switch (englishTitle.toLowerCase()) {
      case 'driver license details':
        return 'Driver License Details';
      case 'car information':
        return 'Car Information';
      default:
        return englishTitle;
    }
  }

  // Helper method to get section icons
  pw.IconData _getSectionIcon(String title) {
    switch (title.toLowerCase()) {
      case 'driver license details':
        return pw.IconData(0xe192); // license icon
      case 'car information':
        return pw.IconData(0xe158); // car icon
      default:
        return pw.IconData(0xe192);
    }
  }

  // Professional PDF info row
  pw.Widget _buildPdfInfoRow(String label, String value) {
    String arabicLabel = _getArabicLabel(label);

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 12),
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Icon(
              _getFieldIcon(label),
              size: 12,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              arabicLabel,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Text(
                value.isNotEmpty ? value : 'Not Specified',
                style: pw.TextStyle(
                  color: value.isNotEmpty ? PdfColors.black : PdfColors.grey500,
                  fontWeight: pw.FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get field labels
  String _getArabicLabel(String englishLabel) {
    switch (englishLabel.toLowerCase()) {
      case 'driver license number':
        return 'Driver License Number';
      case 'driver license expiry':
        return 'Driver License Expiry';
      case 'car type':
        return 'Car Type';
      case 'car color':
        return 'Car Color';
      case 'car plate number':
        return 'Car Plate Number';
      case 'car license expiry':
        return 'Car License Expiry';
      default:
        return englishLabel;
    }
  }

  // Helper method to get field icons
  pw.IconData _getFieldIcon(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'driver license number':
      case 'driver license expiry':
        return pw.IconData(0xe192); // license icon
      case 'car type':
      case 'car color':
      case 'car plate number':
      case 'car license expiry':
        return pw.IconData(0xe158); // car icon
      default:
        return pw.IconData(0xe192);
    }
  }

  // Professional PDF image container
  pw.Widget _buildPdfImageContainer(String label, Uint8List imageBytes,
      {bool isFullWidth = false}) {
    String arabicImageLabel = _getArabicImageLabel(label);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(13),
        border: pw.Border.all(color: PdfColors.blue100, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Image Label
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(13),
                topRight: pw.Radius.circular(13),
              ),
            ),
            child: pw.Text(
              arabicImageLabel,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          // Image Container
          pw.Container(
            padding: pw.EdgeInsets.all(15),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: isFullWidth ? pw.BoxFit.fitWidth : pw.BoxFit.contain,
                width: isFullWidth ? null : double.infinity,
                height: isFullWidth ? 200 : 180,
              ),
            ),
          ),
          // Image Footer
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(13),
                bottomRight: pw.Radius.circular(13),
              ),
            ),
            child: pw.Text(
              'Verified & Uploaded Successfully',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.green600,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get image labels
  String _getArabicImageLabel(String englishLabel) {
    switch (englishLabel.toLowerCase()) {
      case 'front id':
        return 'Front ID';
      case 'back id':
        return 'Back ID';
      case 'front license':
        return 'Front License';
      case 'back license':
        return 'Back License';
      case 'car front license':
        return 'Car Front License';
      case 'car back license':
        return 'Car Back License';
      case 'car image':
        return 'Car Image';
      default:
        return englishLabel;
    }
  }

  // Professional PDF footer
  pw.Widget _buildPdfFooter(pw.Context context) {
    final currentDate = DateTime.now();
    final formattedDate =
        '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
    final referenceNumber = 'DOC-${currentDate.millisecondsSinceEpoch}';

    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.grey50, PdfColors.grey100],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Generation Date
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  'Generated on: $formattedDate',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              // Reference Number
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  'Reference: $referenceNumber',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          // Security Notice
          pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Text(
              'Protected Official Document - For Official Use Only',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.blue700,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Function to pick image for specific document type
  Future<void> pickImageForDocument(String documentType) async {
    print('🎯 starting image selection for document: $documentType');

    // Set the currently selecting type to track it
    currentlySelectingImageType = documentType;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(defaultRadius),
              topRight: Radius.circular(defaultRadius))),
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: ImageSourceDialog(
                onCamera: () async {
                  Navigator.pop(context);
                  try {
                    var result = await ImagePicker().pickImage(
                        source: ImageSource.camera, imageQuality: 100);
                    if (result != null) {
                      File imageFile = File(result.path);
                      File compressedFile = await compressFile(imageFile,
                          documentType: documentType);
                      int b = await compressedFile.length();
                      double fileSizeInMB = b / (1024 * 1024);
                      if (fileSizeInMB > 2) {
                        return toast("حجم الملف يجب أن يكون أقل من 2 ميجابايت");
                      }
                      _setImageForDocumentType(documentType, compressedFile);
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
                    File imageFile = File(result.path);
                    File compressedFile = await compressFile(imageFile,
                        documentType: documentType);
                    int b = await compressedFile.length();
                    double fileSizeInMB = b / (1024 * 1024);
                    if (fileSizeInMB > 2) {
                      return toast("حجم الملف يجب أن يكون أقل من 2 ميجابايت");
                    }
                    _setImageForDocumentType(documentType, compressedFile);
                  }
                },
                onFile: () async {
                  Navigator.pop(context);
                  // For document images, we'll still use image picker
                  var result = await ImagePicker().pickImage(
                      source: ImageSource.gallery, imageQuality: 100);
                  if (result != null) {
                    File imageFile = File(result.path);
                    File compressedFile = await compressFile(imageFile,
                        documentType: documentType);
                    int b = await compressedFile.length();
                    double fileSizeInMB = b / (1024 * 1024);
                    if (fileSizeInMB > 2) {
                      return toast("حجم الملف يجب أن يكون أقل من 2 ميجابايت");
                    }
                    _setImageForDocumentType(documentType, compressedFile);
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

  void _setImageForDocumentType(String documentType, File imageFile) {
    print('=== SETTING IMAGE FOR: $documentType ===');
    print('original image path: ${imageFile.path}');
    print('image exists: ${imageFile.existsSync()}');
    print('image size: ${imageFile.lengthSync()} bytes');

    // Create a completely new file with unique name to avoid any reference issues
    Directory tempDir = Directory.systemTemp;
    String uniqueFileName =
        '${documentType}_final_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}.png';
    File uniqueFile = File('${tempDir.path}/$uniqueFileName');

    // Read and copy the image bytes to the new unique file
    Uint8List imageBytes = imageFile.readAsBytesSync();
    uniqueFile.writeAsBytesSync(imageBytes);

    // Generate hash to verify uniqueness
    String imageHash = base64Encode(
        imageBytes.take(100).toList()); // Hash first 100 bytes for speed

    print('📄 we created a unique file: ${uniqueFile.path}');
    print('📄 unique file size: ${uniqueFile.lengthSync()} bytes');
    print('🔍 first 100 bytes hash: $imageHash');

    setState(() {
      // Clear the currently selecting type first
      currentlySelectingImageType = null;

      // Set the specific image based on document type with the unique file
      switch (documentType) {
        case 'front_id':
          frontIdImage = uniqueFile;
          print('✅ we set the front face: ${frontIdImage?.path}');
          print('✅ front face size: ${frontIdImage?.lengthSync()} bytes');
          break;
        case 'back_id':
          backIdImage = uniqueFile;
          print('✅ we set the back face: ${backIdImage?.path}');
          print('✅ back face size: ${backIdImage?.lengthSync()} bytes');
          break;
        case 'front_license':
          frontLicenseImage = uniqueFile;
          print('✅ SET FRONT LICENSE: ${frontLicenseImage?.path}');
          print(
              '✅ front license size: ${frontLicenseImage?.lengthSync()} bytes');
          break;
        case 'back_license':
          backLicenseImage = uniqueFile;
          print(
              '✅ قمنا بتعيين رخصة القيادة الخلفية: ${backLicenseImage?.path}');
          print('✅ back license size: ${backLicenseImage?.lengthSync()} bytes');
          break;
        case 'car_front_license':
          carFrontLicenseImage = uniqueFile;
          print('✅ we set the front license: ${carFrontLicenseImage?.path}');
          print(
              '✅ front license size: ${carFrontLicenseImage?.lengthSync()} bytes');
          break;
        case 'car_back_license':
          carBackLicenseImage = uniqueFile;
          print('✅ we set the back license: ${carBackLicenseImage?.path}');
          print(
              '✅ back license size: ${carBackLicenseImage?.lengthSync()} bytes');
          break;
        case 'car_image':
          carImage = uniqueFile;
          print('✅ we set the car image: ${carImage?.path}');
          print('✅ car image size: ${carImage?.lengthSync()} bytes');
          break;
        default:
          print('❌ undefined document: $documentType');
          return;
      }

      // Print current state of all images with detailed info
      print('--- images state after setting $documentType ---');
      if (frontIdImage != null) {
        print(
            'front face: ${frontIdImage!.path} (${frontIdImage!.lengthSync()} bytes)');
      } else {
        print('front face: NULL');
      }
      if (backIdImage != null) {
        print(
            'back face: ${backIdImage!.path} (${backIdImage!.lengthSync()} bytes)');
      } else {
        print('back face: NULL');
      }
      if (frontLicenseImage != null) {
        print(
            'front license: ${frontLicenseImage!.path} (${frontLicenseImage!.lengthSync()} bytes)');
      } else {
        print('front license: NULL');
      }
      if (backLicenseImage != null) {
        print(
            'back license: ${backLicenseImage!.path} (${backLicenseImage!.lengthSync()} bytes)');
      } else {
        print('back license: NULL');
      }
      if (carFrontLicenseImage != null) {
        print(
            'front license: ${carFrontLicenseImage!.path} (${carFrontLicenseImage!.lengthSync()} bytes)');
      } else {
        print('front license: NULL');
      }
      if (carBackLicenseImage != null) {
        print(
            'back license: ${carBackLicenseImage!.path} (${carBackLicenseImage!.lengthSync()} bytes)');
      } else {
        print('back license: NULL');
      }
      if (carImage != null) {
        print('car image: ${carImage!.path} (${carImage!.lengthSync()} bytes)');
      } else {
        print('car image: NULL');
      }
      print('========================================');
    });
  }

  // Function to upload combined PDF
  Future<void> uploadCombinedDocument() async {
    // Check if there are pending documents
    if (hasPendingDocuments) {
      showPendingDocumentsDialog();
      return;
    }

    // Check if there are rejected documents
    if (hasRejectedDocuments) {
      showRejectedDocumentsDialog();
      return;
    }

    if (frontIdImage == null ||
        backIdImage == null ||
        frontLicenseImage == null ||
        backLicenseImage == null) {
      toast("يجب تحديد جميع     الصور الأربع");
      return;
    }

    // Immediately set as pending and show pending page
    setState(() {
      hasPendingDocuments = true;
      hasApprovedDocuments = false;
      hasRejectedDocuments = false;
    });

    // NEW: Clear preserved state since submission started
    _clearPreservedState();

    // Show success message and navigate to pending page immediately
    toast("تم تقديم المستندات بنجاح! 🎉 يمكنك مشاهدة شهادة التأكيد.");

    // Continue upload process in background
    _uploadInBackground();
  }

  // Background upload process
  Future<void> _uploadInBackground() async {
    try {
      // Show loading indicator for background process
      appStore.setLoading(true);

      // Combine images into PDF
      String? pdfPath = await combineImagesToPDF();
      if (pdfPath == null) {
        appStore.setLoading(false);
        // If PDF creation fails, reset status
        setState(() {
          hasPendingDocuments = false;
        });
        toast("فشل في إعداد المستندات");
        return;
      }

      // Use the existing addDocument function with the combined PDF
      setState(() {
        imagePath = pdfPath;
      });

      // Find or create a generic document ID for combined documents
      int combinedDocId = docId != 0
          ? docId
          : (documentList.isNotEmpty ? documentList.first.id! : 1);

      // Upload the document
      await addDocument(combinedDocId, isExpire, dateTime: selectedDate);

      // Stop loading indicator
      appStore.setLoading(false);

      // Refresh document list to get the latest status in background
      await driverDocument();

      // Don't call checkDocumentStatus immediately to avoid resetting pending status
      // checkDocumentStatus();
    } catch (error) {
      // Stop loading and show error
      appStore.setLoading(false);

      // If there's an error, reset the pending status
      setState(() {
        hasPendingDocuments = false;
      });

      toast("حدث خطأ أثناء الإرسال: ${error.toString()}");
    }
  }

  // Helper method to build image upload box
  Widget _buildImageUploadBox({
    required String title,
    required File? image,
    required VoidCallback onTap,
    required IconData icon,
    required String documentType,
  }) {
    bool hasImage = image != null;
    print(
        'Building box for $documentType, hasImage: $hasImage, imagePath: ${image?.path}');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate height based on available width with minimum and maximum constraints
        double height =
            constraints.maxWidth.isFinite ? constraints.maxWidth * 0.8 : 120;
        height = height.clamp(100.0, 200.0);

        return InkWell(
          key: ValueKey('image_box_$documentType'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: height,
            constraints: BoxConstraints(
              minHeight: 100,
              maxHeight: 200,
              minWidth: 80,
            ),
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.green.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage ? Colors.green : Colors.grey.shade300,
                width: hasImage ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (hasImage && image!.existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image for $documentType: $error');
                        return _buildEmptyImageContainer(title, icon);
                      },
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: hasImage
                        ? Colors.black.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hasImage
                                ? Colors.white.withOpacity(0.9)
                                : primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasImage ? Icons.check : icon,
                            color: hasImage ? Colors.green : primaryColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            title,
                            style: boldTextStyle(
                              size: 11,
                              color: hasImage ? Colors.white : primaryColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!hasImage) ...[
                          SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              "اضغط للتحديد",
                              style: secondaryTextStyle(
                                size: 10,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build empty image container
  Widget _buildEmptyImageContainer(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryColor, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: boldTextStyle(size: 11, color: primaryColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            "فشل في تحميل الصورة",
            style: secondaryTextStyle(size: 9, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to check if all images are selected
  bool _areAllImagesSelected() {
    return frontIdImage != null &&
        backIdImage != null &&
        frontLicenseImage != null &&
        backLicenseImage != null;
  }

  // Helper method to get count of selected images
  int _getSelectedImagesCount() {
    int count = 0;
    if (frontIdImage != null) count++;
    if (backIdImage != null) count++;
    if (frontLicenseImage != null) count++;
    if (backLicenseImage != null) count++;
    if (carFrontLicenseImage != null) count++;
    if (carBackLicenseImage != null) count++;
    if (carImage != null) count++;
    return count;
  }

  // NEW: Helper methods for modern PageView design

  // Navigate to next page
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      // NEW: Preserve state before navigation
      _preserveScreenState();

      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Navigate to previous page
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Build modern page indicator
  Widget _buildPageIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(_totalPages, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 32 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == index
                  ? primaryColor
                  : primaryColor.withOpacity(0.3),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build modern progress header
  Widget _buildProgressHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("التقدم", style: boldTextStyle(size: 18)),
              Text("${_getSelectedImagesCount()}/7",
                  style: boldTextStyle(size: 18, color: primaryColor)),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: _getSelectedImagesCount() / 7,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getSelectedImagesCount() == 7 ? Colors.green : primaryColor,
            ),
            minHeight: 8,
          ),
          SizedBox(height: 8),
          Text(
            _getSelectedImagesCount() == 7
                ? "تم اكتمال جميع المتطلبات! 🎉"
                : "يرجى إكمال جميع الحقول والصور المطلوبة",
            style: secondaryTextStyle(
              color: _getSelectedImagesCount() == 7
                  ? Colors.green
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // NEW: Always preserve state before navigation
        _preserveScreenState();

        // Check document status before allowing navigation
        if (hasPendingDocuments) {
          // Documents are pending - show dialog and prevent navigation
          showPendingDocumentsDialog();
          return false;
        }

        if (hasRejectedDocuments) {
          // Documents are rejected - show dialog and prevent navigation
          showRejectedDocumentsDialog();
          return false;
        }

        // If navigating within the form pages, handle internal navigation
        if (_currentPage > 0) {
          _previousPage();
          return false;
        }

        // Allow normal back navigation and preserve state
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Stack(
          children: <Widget>[
            // Show only pending status page when documents are pending
            if (hasPendingDocuments)
              _buildProfessionalSubmissionConfirmation()
            // Show only rejected status page when documents are rejected
            else if (hasRejectedDocuments)
              _buildRejectedOnlyPage()
            else
              Column(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      const BackAppBar(title: 'الوثائق والمستندات'),
                      //ogress header (only show if not pending)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildProgressHeader(),
                      ),
                    ],
                  ),

                  // PageView content
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemCount: _totalPages,
                          itemBuilder: (context, index) {
                            // NEW: Add safety check for widget building
                            try {
                              switch (index) {
                                case 0:
                                  return _buildWelcomePage();
                                case 1:
                                  return _buildPersonalDocumentsPage();
                                case 2:
                                  return _buildDriverLicensePage();
                                case 3:
                                  return _buildVehicleInfoPage();
                                case 4:
                                  return _buildVehicleDocumentsPage();
                                case 5:
                                  return _buildReviewPage();
                                default:
                                  return Container();
                              }
                            } catch (e) {
                              print('Error building page $index: $e');
                              // Return a safe fallback widget
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 50, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('حدث خطأ في تحميل الصفحة',
                                        style: TextStyle(color: Colors.grey)),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Reset to first page
                                        setState(() {
                                          _currentPage = 0;
                                        });
                                        _pageController.animateToPage(0,
                                            duration:
                                                Duration(milliseconds: 300),
                                            curve: Curves.easeInOut);
                                      },
                                      child: Text('العودة للبداية'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  // Page indicator
                  _buildPageIndicator(),

                  // Navigation buttons
                  _buildNavigationButtons(),
                ],
              ),

            // Loading overlay
            Observer(
              builder: (_) => Visibility(
                visible: appStore.isLoading,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "جاري رفع المستندات...",
                            style: boldTextStyle(size: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "يرجى الانتظار",
                            style: secondaryTextStyle(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: null,
      ),
    );
  }

  // Build dedicated pending-only page
  Widget _buildPendingOnlyPage() {
    return Scaffold(
      appBar: const BackAppBar(title: 'الوثائق والمستندات'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large pending icon with animation
              Container(
                padding: EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pending_actions,
                  size: 60,
                  color: Colors.orange,
                ),
              ),

              SizedBox(height: 20),

              // Main message
              Text(
                "المستندات قيد المراجعة",
                style: boldTextStyle(size: 20, color: Colors.black87),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16),

              Text(
                "تم استلام مستنداتك بنجاح",
                style: boldTextStyle(size: 18, color: Colors.orange),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),

              Text(
                "يرجى الانتظار حتى تتم مراجعة واعتماد مستنداتك من قبل فريق الإدارة",
                style:
                    secondaryTextStyle(size: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40),

              // Status info card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 12),
                        Text(
                          "معلومات المراجعة",
                          style: boldTextStyle(size: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildStatusRow(
                      "وقت التقديم",
                      DateTime.now().toString().split('.')[0],
                      Icons.access_time,
                    ),
                    Divider(height: 24),
                    _buildStatusRow(
                      "الحالة الحالية",
                      "قيد المراجعة",
                      Icons.hourglass_empty,
                      color: Colors.orange,
                    ),
                    Divider(height: 24),
                    _buildStatusRow(
                      "الوقت المتوقع",
                      "24-48 ساعة",
                      Icons.schedule,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Note
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "سيتم إشعارك فور اكتمال مراجعة مستنداتك",
                        style: secondaryTextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),

              // Refresh button
              Container(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    await _refreshDocumentStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "تحديث حالة المراجعة",
                        style: boldTextStyle(color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Build individual pages for PageView

  // Page 0: Welcome page
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),

          // Welcome animation
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.1),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 80,
              color: primaryColor,
            ),
          ),

          SizedBox(height: 30),

          Text(
            "مرحباً بك في تسجيل المستندات",
            style: boldTextStyle(size: 24, color: Colors.black87),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16),

          Text(
            "سنحتاج إلى بعض المستندات والمعلومات لإكمال ملفك الشخصي كسائق معتمد",
            style: secondaryTextStyle(size: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 40),

          // Features list
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "ما سنحتاجه منك:",
                  style: boldTextStyle(size: 18),
                ),
                SizedBox(height: 20),
                _buildFeatureItem(
                  icon: Icons.credit_card,
                  title: "بطاقة الهوية",
                  subtitle: "الوجه الأمامي والخلفي",
                ),
                _buildFeatureItem(
                  icon: Icons.drive_eta,
                  title: "رخضه القياده و الاوراق الرسميه",
                  subtitle: "رخصة سارية المفعول",
                ),
                _buildFeatureItem(
                  icon: Icons.directions_car,
                  title: "معلومات السيارة",
                  subtitle: "نوع وتفاصيل السيارة",
                ),
                _buildFeatureItem(
                  icon: Icons.description,
                  title: "وثائق المركبة",
                  subtitle: "رخصة وصور السيارة",
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "جميع معلوماتك محمية وآمنة",
                    style: boldTextStyle(color: Colors.green, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build feature item for welcome page
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: boldTextStyle(size: 16)),
                Text(subtitle, style: secondaryTextStyle(size: 14)),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  // Page 1: Personal documents (ID)
  Widget _buildPersonalDocumentsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: "بطاقة الهوية الشخصية",
            subtitle: "صور واضحة للوجه الأمامي والخلفي",
            icon: Icons.credit_card,
            color: Colors.blue,
          ),
          Card(
            elevation: 2,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "يرجى تصوير بطاقة الهوية بوضوح",
                    style: boldTextStyle(size: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "تأكد من وضوح جميع البيانات والنصوص",
                    style: secondaryTextStyle(),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageUploadBox(
                          title: "الوجه الأمامي",
                          image: frontIdImage,
                          onTap: () => pickImageForDocument('front_id'),
                          icon: Icons.credit_card,
                          documentType: 'front_id',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildImageUploadBox(
                          title: "الوجه الخلفي",
                          image: backIdImage,
                          onTap: () => pickImageForDocument('back_id'),
                          icon: Icons.credit_card,
                          documentType: 'back_id',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 2: Driver License
  Widget _buildDriverLicensePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: "رخصة القيادة الشخصية",
            subtitle: "بيانات وصور رخصة القيادة",
            icon: Icons.drive_eta,
            color: Colors.green,
          ),
          Card(
            color: Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInputField(
                    label: "رقم رخصة القيادة",
                    hint: "أدخل رقم رخصة القيادة",
                    controller: driverLicenseNumberController,
                    icon: Icons.drive_eta,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال رقم رخصة القيادة';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    label: "تاريخ انتهاء رخصة القيادة",
                    hint: "اختر تاريخ انتهاء الرخصة",
                    controller: driverLicenseExpiryController,
                    icon: Icons.calendar_today,
                    readOnly: true,
                    onTap: () => selectDriverLicenseExpiryDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب تحديد تاريخ انتهاء الرخصة';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Text("صور رخصة القيادة", style: boldTextStyle(size: 16)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageUploadBox(
                          title: "الوجه الأمامي",
                          image: frontLicenseImage,
                          onTap: () => pickImageForDocument('front_license'),
                          icon: Icons.drive_eta,
                          documentType: 'front_license',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildImageUploadBox(
                          title: "الوجه الخلفي",
                          image: backLicenseImage,
                          onTap: () => pickImageForDocument('back_license'),
                          icon: Icons.drive_eta,
                          documentType: 'back_license',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 3: Vehicle Information
  Widget _buildVehicleInfoPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: "معلومات المركبة",
            subtitle: "تفاصيل السيارة الأساسية",
            icon: Icons.directions_car,
            color: Colors.orange,
          ),
          Card(
            color: Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInputField(
                    label: "نوع السيارة",
                    hint: "مثال: تويوتا كامري 2020",
                    controller: carTypeController,
                    icon: Icons.directions_car,
                    onChanged: (value) {
                      _autoSaveVehicleInfo();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال نوع السيارة';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    label: "لون السيارة",
                    hint: "مثال: أبيض، أسود، أزرق",
                    controller: carColorController,
                    icon: Icons.palette,
                    onChanged: (value) {
                      _autoSaveVehicleInfo();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال لون السيارة';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    label: "رقم لوحة السيارة",
                    hint: "أدخل رقم لوحة السيارة",
                    controller: carPlateNumberController,
                    icon: Icons.confirmation_number,
                    onChanged: (value) {
                      _autoSaveVehicleInfo();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال رقم لوحة السيارة';
                      }
                      return null;
                    },
                  ),
                  _buildInputField(
                    label: "تاريخ انتهاء رخصة السيارة",
                    hint: "اختر تاريخ انتهاء رخصة السيارة",
                    controller: carLicenseExpiryController,
                    icon: Icons.calendar_today,
                    readOnly: true,
                    onTap: () {
                      selectCarLicenseExpiryDate(context).then((_) {
                        _autoSaveVehicleInfo();
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب تحديد تاريخ انتهاء رخصة السيارة';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'نوع المركبة',
                      hintText: 'اختر نوع المركبة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.directions_car,
                          color: Colors.grey.shade600),
                    ),
                    value: selectedServiceId,
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedServiceId = newValue!;
                      });
                      _autoSaveVehicleInfo();
                    },
                    items: serviceList
                        .map<DropdownMenuItem<int>>((ServiceList service) {
                      return DropdownMenuItem<int>(
                        value: service.id,
                        child: Text(
                          service.name ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600),
                    isExpanded: true,
                    validator: (value) {
                      if (value == null) {
                        return 'الرجاء اختيار نوع المركبة';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Debouncer to prevent too frequent API calls
  Timer? _debounceTimer;

  void _autoSaveVehicleInfo() {
    // Cancel previous timer if it exists
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Set new timer
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (_formKey.currentState!.validate()) {
        _saveVehicleInfo();
      }
    });
  }

  void _saveVehicleInfo() async {
    try {
      await updateVehicleDetail(
        carModel: carTypeController.text.trim(),
        carColor: carColorController.text.trim(),
        carPlateNumber: carPlateNumberController.text.trim(),
        carProduction: carLicenseExpiryController.text.trim(),
        serviceId: selectedServiceId,
      ).then((value) {
        // Show a subtle indication that data was saved
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ معلومات السيارة'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }).catchError((error) {
        toast(error.toString());
      });
    } catch (e) {
      toast(e.toString());
    }
  }

  // Page 4: Vehicle Documents
  Widget _buildVehicleDocumentsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: "وثائق المركبة",
            subtitle: "رخصة وصور السيارة",
            icon: Icons.description,
            color: Colors.purple,
          ),
          Card(
            elevation: 2,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text("صور رخصة السيارة", style: boldTextStyle(size: 16)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageUploadBox(
                          title: "الوجه الأمامي",
                          image: carFrontLicenseImage,
                          onTap: () =>
                              pickImageForDocument('car_front_license'),
                          icon: Icons.description,
                          documentType: 'car_front_license',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildImageUploadBox(
                          title: "الوجه الخلفي",
                          image: carBackLicenseImage,
                          onTap: () => pickImageForDocument('car_back_license'),
                          icon: Icons.description,
                          documentType: 'car_back_license',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text("صورة السيارة", style: boldTextStyle(size: 16)),
                  SizedBox(height: 12),
                  Container(
                    height: 200,
                    child: _buildImageUploadBox(
                      title: "صورة واضحة للسيارة",
                      image: carImage,
                      onTap: () => pickImageForDocument('car_image'),
                      icon: Icons.camera_alt,
                      documentType: 'car_image',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 5: Review and Submit
  Widget _buildReviewPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: "مراجعة البيانات",
            subtitle: "تأكد من صحة جميع المعلومات",
            icon: Icons.check_circle,
            color: Colors.green,
          ),

          // Show current status if documents are submitted
          if (_isSubmissionCompleted()) ...[
            // Status Card based on current state
            if (hasPendingDocuments)
              _buildPendingStatusCard()
            else if (hasApprovedDocuments &&
                !hasPendingDocuments &&
                !hasRejectedDocuments)
              _buildApprovedStatusCard()
            else if (hasRejectedDocuments)
              _buildRejectedStatusCard(),
          ] else ...[
            // Progress Summary (only show if not submitted)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getSelectedImagesCount() == 7
                        ? Colors.green.withOpacity(0.1)
                        : primaryColor.withOpacity(0.1),
                    _getSelectedImagesCount() == 7
                        ? Colors.green.withOpacity(0.05)
                        : primaryColor.withOpacity(0.05)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _getSelectedImagesCount() == 7
                        ? Colors.green.withOpacity(0.3)
                        : primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("إجمالي التقدم", style: boldTextStyle(size: 18)),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getSelectedImagesCount() == 7
                              ? Colors.green
                              : primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_getSelectedImagesCount()}/7",
                          style: boldTextStyle(color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _getSelectedImagesCount() / 7,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getSelectedImagesCount() == 7
                          ? Colors.green
                          : primaryColor,
                    ),
                    minHeight: 8,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _getSelectedImagesCount() == 7
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: _getSelectedImagesCount() == 7
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getSelectedImagesCount() == 7
                              ? "تم اكتمال جميع المتطلبات! جاهز للإرسال 🎉"
                              : "يرجى إكمال جميع الحقول المطلوبة قبل الإرسال",
                          style: boldTextStyle(
                            color: _getSelectedImagesCount() == 7
                                ? Colors.green
                                : Colors.orange,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Summary Cards
            _buildSummaryCard(
              title: "الوثائق الشخصية",
              items: [
                _buildSummaryItem("بطاقة الهوية (أمامي)", frontIdImage != null),
                _buildSummaryItem("بطاقة الهوية (خلفي)", backIdImage != null),
                _buildSummaryItem(
                    "رخصة القيادة (أمامي)", frontLicenseImage != null),
                _buildSummaryItem(
                    "رخصة القيادة (خلفي)", backLicenseImage != null),
              ],
              icon: Icons.person,
              color: Colors.blue,
            ),

            SizedBox(height: 16),

            _buildSummaryCard(
              title: "معلومات المركبة",
              items: [
                _buildSummaryItem(
                    "نوع السيارة", carTypeController.text.isNotEmpty),
                _buildSummaryItem(
                    "لون السيارة", carColorController.text.isNotEmpty),
                _buildSummaryItem(
                    "رقم اللوحة", carPlateNumberController.text.isNotEmpty),
              ],
              icon: Icons.directions_car,
              color: Colors.orange,
            ),

            SizedBox(height: 16),

            _buildSummaryCard(
              title: "وثائق المركبة",
              items: [
                _buildSummaryItem(
                    "رخصة السيارة (أمامي)", carFrontLicenseImage != null),
                _buildSummaryItem(
                    "رخصة السيارة (خلفي)", carBackLicenseImage != null),
                _buildSummaryItem("صورة السيارة", carImage != null),
              ],
              icon: Icons.description,
              color: Colors.purple,
            ),

            SizedBox(height: 24),

            // Terms and conditions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "الشروط والأحكام",
                          style: boldTextStyle(size: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    "• جميع المعلومات المقدمة صحيحة ودقيقة\n"
                    "• الوثائق المرفوعة واضحة وقابلة للقراءة\n"
                    "• أوافق على استخدام هذه البيانات لأغراض التحقق\n"
                    "• سيتم مراجعة الطلب خلال 24-48 ساعة",
                    style: secondaryTextStyle(size: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build pending status card
  Widget _buildPendingStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "حالة الطلب الحالية",
                      style: boldTextStyle(size: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "المستندات قيد المراجعة",
                      style: boldTextStyle(
                        size: 18,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _refreshDocumentStatus,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "طلبك قيد المراجعة، سيتم إشعارك عند اتخاذ قرار\nيرجى الانتظار حتى تتم مراجعة واعتماد مستنداتك",
            style: secondaryTextStyle(
              color: Colors.orange.shade700,
              size: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildStatusRow(
                  "وقت التقديم",
                  DateTime.now().toString().split('.')[0],
                  Icons.access_time,
                ),
                Divider(),
                _buildStatusRow(
                  "الوقت المتوقع",
                  "24-48 ساعة",
                  Icons.update,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build approved status card
  Widget _buildApprovedStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "حالة الطلب الحالية",
                      style: boldTextStyle(size: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "موافق عليه",
                      style: boldTextStyle(
                        size: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "تهانينا! تم الموافقة على جميع مستنداتك 🎉\nيمكنك الآن الدخول إلى الصفحة الرئيسية",
            style: secondaryTextStyle(
              color: Colors.green.shade700,
              size: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          AppButtonWidget(
            text: "الذهاب إلى الصفحة الرئيسية",
            textStyle: boldTextStyle(color: Colors.white),
            width: MediaQuery.of(context).size.width,
            color: Colors.green,
            onTap: () {
              getDetailAPi();
            },
            elevation: 0,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  // Build rejected status card
  Widget _buildRejectedStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cancel,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "حالة الطلب الحالية",
                      style: boldTextStyle(size: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "مرفوض",
                      style: boldTextStyle(
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "تم رفض بعض المستندات\nيرجى مراجعة المستندات وإعادة تقديمها",
            style: secondaryTextStyle(
              color: Colors.red.shade700,
              size: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (rejectionReason != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "سبب الرفض: $rejectionReason",
                      style: boldTextStyle(color: Colors.red, size: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16),
          AppButtonWidget(
            text: "إعادة إرسال المستندات",
            textStyle: boldTextStyle(color: Colors.white),
            width: MediaQuery.of(context).size.width,
            color: Colors.red,
            onTap: () {
              // Reset form and start over
              setState(() {
                _currentPage = 1;
                frontIdImage = null;
                backIdImage = null;
                frontLicenseImage = null;
                backLicenseImage = null;
                carFrontLicenseImage = null;
                carBackLicenseImage = null;
                carImage = null;
                driverLicenseNumberController.clear();
                driverLicenseExpiryController.clear();
                carTypeController.clear();
                carPlateNumberController.clear();
                carLicenseExpiryController.clear();
                carColorController.clear();
                driverLicenseExpiryDate = null;
                carLicenseExpiryDate = null;

                // Reset document status
                hasPendingDocuments = false;
                hasApprovedDocuments = false;
                hasRejectedDocuments = false;
                rejectionReason = null;
              });
              _pageController.animateToPage(
                1,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            elevation: 0,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build summary card
  Widget _buildSummaryCard({
    required String title,
    required List<Widget> items,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Text(title, style: boldTextStyle(size: 16)),
              ],
            ),
            SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  // Build summary item
  Widget _buildSummaryItem(String title, bool isComplete) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green : Colors.grey,
            size: 18,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: primaryTextStyle(
                size: 14,
                color: isComplete ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: boldTextStyle(size: 20)),
                SizedBox(height: 4),
                Text(subtitle, style: secondaryTextStyle(size: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build input fields
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: boldTextStyle(size: 14)),
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Helper method to build navigation buttons
  Widget _buildNavigationButtons() {
    // Don't show navigation buttons if documents are submitted and pending/approved/rejected
    if (_isSubmissionCompleted()) {
      return Container(); // Hide all navigation buttons
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0 && _currentPage < _totalPages - 1)
            Expanded(
              child: Container(
                height: 50,
                margin: EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, color: primaryColor),
                      SizedBox(width: 8),
                      Text(
                        "السابق",
                        style: boldTextStyle(color: primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 50,
              margin: EdgeInsets.only(left: _currentPage > 0 ? 8 : 0),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _totalPages - 1) {
                    _nextPage();
                  } else {
                    // Only allow submission if documents are not already submitted
                    if (!_isSubmissionCompleted()) {
                      if (_validateForm()) {
                        uploadCombinedDocument();
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage < _totalPages - 1 ? "التالي" : "إرسال",
                      style: boldTextStyle(color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      _currentPage < _totalPages - 1
                          ? Icons.arrow_forward
                          : Icons.send,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get API details
  getDetailAPi() async {
    appStore.setLoading(true);
    await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
      appStore.setLoading(false);
      if (value.data != null) {
        // Navigate to MainScreen
        launchScreen(context, MainScreen(), isNewTask: true);
      }
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  // Helper method to build status row
  Widget _buildStatusRow(String label, String value, IconData icon,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        SizedBox(width: 8),
        Text(
          label + ": ",
          style: boldTextStyle(size: 12, color: Colors.grey.shade700),
        ),
        Expanded(
          child: Text(
            value,
            style: primaryTextStyle(size: 12, color: color ?? Colors.black87),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // Add new method to check document status
  void checkDocumentStatus() {
    if (driverDocumentList.isEmpty) {
      // Don't reset status if we manually set pending status (during upload)
      if (!hasPendingDocuments) {
        setState(() {
          hasPendingDocuments = false;
          hasApprovedDocuments = false;
          hasRejectedDocuments = false;
          rejectionReason = null;
        });
      }
      return;
    }

    setState(() {
      hasPendingDocuments =
          driverDocumentList.any((doc) => doc.isVerified == 0);
      hasApprovedDocuments =
          driverDocumentList.any((doc) => doc.isVerified == 1);
      hasRejectedDocuments =
          driverDocumentList.any((doc) => doc.isVerified == 2);

      // Get rejection reason if any document is rejected
      if (hasRejectedDocuments) {
        var rejectedDoc = driverDocumentList.firstWhere(
            (doc) => doc.isVerified == 2,
            orElse: () => DriverDocumentModel());
        rejectionReason = rejectedDoc.documentName;
      }
    });

    // Handle navigation based on document status
    if (hasApprovedDocuments && !hasPendingDocuments && !hasRejectedDocuments) {
      // All documents are approved - navigate to MainScreen
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          launchScreen(context, MainScreen(), isNewTask: true);
        }
      });
    }
    // Remove the automatic dialog showing - let user trigger it manually
  }

  // Add new method to show pending documents dialog
  void showPendingDocumentsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async =>
              false, // Prevent dialog dismissal on back press
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      size: 40,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "المستندات قيد المراجعة",
                    style: boldTextStyle(size: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "يرجى الانتظار حتى تتم مراجعة واعتماد مستنداتك من قبل الإدارة",
                    style: secondaryTextStyle(size: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildStatusRow(
                          "وقت التقديم",
                          DateTime.now().toString().split('.')[0],
                          Icons.access_time,
                        ),
                        Divider(),
                        _buildStatusRow(
                          "حالة المراجعة",
                          "قيد المراجعة",
                          Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                        Divider(),
                        _buildStatusRow(
                          "الوقت المتوقع",
                          "24-48 ساعة",
                          Icons.update,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  AppButtonWidget(
                    text: "حسناً",
                    textStyle: boldTextStyle(color: Colors.white),
                    width: MediaQuery.of(context).size.width,
                    color: primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      // Stay in DocumentsScreen - don't navigate away
                    },
                    elevation: 0,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add new method to show rejected documents dialog
  void showRejectedDocumentsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async =>
              false, // Prevent dialog dismissal on back press
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cancel,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "تم رفض بعض المستندات",
                    style: boldTextStyle(size: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "يرجى مراجعة المستندات المرفوضة وإعادة تقديمها بالمواصفات المطلوبة",
                    style: secondaryTextStyle(size: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (rejectionReason != null) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "سبب الرفض: $rejectionReason",
                              style: boldTextStyle(color: Colors.red, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildStatusRow(
                          "حالة المراجعة",
                          "مرفوض",
                          Icons.cancel,
                          color: Colors.red,
                        ),
                        Divider(),
                        _buildStatusRow(
                          "الإجراء المطلوب",
                          "إعادة تقديم المستندات",
                          Icons.refresh,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  AppButtonWidget(
                    text: "إعادة تقديم المستندات",
                    textStyle: boldTextStyle(color: Colors.white),
                    width: MediaQuery.of(context).size.width,
                    color: primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      // Reset to first page to start document submission again
                      setState(() {
                        _currentPage = 1; // Start from personal documents page
                        // Reset all form data
                        frontIdImage = null;
                        backIdImage = null;
                        frontLicenseImage = null;
                        backLicenseImage = null;
                        carFrontLicenseImage = null;
                        carBackLicenseImage = null;
                        carImage = null;
                        driverLicenseNumberController.clear();
                        driverLicenseExpiryController.clear();
                        carTypeController.clear();
                        carPlateNumberController.clear();
                        carLicenseExpiryController.clear();
                        carColorController.clear();
                        driverLicenseExpiryDate = null;
                        carLicenseExpiryDate = null;
                      });
                      _pageController.animateToPage(
                        1,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    elevation: 0,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add new method to refresh document status
  Future<void> _refreshDocumentStatus() async {
    appStore.setLoading(true);
    try {
      await driverDocument();
      checkDocumentStatus();

      // Show status message
      if (hasPendingDocuments) {
        toast("الطلب قيد المراجعة - يرجى الانتظار");
      } else if (hasApprovedDocuments &&
          !hasPendingDocuments &&
          !hasRejectedDocuments) {
        toast("تم الموافقة على جميع المستندات! 🎉");
      } else if (hasRejectedDocuments) {
        toast("تم رفض بعض المستندات - يرجى المراجعة");
      }
    } catch (error) {
      toast("خطأ في تحديث الحالة");
    } finally {
      appStore.setLoading(false);
    }
  }

  // Helper method to get current submission status for UI
  String _getSubmissionStatus() {
    if (hasPendingDocuments) {
      return "قيد المراجعة";
    } else if (hasApprovedDocuments &&
        !hasPendingDocuments &&
        !hasRejectedDocuments) {
      return "موافق عليه";
    } else if (hasRejectedDocuments) {
      return "مرفوض";
    } else {
      return "إرسال";
    }
  }

  // Helper method to check if submission is completed
  bool _isSubmissionCompleted() {
    return hasPendingDocuments || hasApprovedDocuments || hasRejectedDocuments;
  }

  // Build dedicated rejected-only page
  Widget _buildRejectedOnlyPage() {
    return Column(
      children: [
        const BackAppBar(title: 'الوثائق والمستندات'),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large rejected icon with animation
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withOpacity(0.1),
                        Colors.red.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cancel,
                    size: 60,
                    color: Colors.red,
                  ),
                ),

                SizedBox(height: 20),

                // Main message
                Text(
                  "تم رفض المستندات",
                  style: boldTextStyle(size: 20, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16),

                Text(
                  "مستنداتك غير مطابقة للمتطلبات",
                  style: boldTextStyle(size: 18, color: Colors.red),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                Text(
                  "يرجى مراجعة المستندات وإعادة تقديمها وفقاً للمتطلبات المحددة",
                  style:
                      secondaryTextStyle(size: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40),

                // Rejection reason if available
                if (rejectionReason != null) ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red),
                            SizedBox(width: 12),
                            Text(
                              "سبب الرفض",
                              style: boldTextStyle(size: 16, color: Colors.red),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          rejectionReason!,
                          style: primaryTextStyle(
                              size: 14, color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],

                // Restart button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Reset form and start over from the beginning
                      setState(() {
                        _currentPage = 0; // Start from welcome page

                        // Reset all form data
                        frontIdImage = null;
                        backIdImage = null;
                        frontLicenseImage = null;
                        backLicenseImage = null;
                        carFrontLicenseImage = null;
                        carBackLicenseImage = null;
                        carImage = null;
                        driverLicenseNumberController.clear();
                        driverLicenseExpiryController.clear();
                        carTypeController.clear();
                        carPlateNumberController.clear();
                        carLicenseExpiryController.clear();
                        carColorController.clear();
                        driverLicenseExpiryDate = null;
                        carLicenseExpiryDate = null;

                        // Reset document status
                        hasPendingDocuments = false;
                        hasApprovedDocuments = false;
                        hasRejectedDocuments = false;
                        rejectionReason = null;
                      });

                      // NEW: Clear any preserved state since we're starting fresh
                      _clearPreservedState();

                      // Navigate to welcome page
                      _pageController.animateToPage(
                        0,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.restart_alt, color: Colors.white),
                    label: Text(
                      "إعادة تقديم المستندات",
                      style: boldTextStyle(color: Colors.white, size: 16),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Note
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_outlined, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "تأكد من جودة الصور ووضوح البيانات قبل الإرسال",
                          style:
                              secondaryTextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NEW: Professional Document Submission Confirmation Page
  Widget _buildProfessionalSubmissionConfirmation() {
    final currentDate = DateTime.now();
    final referenceNumber = 'DOC-${currentDate.millisecondsSinceEpoch}';
    final formattedDate =
        '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 40),

              // Header with logo and title
              Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Success Icon with animation
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.verified_outlined,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 25),

                    // Main Title
                    Text(
                      'تم تقديم المستندات بنجاح',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 12),

                    Text(
                      'أوراق السائق الرسمية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Document Details Card
              Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Document Info Header
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade700],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'معلومات التقديم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    // Submission Date
                    _buildProfessionalInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'تاريخ التقديم',
                      value: formattedDate,
                      iconColor: Colors.blue.shade600,
                    ),

                    SizedBox(height: 20),

                    // Reference Number
                    _buildProfessionalInfoRow(
                      icon: Icons.confirmation_number_outlined,
                      label: 'رقم المرجع',
                      value: referenceNumber,
                      iconColor: Colors.orange.shade600,
                    ),

                    SizedBox(height: 20),

                    // Status
                    _buildProfessionalInfoRow(
                      icon: Icons.pending_actions_outlined,
                      label: 'الحالة',
                      value: 'قيد المراجعة',
                      iconColor: Colors.amber.shade600,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),

              // Progress Timeline
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مراحل المراجعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildTimelineStep(
                      title: 'تم استلام المستندات',
                      subtitle: 'تم رفع جميع المستندات المطلوبة',
                      isCompleted: true,
                      isActive: false,
                    ),
                    _buildTimelineStep(
                      title: 'مراجعة المستندات',
                      subtitle: 'جاري مراجعة صحة ووضوح المستندات',
                      isCompleted: false,
                      isActive: true,
                    ),
                    _buildTimelineStep(
                      title: 'اعتماد الحساب',
                      subtitle: 'ستتمكن من بدء العمل بعد الاعتماد',
                      isCompleted: false,
                      isActive: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),

              // Important Notes
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 24,
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملاحظة هامة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'ستصلك رسالة تأكيد خلال 24-48 ساعة بنتيجة مراجعة المستندات',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Footer - Restricted Notice
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'محفوظ - للاستخدام الرسمي فقط',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _refreshDocumentStatus,
                  icon: Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    "تحديث الحالة",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Professional Info Row Widget
  Widget _buildProfessionalInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Timeline Step Widget
  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? Colors.blue
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? Colors.green
                      : isActive
                          ? Colors.blue
                          : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check
                    : isActive
                        ? Icons.access_time
                        : Icons.circle,
                color: Colors.white,
                size: 12,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive || isCompleted
                        ? Colors.grey.shade800
                        : Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!isLast) SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Generate PDF Confirmation
  void _generateConfirmationPDF() async {
    // Implementation to generate and download PDF confirmation
    toast('جاري تحضير ملف التأكيد...');
    // Add PDF generation logic here
  }

  // Method to show professional confirmation as separate screen
  static void showProfessionalConfirmation(BuildContext context) {
    toast('This method is deprecated.');
  }
}
