import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/controller.dart';
import '../core/design.dart';
import '../core/models.dart';

class OfficeContent extends ConsumerWidget {
  const OfficeContent({super.key, required this.builder});
  final Widget Function(Office) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(officeProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => PageBody(
          children: [
            ErrorNotice(
              errorText(context, e),
              onRetry: () => ref.invalidate(officeProvider),
            ),
            OutlinedButton(
              onPressed: () => context.push('/office'),
              child: Text(context.tr('Choose an office', 'اختر مكتباً')),
            ),
          ],
        ),
        data: (office) =>
            office == null ? const WelcomeContent() : builder(office),
      );
}

class WelcomeContent extends StatelessWidget {
  const WelcomeContent({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      HeroCard(onBrowse: () => context.push('/office')),
      const SizedBox(height: 24),
      EmptyState(
        icon: Icons.storefront_outlined,
        title: context.tr('Your journey starts here', 'رحلتك تبدأ من هنا'),
        message: context.tr(
          'Connect to your service office to explore services, see fees and place your first order.',
          'اختر مكتب الخدمات للاطلاع على الخدمات والرسوم وتقديم طلبك الأول.',
        ),
        action: FilledButton.icon(
          onPressed: () => context.push('/office'),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(context.tr('Choose your office', 'اختر مكتبك')),
        ),
      ),
    ],
  );
}

class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.onBrowse});
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: Container(
      color: mint,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 630;
          final copy = Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.tr('YOUR ROAD, SIMPLIFIED', 'طريقك أسهل مع مسار'),
                    style: const TextStyle(
                      color: emerald,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  context.tr(
                    'Less paperwork.\nMore open roads.',
                    'معاملات أسهل.\nوطريق بلا متاعب.',
                  ),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'All your vehicle essentials,\nin one place.',
                    'كل ما تحتاجه مركبتك،\nفي مكان واحد.',
                  ),
                  style: const TextStyle(
                    color: muted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onBrowse,
                  label: Text(context.tr('Explore services', 'استكشف الخدمات')),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                ),
              ],
            ),
          );
          final art = Image.asset(
            'assets/images/vehicle-hero.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          );
          return wide
              ? Row(
                  children: [
                    Expanded(child: copy),
                    Expanded(child: AspectRatio(aspectRatio: 1.25, child: art)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    copy,
                    AspectRatio(aspectRatio: 2.05, child: art),
                  ],
                );
        },
      ),
    ),
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => OfficeContent(
    builder: (office) => RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(officeProvider);
        await ref.read(officeProvider.future);
      },
      child: PageBody(
        children: [
          PageHeading(
            context.tr('A smoother road ahead.', 'رحلة أسهل تبدأ هنا.'),
            context.tr(
              'Welcome to your vehicle services, all in one place.',
              'أهلاً بك في خدمات مركبتك، كلها في مكان واحد.',
            ),
          ),
          HeroCard(onBrowse: () => context.go('/services')),
          SectionHeading(
            context.tr('What can we help with?', 'كيف يمكننا مساعدتك؟'),
            action: TextButton(
              onPressed: () => context.go('/services'),
              child: Text(context.tr('View all', 'عرض الكل')),
            ),
          ),
          ServicesGrid(services: office.services.take(4).toList()),
          SectionHeading(
            context.tr('Already have an order?', 'لديك طلب بالفعل؟'),
          ),
          Panel(
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: mint,
                  radius: 25,
                  child: Icon(Icons.route_outlined, color: emerald),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Stay in the loop', 'تابع كل خطوة'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        context.tr(
                          'Follow your order, from start to finish.',
                          'تتبّع طلبك من البداية حتى الإنجاز.',
                        ),
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Track an order', 'تتبع طلباً'),
                  onPressed: () => context.go('/orders'),
                  icon: const Icon(Icons.arrow_forward_rounded, color: emerald),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 15, color: muted),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  context.tr(
                    'Private tracking. Clear fees. No signup needed.',
                    'تتبع خاص. رسوم واضحة. دون إنشاء حساب.',
                  ),
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) => OfficeContent(
    builder: (office) {
      final services = office.services
          .where(
            (s) => '${s.name} ${serviceName(context, s.name)}'
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList();
      return PageBody(
        children: [
          PageHeading(
            context.tr('Made for your next mile.', 'خدمات لكل خطوة في طريقك.'),
            context.tr(
              'Choose a service. We’ll take it from there.',
              'اختر الخدمة ودع المكتب يتولى الباقي.',
            ),
          ),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: context.tr(
                'Find a vehicle service',
                'ابحث عن خدمة للمركبة',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: emerald,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  context.tr('All services', 'كل الخدمات'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                context.tr(
                  '${services.length} services',
                  '${services.length} خدمات',
                ),
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (services.isEmpty)
            EmptyState(
              icon: Icons.search_off_rounded,
              title: context.tr('No services found', 'لم يتم العثور على خدمات'),
              message: context.tr(
                'Try another search, or check back with your office.',
                'جرّب بحثاً آخر أو راجع مكتبك لاحقاً.',
              ),
            )
          else
            ServicesGrid(services: services),
        ],
      );
    },
  );
}

class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key, required this.services});
  final List<Service> services;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = MediaQuery.textScalerOf(context).scale(14) > 20
          ? 1
          : constraints.maxWidth > 780
          ? 3
          : constraints.maxWidth > 310
          ? 2
          : 1;
      final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: services
            .map(
              (service) => SizedBox(width: width, child: ServiceCard(service)),
            )
            .toList(),
      );
    },
  );
}

