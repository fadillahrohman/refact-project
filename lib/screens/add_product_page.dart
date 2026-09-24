import 'package:flutter/material.dart';

import '../models/product.dart';

class AddProductPage extends StatefulWidget {
  final Product? product;

  const AddProductPage({super.key, this.product});
  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  double _price = 0;
  int _quantity = 0;
  String _description = '';
  String _category = '';
  bool _isLoading = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _name = product.name;
      _price = product.price;
      _quantity = product.quantity;
      _description = product.description;
      _category = product.category;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        if (_price < 1000) {
          throw Exception("Harga produk minimal Rp 1.000");
        }

        final product = Product(
          id: widget.product?.id,
          name: _name,
          price: _price,
          quantity: _quantity,
          description: _description,
          category: _category,
          imageUrl:
                widget.product?.imageUrl ??
                  'https://picsum.photos/200/300?random=${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          Navigator.pop(context, product);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll("Exception: ", "")),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: widget.product?.name,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Nama tidak boleh kosong'
                    : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: widget.product?.price.toStringAsFixed(0),
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harga harus berupa angka';
                  }
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!),
              ),
              TextFormField(
                initialValue: widget.product?.quantity.toString(),
                decoration: const InputDecoration(labelText: 'Kuantitas'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kuantitas tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Kuantitas harus berupa angka';
                  }
                  return null;
                },
                onSaved: (value) => _quantity = int.parse(value!),
              ),
              TextFormField(
                initialValue: widget.product?.description,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Deskripsi tidak boleh kosong'
                    : null,
                onSaved: (value) => _description = value!,
              ),
              TextFormField(
                initialValue: widget.product?.category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Kategori tidak boleh kosong'
                    : null,
                onSaved: (value) => _category = value!,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Produk'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
