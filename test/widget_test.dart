import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masar/core/controller.dart';
import 'package:masar/core/storage.dart';
import 'package:masar/main.dart';
import 'support.dart';

Future<AppController> launch(
  WidgetTester tester, {
  FakeApi? api,
  String language = 'en',
}) async {
  SharedPreferences.setMockInitialValues({
    'masar.office': 'test-office',
    'masar.locale': language,
  });
  final vault = MemoryVault();
  final backend = api ?? FakeApi();
  backend.vault = vault;
  final app = AppController(
    api: backend,
    vault: vault,
    preferences: Preferences(await SharedPreferences.getInstance()),
  );
  await app.initialize();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appProvider.overrideWith((ref) => app)],
      child: const MasarApp(),
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      350,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
  }
  await tester.ensureVisible(finder.last);
  await tester.pumpAndSettle();
  await tester.tap(finder.last);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String label, String value) async {
  final finder = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
}

void main() {
  testWidgets('mobile home and Arabic layout render without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await launch(tester);
    expect(find.text('A smoother road ahead.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tapText(tester, 'Settings');
    await tapText(tester, 'العربية');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(app.locale, const Locale('ar'));
    expect(
      Directionality.of(tester.element(find.byType(SegmentedButton<String>))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Arabic prices fit a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester, language: 'ar');
    await tapText(tester, 'الخدمات');
    await tapText(tester, 'تجديد تسجيل المركبة');
    await tapText(tester, 'أضف إلى السلة');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'catalog, cart and interrupted checkout recover without a duplicate',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakeApi()
        ..loseFirstResponse = true
        ..limitRetry = true;
      final app = await launch(tester, api: api);
      await tapText(tester, 'Services');
      await tapText(tester, 'Registration renewal');
      await tapText(tester, 'Add to cart');
      expect(app.total, 400000);
      await tapText(tester, 'Continue to checkout');
      await tapText(tester, 'Continue');
      expect(find.text('This field is required'), findsWidgets);
      await fill(tester, 'Full name', 'Test Customer');
      await fill(tester, 'Phone number', '0912345678');
      await tapText(tester, 'Continue');
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Plate number'),
            )
            .controller!
            .text,
        isEmpty,
      );
      final municipality = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Choose a municipality',
      );
      await tester.ensureVisible(municipality);
      await tester.tap(municipality);
      await tester.pumpAndSettle();
      await tapText(tester, 'Tripoli · 5');
      await fill(tester, 'Plate number', '١٢٣٤٥');
      expect(api.catalogQueries, isEmpty);
      await fill(tester, 'Make', 'T');
      await tester.pump(const Duration(milliseconds: 350));
      expect(api.catalogQueries, isEmpty);
      await fill(tester, 'Make', 'Toy');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tapText(tester, 'Toyota');
      await fill(tester, 'Model', 'Cor');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tapText(tester, 'Corolla');
      expect(api.catalogQueries, contains('model:448:Cor'));
      expect(api.photoQueries, contains('Toyota Corolla'));
      await fill(tester, 'Year', '2022');
      await tapText(tester, 'Continue');
      await tapText(tester, 'Continue');
      await tapText(tester, 'Place order');
      expect(app.orders, hasLength(1));
      expect(api.keys, hasLength(1));
      await tapText(tester, 'Retry same order');
      expect(api.keys, hasLength(2));
      expect(api.keys[0], api.keys[1]);
      expect(api.payloads[0], api.payloads[1]);
      expect(api.payloads[0]['plate'], '5-12345');
      expect(app.orders.single.number, 'ORD-TEST');
      expect(app.cart, isEmpty);
      expect(find.text('You’re on your way!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
