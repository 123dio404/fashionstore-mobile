class RegisterRequest {
  final String email;
  final String fullName;
  final String password;

  const RegisterRequest({
    required this.email,
    required this.fullName,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'full_name': fullName,
        'password': password,
      };
}

enum Role {
  administrador('Administrador'),
  encargado('Encargado'),
  cajero('Cajero'),
  cliente('Cliente'),
  proveedor('Proveedor');

  const Role(this.value);
  final String value;

  static Role fromJson(String value) =>
      Role.values.firstWhere((role) => role.value == value, orElse: () => Role.cliente);
}

class UserResponse {
  final String id;
  final String email;
  final String fullName;
  final Role role;
  final bool isActive;

  const UserResponse({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        role: Role.fromJson(json['role'] as String),
        isActive: json['is_active'] as bool,
      );
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final UserResponse user;

  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String? ?? 'bearer',
        user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
      );
}
