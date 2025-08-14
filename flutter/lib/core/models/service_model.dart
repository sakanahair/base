import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final int duration; // 分単位
  final String description;
  final List<String> options;
  final List<String> images;
  final String industry; // 業種（beauty, restaurant, clinic等）
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.duration,
    this.description = '',
    this.options = const [],
    this.images = const [],
    required this.industry,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestoreからのデータ変換
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      duration: data['duration'] ?? 0,
      description: data['description'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      industry: data['industry'] ?? 'beauty',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestoreへのデータ変換
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'duration': duration,
      'description': description,
      'options': options,
      'images': images,
      'industry': industry,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // JSONからのデータ変換（LocalStorage用）
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      description: json['description'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      industry: json['industry'] ?? 'beauty',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // JSONへのデータ変換（LocalStorage用）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'duration': duration,
      'description': description,
      'options': options,
      'images': images,
      'industry': industry,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // コピーメソッド
  ServiceModel copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? duration,
    String? description,
    List<String>? options,
    List<String>? images,
    String? industry,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      options: options ?? this.options,
      images: images ?? this.images,
      industry: industry ?? this.industry,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}