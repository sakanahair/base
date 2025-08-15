import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSettingsModel {
  final String id;
  final String tenantId;
  final Map<String, PaymentMethod> acceptedPayments;
  final String paymentPolicy;
  final String cancellationPolicy;
  final bool depositRequired;
  final String? depositDetails;
  final String? minimumCharge;
  final String? serviceCharge;
  final String taxSettings;
  final String? insuranceInfo;
  final String? returnPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentSettingsModel({
    required this.id,
    required this.tenantId,
    required this.acceptedPayments,
    required this.paymentPolicy,
    required this.cancellationPolicy,
    required this.depositRequired,
    this.depositDetails,
    this.minimumCharge,
    this.serviceCharge,
    required this.taxSettings,
    this.insuranceInfo,
    this.returnPolicy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    final paymentsMap = <String, PaymentMethod>{};
    if (json['acceptedPayments'] != null) {
      (json['acceptedPayments'] as Map<String, dynamic>).forEach((key, value) {
        paymentsMap[key] = PaymentMethod.fromJson(value);
      });
    }

    return PaymentSettingsModel(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      acceptedPayments: paymentsMap,
      paymentPolicy: json['paymentPolicy'] ?? '',
      cancellationPolicy: json['cancellationPolicy'] ?? '',
      depositRequired: json['depositRequired'] ?? false,
      depositDetails: json['depositDetails'],
      minimumCharge: json['minimumCharge'],
      serviceCharge: json['serviceCharge'],
      taxSettings: json['taxSettings'] ?? '内税表示',
      insuranceInfo: json['insuranceInfo'],
      returnPolicy: json['returnPolicy'],
      createdAt: json['createdAt'] != null 
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null
        ? (json['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final paymentsJson = <String, dynamic>{};
    acceptedPayments.forEach((key, value) {
      paymentsJson[key] = value.toJson();
    });

    return {
      'id': id,
      'tenantId': tenantId,
      'acceptedPayments': paymentsJson,
      'paymentPolicy': paymentPolicy,
      'cancellationPolicy': cancellationPolicy,
      'depositRequired': depositRequired,
      'depositDetails': depositDetails,
      'minimumCharge': minimumCharge,
      'serviceCharge': serviceCharge,
      'taxSettings': taxSettings,
      'insuranceInfo': insuranceInfo,
      'returnPolicy': returnPolicy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PaymentSettingsModel copyWith({
    String? id,
    String? tenantId,
    Map<String, PaymentMethod>? acceptedPayments,
    String? paymentPolicy,
    String? cancellationPolicy,
    bool? depositRequired,
    String? depositDetails,
    String? minimumCharge,
    String? serviceCharge,
    String? taxSettings,
    String? insuranceInfo,
    String? returnPolicy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentSettingsModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      acceptedPayments: acceptedPayments ?? this.acceptedPayments,
      paymentPolicy: paymentPolicy ?? this.paymentPolicy,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      depositRequired: depositRequired ?? this.depositRequired,
      depositDetails: depositDetails ?? this.depositDetails,
      minimumCharge: minimumCharge ?? this.minimumCharge,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      taxSettings: taxSettings ?? this.taxSettings,
      insuranceInfo: insuranceInfo ?? this.insuranceInfo,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PaymentMethod {
  final bool enabled;
  final List<String>? brands;
  final List<String>? plans;

  PaymentMethod({
    required this.enabled,
    this.brands,
    this.plans,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      enabled: json['enabled'] ?? false,
      brands: json['brands'] != null ? List<String>.from(json['brands']) : null,
      plans: json['plans'] != null ? List<String>.from(json['plans']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      if (brands != null) 'brands': brands,
      if (plans != null) 'plans': plans,
    };
  }

  PaymentMethod copyWith({
    bool? enabled,
    List<String>? brands,
    List<String>? plans,
  }) {
    return PaymentMethod(
      enabled: enabled ?? this.enabled,
      brands: brands ?? this.brands,
      plans: plans ?? this.plans,
    );
  }
}