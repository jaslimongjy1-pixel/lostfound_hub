class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleValue = json['role'] ?? json['user_role'] ?? 'public';

    return UserModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['name'] ?? json['user_name'] ?? '',
      email: json['email'] ?? json['user_email'] ?? '',
      role: roleValue.toString().toLowerCase(),
    );
  }
}
