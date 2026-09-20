import 'package:flutter/material.dart';
import 'app_repository.dart';
import 'auth/data/auth_repository.dart';
import 'auth/data/models/auth_models.dart';
import 'auth/presentation/login_screen.dart';
import 'auth/presentation/register_screen.dart';
import 'catalog/data/catalog_repository.dart';
import 'catalog/data/models/catalog_models.dart';
import 'catalog/presentation/product_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AuthRepository auth;
  final CatalogRepository catalog;
  final AppRepository app;
  const DashboardScreen(
      {super.key,
      required this.auth,
      required this.catalog,
      required this.app});
  @override
  State<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardScreen> {
  int tab = 0;
  UserResponse? user;
  @override
  void initState() {
    super.initState();
    widget.auth.currentUser().then((u) {
      if (mounted) setState(() => user = u);
    }).catchError((_) {});
  }

  Widget _catalog() => FutureBuilder<List<ProductResponse>>(
      future: widget.catalog.products(),
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) return Center(child: Text('${s.error}'));
        final products = s.data ?? [];
        return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: GridView.builder(
              itemCount: products.length,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .72,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10),
              itemBuilder: (_, i) => Card(
                  child: InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                  product: products[i],
                                  repository: widget.catalog,
                                  appRepository: widget.app))),
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                    child: Center(
                                        child:
                                            Icon(Icons.checkroom, size: 52))),
                                Text(products[i].name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                    '\$${products[i].price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))
                              ])))),
            ));
      });
  Widget _loginPrompt(String text) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(text),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => LoginScreen(repository: widget.auth))),
            child: const Text('Iniciar sesión'))
      ]));
  Widget _cart() => FutureBuilder<Map<String, dynamic>>(
      future: widget.app.cart(),
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) {
          return _loginPrompt('Inicia sesión para ver tu carrito');
        }
        final data = s.data ?? {};
        final items = (data['items'] as List? ?? []).whereType<Map>().toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          Text('Total: \$${data['total'] ?? 0}',
              style: Theme.of(c).textTheme.headlineSmall),
          ...items.map((x) => ListTile(
              title: Text('${x['product_name'] ?? 'Producto'}'),
              subtitle: Text('Cantidad: ${x['quantity']}'),
              trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => widget.app
                      .removeCart(int.tryParse('${x['id']}') ?? 0)
                      .then((_) => setState(() {}))))),
          if (items.isNotEmpty)
            FilledButton(onPressed: _checkout, child: const Text('Pagar ahora'))
        ]);
      });
  Widget _account() => user == null
      ? _loginPrompt('Accede a tu perfil')
      : ListView(padding: const EdgeInsets.all(20), children: [
          ListTile(
              leading: const Icon(Icons.person),
              title: Text(user!.fullName),
              subtitle: Text(user!.email)),
          FilledButton.tonal(
              onPressed: _profile, child: const Text('Editar perfil')),
          ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de compras'),
              onTap: () => _listPage('Historial', '/purchases/history')),
          ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Mis reservas'),
              onTap: _reservations),
          ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await widget.auth.logout();
                setState(() => user = null);
              })
        ]);
  Future<void> _checkout() async {
    final branches =
        (await widget.catalog.branches()).where((b) => b.isActive).toList();
    if (branches.isEmpty) return;
    try {
      await widget.app.checkout(branches.first.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Compra realizada')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _profile() async {
    final n = TextEditingController(text: user!.fullName);
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('Perfil'),
                content: TextField(
                    controller: n,
                    decoration: const InputDecoration(labelText: 'Nombre')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () async {
                        final u = await widget.auth
                            .updateProfile({'full_name': n.text});
                        if (mounted) {
                          setState(() => user = u);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Guardar'))
                ]));
  }

  Future<void> _listPage(String title, String path) async {
    try {
      final raw = await widget.app.list(path);
      if (!mounted) return;
      showModalBottomSheet(
          context: context,
          builder: (_) => ListView(children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(title,
                        style: Theme.of(context).textTheme.headlineSmall)),
                ...raw.map((x) => ListTile(
                    title: Text('Orden #${x['id'] ?? ''}'),
                    subtitle: Text('${x['sale_date'] ?? x['status'] ?? ''}')))
              ]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _reservations() async {
    try {
      final data = await widget.app.list('/reservations');
      if (!mounted) return;
      showModalBottomSheet(
          context: context,
          builder: (_) => ListView(children: [
                ...data.map((x) => ListTile(
                    title: Text('Reserva #${x['id']}'),
                    subtitle: Text(
                        '${x['reservation_date']} ${x['reservation_time']}'),
                    trailing: IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () =>
                            widget.app.delete('/reservations/${x['id']}'))))
              ]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _extras() async {
    final choices = [
      'Colecciones y promociones',
      'Reservar probador',
      'Probador virtual',
      'Preferencias',
      'Chatbot'
    ];
    final selected = await showModalBottomSheet<int>(
        context: context,
        builder: (_) => ListView.builder(
            itemCount: choices.length,
            itemBuilder: (_, i) => ListTile(
                title: Text(choices[i]),
                onTap: () => Navigator.pop(context, i))));
    if (selected == null) return;
    if (selected == 0) {
      await _listPage('Colecciones', '/collections');
      await _listPage('Promociones', '/promotions');
    } else if (selected == 1) {
      try {
        final products = await widget.catalog.products();
        final branches =
            (await widget.catalog.branches()).where((b) => b.isActive).toList();
        if (products.isEmpty ||
            branches.isEmpty ||
            products.first.variants.isEmpty) {
          return;
        }
        final availability = await widget.catalog
            .availability(products.first.id, branches.first.id);
        if (availability.isEmpty) return;
        final stocks = await widget.app.list('/inventory/stock', query: {
          'branch_id': branches.first.id,
          'variant_id': availability.first.variantId,
        });
        if (stocks.isEmpty) return;
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        await widget.app.create('/reservations', {
          'branch_id': branches.first.id,
          'reservation_date': tomorrow.toIso8601String().substring(0, 10),
          'reservation_time': '10:00:00',
          'items': [
            {'stock_id': asInt(stocks.first['id']), 'quantity': 1}
          ],
        });
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Reserva creada')));
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    } else if (selected == 2) {
      try {
        await widget.app.create('/virtual-fitting/sessions', {});
      } catch (_) {}
    } else if (selected == 3) {
      try {
        await widget.app.savePreferences({
          'preferred_colors': ['negro'],
          'preferred_sizes': []
        });
      } catch (_) {}
    } else {
      try {
        final c = await widget.app.create(
            '/chatbot/conversations', {'title': 'Asistente FashionStore'});
        if (mounted) {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                  title: const Text('Chatbot'),
                  content: Text('Conversación #${c['id']} creada.')));
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(
          title: Image.asset('assets/images/logo.png', height: 28),
          actions: [
        if (user == null)
          IconButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RegisterScreen(repository: widget.auth))),
              icon: const Icon(Icons.person_add))
      ]),
      body: [_catalog(), _cart(), _account()][tab],
      bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.storefront), label: 'Catálogo'),
            NavigationDestination(
                icon: Icon(Icons.shopping_bag), label: 'Carrito'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Cuenta')
          ]),
      floatingActionButton: tab == 0
          ? FloatingActionButton.extended(
              onPressed: _extras,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Más'))
          : null);
}
