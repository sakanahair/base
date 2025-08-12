import 'package:cloud_firestore/cloud_firestore.dart';

enum SiteStatus {
  active('active'),
  inactive('inactive'),
  suspended('suspended'),
  trial('trial');

  final String value;
  const SiteStatus(this.value);

  static SiteStatus fromString(String value) {
    return SiteStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SiteStatus.inactive,
    );
  }
}

class SiteModel {
  final String id;
  final String name;
  final String domain;
  final String? subdomain;
  final String ownerId;
  final SiteStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> settings;
  final Map<String, dynamic>? customization;
  final List<String> adminIds;
  final int? userLimit;
  final int? currentUserCount;

  SiteModel({
    required this.id,
    required this.name,
    required this.domain,
    this.subdomain,
    required this.ownerId,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    required this.settings,
    this.customization,
    required this.adminIds,
    this.userLimit,
    this.currentUserCount,
  });

  factory SiteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SiteModel(
      id: doc.id,
      name: data['name'] ?? '',
      domain: data['domain'] ?? '',
      subdomain: data['subdomain'],
      ownerId: data['ownerId'] ?? '',
      status: SiteStatus.fromString(data['status'] ?? 'inactive'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      settings: data['settings'] ?? {},
      customization: data['customization'],
      adminIds: List<String>.from(data['adminIds'] ?? []),
      userLimit: data['userLimit'],
      currentUserCount: data['currentUserCount'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'domain': domain,
      'subdomain': subdomain,
      'ownerId': ownerId,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null
          ? Timestamp.fromDate(expiresAt!)
          : null,
      'settings': settings,
      'customization': customization,
      'adminIds': adminIds,
      'userLimit': userLimit,
      'currentUserCount': currentUserCount,
    };
  }

  SiteModel copyWith({
    String? id,
    String? name,
    String? domain,
    String? subdomain,
    String? ownerId,
    SiteStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? customization,
    List<String>? adminIds,
    int? userLimit,
    int? currentUserCount,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      subdomain: subdomain ?? this.subdomain,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      settings: settings ?? this.settings,
      customization: customization ?? this.customization,
      adminIds: adminIds ?? this.adminIds,
      userLimit: userLimit ?? this.userLimit,
      currentUserCount: currentUserCount ?? this.currentUserCount,
    );
  }
}