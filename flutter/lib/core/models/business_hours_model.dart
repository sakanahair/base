import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessHoursModel {
  final String id;
  final String tenantId;
  final Map<String, DayHours> regularHours;
  final List<String> holidays;
  final String? breakTime;
  final String? specialNotes;
  final String? reservationHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessHoursModel({
    required this.id,
    required this.tenantId,
    required this.regularHours,
    required this.holidays,
    this.breakTime,
    this.specialNotes,
    this.reservationHours,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessHoursModel.fromJson(Map<String, dynamic> json) {
    final hoursMap = <String, DayHours>{};
    if (json['regularHours'] != null) {
      (json['regularHours'] as Map<String, dynamic>).forEach((key, value) {
        hoursMap[key] = DayHours.fromJson(value);
      });
    }

    return BusinessHoursModel(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      regularHours: hoursMap,
      holidays: List<String>.from(json['holidays'] ?? []),
      breakTime: json['breakTime'],
      specialNotes: json['specialNotes'],
      reservationHours: json['reservationHours'],
      createdAt: json['createdAt'] != null 
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null
        ? (json['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final hoursJson = <String, dynamic>{};
    regularHours.forEach((key, value) {
      hoursJson[key] = value.toJson();
    });

    return {
      'id': id,
      'tenantId': tenantId,
      'regularHours': hoursJson,
      'holidays': holidays,
      'breakTime': breakTime,
      'specialNotes': specialNotes,
      'reservationHours': reservationHours,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BusinessHoursModel copyWith({
    String? id,
    String? tenantId,
    Map<String, DayHours>? regularHours,
    List<String>? holidays,
    String? breakTime,
    String? specialNotes,
    String? reservationHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessHoursModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      regularHours: regularHours ?? this.regularHours,
      holidays: holidays ?? this.holidays,
      breakTime: breakTime ?? this.breakTime,
      specialNotes: specialNotes ?? this.specialNotes,
      reservationHours: reservationHours ?? this.reservationHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DayHours {
  final String open;
  final String close;
  final bool isOpen;
  final String lastOrder;

  DayHours({
    required this.open,
    required this.close,
    required this.isOpen,
    required this.lastOrder,
  });

  factory DayHours.fromJson(Map<String, dynamic> json) {
    return DayHours(
      open: json['open'] ?? '',
      close: json['close'] ?? '',
      isOpen: json['isOpen'] ?? false,
      lastOrder: json['lastOrder'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
      'isOpen': isOpen,
      'lastOrder': lastOrder,
    };
  }

  DayHours copyWith({
    String? open,
    String? close,
    bool? isOpen,
    String? lastOrder,
  }) {
    return DayHours(
      open: open ?? this.open,
      close: close ?? this.close,
      isOpen: isOpen ?? this.isOpen,
      lastOrder: lastOrder ?? this.lastOrder,
    );
  }
}