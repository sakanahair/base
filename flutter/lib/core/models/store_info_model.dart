import 'package:cloud_firestore/cloud_firestore.dart';

class StoreInfoModel {
  final String id;
  final String tenantId;
  final String storeName;
  final String industry;
  final String description;
  final String postalCode;
  final String prefecture;
  final String city;
  final String address;
  final String building;
  final String phone;
  final String email;
  final String website;
  final String establishedYear;
  final String numberOfSeats;
  final String numberOfStaff;
  final String parkingSpaces;
  final List<String> services;
  final List<String> paymentMethods;
  final List<String> features;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreInfoModel({
    required this.id,
    required this.tenantId,
    required this.storeName,
    required this.industry,
    required this.description,
    required this.postalCode,
    required this.prefecture,
    required this.city,
    required this.address,
    required this.building,
    required this.phone,
    required this.email,
    required this.website,
    required this.establishedYear,
    required this.numberOfSeats,
    required this.numberOfStaff,
    required this.parkingSpaces,
    required this.services,
    required this.paymentMethods,
    required this.features,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreInfoModel.fromJson(Map<String, dynamic> json) {
    return StoreInfoModel(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      storeName: json['storeName'] ?? '',
      industry: json['industry'] ?? '美容室・サロン',
      description: json['description'] ?? '',
      postalCode: json['postalCode'] ?? '',
      prefecture: json['prefecture'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      building: json['building'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
      establishedYear: json['establishedYear'] ?? '',
      numberOfSeats: json['numberOfSeats'] ?? '',
      numberOfStaff: json['numberOfStaff'] ?? '',
      parkingSpaces: json['parkingSpaces'] ?? '',
      services: List<String>.from(json['services'] ?? []),
      paymentMethods: List<String>.from(json['paymentMethods'] ?? []),
      features: List<String>.from(json['features'] ?? []),
      createdAt: json['createdAt'] != null 
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null
        ? (json['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'storeName': storeName,
      'industry': industry,
      'description': description,
      'postalCode': postalCode,
      'prefecture': prefecture,
      'city': city,
      'address': address,
      'building': building,
      'phone': phone,
      'email': email,
      'website': website,
      'establishedYear': establishedYear,
      'numberOfSeats': numberOfSeats,
      'numberOfStaff': numberOfStaff,
      'parkingSpaces': parkingSpaces,
      'services': services,
      'paymentMethods': paymentMethods,
      'features': features,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  StoreInfoModel copyWith({
    String? id,
    String? tenantId,
    String? storeName,
    String? industry,
    String? description,
    String? postalCode,
    String? prefecture,
    String? city,
    String? address,
    String? building,
    String? phone,
    String? email,
    String? website,
    String? establishedYear,
    String? numberOfSeats,
    String? numberOfStaff,
    String? parkingSpaces,
    List<String>? services,
    List<String>? paymentMethods,
    List<String>? features,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoreInfoModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      storeName: storeName ?? this.storeName,
      industry: industry ?? this.industry,
      description: description ?? this.description,
      postalCode: postalCode ?? this.postalCode,
      prefecture: prefecture ?? this.prefecture,
      city: city ?? this.city,
      address: address ?? this.address,
      building: building ?? this.building,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      establishedYear: establishedYear ?? this.establishedYear,
      numberOfSeats: numberOfSeats ?? this.numberOfSeats,
      numberOfStaff: numberOfStaff ?? this.numberOfStaff,
      parkingSpaces: parkingSpaces ?? this.parkingSpaces,
      services: services ?? this.services,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      features: features ?? this.features,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}