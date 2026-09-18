import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../data/models/catalog_models.dart';

class CatalogScreen extends StatefulWidget {
  final CatalogRepository repository;

  const CatalogScreen({super.key, required this.repository});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<ProductResponse>> _products;

  @override
  void initState() {
    super.initState();
    _products = widget.repository.products();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('FashionStore'),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.person_outline),
            ),
          ],
        ),
        body: FutureBuilder<List<ProductResponse>>(
          future: _products,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final products = snapshot.data ?? [];
            if (products.isEmpty)
              return const Center(child: Text('No hay productos disponibles.'));
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/product',
                        arguments: product),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: product.model3dUrl == null
                                ? const Center(
                                    child: Icon(Icons.checkroom, size: 64))
                                : const Center(
                                    child: Icon(Icons.view_in_ar, size: 64)),
                          ),
                          Text(product.name,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('\$${product.price.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
