import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'features/app_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/dashboard_screen.dart';
import 'features/catalog/data/catalog_repository.dart';

void main() {
  final client = ApiClient();
  final auth = AuthRepository(client: client);
  runApp(FashionStoreApp(
      auth: auth,
      catalog: CatalogRepository(client: client),
      app: AppRepository(client: client)));
}

class FashionStoreApp extends StatelessWidget {
  final AuthRepository auth;
  final CatalogRepository catalog;
  final AppRepository app;
  const FashionStoreApp(
      {super.key,
      required this.auth,
      required this.catalog,
      required this.app});
  @override
  Widget build(BuildContext c) => MaterialApp(
      title: 'FashionStore',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff7c3aed)),
          useMaterial3: true),
      home: DashboardScreen(auth: auth, catalog: catalog, app: app));
}
