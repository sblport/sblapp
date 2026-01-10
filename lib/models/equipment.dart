class Equipment {
  final int id;
  final String code;
  final String? category;
  final String? brand;

  Equipment({
    required this.id,
    required this.code,
    this.category,
    this.brand,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] as String,
      category: json['category'] as String?,
      brand: json['brand'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'category': category,
      'brand': brand,
    };
  }

  String get displayName {
    if (category != null && brand != null) {
      return '$code - $category ($brand)';
    } else if (category != null) {
      return '$code - $category';
    }
    return code;
  }
}
