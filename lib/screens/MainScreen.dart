import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/settings_screen.dart';
import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../Services/DriverZegoService.dart';
import 'DashboardScreen.dart';
import 'HomeScreen.dart';
import 'RidesListScreen.dart';
import 'all_of_details.dart';
import 'profile_Screen.dart';
import 'EditProfileScreen.dart';
import 'SignInScreen.dart';
import 'DocumentsScreen.dart';
import '../network/RestApis.dart';
import 'ZegoTestScreen.dart';

class MainScreen extends StatefulWidget {
  final int pageIndex;
  const MainScreen({super.key, this.pageIndex = 0});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  late List<Widget> _screens;
  bool isLoading = true;
  bool hasPendingDocuments = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.pageIndex;

    // Check document status first
    checkDocumentStatus();

    _pageController = PageController(initialPage: 0);

    // Initialize Zego service for driver after successful login
    _initializeZegoService();
  }

  Future<void> checkDocumentStatus() async {
    setState(() => isLoading = true);

    try {
      final docs = await getDriverDocumentList();

      if (docs.data != null && docs.data!.isNotEmpty) {
        setState(() {
          hasPendingDocuments = docs.data!.any((doc) => doc.isVerified == 0);
        });
      }

      // Initialize screens regardless of document status
      setState(() {
        _screens = [
          AllOfDetails(),
          RidesListScreen(),
          DashboardScreen(),
          SettingsScreen(),
        ];
        isLoading = false;
      });
    } catch (e) {
      print('Error checking document status: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _initializeZegoService() async {
    try {
      print('🚀 MainScreen: Initializing Zego service for driver...');

      // Initialize Zego SDK
      bool initResult = await DriverZegoService.initializeZego();
      print('📱 Zego initialization result: $initResult');

      // Auto-login driver to Zego
      bool loginResult = await DriverZegoService.autoLoginDriver();
      print('🔐 Driver Zego login result: $loginResult');

      if (loginResult) {
        print('✅ Driver is now ready to receive calls from riders!');
        // Print debug info for troubleshooting
        DriverZegoService.printDebugInfo();
      } else {
        print('❌ Failed to login driver to Zego - calls will not work');
        DriverZegoService.checkZegoStatus();
      }
    } catch (e) {
      print('❌ Error initializing Zego service: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          _onItemTapped(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: _screens,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: _buildSvgIcon('images/app_images/home.svg', 0),
              activeIcon: _buildSvgIcon('images/app_images/home.svg', 0,
                  isActive: true),
              label: "الرئيسيه",
              backgroundColor: Colors.white,
            ),
            BottomNavigationBarItem(
              icon: _buildSvgIcon('images/app_images/clarity_car-line.svg', 1),
              activeIcon: _buildSvgIcon(
                  'images/app_images/clarity_car-line.svg', 1,
                  isActive: true),
              label: language.rides,
              backgroundColor: Colors.white,
            ),
            BottomNavigationBarItem(
              icon: _buildSvgIcon('assets/icons/activity_icon.svg', 2),
              activeIcon: _buildSvgIcon('assets/icons/activity_icon.svg', 2,
                  isActive: true),
              label: "الخريطه",
              backgroundColor: Colors.white,
            ),
            BottomNavigationBarItem(
              icon: _buildSvgIcon(
                  'images/app_images/iconamoon_profile-light.svg', 3),
              activeIcon: _buildSvgIcon(
                  'images/app_images/iconamoon_profile-light.svg', 3,
                  isActive: true),
              label: "الحساب",
              backgroundColor: Colors.white,
            ),
          ],
        ),
        floatingActionButton: kDebugMode
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ZegoTestScreen()),
                  );
                },
                child: Icon(Icons.video_call),
                backgroundColor: primaryColor,
                tooltip: 'Zego Debug',
              )
            : null,
      ),
    );
  }

  Widget _buildSvgIcon(String assetPath, int index, {bool isActive = false}) {
    return SvgPicture.asset(
      assetPath,
      height: 24,
      width: 24,
      colorFilter: ColorFilter.mode(
        isActive ? primaryColor : Colors.grey,
        BlendMode.srcIn,
      ),
    );
  }
}
