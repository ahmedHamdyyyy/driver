import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/Services/RideService.dart';

/// Utility class to ensure new drivers start with completely clean data
class NewDriverDataCleaner {
  static final RideService _rideService = RideService();

  /// Complete data cleanup for new drivers
  static Future<void> clearAllDataForNewDriver() async {
    try {
      log('🧹 Starting complete data cleanup for new driver...');

      // Clear all ride-related SharedPreferences
      await _clearRidePreferences();

      // Clear all cached data from AppStore
      await _clearAppStoreData();

      // Clear Firebase/Firestore cached data
      await _clearFirebaseData();

      // Clear any temporary files or cached images
      await _clearTemporaryData();

      log('✅ Complete data cleanup completed successfully');
    } catch (e) {
      log('❌ Error during data cleanup: $e');
    }
  }

  /// Clear all ride-related SharedPreferences
  static Future<void> _clearRidePreferences() async {
    try {
      log('🧹 Clearing ride-related SharedPreferences...');

      // Remove ride-specific data
      await sharedPref.remove(ON_RIDE_MODEL);
      await sharedPref.remove(IS_TIME2);
      await sharedPref.remove('RIDE_ID_IS');

      // Clear any cached ride lists or data
      await sharedPref.remove('cached_rides');
      await sharedPref.remove('last_ride_update');
      await sharedPref.remove('pending_rides_count');

      // Clear document screen state (if exists from previous incomplete registration)
      await sharedPref.remove('documents_screen_state');

      // Clear any location-based ride caches
      await sharedPref.remove('nearby_rides_cache');
      await sharedPref.remove('driver_location_rides');

      log('✅ SharedPreferences cleared successfully');
    } catch (e) {
      log('❌ Error clearing SharedPreferences: $e');
    }
  }

  /// Clear AppStore cached data
  static Future<void> _clearAppStoreData() async {
    try {
      log('🧹 Clearing AppStore cached data...');

      // Reset current ride request
      appStore.currentRiderRequest = null;

      // Reset any review or rating data
      appStore.setIsShowRiderReview('0');

      log('✅ AppStore data cleared successfully');
    } catch (e) {
      log('❌ Error clearing AppStore data: $e');
    }
  }

  /// Clear Firebase/Firestore cached data
  static Future<void> _clearFirebaseData() async {
    try {
      log('🧹 Clearing Firebase cached data...');

      final userId = sharedPref.getInt(USER_ID);
      if (userId != null && userId > 0) {
        // Clear any existing ride entries for this driver
        await _rideService.removeOldRideEntry(userId: userId);

        // Clear Firestore cache (local cache)
        try {
          await FirebaseFirestore.instance.clearPersistence();
          log('✅ Firestore cache cleared');
        } catch (e) {
          // This might fail if there are active listeners, which is okay
          log('ℹ️ Firestore cache clear skipped (active listeners): $e');
        }
      }

      log('✅ Firebase data cleared successfully');
    } catch (e) {
      log('❌ Error clearing Firebase data: $e');
    }
  }

  /// Clear temporary data and caches
  static Future<void> _clearTemporaryData() async {
    try {
      log('🧹 Clearing temporary data...');

      // Clear any temporary ride data
      await sharedPref.remove('temp_ride_data');
      await sharedPref.remove('last_ride_check');
      await sharedPref.remove('ride_notifications_cache');

      // Clear any driver status caches
      await sharedPref.remove('driver_online_status_cache');
      await sharedPref.remove('last_location_update');

      log('✅ Temporary data cleared successfully');
    } catch (e) {
      log('❌ Error clearing temporary data: $e');
    }
  }

  /// Check if this is a new driver registration
  static bool isNewDriverRegistration() {
    try {
      // Check if this is the first time the driver is entering the app
      final isFirstLogin = sharedPref.getBool('is_first_driver_login') ?? true;
      final hasCompletedRides = sharedPref.getInt('total_completed_rides') ?? 0;

      return isFirstLogin && hasCompletedRides == 0;
    } catch (e) {
      log('Error checking new driver status: $e');
      return false;
    }
  }

  /// Mark driver as no longer new (call after successful first ride)
  static Future<void> markDriverAsExperienced() async {
    try {
      await sharedPref.setBool('is_first_driver_login', false);
      log('✅ Driver marked as experienced');
    } catch (e) {
      log('❌ Error marking driver as experienced: $e');
    }
  }

  /// Reset new driver flag (for testing or re-registration)
  static Future<void> resetNewDriverFlag() async {
    try {
      await sharedPref.setBool('is_first_driver_login', true);
      await sharedPref.setInt('total_completed_rides', 0);
      log('✅ New driver flag reset');
    } catch (e) {
      log('❌ Error resetting new driver flag: $e');
    }
  }

  /// Cleanup specifically for logout
  static Future<void> clearDataOnLogout() async {
    try {
      log('🧹 Clearing data on logout...');

      // Clear all ride-related data
      await _clearRidePreferences();
      await _clearAppStoreData();

      // Clear Firebase cache
      try {
        await FirebaseFirestore.instance.clearPersistence();
      } catch (e) {
        log('Firestore cache clear skipped on logout: $e');
      }

      // Reset new driver flag for next registration
      // await resetNewDriverFlag();

      log('✅ Logout data cleanup completed');
    } catch (e) {
      log('❌ Error during logout cleanup: $e');
    }
  }

  /// Enhanced ride data filtering for new drivers
  static List<T> filterRidesForNewDriver<T>(List<T> rides, int driverId) {
    try {
      // For new drivers, only show rides that are specifically assigned to them
      // or rides that are genuinely available for all drivers in their area

      /*if (isNewDriverRegistration()) {
        log('🔍 Filtering rides for new driver ID: $driverId');

        // Return empty list for new drivers to ensure clean start
        // They should only see new incoming ride requests, not historical data
        return <T>[];
      }*/

      // For experienced drivers, return all rides
      return rides;
    } catch (e) {
      log('❌ Error filtering rides for new driver: $e');
      return rides;
    }
  }

  /// Clean start verification
  static Future<bool> verifyCleanStart() async {
    try {
      log('🔍 Verifying clean start for new driver...');

      // Check if critical ride data is cleared
      final hasOldRideData = sharedPref.getString(ON_RIDE_MODEL) != null;
      final hasTimeData = sharedPref.getString(IS_TIME2) != null;
      final hasRideId = sharedPref.getString('RIDE_ID_IS') != null;

      final isClean = !hasOldRideData && !hasTimeData && !hasRideId;

      log(isClean
          ? '✅ Clean start verified - no old ride data found'
          : '⚠️ Warning: Old ride data still present');

      return isClean;
    } catch (e) {
      log('❌ Error verifying clean start: $e');
      return false;
    }
  }
}
