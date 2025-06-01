class PaymentCardModel {
  int? id;
  String? cardHolderName;
  String? cardNumber;
  String? expiryDate;
  String? cvv;
  int? userId;
  String? createdAt;
  String? updatedAt;

  PaymentCardModel({
    this.id,
    this.cardHolderName,
    this.cardNumber,
    this.expiryDate,
    this.cvv,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentCardModel.fromJson(Map<String, dynamic> json) {
    return PaymentCardModel(
      id: json['id'],
      cardHolderName: json['card_holder_name'],
      cardNumber: json['card_number'],
      expiryDate: json['expiry_date'],
      cvv: json['cvv'],
      userId: json['user_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['card_holder_name'] = this.cardHolderName;
    data['card_number'] = this.cardNumber;
    data['expiry_date'] = this.expiryDate;
    data['cvv'] = this.cvv;
    data['user_id'] = this.userId;

    // Only include these fields if not null to avoid sending them during creation
    if (this.id != null) data['id'] = this.id;
    if (this.createdAt != null) data['created_at'] = this.createdAt;
    if (this.updatedAt != null) data['updated_at'] = this.updatedAt;

    return data;
  }
}
