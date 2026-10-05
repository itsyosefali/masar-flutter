import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masar/core/controller.dart';
import 'package:masar/core/models.dart';
import 'package:masar/core/storage.dart';
import 'support.dart';

void main() {
  test('office app links override saved office and language', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = Preferences(await SharedPreferences.getInstance());
    await preferences.setOffice('previous-office');
    await preferences.setLocale('en');
    final app = AppController(
      api: FakeApi(),
      vault: MemoryVault(),
      preferences: preferences,
    );
    await app.initialize(
      launchUri: Uri.parse(
        'https://masar.test/app/?office=current-office&lang=ar',
      ),
    );
    expect(app.officeSlug, 'current-office');
    expect(preferences.office, 'current-office');
    expect(app.locale?.languageCode, 'ar');
    expect(preferences.locale, 'ar');
    app.dispose();
  });
  test('money preserves all three LYD decimal places', () {
    expect(money(400001), '400.001 LYD');
    expect(money(1), '0.001 LYD');
    expect(money(235000), '235.000 LYD');
  });
  test('tracking links require the secret, not the order reference', () {
    final key = randomKey();
    expect(key, matches(RegExp(r'^[a-f0-9]{64}$')));
    final link = TrackingLink.parse(
      'https://masar.test/portal/?office=test-office#track=$key',
    );
    expect(link.slug, 'test-office');
    expect(link.key, key);
    expect(
      TrackingLink.parse('masar://app/open?office=test-office#track=$key').key,
      key,
    );
    expect(() => TrackingLink.parse('ORD-TEST'), throwsFormatException);
    expect(() => TrackingLink.parse(key), throwsFormatException);
    expect(TrackingLink.parse(key, currentOffice: 'test-office').key, key);
    expect(
      () => TrackingLink.parse(
        'https://masar.test/portal/?office=test-office&track=$key',
      ),
      throwsFormatException,
    );
  });
  test('payments are computed from recorded integer amounts', () {
    final order = TrackedOrder.fromJson(orderJson);
    expect(order.paid, 100000);
    expect(order.total - order.paid, 300000);
  });
  test('changing office clears cart but preserves private orders', () async {
    SharedPreferences.setMockInitialValues({});
    final vault = MemoryVault();
    final app = AppController(
      api: FakeApi(),
      vault: vault,
      preferences: Preferences(await SharedPreferences.getInstance()),
    );
    await app.initialize();
    await app.selectOffice('test-office');
    app.toggleService(testServices.first);
    await app.saveOrder(
      OrderAccess(
        id: 'saved',
        slug: 'test-office',
        key: randomKey(),
        number: 'ORD-TEST',
      ),
    );
    await app.selectOffice('another-office');
    expect(app.cart, isEmpty);
    expect(app.orders.single.id, 'saved');
    final restarted = AppController(
      api: FakeApi(),
      vault: vault,
      preferences: app.preferences,
    );
    await restarted.initialize();
    expect(restarted.orders.single.key, app.orders.single.key);
    app.dispose();
    restarted.dispose();
  });
  test('failed secure write does not pretend to save an order', () async {
    SharedPreferences.setMockInitialValues({});
    final vault = MemoryVault()..fail = true;
    final app = AppController(
      api: FakeApi(),
      vault: vault,
      preferences: Preferences(await SharedPreferences.getInstance()),
    );
    await app.initialize();
    await expectLater(
      app.saveOrder(
        OrderAccess(id: 'x', slug: 'test-office', key: randomKey(), number: ''),
      ),
      throwsStateError,
    );
    expect(app.orders, isEmpty);
    app.dispose();
  });
}
