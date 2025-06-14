import 'package:taxi_driver/model/CouponData.dart';
import 'package:taxi_driver/model/ExtraChargeRequestModel.dart';

class RiderModel {
  num? amount;
  num? baseFare;
  String? cancelBy;
  int? canceLationCharges;
  String? coupon;
  CouponData? couponData;
  String? createdAt;
  String? datetime;
  num? distance;
  int? driverId;
  String? driverName;
  String? driverProfileImage;
  num? duration;
  String? endAddress;
  String? endLatitude;
  String? endLongitude;
  String? endTime;
  List<ExtraChargeRequestModel>? extraCharges;
  int? id;
  int? isDriverRated;
  int? isRiderRated;
  int? isSchedule;
  int? maxTimeForFindDriverForRideRequest;
  num? minimumFare;
  String? otp;
  int? paymentId;
  String? paymentStatus;
  String? paymentType;
  num? perDistance;
  num? perMinuteDrive;
  String? reason;
  int? rideAttempt;
  int? riderId;
  int? ride_has_bids;
  String? riderName;
  String? riderEmail;
  String? riderProfileImage;
  int? seatCount;
  int? serviceId;
  String? startAddress;
  String? startLatitude;
  String? startLongitude;
  String? startTime;
  String? status;
  num? subtotal;
  num? totalAmount;
  String? updatedAt;
  num? waitingTime;
  num? waitingTimeCharges;
  num? perMinuteWaiting;
  String? distanceUnit;
  num? couponDiscount;
  num? perMinuteWaitingCharge;
  num? surgeCharge;
  num? perMinuteDriveCharge;
  num? perDistanceCharge;
  String? driverContactNumber;
  String? riderContactNumber;
  num? extraChargesAmount;
  OtherRiderData? otherRiderData;
  num? tips;
  List<MultiDropLocation>? multiDropLocation;

  RiderModel({
    this.amount,
    this.baseFare,
    this.cancelBy,
    this.canceLationCharges,
    this.multiDropLocation,
    this.coupon,
    this.couponData,
    this.ride_has_bids,
    this.createdAt,
    this.datetime,
    this.distance,
    this.driverId,
    this.riderEmail,
    this.driverName,
    this.driverProfileImage,
    this.duration,
    this.endAddress,
    this.endLatitude,
    this.endLongitude,
    this.endTime,
    this.extraCharges,
    this.id,
    this.isDriverRated,
    this.isRiderRated,
    this.isSchedule,
    this.maxTimeForFindDriverForRideRequest,
    this.minimumFare,
    this.otp,
    this.paymentId,
    this.paymentStatus,
    this.paymentType,
    this.perDistance,
    this.perMinuteDrive,
    this.reason,
    this.rideAttempt,
    this.riderId,
    this.riderName,
    this.riderProfileImage,
    this.seatCount,
    this.serviceId,
    this.startAddress,
    this.startLatitude,
    this.startLongitude,
    this.startTime,
    this.status,
    this.subtotal,
    this.totalAmount,
    this.updatedAt,
    this.waitingTime,
    this.waitingTimeCharges,
    this.perMinuteWaiting,
    this.distanceUnit,
    this.couponDiscount,
    this.perDistanceCharge,
    this.perMinuteDriveCharge,
    this.perMinuteWaitingCharge,
    this.driverContactNumber,
    this.riderContactNumber,
    this.otherRiderData,
    this.extraChargesAmount,
    this.surgeCharge,
    this.tips,
  });

