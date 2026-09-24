import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import 'add_product_page.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filteredProducts(List<Product> products) =>
      products.where((product) {
        return product.name.toLowerCase().contains(_searchQuery) ||
            product.category.toLowerCase().contains(_searchQuery);
      }).toList();

  Future<void> _addProduct() async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductPage()),
    );
    if (product == null || !mounted) return;
    await _runMutation(
      () => context.read<ProductProvider>().addProduct(product),
      'Produk berhasil ditambahkan.',
    );
  }

  Future<void> _editProduct(Product currentProduct) async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductPage(product: currentProduct),
      ),
    );
    if (product == null || !mounted) return;
    await _runMutation(
      () => context.read<ProductProvider>().updateProduct(product),
      'Produk berhasil diperbarui.',
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('Produk "${product.name}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runMutation(
      () => context.read<ProductProvider>().deleteProduct(product),
      'Produk berhasil dihapus.',
    );
  }

  Future<void> _runMutation(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openDetails(Product product) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
          onEdit: () {
            Navigator.pop(context);
            _editProduct(product);
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteProduct(product);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.products;
    final filteredProducts = _filteredProducts(products);
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari produk',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: _buildContent(filteredProducts)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: provider.isLoading ? null : _addProduct,
        tooltip: 'Tambah produk',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(List<Product> filteredProducts) {
    final provider = context.watch<ProductProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: provider.loadProducts,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (filteredProducts.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'Belum ada produk.'
              : 'Produk tidak ditemukan.',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            onTap: () => _openDetails(product),
            leading: Image.network(
              product.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image),
            ),
            title: Text(product.name),
            subtitle: Text(
              'Rp ${product.price.toStringAsFixed(0)} | Stok: ${product.quantity}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editProduct(product);
                }
                if (value == 'delete') {
                  _deleteProduct(product);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }
}
