import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api.dart';
import 'core/controller.dart';
import 'core/design.dart';
import 'core/storage.dart';
import 'features/catalog.dart';
import 'features/checkout.dart';
import 'features/orders.dart';
import 'features/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = CustomerApi();
  final controller = AppController(
    api: api,
    vault: SecureOrderVault(Uri.encodeComponent(api.baseUrl)),
    preferences: Preferences(await SharedPreferences.getInstance()),
  );
  await controller.initialize(launchUri: kIsWeb ? Uri.base : null);
  runApp(
    ProviderScope(
      overrides: [appProvider.overrideWith((ref) => controller)],
      child: const MasarApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            CustomerShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/services',
            builder: (context, state) => const ServicesScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/office',
        builder: (context, state) => const OfficeScreen(),
      ),
      GoRoute(
        path: '/service/:id',
        builder: (context, state) =>
            ServiceScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderScreen(
          id: state.pathParameters['id']!,
          confirmed: state.uri.queryParameters['new'] == '1',
        ),
      ),
      GoRoute(
        path: '/open',
        builder: (context, state) =>
            ImportLinkScreen(link: state.uri.toString()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/'),
          child: Text(context.tr('Go home', 'الرئيسية')),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});

class MasarApp extends ConsumerWidget {
  const MasarApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appProvider.select((a) => a.locale));
    final deviceArabic =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar';
    return MaterialApp.router(
      title: 'Masar · مسار',
      debugShowCheckedModeBanner: false,
      theme: masarTheme(
        locale?.languageCode == 'ar' || (locale == null && deviceArabic),
      ),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final office = ref.watch(officeProvider).valueOrNull;
    final routes = ['/', '/services', '/orders', '/settings'];
    final index = routes.indexOf(path).clamp(0, 3);
    final labels = [
      context.tr('Home', 'الرئيسية'),
      context.tr('Services', 'الخدمات'),
      context.tr('My orders', 'طلباتي'),
      context.tr('Settings', 'الإعدادات'),
    ];
    const icons = [
      Icons.home_outlined,
      Icons.grid_view_rounded,
      Icons.receipt_long_outlined,
      Icons.tune_rounded,
    ];
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 83,
        titleSpacing: 22,
        title: const Brand(),
        actions: [
          if (office != null)
            TextButton.icon(
              onPressed: () => context.push('/office'),
              icon: const Icon(Icons.storefront_outlined, size: 17),
              label: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 220 : 105),
                child: Text(office.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          IconButton(
            tooltip: context.tr('Shopping cart', 'سلة الخدمات'),
            onPressed: () => context.push('/cart'),
            icon: Badge(
              isLabelVisible: app.cart.isNotEmpty,
              label: Text('${app.cart.length}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            Container(
              width: 230,
              margin: const EdgeInsetsDirectional.only(
                start: 20,
                top: 20,
                bottom: 24,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < routes.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        selected: index == i,
                        selectedTileColor: mint,
                        selectedColor: emerald,
                        leading: Icon(icons[i]),
                        title: Text(labels[i]),
                        onTap: () => context.go(routes[i]),
                      ),
                    ),
                  const Spacer(),
                  const Icon(Icons.verified_user_outlined, color: emerald),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'A little less paperwork.\nA lot more peace of mind.',
                      'معاملات أسهل.\nوراحة بال أكثر.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(routes[i]),
              destinations: [
                for (var i = 0; i < routes.length; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
              ],
            ),
    );
  }
}
