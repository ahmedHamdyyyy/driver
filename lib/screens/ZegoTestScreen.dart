import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../Services/DriverZegoService.dart';
import '../main.dart';
import '../utils/Constants.dart';
import '../utils/Colors.dart';
import '../utils/Extensions/app_common.dart';

class ZegoTestScreen extends StatefulWidget {
  @override
  _ZegoTestScreenState createState() => _ZegoTestScreenState();
}

class _ZegoTestScreenState extends State<ZegoTestScreen> {
  String _statusText = 'Ready to test Zego integration...';
  bool _isLoading = false;
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _addLog('🚀 Zego Test Screen initialized');
    _checkInitialStatus();
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.insert(
          0, '${DateTime.now().toString().substring(11, 19)} - $message');
    });
    if (kDebugMode) {
      print(message);
    }
  }

  void _updateStatus(String status) {
    setState(() {
      _statusText = status;
    });
    _addLog('📊 Status: $status');
  }

  Future<void> _checkInitialStatus() async {
    _addLog('🔍 Checking initial Zego status...');

    // Check shared preferences data
    String phone = sharedPref.getString(CONTACT_NUMBER) ?? 'NOT SET';
    String firstName = sharedPref.getString(FIRST_NAME) ?? 'NOT SET';
    String lastName = sharedPref.getString(LAST_NAME) ?? 'NOT SET';
    bool isLoggedIn = sharedPref.getBool(IS_LOGGED_IN) ?? false;

    _addLog('📱 Driver Phone: $phone');
    _addLog('👤 Driver Name: $firstName $lastName');
    _addLog('🔐 App Login Status: $isLoggedIn');
    _addLog('🎯 Zego Login Status: ${DriverZegoService.isLoggedIn}');
    _addLog('🆔 Current Zego ID: ${DriverZegoService.currentDriverId}');

    if (phone == 'NOT SET') {
      _updateStatus('❌ Driver phone not found in SharedPreferences');
    } else if (!isLoggedIn) {
      _updateStatus('❌ Driver not logged into the app');
    } else if (!DriverZegoService.isLoggedIn) {
      _updateStatus('⚠️ Driver not logged into Zego - needs auto-login');
    } else {
      _updateStatus('✅ Driver logged into Zego - ready for calls');
    }
  }

  Future<void> _testInitialization() async {
    setState(() => _isLoading = true);
    _updateStatus('🚀 Testing Zego initialization...');

    try {
      bool result = await DriverZegoService.initializeZego();
      _addLog('📱 Initialization result: $result');

      if (result) {
        _updateStatus('✅ Zego initialization successful');
      } else {
        _updateStatus('❌ Zego initialization failed');
      }
    } catch (e) {
      _addLog('❌ Initialization error: $e');
      _updateStatus('❌ Initialization error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testAutoLogin() async {
    setState(() => _isLoading = true);
    _updateStatus('🔐 Testing driver auto-login...');

    try {
      bool result = await DriverZegoService.autoLoginDriver();
      _addLog('🔐 Auto-login result: $result');

      if (result) {
        _updateStatus('✅ Driver auto-login successful');
        _addLog('🎉 Driver ID: ${DriverZegoService.currentDriverId}');
        _addLog('👤 Driver Name: ${DriverZegoService.currentDriverName}');
      } else {
        _updateStatus('❌ Driver auto-login failed');
      }
    } catch (e) {
      _addLog('❌ Auto-login error: $e');
      _updateStatus('❌ Auto-login error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testFullFlow() async {
    setState(() => _isLoading = true);
    _updateStatus('🧪 Testing complete Zego flow...');

    try {
      // Step 1: Initialize
      _addLog('🚀 Step 1: Initializing Zego...');
      bool initResult = await DriverZegoService.initializeZego();
      _addLog('📱 Init result: $initResult');

      if (!initResult) {
        _updateStatus('❌ Initialization failed - stopping test');
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Auto-login
      _addLog('🔐 Step 2: Auto-login driver...');
      bool loginResult = await DriverZegoService.autoLoginDriver();
      _addLog('🔐 Login result: $loginResult');

      if (!loginResult) {
        _updateStatus('❌ Auto-login failed - stopping test');
        setState(() => _isLoading = false);
        return;
      }

      // Step 3: Check status
      _addLog('🔍 Step 3: Checking final status...');
      DriverZegoService.checkZegoStatus();

      _updateStatus('✅ Complete flow test successful - ready for calls!');
      _addLog('🎉 Driver can now receive calls from riders');
    } catch (e) {
      _addLog('❌ Full flow error: $e');
      _updateStatus('❌ Full flow error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _checkPermissions() async {
    setState(() => _isLoading = true);
    _updateStatus('🔐 Checking permissions...');

    try {
      bool result = await DriverZegoService.checkPermissions();
      _addLog('🔐 Permissions result: $result');

      if (result) {
        _updateStatus('✅ All permissions granted');
      } else {
        _updateStatus('⚠️ Some permissions missing - may affect calls');
      }
    } catch (e) {
      _addLog('❌ Permission check error: $e');
      _updateStatus('❌ Permission check error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testCallRider() async {
    setState(() => _isLoading = true);
    _updateStatus('📞 Testing call to rider...');

    try {
      // Test video call
      _addLog('📹 Testing video call to rider...');
      bool videoResult = await DriverZegoService.testCallRider(
        context: context,
        testRiderPhone: "966501234567",
        testRiderName: "Test Rider",
        isVideoCall: true,
      );
      _addLog('📹 Video call result: $videoResult');

      // Wait a bit before voice call test
      await Future.delayed(Duration(seconds: 2));

      // Test voice call
      _addLog('📞 Testing voice call to rider...');
      bool voiceResult = await DriverZegoService.testCallRider(
        context: context,
        testRiderPhone: "966501234567",
        testRiderName: "Test Rider",
        isVideoCall: false,
      );
      _addLog('📞 Voice call result: $voiceResult');

      if (videoResult && voiceResult) {
        _updateStatus('✅ Call tests successful - driver can call riders!');
      } else {
        _updateStatus('⚠️ Some call tests failed - check configuration');
      }
    } catch (e) {
      _addLog('❌ Call test error: $e');
      _updateStatus('❌ Call test error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _showCallStatus() {
    Map<String, dynamic> status = DriverZegoService.getCallStatus();

    _addLog('📊 Current call status:');
    status.forEach((key, value) {
      _addLog('   $key: $value');
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: status.entries
              .map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(entry.value.toString()),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _printDebugInfo() {
    _addLog('📋 Printing comprehensive debug info...');
    DriverZegoService.printDebugInfo();
    _updateStatus('📋 Debug info printed to console');
  }

  void _refreshConnection() async {
    setState(() => _isLoading = true);
    _updateStatus('🔄 Refreshing Zego connection...');

    try {
      bool result = await DriverZegoService.refreshConnection();
      _addLog('🔄 Refresh result: $result');

      if (result) {
        _updateStatus('✅ Connection refreshed successfully');
      } else {
        _updateStatus('❌ Connection refresh failed');
      }
    } catch (e) {
      _addLog('❌ Refresh error: $e');
      _updateStatus('❌ Refresh error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _simulateIncomingCall() {
    _addLog('📞 Simulating incoming call...');
    DriverZegoService.logIncomingCall('test_rider_123', 'Test Rider');
    _updateStatus('📞 Incoming call simulated - check logs');
  }

  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
    });
    _addLog('🧹 Logs cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zego Integration Test',
            style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Status:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                Text(_statusText, style: TextStyle(fontSize: 14)),
                if (_isLoading) ...[
                  SizedBox(height: 8),
                  LinearProgressIndicator(),
                ],
              ],
            ),
          ),

          // Test Buttons
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTestButton(
                      '🔍 Check Status', _checkInitialStatus, Colors.blue),
                  _buildTestButton(
                      '🔐 Check Permissions', _checkPermissions, Colors.orange),
                  _buildTestButton('🚀 Test Initialization',
                      _testInitialization, Colors.green),
                  _buildTestButton(
                      '🔐 Test Auto-Login', _testAutoLogin, Colors.purple),
                  _buildTestButton(
                      '🧪 Test Complete Flow', _testFullFlow, Colors.teal),
                  _buildTestButton('🔄 Refresh Connection', _refreshConnection,
                      Colors.amber),
                  _buildTestButton(
                      '📋 Print Debug Info', _printDebugInfo, Colors.indigo),
                  _buildTestButton(
                      '📞 Simulate Call', _simulateIncomingCall, Colors.red),
                  _buildTestButton(
                      '📱 Test Call Rider', _testCallRider, Colors.deepOrange),
                  _buildTestButton(
                      '📊 Show Call Status', _showCallStatus, Colors.cyan),
                  _buildTestButton('🧹 Clear Logs', _clearLogs, Colors.grey),

                  SizedBox(height: 20),

                  // Debug Logs
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Debug Logs:',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _debugLogs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  _debugLogs[index],
                                  style: TextStyle(
                                      color: Colors.green.shade300,
                                      fontSize: 12,
                                      fontFamily: 'monospace'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String title, VoidCallback onPressed, Color color) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
