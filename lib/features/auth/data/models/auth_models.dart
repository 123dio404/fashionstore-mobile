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

  static Role fromJson(String value) => Role.values
      .firstWhere((role) => role.value == value, orElse: () => Role.cliente);
}

class UserResponse {
  final int id;
  final int? tenantId;
  final String? tenantName;
  final String? planName;
  final String email;
  final String fullName;
  final Role role;
  final bool isActive;

  const UserResponse({
    required this.id,
    this.tenantId,
    this.tenantName,
    this.planName,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
        id: int.tryParse('${json['id']}') ?? 0,
        tenantId: json['tenant_id'] == null ? null : int.tryParse('${json['tenant_id']}'),
        tenantName: json['tenant_name']?.toString(),
        planName: json['plan_name']?.toString(),
        email: '${json['email'] ?? ''}',
        fullName: '${json['full_name'] ?? ''}',
        role: Role.fromJson('${json['role'] ?? 'Cliente'}'),
        isActive: json['is_active'] as bool? ?? true,
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
