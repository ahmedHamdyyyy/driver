import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
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
      frontIdImage = null;
      backIdImage = null;
      frontLicenseImage = null;
      backLicenseImage = null;
      combinedFilePath = null;
      currentlySelectingImageType = null;
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

  // Function to combine 4 images into a single PDF
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

      // Read image bytes
      Uint8List frontIdBytes = await compressedFrontId.readAsBytes();
      Uint8List backIdBytes = await compressedBackId.readAsBytes();
      Uint8List frontLicenseBytes = await compressedFrontLicense.readAsBytes();
      Uint8List backLicenseBytes = await compressedBackLicense.readAsBytes();

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
                        'DRIVER DOCUMENTS',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Official Registration Documents',
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
                        'Submission Date: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Reference: DOC-${DateTime.now().millisecondsSinceEpoch}',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(flex: 3),

                // Footer
                pw.Text(
                  'This document contains required registration documents',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      // Documents Pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(30),
          header: (pw.Context context) {
            return pw.Container(
              padding: pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.blue200, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DRIVER DOCUMENTS',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              padding: pw.EdgeInsets.only(top: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Generated automatically on ${DateTime.now().toString().split(' ')[0]}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // Document 1: Front ID
              _buildDocumentSection(
                title: 'National ID Card - Front Side',
                subtitle: 'Document 1 of 4',
                imageBytes: frontIdBytes,
                documentNumber: '1',
              ),

              pw.NewPage(),

              // Document 2: Back ID
              _buildDocumentSection(
                title: 'National ID Card - Back Side',
                subtitle: 'Document 2 of 4',
                imageBytes: backIdBytes,
                documentNumber: '2',
              ),

              pw.NewPage(),

              // Document 3: Front License
              _buildDocumentSection(
                title: 'Driving License - Front Side',
                subtitle: 'Document 3 of 4',
                imageBytes: frontLicenseBytes,
                documentNumber: '3',
              ),

              pw.NewPage(),

              // Document 4: Back License
              _buildDocumentSection(
                title: 'Driving License - Back Side',
                subtitle: 'Document 4 of 4',
                imageBytes: backLicenseBytes,
                documentNumber: '4',
              ),
            ];
          },
        ),
      );

      // Save PDF to temporary file
      String pdfPath =
          '${tempDir.path}/driver_documents_${DateTime.now().millisecondsSinceEpoch}.pdf';
      File pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      return pdfPath;
    } catch (e) {
      log('فشل في دمج الصور: ${e.toString()}');
      toast('فشل في دمج الصور');
      return null;
    }
  }

  // Helper method to build professional document section
  pw.Widget _buildDocumentSection({
    required String title,
    required String subtitle,
    required Uint8List imageBytes,
    required String documentNumber,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Document header
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            border: pw.Border.all(color: PdfColors.blue200),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue500,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    documentNumber,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 15),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      subtitle,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.blue600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Document image with professional frame
        pw.Center(
          child: pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.grey400, width: 2),
              borderRadius: pw.BorderRadius.circular(15),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColors.grey300,
                  offset: PdfPoint(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
                width: 400,
                height: 250,
              ),
            ),
          ),
        ),

        pw.SizedBox(height: 20),

        // Document verification note
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            border: pw.Border.all(color: PdfColors.green200),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.green500,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'OK',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Document uploaded successfully',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Function to pick image for specific document type
  Future<void> pickImageForDocument(String documentType) async {
    print('🎯 STARTING IMAGE SELECTION FOR: $documentType');

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
    print('Original image path: ${imageFile.path}');
    print('Image file exists: ${imageFile.existsSync()}');
    print('Image file size: ${imageFile.lengthSync()} bytes');

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

    print('📄 Created unique file: ${uniqueFile.path}');
    print('📄 Unique file size: ${uniqueFile.lengthSync()} bytes');
    print('🔍 Image hash (first 100 bytes): $imageHash');

    setState(() {
      // Clear the currently selecting type first
      currentlySelectingImageType = null;

      // Set the specific image based on document type with the unique file
      switch (documentType) {
        case 'front_id':
          frontIdImage = uniqueFile;
          print('✅ SET FRONT ID: ${frontIdImage?.path}');
          print('✅ FRONT ID SIZE: ${frontIdImage?.lengthSync()} bytes');
          break;
        case 'back_id':
          backIdImage = uniqueFile;
          print('✅ SET BACK ID: ${backIdImage?.path}');
          print('✅ BACK ID SIZE: ${backIdImage?.lengthSync()} bytes');
          break;
        case 'front_license':
          frontLicenseImage = uniqueFile;
          print('✅ SET FRONT LICENSE: ${frontLicenseImage?.path}');
          print(
              '✅ FRONT LICENSE SIZE: ${frontLicenseImage?.lengthSync()} bytes');
          break;
        case 'back_license':
          backLicenseImage = uniqueFile;
          print('✅ SET BACK LICENSE: ${backLicenseImage?.path}');
          print('✅ BACK LICENSE SIZE: ${backLicenseImage?.lengthSync()} bytes');
          break;
        default:
          print('❌ Unknown document type: $documentType');
          return;
      }

      // Print current state of all images with detailed info
      print('--- DETAILED STATE AFTER SETTING $documentType ---');
      if (frontIdImage != null) {
        print(
            'Front ID: ${frontIdImage!.path} (${frontIdImage!.lengthSync()} bytes)');
      } else {
        print('Front ID: NULL');
      }
      if (backIdImage != null) {
        print(
            'Back ID: ${backIdImage!.path} (${backIdImage!.lengthSync()} bytes)');
      } else {
        print('Back ID: NULL');
      }
      if (frontLicenseImage != null) {
        print(
            'Front License: ${frontLicenseImage!.path} (${frontLicenseImage!.lengthSync()} bytes)');
      } else {
        print('Front License: NULL');
      }
      if (backLicenseImage != null) {
        print(
            'Back License: ${backLicenseImage!.path} (${backLicenseImage!.lengthSync()} bytes)');
      } else {
        print('Back License: NULL');
      }
      print('========================================');
    });
  }

  // Function to upload combined PDF
  Future<void> uploadCombinedDocument() async {
    if (frontIdImage == null ||
        backIdImage == null ||
        frontLicenseImage == null ||
        backLicenseImage == null) {
      toast("يجب تحديد جميع الصور الأربع قبل الرفع");
      return;
    }

    appStore.setLoading(true);

    // Combine images into PDF
    String? pdfPath = await combineImagesToPDF();
    if (pdfPath == null) {
      appStore.setLoading(false);
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

    await addDocument(combinedDocId, isExpire, dateTime: selectedDate);
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
    return count;
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
                      // Modern 4-Image Upload Section
                      Container(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                primaryColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.camera_alt,
                                            color: primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "تحميل الوثائق المطلوبة",
                                                style: boldTextStyle(size: 20),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "يرجى تحميل جميع الصور المطلوبة بوضوح",
                                                style: secondaryTextStyle(
                                                    size: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24),

                                    // Grid of 4 image upload boxes
                                    GridView.count(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.2,
                                      children: [
                                        _buildImageUploadBox(
                                          title:
                                              "بطاقة الهوية\n(الوجه الأمامي)",
                                          image: frontIdImage,
                                          onTap: () {
                                            print('Tapping front_id');
                                            pickImageForDocument('front_id');
                                          },
                                          icon: Icons.credit_card,
                                          documentType: 'front_id',
                                        ),
                                        _buildImageUploadBox(
                                          title: "بطاقة الهوية\n(الوجه الخلفي)",
                                          image: backIdImage,
                                          onTap: () {
                                            print('Tapping back_id');
                                            pickImageForDocument('back_id');
                                          },
                                          icon: Icons.credit_card,
                                          documentType: 'back_id',
                                        ),
                                        _buildImageUploadBox(
                                          title:
                                              "رخصة القيادة\n(الوجه الأمامي)",
                                          image: frontLicenseImage,
                                          onTap: () {
                                            print('Tapping front_license');
                                            pickImageForDocument(
                                                'front_license');
                                          },
                                          icon: Icons.drive_eta,
                                          documentType: 'front_license',
                                        ),
                                        _buildImageUploadBox(
                                          title: "رخصة القيادة\n(الوجه الخلفي)",
                                          image: backLicenseImage,
                                          onTap: () {
                                            print('Tapping back_license');
                                            pickImageForDocument(
                                                'back_license');
                                          },
                                          icon: Icons.drive_eta,
                                          documentType: 'back_license',
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 24),

                                    // Upload Button
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      width: double.infinity,
                                      child: AppButtonWidget(
                                        text: "رفع جميع الوثائق",
                                        textStyle: boldTextStyle(
                                            color: Colors.white, size: 16),
                                        onTap: uploadCombinedDocument,
                                        color: _areAllImagesSelected()
                                            ? primaryColor
                                            : Colors.grey.shade400,
                                        elevation:
                                            _areAllImagesSelected() ? 4 : 0,
                                        shapeBorder: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 16),

                                    // Progress indicator
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${_getSelectedImagesCount()}/4 صور محددة",
                                          style: primaryTextStyle(
                                            color: _areAllImagesSelected()
                                                ? Colors.green
                                                : primaryColor,
                                            size: 14,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          width: 100,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor:
                                                _getSelectedImagesCount() / 4,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: _areAllImagesSelected()
                                                    ? Colors.green
                                                    : primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
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
