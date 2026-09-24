import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/product.dart';
import '../services/product_api_service.dart';
import 'add_product_page.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  bool isLoading = false;
  String? errorMessage;
  List<Product> products = [];
  final ProductApiService _api = ProductApiService();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final loadedProducts = await _api.getProducts();
      if (!mounted) return;
      setState(() {
        products = loadedProducts;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat produk: $error';
      });
    }
  }

  List<Product> get _filteredProducts => products.where((product) {
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
      () async {
        final created = await _api.createProduct(product);
        if (mounted) setState(() => products = [...products, created]);
      },
      'Produk berhasil ditambahkan.',
    );
  }

  Future<void> _editProduct(int index) async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => AddProductPage(product: products[index])),
    );
    if (product == null || !mounted) return;
    await _runMutation(
      () async {
        final updated = await _api.updateProduct(product);
        if (mounted) {
          setState(() {
            products = [...products]..[index] = updated;
          });
        }
      },
      'Produk berhasil diperbarui.',
    );
  }

  Future<void> _deleteProduct(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('Produk "${products[index].name}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runMutation(
      () async {
        await _api.deleteProduct(products[index].id);
        if (mounted) setState(() => products = [...products]..removeAt(index));
      },
      'Produk berhasil dihapus.',
    );
  }

  Future<void> _runMutation(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = error.response?.data?.toString() ?? error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage ?? 'Terjadi kesalahan.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }
  }

  Future<void> _openDetails(Product product, int index) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
          onEdit: () {
            Navigator.pop(context);
            _editProduct(index);
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteProduct(index);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _filteredProducts;
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
        onPressed: _addProduct,
        tooltip: 'Tambah produk',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(List<Product> filteredProducts) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadProducts, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    if (filteredProducts.isEmpty) {
      return Center(
        child: Text(_searchQuery.isEmpty ? 'Belum ada produk.' : 'Produk tidak ditemukan.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final productIndex = products.indexOf(product);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            onTap: () => _openDetails(product, productIndex),
            leading: Image.network(
              product.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
            ),
            title: Text(product.name),
            subtitle: Text('Rp ${product.price.toStringAsFixed(0)} | Stok: ${product.quantity}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editProduct(productIndex);
                if (value == 'delete') _deleteProduct(productIndex);
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
