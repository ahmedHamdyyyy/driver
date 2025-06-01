import 'package:flutter/material.dart';
import 'package:taxi_driver/screens/onboarding/presentaion/onboarding_screen.dart';
import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import 'MainScreen.dart';
import 'SignInScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and title at the top
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/icons/IconApp.png', height: 120),
                      SizedBox(height: 16),
                      Text(
                        language.appName,
                        style: boldTextStyle(size: 28, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          language.mostReliableMightyDriverApp,
                          style:
                              primaryTextStyle(size: 16, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Buttons
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Sign In button
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.9)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: MaterialButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onPressed: () {
                              launchScreen(context, OnboardingScreen(),
                                  pageRouteAnimation:
                                      PageRouteAnimation.SlideBottomTop);
                            },
                            child: Text(
                              language.logIn,
                              style:
                                  boldTextStyle(color: primaryColor, size: 18),
                            ),
                          ),
                        ),

                        /*      SizedBox(height: 16),

                        // Continue as Guest button
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: MaterialButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onPressed: () async {
                              await appStore.setIsGuest(true);
                              launchScreen(context, MainScreen(),
                                  pageRouteAnimation:
                                      PageRouteAnimation.SlideBottomTop,
                                  isNewTask: true);
                            },
                            child: Text(
                              "دخول كضيف",
                              style:
                                  boldTextStyle(color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                     */
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
