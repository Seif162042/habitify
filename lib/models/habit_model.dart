class HabitModel {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String frequency;
  final DateTime createdAt;
  final int streak;
  final DateTime? lastCompletedDate;

  HabitModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.frequency,
    required this.createdAt,
    this.streak = 0,
    this.lastCompletedDate,
  });

  factory HabitModel.fromMap(Map<String, dynamic> map, String id) {
    return HabitModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      frequency: map['frequency'] ?? 'daily',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      streak: map['streak'] ?? 0,
      lastCompletedDate: map['lastCompletedDate']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'frequency': frequency,
      'createdAt': createdAt,
      'streak': streak,
      'lastCompletedDate': lastCompletedDate,
    };
  }

  HabitModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? frequency,
    DateTime? createdAt,
    int? streak,
    DateTime? lastCompletedDate,
  }) {
    return HabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      streak: streak ?? this.streak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }
}
