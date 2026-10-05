import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

abstract class OrderVault {
  Future<List<OrderAccess>> read();
  Future<void> write(List<OrderAccess> orders);
}

class SecureOrderVault implements OrderVault {
  const SecureOrderVault(this.namespace);
  final String namespace;
  static const _storage = FlutterSecureStorage();
  String get _key => 'masar.orders.v1.$namespace';
  @override
  Future<List<OrderAccess>> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return [];
    return (jsonDecode(value) as List)
        .map((j) => OrderAccess.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  @override
  Future<void> write(List<OrderAccess> orders) => _storage.write(
    key: _key,
    value: jsonEncode(orders.map((o) => o.toJson()).toList()),
  );
}

class Preferences {
  Preferences(this.storage);
  final SharedPreferences storage;
  String? get locale => storage.getString('masar.locale');
  String? get office => storage.getString('masar.office');
  Future<void> setLocale(String value) async {
    await storage.setString('masar.locale', value);
  }

  Future<void> setOffice(String value) async {
    await storage.setString('masar.office', value);
  }
}
