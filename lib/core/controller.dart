import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api.dart';
import 'models.dart';
import 'storage.dart';

final appProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw UnimplementedError('Override at startup'),
);
final officeProvider = FutureProvider<Office?>((ref) async {
  final slug = ref.watch(appProvider.select((app) => app.officeSlug));
  if (slug == null || slug.isEmpty) return null;
  return ref.read(appProvider).api.office(slug);
});
final trackingProvider = FutureProvider.autoDispose
    .family<TrackedOrder, String>((ref, id) async {
      final app = ref.read(appProvider);
      final access = app.orders.where((o) => o.id == id).firstOrNull;
      if (access == null) {
        throw const ApiFailure('Order not saved on this device.', status: 404);
      }
      return app.api.track(access);
    });

class AppController extends ChangeNotifier {
  AppController({
    required this.api,
    required this.vault,
    required this.preferences,
  });
  final CustomerApi api;
  final OrderVault vault;
  final Preferences preferences;
  String? officeSlug;
  Locale? locale;
  List<OrderAccess> orders = [];
  final List<Service> _cart = [];
  String? storageError;
  List<Service> get cart => List.unmodifiable(_cart);
  int get total => _cart.fold(0, (sum, s) => sum + s.total);
  Future<void> initialize({Uri? launchUri}) async {
    officeSlug =
        preferences.office ?? const String.fromEnvironment('OFFICE_SLUG');
    locale = preferences.locale == null ? null : Locale(preferences.locale!);
    final office = launchUri?.queryParameters['office']?.trim();
    if (office != null && office.isNotEmpty) {
      officeSlug = office;
      await preferences.setOffice(office);
    }
    final language = launchUri?.queryParameters['lang'];
    if (language == 'en' || language == 'ar') {
      locale = Locale(language!);
      await preferences.setLocale(language);
    }
    try {
      orders = await vault.read();
    } catch (_) {
      storageError =
          'Secure storage is unavailable. Restart the app before placing an order.';
    }
  }

  Future<void> setLocale(String code) async {
    await preferences.setLocale(code);
    locale = Locale(code);
    notifyListeners();
  }

  Future<void> selectOffice(String slug) async {
    await preferences.setOffice(slug);
    if (officeSlug != slug) _cart.clear();
    officeSlug = slug;
    notifyListeners();
  }

  bool contains(Service service) => _cart.any((s) => s.id == service.id);
  void toggleService(Service service) {
    if (contains(service)) {
      _cart.removeWhere((s) => s.id == service.id);
    } else if (_cart.length < 8) {
      _cart.add(service);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void updatePrices(Office office) {
    final ids = _cart.map((s) => s.id).toSet();
    _cart
      ..clear()
      ..addAll(office.services.where((s) => ids.contains(s.id)));
    notifyListeners();
  }

  Future<void> saveOrder(OrderAccess access) async {
    if (storageError != null) throw StateError(storageError!);
    final next = [access, ...orders.where((o) => o.id != access.id)];
    await vault.write(next);
    orders = next;
    notifyListeners();
  }

  Future<void> forgetOrder(String id) async {
    final next = orders.where((o) => o.id != id).toList();
    await vault.write(next);
    orders = next;
    notifyListeners();
  }

  Future<OrderAccess> importOrder(String input) async {
    final link = TrackingLink.parse(input, currentOffice: officeSlug);
    final existing = orders
        .where((o) => o.slug == link.slug && o.key == link.key)
        .firstOrNull;
    final access =
        existing ??
        OrderAccess(
          id: randomKey(12),
          slug: link.slug,
          key: link.key,
          number: '',
        );
    final tracked = await api.track(access);
    final saved = access.withNumber(tracked.number);
    await saveOrder(saved);
    return saved;
  }
}
