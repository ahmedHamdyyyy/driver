import 'package:taxi_driver/model/RiderModel.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Constants.dart';

/// خدمة التحقق من تطابق نوع الخدمة بين الطلبات والسائق
class ServiceMatchingService {
  static UserData? _currentDriverData;
  static int? _driverServiceId;

  /// جلب معلومات السائق الحالي والاحتفاظ بها في الذاكرة
  static Future<void> initializeDriverData() async {
    try {
      final driverId = sharedPref.getInt(USER_ID);
      if (driverId != null) {
        final response = await getUserDetail(userId: driverId);
        _currentDriverData = response.data;
        _driverServiceId = response.data?.serviceId;
        print('🚗 تم تحميل معلومات السائق - نوع الخدمة: $_driverServiceId');
      }
    } catch (e) {
      print('❌ خطأ في جلب معلومات السائق: $e');
    }
  }

  /// الحصول على نوع خدمة السائق الحالي
  static int? get driverServiceId {
    if (_driverServiceId == null) {
      // محاولة جلب البيانات من SharedPreferences كـ backup
      final serviceId = sharedPref.getInt('driver_service_id');
      if (serviceId != null) {
        _driverServiceId = serviceId;
      }
    }
    return _driverServiceId;
  }

  /// التحقق من تطابق نوع الخدمة
  static bool isServiceMatch(RiderModel ride) {
    final rideServiceId = ride.serviceId;
    final driverServiceId = ServiceMatchingService.driverServiceId;

    // إذا لم نتمكن من جلب معلومات السائق، نعرض جميع الطلبات (للأمان)
    if (driverServiceId == null) {
      print('⚠️ لم يتم العثور على نوع خدمة السائق - عرض جميع الطلبات');
      return true;
    }

    // إذا لم يكن للطلب نوع خدمة محدد، نعرضه (للأمان)
    if (rideServiceId == null) {
      print('⚠️ الطلب ${ride.id} لا يحتوي على نوع خدمة محدد');
      return true;
    }

    final isMatch = rideServiceId == driverServiceId;

    if (!isMatch) {
      print(
          '🚫 تم إخفاء الطلب ${ride.id} - نوع الخدمة المطلوب: $rideServiceId، نوع خدمة السائق: $driverServiceId');
    } else {
      print('✅ تم عرض الطلب ${ride.id} - نوع الخدمة متطابق: $rideServiceId');
    }

    return isMatch;
  }

  /// تصفية قائمة الطلبات حسب نوع الخدمة
  static List<RiderModel> filterRidesByService(List<RiderModel> rides) {
    if (rides.isEmpty) return rides;

    final originalCount = rides.length;
    final filteredRides = rides.where((ride) => isServiceMatch(ride)).toList();
    final filteredCount = filteredRides.length;

    if (originalCount != filteredCount) {
      print(
          '📊 تم تصفية الطلبات: $originalCount ← $filteredCount (تم إخفاء ${originalCount - filteredCount} طلبات غير متطابقة)');
    }

    return filteredRides;
  }

  /// حفظ نوع خدمة السائق في SharedPreferences للوصول السريع
  static Future<void> saveDriverServiceId(int serviceId) async {
    _driverServiceId = serviceId;
    await sharedPref.setInt('driver_service_id', serviceId);
    print('💾 تم حفظ نوع خدمة السائق: $serviceId');
  }

  /// إعادة تعيين بيانات السائق (مفيد عند تسجيل الخروج)
  static void resetDriverData() {
    _currentDriverData = null;
    _driverServiceId = null;
    sharedPref.remove('driver_service_id');
    print('🔄 تم إعادة تعيين معلومات السائق');
  }

  /// الحصول على اسم نوع الخدمة
  static String getServiceName() {
    if (_currentDriverData?.driverService?.name != null) {
      return _currentDriverData!.driverService!.name!;
    }
    return 'نوع الخدمة غير محدد';
  }

  /// إحصائيات التصفية للعرض في واجهة المستخدم
  static Map<String, dynamic> getFilteringStats(
      List<RiderModel> originalRides, List<RiderModel> filteredRides) {
    return {
      'totalRides': originalRides.length,
      'visibleRides': filteredRides.length,
      'hiddenRides': originalRides.length - filteredRides.length,
      'driverServiceId': driverServiceId,
      'serviceName': getServiceName(),
    };
  }
}
