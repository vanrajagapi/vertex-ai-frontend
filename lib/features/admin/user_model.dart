class AdminUser {
  final String? id;
  final String username;
  final String? email;
  final String? fullName;
  final String role;
  final bool? isActive;
  final bool? disabled;

  AdminUser({
    this.id,
    required this.username,
    this.email,
    this.fullName,
    required this.role,
    this.isActive,
    this.disabled,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString(),
      username: json['username'] ?? '',
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'] ?? '',
      isActive: json['is_active'],
      disabled: json['disabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'disabled': disabled,
    };
  }

  // Helper to get active status regardless of field name
  bool get isUserActive => isActive ?? !(disabled ?? false);
}
