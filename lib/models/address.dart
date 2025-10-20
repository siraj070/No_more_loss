class Address {
  final String id;
  final String fullAddress;
  final String landmark;
  final String city;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  Address({
    required this.id,
    required this.fullAddress,
    required this.landmark,
    required this.city,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'fullAddress': fullAddress,
    'landmark': landmark,
    'city': city,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'isDefault': isDefault,
  };

  factory Address.fromJson(String id, Map<String, dynamic> json) {
    return Address(
      id: id,
      fullAddress: json['fullAddress'] ?? '',
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      isDefault: json['isDefault'] ?? false,
    );
  }
}
