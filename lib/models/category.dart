import 'dart:convert';

class Category {
  final String id;
  final String name;
  final bool isIncome;
  final bool isSystem;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.isIncome,
    this.isSystem = false,
    required this.createdAt,
  });

  factory Category.create({
    required String name,
    required bool isIncome,
    bool isSystem = false,
  }) {
    return Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      isIncome: isIncome,
      isSystem: isSystem,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isIncome': isIncome,
      'isSystem': isSystem,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      isIncome: map['isIncome'] as bool,
      isSystem: map['isSystem'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Category.fromJson(String source) =>
      Category.fromMap(json.decode(source) as Map<String, dynamic>);
}