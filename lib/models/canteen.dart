class ComponentTag {
  final int id;
  final String component;
  final String label;
  final bool isDefault;

  ComponentTag({
    required this.id,
    required this.component,
    required this.label,
    required this.isDefault,
  });

  factory ComponentTag.fromJson(Map<String, dynamic> json) => ComponentTag(
    id:        json['id'] as int,
    component: json['component'] as String,
    label:     json['label'] as String,
    isDefault: json['is_default'] as bool,
  );
}

class DailyMeal {
  final int id;
  final String date;
  final String mealType;
  final int? setNumber;
  final String? photoUrl;
  final Map<String, String> components;
  final bool isActive;
  final double? averageRating;
  final int ratingCount;
  final Map<String, List<Map<String, dynamic>>> tagsByComponent;

  DailyMeal({
    required this.id,
    required this.date,
    required this.mealType,
    this.setNumber,
    this.photoUrl,
    required this.components,
    required this.isActive,
    this.averageRating,
    required this.ratingCount,
    required this.tagsByComponent,
  });

  factory DailyMeal.fromJson(Map<String, dynamic> json) {
    // Parse components map
    final rawComponents = json['components'] as Map<String, dynamic>? ?? {};
    final components = rawComponents.map((k, v) => MapEntry(k, v.toString()));

    // Parse tags_by_component
    final rawTags = json['tags_by_component'] as Map<String, dynamic>? ?? {};
    final tagsByComponent = rawTags.map((k, v) => MapEntry(
      k,
      (v as List).map((t) => t as Map<String, dynamic>).toList(),
    ));

    return DailyMeal(
      id:               json['id'] as int,
      date:             json['date'] as String,
      mealType:         json['meal_type'] as String,
      setNumber:        json['set_number'] as int?,
      photoUrl:         json['photo_url'] as String?,
      components:       components,
      isActive:         json['is_active'] as bool,
      averageRating:    (json['average_rating'] as num?)?.toDouble(),
      ratingCount:      json['rating_count'] as int,
      tagsByComponent:  tagsByComponent,
    );
  }

  // Display name for the set
  String get setLabel {
    if (setNumber == null) return '';
    if (setNumber == 3) return 'Set 3 (Cháo)';
    return 'Set $setNumber';
  }
}