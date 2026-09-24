class Product {
  final String? id;
  final String name;
  final double price;
  final int quantity;
  final String description;
  final String category;
  final String imageUrl;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl'] ?? json['image_url'] ?? json['image'];
    return Product(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageUrl: _imageUrl(image),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
    };
  }

  static String _imageUrl(dynamic image) {
    if (image is Map<String, dynamic>) {
      image = image['id'] ?? image['filename_disk'];
    }
    final value = image?.toString() ?? '';
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    return 'https://pos.cicd.web.id/assets/$value';
  }
}

