class RatingModel {
  int? id;
  int? driverId;
  int? riderId;
  int? rideRequestId;
  num? rating;
  String? comment;
  String? userName;
  String? userImage;
  String? createdAt;
  String? updatedAt;

  RatingModel({
    this.id,
    this.driverId,
    this.riderId,
    this.rideRequestId,
    this.rating,
    this.comment,
    this.userName,
    this.userImage,
    this.createdAt,
    this.updatedAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'],
      driverId: json['driver_id'],
      riderId: json['rider_id'],
      rideRequestId: json['ride_request_id'],
      rating: json['rating'],
      comment: json['comment'],
      userName: json['user_name'],
      userImage: json['user_image'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['driver_id'] = this.driverId;
    data['rider_id'] = this.riderId;
    data['ride_request_id'] = this.rideRequestId;
    data['rating'] = this.rating;
    data['comment'] = this.comment;
    data['user_name'] = this.userName;
    data['user_image'] = this.userImage;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
