import 'package:dio/dio.dart';

import '../models/product.dart';

class ProductApiService {
  ProductApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://pos.cicd.web.id',
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<List<Product>> getProducts() async {
    final response = await _dio.get('/items/products');
    final data = response.data is Map ? response.data['data'] : response.data;
    if (data is! List) throw const FormatException('Format data produk tidak valid.');
    return data
        .whereType<Map>()
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Product> createProduct(Product product) async {
    final response = await _dio.post('/items/products', data: product.toJson());
    return Product.fromJson(_unwrapObject(response.data));
  }

  Future<Product> updateProduct(Product product) async {
    if (product.id == null || product.id!.isEmpty) {
      throw const FormatException('Produk tidak memiliki ID untuk diubah.');
    }
    final response = await _dio.patch(
      '/items/products/${product.id}',
      data: product.toJson(),
    );
    return Product.fromJson(_unwrapObject(response.data));
  }

  Future<void> deleteProduct(String? id) async {
    if (id == null || id.isEmpty) {
      throw const FormatException('Produk tidak memiliki ID untuk dihapus.');
    }
    await _dio.delete('/items/products/$id');
  }

  Map<String, dynamic> _unwrapObject(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : responseData;
    if (data is! Map) throw const FormatException('Format respons produk tidak valid.');
    return Map<String, dynamic>.from(data);
  }
}