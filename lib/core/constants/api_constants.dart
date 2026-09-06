class ApiConstants {
  ApiConstants._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const currentUser = '/users/me';
  static const products = '/products';
  static const branches = '/branches';
  static const cities = '/cities';
  static const availability = '/availability';
  static const transfers = '/inventory/transfers';
}
