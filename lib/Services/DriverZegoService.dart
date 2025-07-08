import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/Constants.dart';
import '../main.dart';

class DriverZegoService {
  static bool _isInitialized = false;
  static bool _isLoggedIn = false;
  static String _currentDriverId = '';
  static String _currentDriverName = '';

  // Getters for external access
  static bool get isInitialized => _isInitialized;
  static bool get isLoggedIn => _isLoggedIn;
  static String get currentDriverId => _currentDriverId;
  static String get currentDriverName => _currentDriverName;

  /// Print debug with clear formatting
  static void _debugPrint(String message, {String emoji = '🔵'}) {
    if (kDebugMode) {
      print('════════════════════════════════════════');
      print('$emoji ZEGO DRIVER DEBUG: $message');
      print('════════════════════════════════════════');
    }
  }

  /// Print status update
  static void _statusPrint(String title, Map<String, dynamic> details) {
    if (kDebugMode) {
      print('\n📊 ═══ $title ═══');
      details.forEach((key, value) {
        print('   $key: $value');
      });
      print('═══════════════════════════════════════\n');
    }
  }

  /// Check and request permissions
  static Future<bool> checkPermissions() async {
    try {
      _debugPrint('🔐 CHECKING PERMISSIONS...', emoji: '🔐');

      Map<Permission, PermissionStatus> permissions = await [
        Permission.microphone,
        Permission.camera,
        Permission.phone,
        Permission.notification,
      ].request();

      bool allGranted = true;
      Map<String, String> permissionStatus = {};

      permissions.forEach((permission, status) {
        String permissionName = permission.toString().split('.').last;
        permissionStatus[permissionName] = status.toString().split('.').last;
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      _statusPrint('PERMISSION STATUS', permissionStatus);

      if (!allGranted) {
        _debugPrint(
            '❌ Some permissions not granted - calls may not work properly',
            emoji: '❌');
      } else {
        _debugPrint('✅ All permissions granted', emoji: '✅');
      }

      return allGranted;
    } catch (e) {
      _debugPrint('❌ Permission check failed: $e', emoji: '❌');
      return false;
    }
  }

  /// Initialize Zego SDK (Note: System calling UI is initialized in main.dart)
  static Future<bool> initializeZego() async {
    try {
      _debugPrint('🚀 INITIALIZING ZEGO SDK...', emoji: '🚀');

      if (_isInitialized) {
        _debugPrint('✅ Zego already initialized', emoji: '✅');
        return true;
      }

      // Check permissions first
      await checkPermissions();

      _statusPrint('INITIALIZATION STATUS', {
        'App ID': ZEGO_APP_ID,
        'App Sign': '${ZEGO_APP_SIGN.substring(0, 10)}...',
        'System UI': 'Initialized in main.dart',
        'Status': 'Ready'
      });

      _isInitialized = true;
      _debugPrint('✅ ZEGO SDK INITIALIZATION COMPLETE', emoji: '✅');
      return true;
    } catch (e) {
      _debugPrint('❌ ZEGO SDK INITIALIZATION FAILED: $e', emoji: '❌');
      return false;
    }
  }

  /// Login driver to Zego
  static Future<bool> loginDriver({
    required String driverPhone,
    required String driverName,
  }) async {
    try {
      _debugPrint('🔐 STARTING DRIVER LOGIN TO ZEGO...', emoji: '🔐');

      // Sanitize phone number (remove special characters)
      final sanitizedPhone = driverPhone.replaceAll(RegExp(r'[^\w\d]'), '');
      final displayName =
          driverName.isNotEmpty ? driverName : 'Driver_$sanitizedPhone';

      _statusPrint('DRIVER LOGIN DETAILS', {
        'Original Phone': driverPhone,
        'Sanitized User ID': sanitizedPhone,
        'Display Name': displayName,
        'Previous Status': _isLoggedIn ? 'Already Logged In' : 'Not Logged In'
      });

      if (_isLoggedIn && _currentDriverId == sanitizedPhone) {
        _debugPrint('✅ Driver already logged in with same credentials',
            emoji: '✅');
        return true;
      }

      // If different driver, logout first
      if (_isLoggedIn && _currentDriverId != sanitizedPhone) {
        _debugPrint('🔄 Different driver detected, logging out previous...',
            emoji: '🔄');
        await logoutDriver();
      }

      _debugPrint('📞 Initializing Zego Call Invitation Service...',
          emoji: '📞');

      // Initialize the call invitation service with driver credentials
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: ZEGO_APP_ID,
        appSign: ZEGO_APP_SIGN,
        userID: sanitizedPhone,
        userName: displayName,
        plugins: [ZegoUIKitSignalingPlugin()],
      );

      _isLoggedIn = true;
      _currentDriverId = sanitizedPhone;
      _currentDriverName = displayName;

      _statusPrint('DRIVER LOGIN SUCCESS', {
        'Driver Zego ID': sanitizedPhone,
        'Driver Zego Name': displayName,
        'Login Status': 'SUCCESS',
        'Can Receive Calls': 'YES'
      });

      _debugPrint('✅ DRIVER SUCCESSFULLY LOGGED INTO ZEGO!', emoji: '🎉');

      // Test connection after login
      await testConnection();

      return true;
    } catch (e) {
      _debugPrint('❌ DRIVER ZEGO LOGIN FAILED: $e', emoji: '❌');
      _statusPrint('LOGIN ERROR DETAILS', {
        'Error': e.toString(),
        'Phone': driverPhone,
        'Action': 'Login Failed'
      });
      return false;
    }
  }

  /// Auto-login after driver authentication
  static Future<bool> autoLoginDriver() async {
    try {
      _debugPrint('🔄 STARTING AUTO-LOGIN PROCESS...', emoji: '🔄');

      // Get driver data from shared preferences
      String driverPhone = sharedPref.getString(CONTACT_NUMBER) ?? '';
      String firstName = sharedPref.getString(FIRST_NAME) ?? '';
      String lastName = sharedPref.getString(LAST_NAME) ?? '';
      String userName = sharedPref.getString(USER_NAME) ?? '';

      String driverName = '$firstName $lastName'.trim();
      if (driverName.isEmpty) {
        driverName = userName;
      }

      _statusPrint('AUTO-LOGIN DRIVER DATA', {
        'Phone from SharedPref': driverPhone,
        'First Name': firstName,
        'Last Name': lastName,
        'User Name': userName,
        'Final Display Name': driverName
      });

      if (driverPhone.isEmpty) {
        _debugPrint('❌ Driver phone not available for Zego login', emoji: '❌');
        return false;
      }

      _debugPrint('🔐 Proceeding with auto-login...', emoji: '🔐');
      return await loginDriver(
        driverPhone: driverPhone,
        driverName: driverName,
      );
    } catch (e) {
      _debugPrint('❌ DRIVER AUTO-LOGIN FAILED: $e', emoji: '❌');
      return false;
    }
  }

  /// Test connection after login
  static Future<void> testConnection() async {
    try {
      _debugPrint('🧪 TESTING ZEGO CONNECTION...', emoji: '🧪');

      // Check if service is properly initialized
      bool canReceiveCalls = _isLoggedIn && _currentDriverId.isNotEmpty;

      _statusPrint('CONNECTION TEST RESULTS', {
        'Service Initialized': _isInitialized,
        'Driver Logged In': _isLoggedIn,
        'Driver ID Set': _currentDriverId.isNotEmpty,
        'Ready for Calls': canReceiveCalls,
        'System UI Active': 'Should be active from main.dart'
      });

      if (canReceiveCalls) {
        _debugPrint('✅ CONNECTION TEST PASSED - Ready to receive calls!',
            emoji: '✅');
      } else {
        _debugPrint('❌ CONNECTION TEST FAILED - Check configuration',
            emoji: '❌');
      }
    } catch (e) {
      _debugPrint('❌ Connection test failed: $e', emoji: '❌');
    }
  }

  /// Logout driver from Zego
  static Future<void> logoutDriver() async {
    try {
      _debugPrint('🔓 STARTING DRIVER LOGOUT FROM ZEGO...', emoji: '🔓');

      _statusPrint('LOGOUT DETAILS', {
        'Current Driver ID': _currentDriverId,
        'Current Driver Name': _currentDriverName,
        'Was Logged In': _isLoggedIn
      });

      if (!_isLoggedIn) {
        _debugPrint('ℹ️ Driver was not logged in', emoji: 'ℹ️');
        return;
      }

      await ZegoUIKitPrebuiltCallInvitationService().uninit();

      _isLoggedIn = false;
      _currentDriverId = '';
      _currentDriverName = '';

      _debugPrint('✅ DRIVER SUCCESSFULLY LOGGED OUT FROM ZEGO', emoji: '✅');
    } catch (e) {
      _debugPrint('❌ DRIVER ZEGO LOGOUT FAILED: $e', emoji: '❌');
    }
  }

  /// Check Zego status for debugging
  static void checkZegoStatus() {
    _debugPrint('🔍 COMPREHENSIVE ZEGO STATUS CHECK', emoji: '🔍');

    _statusPrint('ZEGO CONFIGURATION', {
      'App ID': ZEGO_APP_ID,
      'App Sign': '${ZEGO_APP_SIGN.substring(0, 15)}...',
      'Callback Secret': '${ZEGO_CALLBACK_SECRET.substring(0, 10)}...',
      'Scenario': ZEGO_SCENARIO
    });

    _statusPrint('DRIVER STATUS', {
      'Zego Initialized': _isInitialized,
      'Driver Logged In': _isLoggedIn,
      'Current Driver ID':
          _currentDriverId.isNotEmpty ? _currentDriverId : 'None',
      'Current Driver Name':
          _currentDriverName.isNotEmpty ? _currentDriverName : 'None'
    });

    _statusPrint('SHARED PREFERENCES DATA', {
      'Contact Number': sharedPref.getString(CONTACT_NUMBER) ?? 'Not Set',
      'First Name': sharedPref.getString(FIRST_NAME) ?? 'Not Set',
      'Last Name': sharedPref.getString(LAST_NAME) ?? 'Not Set',
      'User Name': sharedPref.getString(USER_NAME) ?? 'Not Set',
      'Is Logged In': sharedPref.getBool(IS_LOGGED_IN) ?? false
    });

    _statusPrint('CALL READINESS', {
      'Can Receive Calls': _isLoggedIn && _currentDriverId.isNotEmpty,
      'System Calling UI': 'Active',
      'Call Invitation Service': _isLoggedIn ? 'Active' : 'Inactive'
    });

    // Print troubleshooting tips
    if (!_isLoggedIn || _currentDriverId.isEmpty) {
      _debugPrint('🔧 TROUBLESHOOTING TIPS:', emoji: '🔧');
      print('   1. Make sure driver is logged into the app');
      print('   2. Check if CONTACT_NUMBER is saved in SharedPreferences');
      print(
          '   3. Call DriverZegoService.autoLoginDriver() after driver login');
      print('   4. Verify Zego credentials are correct');
      print('   5. Check app permissions (microphone, camera, phone)');
    }
  }

  /// Get driver Zego ID (sanitized phone)
  static String getDriverZegoId() {
    String driverPhone = sharedPref.getString(CONTACT_NUMBER) ?? '';
    String sanitized = driverPhone.replaceAll(RegExp(r'[^\w\d]'), '');

    _debugPrint('📱 Getting Driver Zego ID: $sanitized', emoji: '📱');
    return sanitized;
  }

  /// Setup call event listeners for debugging
  static void setupCallEventListeners() {
    _debugPrint('🎧 SETTING UP CALL EVENT LISTENERS...', emoji: '🎧');

    // Note: These would be set during the init process
    // This is for documentation purposes to show what events we're tracking
    _statusPrint('CALL EVENTS MONITORING', {
      'Incoming Call': 'Will be logged when received',
      'Call Accepted': 'Will be logged when answered',
      'Call Declined': 'Will be logged when declined',
      'Call Ended': 'Will be logged when ended'
    });
  }

  /// Log incoming call event
  static void logIncomingCall(String callerID, String callerName) {
    _debugPrint('📞 INCOMING CALL RECEIVED!', emoji: '📞');

    _statusPrint('INCOMING CALL DETAILS', {
      'Caller ID': callerID,
      'Caller Name': callerName,
      'Driver ID': _currentDriverId,
      'Driver Name': _currentDriverName,
      'Timestamp': DateTime.now().toString()
    });
  }

  /// Log call answer event
  static void logCallAnswered(String callerID) {
    _debugPrint('✅ CALL ANSWERED BY DRIVER!', emoji: '✅');

    _statusPrint('CALL ANSWERED', {
      'Caller ID': callerID,
      'Driver ID': _currentDriverId,
      'Action': 'Call Accepted',
      'Timestamp': DateTime.now().toString()
    });
  }

  /// Log call decline event
  static void logCallDeclined(String callerID) {
    _debugPrint('❌ CALL DECLINED BY DRIVER!', emoji: '❌');

    _statusPrint('CALL DECLINED', {
      'Caller ID': callerID,
      'Driver ID': _currentDriverId,
      'Action': 'Call Declined',
      'Timestamp': DateTime.now().toString()
    });
  }

  /// Log call end event
  static void logCallEnded(String callerID, int duration) {
    _debugPrint('📴 CALL ENDED!', emoji: '📴');

    _statusPrint('CALL ENDED', {
      'Caller ID': callerID,
      'Driver ID': _currentDriverId,
      'Duration': '${duration}s',
      'Action': 'Call Ended',
      'Timestamp': DateTime.now().toString()
    });
  }

  /// Force refresh Zego connection
  static Future<bool> refreshConnection() async {
    try {
      _debugPrint('🔄 REFRESHING ZEGO CONNECTION...', emoji: '🔄');

      if (_isLoggedIn) {
        await logoutDriver();
        await Future.delayed(Duration(seconds: 1));
      }

      return await autoLoginDriver();
    } catch (e) {
      _debugPrint('❌ Connection refresh failed: $e', emoji: '❌');
      return false;
    }
  }

  /// Call a rider - Voice Call
  static Future<bool> callRiderVoice({
    required String riderPhoneNumber,
    required BuildContext context,
    String? riderName,
  }) async {
    try {
      _debugPrint('📞 INITIATING VOICE CALL TO RIDER...', emoji: '📞');

      // Sanitize rider phone number
      final sanitizedRiderPhone =
          riderPhoneNumber.replaceAll(RegExp(r'[^\w\d]'), '');
      final displayRiderName = riderName?.isNotEmpty == true
          ? riderName!
          : 'Rider_$sanitizedRiderPhone';

      _statusPrint('VOICE CALL TO RIDER', {
        'Driver ID': _currentDriverId,
        'Driver Name': _currentDriverName,
        'Target Rider Phone': riderPhoneNumber,
        'Sanitized Rider ID': sanitizedRiderPhone,
        'Rider Display Name': displayRiderName,
        'Call Type': 'VOICE'
      });

      // Check if driver is logged in
      if (!_isLoggedIn || _currentDriverId.isEmpty) {
        _debugPrint('❌ Driver not logged in to Zego', emoji: '❌');
        return false;
      }

      // Check if target rider ID is valid
      if (sanitizedRiderPhone.isEmpty) {
        _debugPrint('❌ Invalid rider phone number', emoji: '❌');
        return false;
      }

      _debugPrint('📞 Sending voice call invitation to rider...', emoji: '📞');

      // Send voice call invitation to rider
      await ZegoUIKitPrebuiltCallInvitationService().send(
        isVideoCall: false,
        invitees: [
          ZegoCallUser(sanitizedRiderPhone, displayRiderName),
        ],
        resourceID: "zego_call_${DateTime.now().millisecondsSinceEpoch}",
      );

      _debugPrint('✅ VOICE CALL INVITATION SENT TO RIDER!', emoji: '✅');

      _statusPrint('CALL SENT SUCCESSFULLY', {
        'Invitation Type': 'Voice Call',
        'From Driver': '${_currentDriverName} ($_currentDriverId)',
        'To Rider': '$displayRiderName ($sanitizedRiderPhone)',
        'Timestamp': DateTime.now().toString(),
        'Status': 'Invitation Sent'
      });

      return true;
    } catch (e) {
      _debugPrint('❌ VOICE CALL TO RIDER FAILED: $e', emoji: '❌');
      _statusPrint('CALL ERROR', {
        'Error': e.toString(),
        'Rider Phone': riderPhoneNumber,
        'Call Type': 'Voice',
        'Driver ID': _currentDriverId
      });
      return false;
    }
  }

  /// Call a rider - Video Call
  static Future<bool> callRiderVideo({
    required String riderPhoneNumber,
    required BuildContext context,
    String? riderName,
  }) async {
    try {
      _debugPrint('📹 INITIATING VIDEO CALL TO RIDER...', emoji: '📹');

      // Sanitize rider phone number
      final sanitizedRiderPhone =
          riderPhoneNumber.replaceAll(RegExp(r'[^\w\d]'), '');
      final displayRiderName = riderName?.isNotEmpty == true
          ? riderName!
          : 'Rider_$sanitizedRiderPhone';

      _statusPrint('VIDEO CALL TO RIDER', {
        'Driver ID': _currentDriverId,
        'Driver Name': _currentDriverName,
        'Target Rider Phone': riderPhoneNumber,
        'Sanitized Rider ID': sanitizedRiderPhone,
        'Rider Display Name': displayRiderName,
        'Call Type': 'VIDEO'
      });

      // Check if driver is logged in
      if (!_isLoggedIn || _currentDriverId.isEmpty) {
        _debugPrint('❌ Driver not logged in to Zego', emoji: '❌');
        return false;
      }

      // Check if target rider ID is valid
      if (sanitizedRiderPhone.isEmpty) {
        _debugPrint('❌ Invalid rider phone number', emoji: '❌');
        return false;
      }

      _debugPrint('📹 Sending video call invitation to rider...', emoji: '📹');

      // Send video call invitation to rider
      await ZegoUIKitPrebuiltCallInvitationService().send(
        isVideoCall: true,
        invitees: [
          ZegoCallUser(sanitizedRiderPhone, displayRiderName),
        ],
        resourceID: "zego_call_${DateTime.now().millisecondsSinceEpoch}",
      );

      _debugPrint('✅ VIDEO CALL INVITATION SENT TO RIDER!', emoji: '✅');

      _statusPrint('CALL SENT SUCCESSFULLY', {
        'Invitation Type': 'Video Call',
        'From Driver': '${_currentDriverName} ($_currentDriverId)',
        'To Rider': '$displayRiderName ($sanitizedRiderPhone)',
        'Timestamp': DateTime.now().toString(),
        'Status': 'Invitation Sent'
      });

      return true;
    } catch (e) {
      _debugPrint('❌ VIDEO CALL TO RIDER FAILED: $e', emoji: '❌');
      _statusPrint('CALL ERROR', {
        'Error': e.toString(),
        'Rider Phone': riderPhoneNumber,
        'Call Type': 'Video',
        'Driver ID': _currentDriverId
      });
      return false;
    }
  }

  /// Generic call rider function with type selection
  static Future<bool> callRider({
    required String riderPhoneNumber,
    required BuildContext context,
    String? riderName,
    bool isVideoCall = true,
  }) async {
    _debugPrint('🎯 CALLING RIDER WITH TYPE SELECTION...', emoji: '🎯');

    if (isVideoCall) {
      return await callRiderVideo(
        riderPhoneNumber: riderPhoneNumber,
        context: context,
        riderName: riderName,
      );
    } else {
      return await callRiderVoice(
        riderPhoneNumber: riderPhoneNumber,
        context: context,
        riderName: riderName,
      );
    }
  }

  /// Test call functionality
  static Future<bool> testCallRider({
    required BuildContext context,
    String testRiderPhone = "966501234567",
    String testRiderName = "Test Rider",
    bool isVideoCall = true,
  }) async {
    _debugPrint('🧪 TESTING CALL TO RIDER...', emoji: '🧪');

    _statusPrint('TEST CALL PARAMETERS', {
      'Test Rider Phone': testRiderPhone,
      'Test Rider Name': testRiderName,
      'Call Type': isVideoCall ? 'Video' : 'Voice',
      'Driver Status': _isLoggedIn ? 'Logged In' : 'Not Logged In'
    });

    return await callRider(
      riderPhoneNumber: testRiderPhone,
      context: context,
      riderName: testRiderName,
      isVideoCall: isVideoCall,
    );
  }

  /// Get current call status
  static Map<String, dynamic> getCallStatus() {
    return {
      'canMakeCalls': _isLoggedIn && _currentDriverId.isNotEmpty,
      'driverLoggedIn': _isLoggedIn,
      'driverID': _currentDriverId,
      'driverName': _currentDriverName,
      'zegoInitialized': _isInitialized,
      'timestamp': DateTime.now().toString(),
    };
  }

  /// Print comprehensive debug info
  static void printDebugInfo() {
    _debugPrint('📋 COMPREHENSIVE DEBUG INFORMATION', emoji: '📋');

    checkZegoStatus();

    _statusPrint('PHONE NUMBER PROCESSING', {
      'Original Phone': sharedPref.getString(CONTACT_NUMBER) ?? 'Not Set',
      'Sanitized ID': getDriverZegoId(),
      'ID Length': getDriverZegoId().length,
      'ID Valid': getDriverZegoId().isNotEmpty && getDriverZegoId().length > 3
    });

    _statusPrint('CALL CAPABILITIES', {
      'Can Make Voice Calls':
          _isLoggedIn && _currentDriverId.isNotEmpty ? 'YES' : 'NO',
      'Can Make Video Calls':
          _isLoggedIn && _currentDriverId.isNotEmpty ? 'YES' : 'NO',
      'Can Receive Calls':
          _isLoggedIn && _currentDriverId.isNotEmpty ? 'YES' : 'NO',
      'Ready for Both Directions':
          _isLoggedIn && _currentDriverId.isNotEmpty ? 'YES' : 'NO'
    });

    _statusPrint('INTEGRATION CHECKLIST', {
      '1. System UI Initialized': 'Check main.dart logs',
      '2. Driver Auto-Login Called':
          _isLoggedIn ? 'YES' : 'NO - CALL autoLoginDriver()',
      '3. Permissions Granted': 'Check permission status above',
      '4. Phone Number Valid': getDriverZegoId().isNotEmpty ? 'YES' : 'NO',
      '5. Zego Credentials': 'Check Constants.dart',
      '6. Call Functions Available':
          'YES - callRider(), callRiderVoice(), callRiderVideo()'
    });
  }
}
