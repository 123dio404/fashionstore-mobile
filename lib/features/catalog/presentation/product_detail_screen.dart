import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../data/models/catalog_models.dart';
import '../../app_repository.dart';
import 'virtual_fitting_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductResponse product;
  final CatalogRepository repository;
  final AppRepository? appRepository;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.repository,
    this.appRepository,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<BranchResponse> _branches = [];
  List<AvailabilityResponse> _availability = [];
  int? _branchId;
  bool _loadingBranches = true;

  @override
  void initState() {
    super.initState();
    widget.repository.branches().then((branches) {
      if (mounted) {
        setState(() {
          _branches = branches.where((branch) => branch.isActive).toList();
          _loadingBranches = false;
        });
      }
    });
  }

  Future<void> _loadAvailability(int branchId) async {
    final result =
        await widget.repository.availability(widget.product.id, branchId);
    if (mounted) setState(() => _availability = result);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.product.name)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.product.name,
                style: Theme.of(context).textTheme.headlineSmall),
            Text('\$${widget.product.price.toStringAsFixed(2)}'),
            if (widget.product.model3dUrl != null)
              ListTile(
                leading: const Icon(Icons.view_in_ar),
                title: const Text('Modelo 3D disponible'),
                subtitle: Text(widget.product.model3dUrl!),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VirtualFittingScreen(
                      modelUrl: widget.product.model3dUrl!,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_loadingBranches)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<int>(
                initialValue: _branchId,
                decoration: const InputDecoration(labelText: 'Sucursal'),
                items: _branches
                    .map((branch) => DropdownMenuItem(
                        value: branch.id, child: Text(branch.name)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _branchId = value);
                  _loadAvailability(value);
                },
              ),
            ..._availability.map(
              (stock) => ListTile(
                title: Text('Variante ${stock.variantId}'),
                subtitle: Text(
                    'Físico: ${stock.physicalStock} | Reservado: ${stock.reservedStock}'),
                trailing: Text('Disponible: ${stock.availableStock}'),
              ),
            ),
            if (widget.appRepository != null && _availability.isNotEmpty)
              FilledButton.icon(
                onPressed: () async {
                  final stock = _availability.firstWhere(
                    (item) => item.availableStock > 0,
                    orElse: () => _availability.first,
                  );
                  try {
                    await widget.appRepository!.addCart(stock.variantId, 1);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Producto agregado al carrito')),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$error')));
                    }
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Agregar al carrito'),
              ),
          ],
        ),
      );
}
