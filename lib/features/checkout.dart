import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api.dart';
import '../core/controller.dart';
import '../core/design.dart';
import '../core/models.dart';
import 'documents.dart';
import 'vehicle_picker.dart';
import 'libya_plate.dart';
import 'payment/payment.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Your cart', 'سلة الخدمات'))),
      body: PageBody(
        children: [
          PageHeading(
            context.tr('One step closer.', 'اقتربت خطوة أخرى.'),
            context.tr(
              'These services are for one vehicle.',
              'هذه الخدمات لمركبة واحدة.',
            ),
          ),
          if (app.cart.isEmpty)
            EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: context.tr('A fresh start', 'بداية جديدة'),
              message: context.tr(
                'Add the services your vehicle needs. We’ll keep the fees clear.',
                'أضف الخدمات التي تحتاجها مركبتك مع رسوم واضحة.',
              ),
              action: FilledButton(
                onPressed: () => context.go('/services'),
                child: Text(context.tr('Explore services', 'استكشف الخدمات')),
              ),
            )
          else ...[
            ...app.cart.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: Row(
                    children: [
                      ServiceIcon(s.name, size: 46),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              serviceName(context, s.name),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              context.price(s.total),
                              style: const TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('Remove service', 'حذف الخدمة'),
                        onPressed: () => app.toggleService(s),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/services'),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('Add another service', 'إضافة خدمة أخرى')),
            ),
            SectionHeading(context.tr('Order summary', 'ملخص الطلب')),
            Panel(
              child: Column(
                children: [
                  FeeRow(
                    context.tr('Government fees', 'الرسوم الحكومية'),
                    app.cart.fold(0, (sum, s) => sum + s.governmentFee),
                  ),
                  FeeRow(
                    context.tr('Office fees', 'رسوم المكتب'),
                    app.cart.fold(0, (sum, s) => sum + s.officeFee),
                  ),
                  const Divider(),
                  FeeRow(
                    context.tr('Total', 'الإجمالي'),
                    app.total,
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => context.push('/checkout'),
              label: Text(context.tr('Continue to checkout', 'متابعة الطلب')),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(
                ref.watch(officeProvider).value?.cardPaymentEnabled == true
                    ? 'Pay by local card, or arrange cash or bank transfer with your office.'
                    : 'Arrange cash or bank transfer with your office after review.',
                ref.watch(officeProvider).value?.cardPaymentEnabled == true
                    ? 'ادفع بالبطاقة المحلية أو نسّق الدفع نقداً أو بالتحويل مع المكتب.'
                    : 'نسّق الدفع نقداً أو بالتحويل مع المكتب بعد المراجعة.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final form = GlobalKey<FormState>();
  final scroll = ScrollController();
  void moveStep(int next) {
    FocusScope.of(context).unfocus();
    setState(() => step = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(0);
    });
  }

  final fields = {
    for (final name in [
      'name',
      'phone',
      'email',
      'plate',
      'make',
      'model',
      'year',
      'vin',
      'notes',
    ])
      name: TextEditingController(),
  };
  final documents = <UploadDocument>[];
  int step = 0;
  bool busy = false, completed = false;
  String payment = 'Cash';
  Object? error;
  OrderAccess? access;
  Map<String, dynamic>? submittedPayload;
  List<UploadDocument>? submittedDocuments;
  bool get locked => submittedPayload != null;
  @override
  void dispose() {
    scroll.dispose();
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String value(String field) => fields[field]!.text.trim();
  Widget field(
    String id,
    String en,
    String ar, {
    bool required = true,
    TextInputType? keyboard,
    int? maxLength,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(id),
      controller: fields[id],
      enabled: !busy && !locked,
      keyboardType: keyboard,
      textDirection: ['phone', 'email', 'year', 'vin'].contains(id)
          ? TextDirection.ltr
          : null,
      maxLength: maxLength,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: context.tr(en, ar)),
      validator: (input) {
        final text = input?.trim() ?? '';
        if (required && text.isEmpty) {
          return context.tr('This field is required', 'هذا الحقل مطلوب');
        }
        if (id == 'year' &&
            (int.tryParse(text) == null ||
                int.parse(text) < 1900 ||
                int.parse(text) > 2100)) {
          return context.tr(
            'Enter a year between 1900 and 2100',
            'أدخل سنة بين ١٩٠٠ و٢١٠٠',
          );
        }
        if (id == 'email' &&
            text.isNotEmpty &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
          return context.tr(
            'Enter a valid email',
            'أدخل بريداً إلكترونياً صالحاً',
          );
        }
        if (text.length > (maxLength ?? 250)) {
          return context.tr('This value is too long', 'القيمة طويلة جداً');
        }
        return null;
      },
    ),
  );
  Future<void> submit() async {
    if (busy) return;
    final app = ref.read(appProvider);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      // Persist the capability before any network request. A lost response can be
      // recovered through My orders, including after the process is terminated.
      access ??= OrderAccess(
        id: randomKey(12),
        slug: app.officeSlug!,
        key: randomKey(),
        number: '',
      );
      await app.saveOrder(access!);
      submittedPayload ??= {
        'name': value('name'),
        'phone': value('phone'),
        'email': value('email'),
        'plate': value('plate'),
        'make': value('make'),
        'model': value('model'),
        'year': int.parse(value('year')),
        'vin': value('vin'),
        'notes': value('notes'),
        'service_ids': app.cart.map((s) => s.id).toList(),
        'expected_total': app.total,
        'payment_method': payment,
      };
      submittedDocuments ??= List.of(documents);
      final number = await app.api.checkout(
        access!.slug,
        access!.key,
        submittedPayload!,
        submittedDocuments!,
      );
      // If this write fails, the pre-saved capability still recovers the order.
      await app.saveOrder(access!.withNumber(number));
      completed = true;
      app.clearCart();
      if (payment == 'Moamalat' && mounted) {
        await showCardPayment(context, app.api, access!);
      }
      if (mounted) context.go('/orders/${access!.id}?new=1');
    } on ApiFailure catch (e) {
      try {
        if (e.status != null &&
            e.status! >= 400 &&
            e.status! < 500 &&
            access != null) {
          // A retry may be rate-limited after an earlier request succeeded.
          // Reconcile every definitive failure before releasing the saved key.
          try {
            final tracked = await app.api.track(access!);
            await app.saveOrder(access!.withNumber(tracked.number));
            completed = true;
            app.clearCart();
            if (mounted) context.go('/orders/${access!.id}?new=1');
            return;
          } on ApiFailure catch (lookup) {
            if (lookup.status != 404) {
              if (mounted) setState(() => error = lookup);
              return;
            }
          }
          await app.forgetOrder(access!.id);
          access = null;
          submittedPayload = null;
          submittedDocuments = null;
          if (e.status == 409) {
            final latest = await app.api.office(app.officeSlug!);
            app.updatePrices(latest);
            ref.invalidate(officeProvider);
          }
        }
        if (mounted) setState(() => error = e);
      } catch (recoveryError) {
        if (mounted) setState(() => error = recoveryError);
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> leave() async {
    if (completed) return true;
    if (busy) return false;
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(c.tr('Leave checkout?', 'مغادرة الطلب؟')),
            content: Text(
              locked
                  ? c.tr(
                      'The order may already have been received. Open My orders to check before placing another order.',
                      'قد يكون الطلب وصل بالفعل. تحقق من «طلباتي» قبل تقديم طلب آخر.',
                    )
                  : c.tr(
                      'Contact details and selected documents will be cleared. Your cart stays saved during this session.',
                      'ستُمسح بيانات الاتصال والمستندات المختارة. تبقى السلة خلال هذه الجلسة.',
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(c.tr('Stay', 'البقاء')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(c.tr('Leave', 'مغادرة')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final titles = [
      context.tr('A little about you', 'لنتعرف عليك'),
      context.tr('Meet your vehicle', 'بيانات مركبتك'),
      context.tr('Your documents', 'مستنداتك'),
      context.tr('Everything look right?', 'هل كل شيء صحيح؟'),
    ];
    return PopScope(
      canPop: completed,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await leave() && mounted) {
          setState(() => completed = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('Checkout', 'إتمام الطلب'))),
        body: app.cart.isEmpty && !locked
            ? PageBody(
                children: [
                  EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: context.tr('Your cart is empty', 'السلة فارغة'),
                    message: context.tr(
                      'Choose a service to begin.',
                      'اختر خدمة للبدء.',
                    ),
                    action: FilledButton(
                      onPressed: () {
                        completed = true;
                        context.go('/services');
                      },
                      child: Text(
                        context.tr('Browse services', 'تصفح الخدمات'),
                      ),
                    ),
                  ),
                ],
              )
            : PageBody(
                controller: scroll,
                children: [
                  Row(
                    children: List.generate(
                      4,
                      (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i <= step
                                ? emerald
                                : const Color(0xFFDDE7E0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.tr(
                      'STEP ${step + 1} OF 4',
                      'الخطوة ${step + 1} من ٤',
                    ),
                    style: const TextStyle(
                      color: emerald,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PageHeading(
                    titles[step],
                    context.tr(
                      'One vehicle · ${app.cart.length} ${app.cart.length == 1 ? 'service' : 'services'} · ${context.price(app.total)}',
                      'مركبة واحدة. ${app.cart.length} خدمات. ${context.price(app.total)}',
                    ),
                  ),
                  Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (step == 0) ...[
                          field('name', 'Full name', 'الاسم الكامل'),
                          field(
                            'phone',
                            'Phone number',
                            'رقم الهاتف',
                            keyboard: TextInputType.phone,
                          ),
                          field(
                            'email',
                            'Email (optional)',
                            'البريد الإلكتروني (اختياري)',
                            required: false,
                            keyboard: TextInputType.emailAddress,
                          ),
                        ],
                        if (step == 1) ...[
                          LibyanPlateField(
                            api: app.api,
                            controller: fields['plate']!,
                            enabled: !busy && !locked,
                          ),
                          VehiclePicker(
                            api: app.api,
                            make: fields['make']!,
                            model: fields['model']!,
                            enabled: !busy && !locked,
                          ),
                          field(
                            'year',
                            'Year',
                            'سنة الصنع',
                            keyboard: TextInputType.number,
                          ),
                          field(
                            'vin',
                            'VIN (optional)',
                            'رقم الهيكل (اختياري)',
                            required: false,
                            maxLength: 100,
                          ),
                        ],
                        if (step == 2) ...[
                          Panel(
                            color: mint,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    'A little preparation goes a long way.',
                                    'خطوة بسيطة تسرّع معاملتك.',
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr(
                                    'You can upload documents now or send them later. Your office will verify them.',
                                    'يمكنك رفع المستندات الآن أو إرسالها لاحقاً. سيتحقق المكتب منها.',
                                  ),
                                ),
                                ...app.cart
                                    .expand((s) => s.requirements)
                                    .toSet()
                                    .map(
                                      (kind) => Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '• ${serviceName(context, kind)}',
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...documents.asMap().entries.map(
                            (entry) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.description_outlined,
                                color: emerald,
                              ),
                              title: Text(
                                entry.value.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                serviceName(context, entry.value.kind),
                              ),
                              trailing: IconButton(
                                tooltip: context.tr(
                                  'Remove document',
                                  'حذف المستند',
                                ),
                                onPressed: () => setState(
                                  () => documents.removeAt(entry.key),
                                ),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: documents.length >= 6
                                ? null
                                : () async {
                                    final doc = await pickDocument(context);
                                    if (doc != null && mounted) {
                                      setState(() => documents.add(doc));
                                    }
                                  },
                            icon: const Icon(Icons.upload_file_rounded),
                            label: Text(
                              context.tr(
                                'Add document (${documents.length}/6)',
                                'إضافة مستند (${documents.length}/٦)',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.tr(
                              'PDF, JPEG or PNG · 5 MB per file',
                              'PDF أو JPEG أو PNG · ٥ ميغابايت لكل ملف',
                            ),
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                        if (step == 3) ...[
                          Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value('name'),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  value('phone'),
                                  textDirection: TextDirection.ltr,
                                ),
                                const Divider(height: 28),
                                Text(
                                  '${value('make')} ${value('model')} · ${value('year')}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(value('plate')),
                                const Divider(height: 28),
                                ...app.cart.map(
                                  (s) => FeeRow(
                                    serviceName(context, s.name),
                                    s.total,
                                  ),
                                ),
                                const Divider(),
                                FeeRow(
                                  context.tr('Total', 'الإجمالي'),
                                  app.total,
                                  strong: true,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr(
                                    '${documents.length} ${documents.length == 1 ? 'document' : 'documents'} attached',
                                    '${documents.length} مستندات مرفقة',
                                  ),
                                  style: const TextStyle(color: muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            initialValue: payment,
                            decoration: InputDecoration(
                              labelText: context.tr(
                                'Payment preference',
                                'طريقة الدفع المفضلة',
                              ),
                            ),
                            items:
                                [
                                      if (ref
                                              .watch(officeProvider)
                                              .value
                                              ?.cardPaymentEnabled ==
                                          true)
                                        'Moamalat',
                                      'Cash',
                                      'Bank transfer',
                                    ]
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(serviceName(context, p)),
                                      ),
                                    )
                                    .toList(),
                            onChanged: busy || locked
                                ? null
                                : (p) => setState(() => payment = p!),
                          ),
                          const SizedBox(height: 16),
                          field(
                            'notes',
                            'Notes for the office (optional)',
                            'ملاحظات للمكتب (اختياري)',
                            required: false,
                            maxLength: 4000,
                          ),
                          Text(
                            context.tr(
                              payment == 'Moamalat'
                                  ? 'Your order will be saved, then Moamalat will open for card payment.'
                                  : 'Your office will review the order and arrange payment with you.',
                              payment == 'Moamalat'
                                  ? 'سيتم حفظ طلبك ثم فتح معاملات للدفع بالبطاقة.'
                                  : 'سيراجع المكتب الطلب وينسق الدفع معك.',
                            ),
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (app.storageError != null)
                    ErrorNotice(
                      context.tr(
                        'Secure storage is unavailable. Restart the app before checkout.',
                        'التخزين الآمن غير متاح. أعد تشغيل التطبيق قبل إتمام الطلب.',
                      ),
                    ),
                  if (error != null) ErrorNotice(errorText(context, error!)),
                  if (locked && error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        context.tr(
                          'Your tracking key is saved. Retry this exact order, or check My orders before starting a new checkout.',
                          'حُفظ مفتاح التتبع. أعد محاولة الطلب نفسه أو تحقق من «طلباتي» قبل تقديم طلب جديد.',
                        ),
                        style: const TextStyle(color: muted),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy || app.storageError != null
                        ? null
                        : () {
                            if (form.currentState?.validate() != true) return;
                            if (step < 3) {
                              moveStep(step + 1);
                            } else {
                              submit();
                            }
                          },
                    child: Text(
                      busy
                          ? context.tr(
                              'Sending your order…',
                              'جارٍ إرسال طلبك…',
                            )
                          : step < 3
                          ? context.tr('Continue', 'متابعة')
                          : locked
                          ? context.tr(
                              'Retry same order',
                              'إعادة محاولة الطلب نفسه',
                            )
                          : context.tr('Place order', 'تقديم الطلب'),
                    ),
                  ),
                  if (step > 0 && !locked)
                    TextButton(
                      onPressed: busy ? null : () => moveStep(step - 1),
                      child: Text(context.tr('Back', 'رجوع')),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}