  // factory RiderModel.fromJson(Map<String, dynamic> json) {
  //   return RiderModel(
  //     amount: json['amount'],
  //     baseFare: json['base_fare'],
  //     cancelBy: json['cancel_by'],
  //     canceLationCharges: int.tryParse(json['cancelation_charges'].toString()),
  //     coupon: json['coupon'],
  //     couponData: json['coupon_data'] != null ? CouponData.fromJson(json['coupon_data']) : null,
  //     createdAt: json['created_at'],
  //     datetime: json['datetime'],
  //     distance: json['distance'],
  //     driverId: json['driver_id'],
  //     driverName: json['driver_name'],
  //     driverProfileImage: json['driver_profile_image'],
  //     duration: json['duration'],
  //     endAddress: json['end_address'],
  //     endLatitude: json['end_latitude'],
  //     endLongitude: json['end_longitude'],
  //     endTime: json['end_time'],
  //     extraCharges: json['extra_charges'] != null ? (json['extra_charges'] as List).map((i) => ExtraChargeRequestModel.fromJson(i)).toList() : null,
  //     id: json['id'],
  //     isDriverRated: json['is_driver_rated'],
  //     riderEmail : json['rider_email'],
  //     isRiderRated: json['is_rider_rated'],
  //     isSchedule: json['is_schedule'],
  //     maxTimeForFindDriverForRideRequest: json['max_time_for_find_driver_for_ride_request'],
  //     minimumFare: json['minimum_fare'],
  //     otp: json['otp'],
  //     paymentId: json['payment_id'],
  //     paymentStatus: json['payment_status'],
  //     paymentType: json['payment_type'],
  //     perDistance: json['per_distance'],
  //     perMinuteDrive: json['per_minute_drive'],
  //     reason: json['reason'],
  //     rideAttempt: json['ride_attempt'],
  //     riderId: json['rider_id'],
  //     riderName: json['rider_name'],
  //     riderProfileImage: json['rider_profile_image'],
  //     seatCount: json['seat_count'],
  //     serviceId: json['service_id'],
  //     startAddress: json['start_address'],
  //     startLatitude: json['start_latitude'],
  //     startLongitude: json['start_longitude'],
  //     startTime: json['start_time'],
  //     status: json['status'],
  //     subtotal: json['subtotal'],
  //     totalAmount: json['total_amount'],
  //     updatedAt: json['updated_at'],
  //     waitingTime: json['waiting_time'],
  //     waitingTimeCharges: json['waiting_time_charges'],
  //     perMinuteWaiting: json['per_minute_waiting'],
  //     distanceUnit: json['distance_unit'],
  //     couponDiscount: json['coupon_discount'],
  //     perDistanceCharge: json['per_distance_charge'],
  //     perMinuteDriveCharge: json['per_minute_drive_charge'],
  //     perMinuteWaitingCharge: json['per_minute_waiting_charge'],
  //     riderContactNumber: json['rider_contact_number'],
  //     driverContactNumber: json['driver_contact_number'],
  //     otherRiderData: json['other_rider_data'] != null ? OtherRiderData.fromJson(json['other_rider_data']) : null,
  //     tips: json['tips'],
  //     extraChargesAmount: json['extra_charges_amount'],
  //   );
  // }

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      amount: json['amount'],
      baseFare: json['base_fare'],
      cancelBy: json['cancel_by'],
      canceLationCharges: int.tryParse(json['cancelation_charges'].toString()),
      ride_has_bids: int.tryParse(json['ride_has_bids'].toString()),
      coupon: json['coupon'],
      couponData: json['coupon_data'] != null
          ? CouponData.fromJson(json['coupon_data'])
          : null,
      createdAt: json['created_at'],
      datetime: json['datetime'],
      distance: json['distance'],
      driverId: int.tryParse(json['driver_id'].toString()),
      driverName: json['driver_name'],
      driverProfileImage: json['driver_profile_image'],
      duration: json['duration'],
      endAddress: json['end_address'],
      endLatitude: json['end_latitude'],
      endLongitude: json['end_longitude'],
      endTime: json['end_time'],
      extraCharges: json['extra_charges'] != null
          ? (json['extra_charges'] as List)
              .map((i) => ExtraChargeRequestModel.fromJson(i))
              .toList()
          : null,
      id: int.tryParse(json['id'].toString()),
      isDriverRated: int.tryParse(json['is_driver_rated'].toString()),
      isRiderRated: int.tryParse(json['is_rider_rated'].toString()),
      isSchedule: int.tryParse(json['is_schedule'].toString()),
      maxTimeForFindDriverForRideRequest: int.tryParse(
          json['max_time_for_find_driver_for_ride_request'].toString()),
      minimumFare: json['minimum_fare'],
      otp: json['otp'],
      multiDropLocation: json["multi_drop_location"] == null
          ? []
          : List<MultiDropLocation>.from(json["multi_drop_location"]!
              .map((x) => MultiDropLocation.fromJson(x))),
      paymentId: int.tryParse(json['payment_id'].toString()),
      paymentStatus: json['payment_status'],
      paymentType: json['payment_type'],
      perDistance: json['per_distance'],
      perMinuteDrive: json['per_minute_drive'],
      reason: json['reason'],
      rideAttempt: int.tryParse(json['ride_attempt'].toString()),
      riderId: int.tryParse(json['rider_id'].toString()),
      riderName: json['rider_name'],
      riderEmail: json['rider_email'],
      riderProfileImage: json['rider_profile_image'],
      seatCount: int.tryParse(json['seat_count'].toString()),
      serviceId: int.tryParse(json['service_id'].toString()),
      surgeCharge: num.tryParse(json['fixed_charge'].toString()),
      startAddress: json['start_address'],
      startLatitude: json['start_latitude'],
      startLongitude: json['start_longitude'],
      startTime: json['start_time'],
      status: json['status'],
      subtotal: num.tryParse(json['subtotal'].toString()),
      totalAmount: json['total_amount'],
      updatedAt: json['updated_at'],
      waitingTime: json['waiting_time'],
      waitingTimeCharges: json['waiting_time_charges'],
      perMinuteWaiting: json['per_minute_waiting'],
      distanceUnit: json['distance_unit'],
      couponDiscount: json['coupon_discount'],
      perDistanceCharge: json['per_distance_charge'],
      perMinuteDriveCharge: json['per_minute_drive_charge'],
      perMinuteWaitingCharge: json['per_minute_waiting_charge'],
      riderContactNumber: json['rider_contact_number'],
      driverContactNumber: json['driver_contact_number'],
      otherRiderData: json['other_rider_data'] != null
          ? OtherRiderData.fromJson(json['other_rider_data'])
          : null,
      tips: json['tips'],
      extraChargesAmount: json['extra_charges_amount'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['amount'] = this.amount;
    data['base_fare'] = this.baseFare;
    data['cancel_by'] = this.cancelBy;
    data['cancelation_charges'] = this.canceLationCharges;
    data['coupon'] = this.coupon;
    data['created_at'] = this.createdAt;
    data['fixed_charge'] = this.surgeCharge;
    data['datetime'] = this.datetime;
    data['ride_has_bids'] = this.ride_has_bids;
    data['distance'] = this.distance;
    data['driver_id'] = this.driverId;
    data['driver_name'] = this.driverName;
    data['driver_profile_image'] = this.driverProfileImage;
    data['duration'] = this.duration;
    data['end_address'] = this.endAddress;
    data['end_latitude'] = this.endLatitude;
    data['end_longitude'] = this.endLongitude;
    data['end_time'] = this.endTime;
    data['id'] = this.id;
    data['is_driver_rated'] = this.isDriverRated;
    data['is_rider_rated'] = this.isRiderRated;
    data['is_schedule'] = this.isSchedule;
    data['max_time_for_find_driver_for_ride_request'] =
        this.maxTimeForFindDriverForRideRequest;
    data['minimum_fare'] = this.minimumFare;
    data['otp'] = this.otp;
    data['rider_email'] = this.riderEmail;
    data['payment_id'] = this.paymentId;
    data['payment_status'] = this.paymentStatus;
    data['payment_type'] = this.paymentType;
    data['per_distance'] = this.perDistance;
    data['per_minute_drive'] = this.perMinuteDrive;
    data['reason'] = this.reason;
    data['ride_attempt'] = this.rideAttempt;
    data['rider_id'] = this.riderId;
    data['rider_name'] = this.riderName;
    data['rider_profile_image'] = this.riderProfileImage;
    data['seat_count'] = this.seatCount;
    data['service_id'] = this.serviceId;
    data['start_address'] = this.startAddress;
    data['start_latitude'] = this.startLatitude;
    data['start_longitude'] = this.startLongitude;
    data['start_time'] = this.startTime;
    data['status'] = this.status;
    data['subtotal'] = this.subtotal;
    data['total_amount'] = this.totalAmount;
    data['updated_at'] = this.updatedAt;
    data['waiting_time'] = this.waitingTime;
    data['waiting_time_charges'] = this.waitingTimeCharges;
    data['per_minute_waiting'] = this.perMinuteWaiting;
    data['distance_unit'] = this.distanceUnit;
    data['coupon_discount'] = this.couponDiscount;
    data['per_distance_charge'] = this.perDistanceCharge;
    data['per_minute_drive_charge'] = this.perMinuteDriveCharge;
    data['per_minute_waiting_charge'] = this.perMinuteWaitingCharge;
    data['rider_contact_number'] = this.perMinuteDriveCharge;
    data['driver_contact_number'] = this.perMinuteWaitingCharge;
    data['extra_charges_amount'] = this.extraChargesAmount;
    data['tips'] = this.tips;
    if (this.extraCharges != null) {
      data['extra_charges'] =
          this.extraCharges!.map((v) => v.toJson()).toList();
    }
    if (this.couponData != null) {
      data['coupon_data'] = this.couponData!.toJson();
    }
    if (this.otherRiderData != null) {
      data['other_rider_data'] = this.otherRiderData!.toJson();
    }
    if (multiDropLocation != null) {
      data["multi_drop_location"] =
          List<dynamic>.from(multiDropLocation!.map((x) => x!.toJson()));
    }
    return data;
  }
}

class OtherRiderData {
  String? name;
  String? conatctNumber;

  OtherRiderData({this.name, this.conatctNumber});

  OtherRiderData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    conatctNumber = json['contact_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['contact_number'] = this.conatctNumber;
    return data;
  }
}

class MultiDropLocation {
  int drop;
  double lat;
  double lng;
  dynamic droppedAt;
  String? address;

  MultiDropLocation({
    required this.drop,
    required this.lat,
    required this.lng,
    required this.droppedAt,
    required this.address,
  });

  factory MultiDropLocation.fromJson(Map<String, dynamic> json) =>
      MultiDropLocation(
        drop: int.tryParse(json["drop"].toString()) ?? 0,
        lat: double.tryParse(json["lat"].toString()) ?? 0.0,
        lng: double.tryParse(json["lng"].toString()) ?? 0.0,
        droppedAt: json["dropped_at"],
        address: json["address"].toString(),
      );

  Map<String, dynamic> toJson() => {
        "drop": drop,
        "lat": lat,
        "lng": lng,
        "dropped_at": droppedAt,
        "address": address,
      };
}
