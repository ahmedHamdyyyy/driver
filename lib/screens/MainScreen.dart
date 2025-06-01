import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_driver/screens/settings/settings_screen/presentation/settings_screen.dart';
import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import 'DashboardScreen.dart';
import 'HomeScreen.dart';
import 'RidesListScreen.dart';
import 'all_of_details.dart';
import 'profile_Screen.dart';
import 'EditProfileScreen.dart';
import 'SignInScreen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.pageIndex;

    // Different screens for guests vs logged in users
    /*   if (appStore.isGuest) { */
    /*    _screens = [
      DashboardScreen(),
      RidesListScreen(),
      _buildGuestProfileScreen(),
      //_buildGuestProfileScreen(),
      _buildGuestProfileScreen(),
    ]; */
    /*   } else { */
    _screens = [
      AllOfDetails(),
      RidesListScreen(),
      DashboardScreen(),

      SettingsScreen(),

      //ProfileScreen(),
    ];
    /*   } */

    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // For guest users, prompt login when trying to access certain tabs

    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

/* 
  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(language.logIn),
          content:
              Text(language.toEnjoyYourRideExperiencePleaseAllowPermissions),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(language.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                launchScreen(context, SignInScreen(),
                    pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
              },
              child: Text(language.logIn),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuestProfileScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 100, color: primaryColor),
          SizedBox(height: 20),
          Text("الحساب", style: boldTextStyle(size: 20)),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              language.toEnjoyYourRideExperiencePleaseAllowPermissions,
              style: primaryTextStyle(size: 16),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () {
              appStore.setIsGuest(false);
              launchScreen(context, SignInScreen(),
                  pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            },
            child:
                Text(language.logIn, style: boldTextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
 */
  @override
  Widget build(BuildContext context) {
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
            /*     BottomNavigationBarItem(
              icon: _buildSvgIcon(
                  'images/app_images/setting-1-svgrepo-com.svg', 2),
              activeIcon: _buildSvgIcon(
                  'images/app_images/setting-1-svgrepo-com.svg', 2,
                  isActive: true),
              label: language.settings,
              backgroundColor: Colors.white,
            ), */

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
