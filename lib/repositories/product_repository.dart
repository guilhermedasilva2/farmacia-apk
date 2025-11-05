import 'package:meu_app_inicial/dto/product_dto.dart';
import 'package:meu_app_inicial/mappers/product_mapper.dart';
import 'package:meu_app_inicial/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
}

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient? client;
  final String tableName;

  SupabaseProductRepository({required this.client, this.tableName = 'products'});

  @override
  Future<List<Product>> fetchProducts() async {
    try {
      if (client == null) throw Exception('No Supabase client');
      final List<dynamic> rows = await client!.from(tableName).select();
      final dtos = rows.map((e) => ProductDto.fromMap(e as Map<String, dynamic>)).toList();
      return ProductMapper.fromDtoList(dtos);
    } catch (_) {
      // Graceful fallback to mock data if table not present or any error occurs
      return MockProductRepository().fetchProducts();
    }
  }
}

class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    return const [
      Product(
        id: '1',
        name: 'Paracetamol 750mg',
        description: 'Analgésico e antitérmico',
        imageUrl: '',
        price: 12.90,
        available: true,
      ),
      Product(
        id: '2',
        name: 'Vitamina C 1g',
        description: 'Suplemento vitamínico',
        imageUrl: '',
        price: 19.50,
        available: true,
      ),
      Product(
        id: '3',
        name: 'Spray Nasal',
        description: 'Descongestionante nasal',
        imageUrl: '',
        price: 24.99,
        available: false,
      ),
    ];
  }
}


