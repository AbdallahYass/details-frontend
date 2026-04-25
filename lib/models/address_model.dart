class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String street;
  final String? building;
  final String? floor;
  final String? apartment;
  final String? notes;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.street,
    this.building,
    this.floor,
    this.apartment,
    this.notes,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      city: json['city'] ?? '',
      street: json['street'] ?? '',
      building: json['building'],
      floor: json['floor'],
      apartment: json['apartment'],
      notes: json['notes'],
      isDefault: json['isDefault'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'city': city,
      'street': street,
      'building': building,
      'floor': floor,
      'apartment': apartment,
      'notes': notes,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
