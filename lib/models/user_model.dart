class UserModel {
  final String id;
  final String email;
  final String displayName;
  final int totalPoints;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.totalPoints = 0,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      totalPoints: map['totalPoints'] ?? 0,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'totalPoints': totalPoints,
      'createdAt': createdAt,
    };
  }
}
