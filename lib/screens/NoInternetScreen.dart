import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Images.dart';
import 'package:flutter/services.dart';

import '../core/widget/appbar/back_app_bar.dart';
import '../main.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';

class NoInternetScreen extends StatefulWidget {
  @override
  _NoInternetScreenState createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    init();
  }

  void init() async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);

    try {
      List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      if (!results.contains(ConnectivityResult.none)) {
        if (Navigator.canPop(navigatorKey.currentState!.overlay!.context)) {
          Navigator.pop(navigatorKey.currentState!.overlay!.context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يزال لا يوجد اتصال بالإنترنت',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: netScreenKey,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          BackAppBar(
            title: "لا يوجد اتصال بالانترنت",
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: primaryColor),
                SizedBox(width: 12),
                Text(
                  "لا يوجد اتصال بالانترنت",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.1),
                    end: Offset(0, -0.1),
                  ).animate(_bounceController),
                  child: Lottie.asset(
                    networkErrorView,
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        "لا يوجد اتصال بالانترنت",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "تأكد من اتصالك بالإنترنت وحاول مرة أخرى",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                AppButtonWidget(
                  width: MediaQuery.of(context).size.width,
                  text: _isChecking ? "جاري الفحص..." : "إعادة المحاولة",
                  textColor: Colors.white,
                  color: primaryColor,
                  shapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                  ),
                  onTap: _isChecking ? null : _checkConnection,
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Open device wifi settings
                    // This is just a placeholder - implement according to your needs
                    toast("Opening Settings...");
                  },
                  child: Text(
                    "فتح إعدادات الواي فاي",
                    style: TextStyle(
                      color: primaryColor,
                      decoration: TextDecoration.underline,
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
