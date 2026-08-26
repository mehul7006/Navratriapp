class User {
  final int? id;
  final String houseNumber;
  final String name;
  final String? mobileNumber;
  final String userType; // 'user', 'organizer', 'sponsor'
  final String? password;
  final String? profileImage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.houseNumber,
    required this.name,
    this.mobileNumber,
    this.userType = 'user',
    this.password,
    this.profileImage,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'house_number': houseNumber,
      'name': name,
      'mobile_number': mobileNumber,
      'user_type': userType,
      'password': password,
      'profile_image': profileImage,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      houseNumber: map['house_number'],
      name: map['name'],
      mobileNumber: map['mobile_number'],
      userType: map['user_type'],
      password: map['password'],
      profileImage: map['profile_image'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  User copyWith({
    int? id,
    String? houseNumber,
    String? name,
    String? mobileNumber,
    String? userType,
    String? password,
    String? profileImage,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      houseNumber: houseNumber ?? this.houseNumber,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      userType: userType ?? this.userType,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
