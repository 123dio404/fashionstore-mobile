import 'package:flutter/material.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/catalog/data/models/catalog_models.dart';
import 'features/catalog/presentation/catalog_screen.dart';
import 'features/catalog/presentation/product_detail_screen.dart';

void main() {
  final authRepository = AuthRepository();
  final catalogRepository = CatalogRepository();
  runApp(FashionStoreApp(
    authRepository: authRepository,
    catalogRepository: catalogRepository,
  ));
}

class FashionStoreApp extends StatelessWidget {
  final AuthRepository authRepository;
  final CatalogRepository catalogRepository;

  const FashionStoreApp({
    super.key,
    required this.authRepository,
    required this.catalogRepository,
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FashionStore',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff7c3aed)),
          useMaterial3: true,
        ),
        initialRoute: '/catalog',
        routes: {
          '/catalog': (_) => CatalogScreen(repository: catalogRepository),
          '/login': (_) => LoginScreen(repository: authRepository),
          '/product': (context) {
            final product = ModalRoute.of(context)!.settings.arguments! as ProductResponse;
            return ProductDetailScreen(product: product, repository: catalogRepository);
          },
        },
      );
}
