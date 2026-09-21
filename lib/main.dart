import 'package:flutter/material.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository.dart';

void main() {
  final client = ApiClient();
  runApp(FashionStoreApp(auth: AuthRepository(client: client)));
}
