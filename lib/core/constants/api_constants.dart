class ApiConstants {
  ApiConstants._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fashionstore-backend-ph17.onrender.com/api/v1',
  );

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const currentUser = '/users/me';
  static const products = '/products';
  static const branches = '/branches';
  static const cities = '/cities';
  static const availability = '/availability';
  static const transfers = '/inventory/transfers';
  // CU10 / CU11 / CU12 — carrito, checkout y ventas viven bajo el router `/commerce`.
  static const cart = '/commerce/cart';
  static const cartItems = '/commerce/cart/items';
  static const checkout = '/commerce/cart/checkout';
  static const sales = '/commerce/sales';
  static const reservations = '/commerce/reservations';
  static const fittingSessions = '/virtual-fitting/sessions';
  static const preferences = '/recommendations/preferences';
  static const recommendations = '/recommendations';
  static const chat = '/chatbot/conversations';
  static const collections = '/collections';
  static const promotions = '/promotions';
  static const purchaseHistory = '/reports/purchases/history';
  static const analyticalQueryVoice = '/reports/analytical-query/voice';
}