class ServiceCard extends ConsumerWidget {
  const ServiceCard(this.service, {super.key});
  final Service service;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final added = ref.watch(appProvider).contains(service);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: added ? emerald : const Color(0xFFE4ECE6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/service/${service.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ServiceIcon(service.name, size: 48),
                  const Spacer(),
                  Icon(
                    added
                        ? Icons.check_circle_rounded
                        : Icons.north_east_rounded,
                    size: 18,
                    color: added ? emerald : muted,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                serviceName(context, service.name),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 7),
              Text(
                context.tr(
                  'Typically ${service.hours} hours',
                  'عادةً ${service.hours} ساعة',
                ),
                style: const TextStyle(color: muted, fontSize: 11),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              Text(
                context.price(service.total),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr('All fees included', 'شامل جميع الرسوم'),
                style: const TextStyle(color: muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceScreen extends ConsumerWidget {
  const ServiceScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Service details', 'تفاصيل الخدمة'))),
    body: OfficeContent(
      builder: (office) {
        final service = office.services.where((s) => s.id == id).firstOrNull;
        if (service == null) {
          return Center(
            child: Text(
              context.tr(
                'Service is no longer available.',
                'هذه الخدمة لم تعد متاحة.',
              ),
            ),
          );
        }
        final app = ref.watch(appProvider);
        final added = app.contains(service);
        return PageBody(
          children: [
            Panel(
              color: mint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceIcon(service.name, size: 72),
                  const SizedBox(height: 22),
                  Text(
                    serviceName(context, service.name),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      'Your office will review your documents and keep you updated as your service progresses.',
                      'سيراجع المكتب مستنداتك ويمكنك متابعة تقدم الخدمة من تفاصيل الطلب.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: emerald,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr(
                            'Target turnaround: ${service.hours} hours',
                            'المدة المستهدفة: ${service.hours} ساعة',
                          ),
                          style: const TextStyle(color: emerald),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    context.tr(
                      'Timing is an estimate, not a guaranteed completion date.',
                      'المدة تقديرية وليست موعد إنجاز مضموناً.',
                    ),
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            SectionHeading(
              context.tr('Simple, transparent pricing', 'رسوم واضحة وبسيطة'),
            ),
            Panel(
              child: Column(
                children: [
                  FeeRow(
                    context.tr('Government fee', 'الرسوم الحكومية'),
                    service.governmentFee,
                  ),
                  FeeRow(
                    context.tr('Office service fee', 'رسوم المكتب'),
                    service.officeFee,
                  ),
                  const Divider(),
                  FeeRow(
                    context.tr('Total', 'الإجمالي'),
                    service.total,
                    strong: true,
                  ),
                ],
              ),
            ),
            SectionHeading(
              context.tr('What you’ll need', 'المستندات المطلوبة'),
            ),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.requirements.isEmpty)
                    Text(
                      context.tr(
                        'Your office will confirm which documents are needed.',
                        'سيؤكد المكتب المستندات المطلوبة.',
                      ),
                    )
                  else
                    ...service.requirements.map(
                      (kind) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.task_alt_rounded,
                              size: 21,
                              color: emerald,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(serviceName(context, kind))),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      'Upload now or send documents later from your private tracking link.',
                      'ارفع المستندات عند الطلب أو أرسلها لاحقاً عبر رابط التتبع الخاص.',
                    ),
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (!added) {
                  if (app.cart.length >= 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr(
                            'You can choose up to 8 services.',
                            'يمكن اختيار ٨ خدمات كحد أقصى.',
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  app.toggleService(service);
                }
                context.push('/cart');
              },
              icon: Icon(
                added ? Icons.shopping_bag_outlined : Icons.add_rounded,
              ),
              label: Text(
                added
                    ? context.tr('View your cart', 'عرض السلة')
                    : context.tr('Add to cart', 'أضف إلى السلة'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    ),
  );
}

class OfficeScreen extends ConsumerStatefulWidget {
  const OfficeScreen({super.key});
  @override
  ConsumerState<OfficeScreen> createState() => _OfficeScreenState();
}

class _OfficeScreenState extends ConsumerState<OfficeScreen> {
  final input = TextEditingController();
  bool busy = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    input.text = ref.read(appProvider).officeSlug ?? '';
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> connect() async {
    var slug = input.text.trim();
    final uri = Uri.tryParse(slug);
    if (uri?.hasScheme == true) slug = uri!.queryParameters['office'] ?? '';
    if (slug.isEmpty) {
      setState(() => error = const FormatException());
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final app = ref.read(appProvider);
      final office = await app.api.office(slug);
      if (!mounted) return;
      if (app.cart.isNotEmpty && app.officeSlug != office.slug) {
        final yes = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(c.tr('Switch offices?', 'تغيير المكتب؟')),
            content: Text(
              c.tr(
                'Your current cart will be cleared. Saved orders will remain available.',
                'ستُفرغ السلة الحالية. ستبقى الطلبات المحفوظة متاحة.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(
                  c.tr('Keep current office', 'الاحتفاظ بالمكتب الحالي'),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(c.tr('Switch office', 'تغيير المكتب')),
              ),
            ],
          ),
        );
        if (yes != true) return;
      }
      await app.selectOffice(office.slug);
      ref.invalidate(officeProvider);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Brand()),
    body: PageBody(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 2.3,
            child: Image.asset(
              'assets/images/vehicle-hero.png',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
        ),
        const SizedBox(height: 28),
        PageHeading(
          context.tr('Your office. Your services.', 'مكتبك. خدماتك.'),
          context.tr(
            'Enter the workspace ID or paste the link shared by your office.',
            'أدخل معرّف المكتب أو ألصق الرابط الذي أرسله لك.',
          ),
        ),
        TextField(
          controller: input,
          enabled: !busy,
          autocorrect: false,
          textDirection: TextDirection.ltr,
          onSubmitted: (_) => busy ? null : connect(),
          decoration: InputDecoration(
            labelText: context.tr(
              'Office link or workspace ID',
              'رابط المكتب أو معرّفه',
            ),
            prefixIcon: const Icon(Icons.storefront_outlined),
          ),
        ),
        if (error != null)
          ErrorNotice(
            error is FormatException
                ? context.tr(
                    'Enter an office ID or a valid office link.',
                    'أدخل معرّف المكتب أو رابطاً صالحاً.',
                  )
                : errorText(context, error!),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: busy ? null : connect,
          child: Text(
            busy
                ? context.tr('Connecting…', 'جارٍ الاتصال…')
                : context.tr('Continue', 'متابعة'),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          context.tr(
            'No account needed. Your office reviews each order before starting the work.',
            'لا تحتاج إلى حساب. يراجع المكتب كل طلب قبل بدء العمل.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted),
        ),
      ],
    ),
  );
}
