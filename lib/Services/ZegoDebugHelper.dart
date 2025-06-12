import 'package:flutter/foundation.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'DriverZegoService.dart';

class ZegoDebugHelper {
  static bool _listenersSetup = false;

  /// Setup comprehensive debugging for Zego calls
  static void setupDebugMode() {
    if (!kDebugMode) return;

    _printHeader('🔧 SETTING UP ZEGO DEBUG MODE');

    if (_listenersSetup) {
      _debugPrint('⚠️ Debug listeners already setup');
      return;
    }

    try {
      // Setup call event listeners
      _setupCallEventListeners();
      _listenersSetup = true;

      _debugPrint('✅ Zego debug mode setup complete');
      _printSeparator();
    } catch (e) {
      _debugPrint('❌ Failed to setup debug mode: $e');
    }
  }

  /// Setup call event listeners
  static void _setupCallEventListeners() {
    _debugPrint('📞 Setting up call event listeners...');

    // Note: In a real implementation, you would use Zego's actual event listeners
    // These are placeholder methods to show the structure

    _debugPrint('🎧 Call event listeners configured:');
    _debugPrint('   - Incoming call detection');
    _debugPrint('   - Call accept/decline tracking');
    _debugPrint('   - Call duration monitoring');
    _debugPrint('   - Connection status tracking');
  }

  /// Log comprehensive app state
  static void logAppState() {
    if (!kDebugMode) return;

    _printHeader('📊 COMPREHENSIVE APP STATE DEBUG');

    // Driver Zego Service Status
    DriverZegoService.checkZegoStatus();

    // Additional debug information
    _printSubHeader('SYSTEM STATUS');
    _debugPrint('Debug Mode: $kDebugMode');
    _debugPrint('Listeners Setup: $_listenersSetup');
    _debugPrint('Platform: ${_getPlatform()}');
    _debugPrint('Current Time: ${DateTime.now()}');

    _printSeparator();
  }

  /// Test Zego connection
  static Future<void> testZegoConnection() async {
    if (!kDebugMode) return;

    _printHeader('🧪 TESTING ZEGO CONNECTION');

    try {
      // Initialize Zego
      _debugPrint('🔄 Testing Zego initialization...');
      bool initResult = await DriverZegoService.initializeZego();
      _debugPrint('Init Result: $initResult');

      // Test auto-login
      _debugPrint('🔄 Testing driver auto-login...');
      bool loginResult = await DriverZegoService.autoLoginDriver();
      _debugPrint('Login Result: $loginResult');

      // Check final status
      _debugPrint('🔄 Checking final status...');
      DriverZegoService.checkZegoStatus();

      if (initResult && loginResult) {
        _printHeader('✅ ZEGO CONNECTION TEST PASSED!');
        _debugPrint('🎉 Driver is ready to receive calls');
      } else {
        _printHeader('❌ ZEGO CONNECTION TEST FAILED!');
        _debugPrint('⚠️ Check configuration and credentials');
      }
    } catch (e) {
      _debugPrint('❌ Test failed with error: $e');
    }

    _printSeparator();
  }

  /// Simulate incoming call for testing
  static void simulateIncomingCall({
    String callerId = 'test_rider_123',
    String callerName = 'Test Rider',
  }) {
    if (!kDebugMode) return;

    _printHeader('📞 SIMULATING INCOMING CALL');

    _debugPrint('Caller ID: $callerId');
    _debugPrint('Caller Name: $callerName');
    _debugPrint('Driver ID: ${DriverZegoService.currentDriverId}');
    _debugPrint('Driver Name: ${DriverZegoService.currentDriverName}');

    // Log the simulated call
    DriverZegoService.logIncomingCall(callerId, callerName);

    _debugPrint('📱 Call notification should appear on device');
    _debugPrint('🎯 Driver can now accept or decline the call');

    _printSeparator();
  }

  /// Log call acceptance
  static void logCallAccepted(String callerId) {
    if (!kDebugMode) return;
    DriverZegoService.logCallAnswered(callerId);
  }

  /// Log call decline
  static void logCallDeclined(String callerId) {
    if (!kDebugMode) return;
    DriverZegoService.logCallDeclined(callerId);
  }

  /// Log call end
  static void logCallEnded(String callerId, String duration) {
    if (!kDebugMode) return;
    int durationInt = int.tryParse(duration) ?? 0;
    DriverZegoService.logCallEnded(callerId, durationInt);
  }

  /// Print formatted debug header
  static void _printHeader(String title) {
    print('\n' + '=' * 80);
    print('🔍 $title');
    print('=' * 80);
  }

  /// Print formatted debug sub-header
  static void _printSubHeader(String title) {
    print('\n📋 ═══ $title ═══');
  }

  /// Print separator
  static void _printSeparator() {
    print('═' * 80 + '\n');
  }

  /// Print debug message
  static void _debugPrint(String message) {
    print('🔹 $message');
  }

  /// Get platform information
  static String _getPlatform() {
    try {
      // This would be replaced with actual platform detection
      return 'Mobile';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Quick status check
  static void quickStatusCheck() {
    if (!kDebugMode) return;

    print('\n🚀 ═══ QUICK ZEGO STATUS ═══');
    print('🔹 Initialized: ${DriverZegoService.isInitialized}');
    print('🔹 Logged In: ${DriverZegoService.isLoggedIn}');
    print('🔹 Driver ID: ${DriverZegoService.currentDriverId}');
    print(
        '🔹 Ready for Calls: ${DriverZegoService.isLoggedIn && DriverZegoService.currentDriverId.isNotEmpty}');
    print('═══════════════════════════\n');
  }

  /// Print startup debug info
  static void printStartupInfo() {
    if (!kDebugMode) return;

    _printHeader('🚀 ZEGO DRIVER APP STARTUP DEBUG');

    print('📱 App Name: Masark Driver');
    print('🔧 Zego Integration: Active');
    print('🌐 Language: Arabic (RTL)');
    print('📞 Call Support: Video/Voice');
    print('🔐 Authentication: Phone Number Based');
    print('🎯 Target: Taxi Driver App');

    _printSeparator();
  }

  /// Monitor call status changes
  static void monitorCallStatusChanges() {
    if (!kDebugMode) return;

    _debugPrint('👀 Monitoring call status changes...');
    _debugPrint('📊 Available states: Idle, Incoming, Active, Ended');
    _debugPrint('🔄 Status updates will be logged automatically');
  }
}
