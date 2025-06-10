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
  }

  @override
  void dispose() {
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
      await getDocument();
      await driverDocument();

      // Check document status after loading data but don't show dialogs automatically
      checkDocumentStatus();
      appStore.setLoading(false);
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

      // Cover Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Spacer(flex: 2),

                // Logo or Icon
                pw.Container(
                  padding: pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Icon(
                    pw.IconData(0xe158), // car icon
                    size: 60,
                    color: PdfColors.blue800,
                  ),
                ),

                pw.SizedBox(height: 30),

                // Main Title
                pw.Container(
                  padding: pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(15),
                    border: pw.Border.all(color: PdfColors.blue200, width: 2),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'driver official documents',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'driver official documents',
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

                pw.Spacer(flex: 1),

                // Document Info
                pw.Container(
                  padding: pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'submission date: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'reference: DOC-${DateTime.now().millisecondsSinceEpoch}',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(flex: 3),

                // Footer
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'restricted - for official use only',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Driver Information Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader("driver information", context),
                pw.SizedBox(height: 20),

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
                pw.SizedBox(height: 20),

                // Vehicle Information
                _buildPdfSection(
                  "car information",
                  [
                    _buildPdfInfoRow("car type", carTypeController.text),
                    _buildPdfInfoRow("car color", carColorController.text),
                    _buildPdfInfoRow(
                        "car plate number", carPlateNumberController.text),
                    _buildPdfInfoRow(
                        "car license expiry", carLicenseExpiryController.text),
                  ],
                ),

                pw.Spacer(),
                _buildPdfFooter(context),
              ],
            );
          },
        ),
      );

      // ID Documents Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader("national documents", context),
                pw.SizedBox(height: 20),
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
            );
          },
        ),
      );

      // Driver License Documents Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader("driver license", context),
                pw.SizedBox(height: 20),
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

  // Helper method to build PDF header
  pw.Widget _buildPdfHeader(String title, pw.Context context) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue200)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build PDF section
  pw.Widget _buildPdfSection(String title, List<pw.Widget> content) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...content,
        ],
      ),
    );
  }

  // Helper method to build PDF info row
  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build PDF image container
  pw.Widget _buildPdfImageContainer(String label, Uint8List imageBytes,
      {bool isFullWidth = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue600,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Image(
            pw.MemoryImage(imageBytes),
            fit: isFullWidth ? pw.BoxFit.fitWidth : pw.BoxFit.contain,
            width: isFullWidth ? null : 200,
            height: isFullWidth ? 200 : 150,
          ),
        ],
      ),
    );
  }

  // Helper method to build PDF footer
  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'generated in ${DateTime.now().toString().split(' ')[0]}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'reference: DOC-${DateTime.now().millisecondsSinceEpoch}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
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

    // Show success message and navigate to pending page immediately
    toast("تم بدء إرسال المستندات! جاري المراجعة... 🎉");

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

    return InkWell(
      key: ValueKey('image_box_$documentType'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color:
              hasImage ? Colors.green.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? Colors.green : Colors.grey.shade300,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
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
                    Text(
                      title,
                      style: boldTextStyle(
                        size: 11,
                        color: hasImage ? Colors.white : primaryColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!hasImage) ...[
                      SizedBox(height: 4),
                      Text(
                        "اضغط للتحديد",
                        style: secondaryTextStyle(
                          size: 10,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
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

        // Only allow navigation if documents are approved or if navigating within the form
        if (_currentPage > 0) {
          _previousPage();
          return false;
        }

        // Allow normal navigation only if documents are approved
        if (hasApprovedDocuments &&
            !hasPendingDocuments &&
            !hasRejectedDocuments) {
          if (Navigator.canPop(context)) {
            return true;
          } else {
            SystemNavigator.pop();
            return false;
          }
        }

        // For all other cases, prevent navigation
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Stack(
          children: <Widget>[
            // Show only pending status page when documents are pending
            if (hasPendingDocuments)
              _buildPendingOnlyPage()
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
    return Column(
      children: [
        const BackAppBar(
            title: 'الوثائق والمستندات'), // Expanded pending content
        Expanded(
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

                // Add refresh button above existing refresh button
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        // Refresh document status instead of skip
                        await _refreshDocumentStatus();
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 16,
                              color: primaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "تحديث الحالة",
                              style:
                                  boldTextStyle(size: 12, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                /*    // Status info card
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
                        DateTime.now().toString().split('.')[0].split(' ')[0],
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

                SizedBox(height: 30), */

                // Refresh button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _refreshDocumentStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      "تحديث حالة المراجعة",
                      style: boldTextStyle(color: Colors.white, size: 16),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Note
                Container(
                  padding: EdgeInsets.all(16),
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
                          style:
                              secondaryTextStyle(color: Colors.blue.shade700),
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
}
