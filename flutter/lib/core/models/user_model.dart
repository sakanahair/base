import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  superAdmin('super_admin'),
  siteAdmin('site_admin'),
  endUser('end_user');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.endUser,
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? siteId;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.siteId,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.metadata,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'end_user'),
      siteId: data['siteId'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.value,
      'siteId': siteId,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? siteId,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      siteId: siteId ?? this.siteId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}