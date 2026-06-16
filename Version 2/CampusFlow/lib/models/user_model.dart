enum UserType {
  student,
  lecturer,
  parent,
  admin,
}

class User {
  final String id;
  final String email;
  final String password;
  final String fullName;
  final UserType userType;
  final String phone;
  final String? profileImage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLogin;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.userType,
    required this.phone,
    this.profileImage,
    this.isActive = true,
    required this.createdAt,
    required this.lastLogin,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'fullName': fullName,
        'userType': userType.name,
        'phone': phone,
        'profileImage': profileImage,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'lastLogin': lastLogin.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        password: json['password'],
        fullName: json['fullName'],
        userType: UserType.values.firstWhere((e) => e.name == json['userType']),
        phone: json['phone'],
        profileImage: json['profileImage'],
        isActive: json['isActive'],
        createdAt: DateTime.parse(json['createdAt']),
        lastLogin: DateTime.parse(json['lastLogin']),
      );
}
