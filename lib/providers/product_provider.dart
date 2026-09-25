import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/product_api_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductApiService? apiService})
    : _apiService = apiService ?? ProductApiService();

  final ProductApiService _apiService;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProducts() async {
    try {
      await _runRequest(() async {
        _products = await _apiService.getProducts();
      });
    } catch (_) {
      // The error is exposed through errorMessage for the page to display.
    }
  }

  Future<void> addProduct(Product product) async {
    await _runRequest(() async {
      final createdProduct = await _apiService.createProduct(product);
      _products = [..._products, createdProduct];
    });
  }

  Future<void> updateProduct(Product product) async {
    await _runRequest(() async {
      final updatedProduct = await _apiService.updateProduct(product);
      final index = _products.indexWhere((item) => item.id == product.id);
      if (index == -1) return;
      _products = [..._products]..[index] = updatedProduct;
    });
  }

  Future<void> deleteProduct(Product product) async {
    await _runRequest(() async {
      await _apiService.deleteProduct(product.id);
      _products = _products.where((item) => item.id != product.id).toList();
    });
  }

  Future<void> _runRequest(Future<void> Function() request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await request();
    } on DioException catch (error) {
      _errorMessage = error.response?.data?.toString() ?? error.message;
      rethrow;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
