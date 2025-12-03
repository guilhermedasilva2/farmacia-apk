import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_inicial/data/models/product_dto.dart';
import 'package:meu_app_inicial/data/repositories/product_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SharedPreferencesProductLocalDataSource auto heals corrupted cache', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products_cache_v1', '{corrupted json');
    final dao = SharedPreferencesProductLocalDataSource(prefs: prefs);

    final read = await dao.readAll();
    expect(read, isEmpty);

    await dao.upsertAll([
      const ProductDto(id: '1', name: 'Test', description: null, imageUrl: null, price: 1, available: true),
    ]);

    final storedRaw = prefs.getString('products_cache_v1');
    expect(storedRaw, isNotNull);
    final decoded = jsonDecode(storedRaw!) as List;
    expect(decoded.length, 1);
  });

  test('SharedPreferencesProductLocalDataSource merges dtos by id', () async {
    final prefs = await SharedPreferences.getInstance();
    final dao = SharedPreferencesProductLocalDataSource(prefs: prefs);

    await dao.upsertAll([
      const ProductDto(id: '1', name: 'Old', description: null, imageUrl: null, price: 10, available: true),
    ]);

    await dao.upsertAll([
      const ProductDto(id: '1', name: 'New', description: 'desc', imageUrl: null, price: 12, available: false),
      const ProductDto(id: '2', name: 'Second', description: null, imageUrl: null, price: 5, available: true),
    ]);

    final all = await dao.readAll();
    expect(all.length, 2);
    final updated = all.firstWhere((dto) => dto.id == '1');
    expect(updated.name, 'New');
    expect(updated.available, false);
  });
}

