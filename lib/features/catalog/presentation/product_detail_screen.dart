import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../data/models/catalog_models.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductResponse product;
  final CatalogRepository repository;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.repository,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<BranchResponse> _branches = [];
  List<AvailabilityResponse> _availability = [];
  String? _branchId;
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

  Future<void> _loadAvailability(String branchId) async {
    final result = await widget.repository.availability(widget.product.id, branchId);
    if (mounted) setState(() => _availability = result);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.product.name)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.product.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('\$${widget.product.price.toStringAsFixed(2)}'),
            if (widget.product.model3dUrl != null)
              const ListTile(
                leading: Icon(Icons.view_in_ar),
                title: Text('Modelo 3D disponible'),
              ),
            const SizedBox(height: 16),
            if (_loadingBranches)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                initialValue: _branchId,
                decoration: const InputDecoration(labelText: 'Sucursal'),
                items: _branches
                    .map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.name)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _branchId = value);
                  _loadAvailability(value);
                },
              ),
            ..._availability.map(
              (stock) => ListTile(
                title: Text('Variante ${stock.variantId.substring(0, 8)}'),
                subtitle: Text('Físico: ${stock.physicalStock} | Reservado: ${stock.reservedStock}'),
                trailing: Text('Disponible: ${stock.availableStock}'),
              ),
            ),
          ],
        ),
      );
}
