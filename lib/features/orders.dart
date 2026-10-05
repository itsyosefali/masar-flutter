import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/controller.dart';
import '../core/design.dart';
import '../core/models.dart';
import 'documents.dart';
import 'payment/payment.dart';

Future<void> showImportOrder(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ImportForm(),
    );

class _ImportForm extends ConsumerStatefulWidget {
  const _ImportForm();
  @override
  ConsumerState<_ImportForm> createState() => _ImportFormState();
}

class _ImportFormState extends ConsumerState<_ImportForm> {
  final input = TextEditingController();
  bool busy = false;
  Object? error;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> open() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final access = await ref.read(appProvider).importOrder(input.text);
      if (mounted) {
        context.pop();
        context.push('/orders/${access.id}');
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('Pick up where you left off', 'تابع من حيث توقفت'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              'Paste your private tracking link. An order reference alone cannot unlock an order.',
              'ألصق رابط التتبع الخاص. رقم الطلب وحده لا يكفي للوصول إلى الطلب.',
            ),
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: input,
            enabled: !busy,
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: context.tr(
                'Private tracking link or key',
                'رابط أو مفتاح التتبع الخاص',
              ),
              prefixIcon: const Icon(Icons.link_rounded),
            ),
          ),
          if (error != null) ErrorNotice(errorText(context, error!)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : open,
            child: Text(
              busy
                  ? context.tr('Finding your order…', 'جارٍ البحث عن طلبك…')
                  : context.tr('Open order', 'فتح الطلب'),
            ),
          ),
        ],
      ),
    ),
  );
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return PageBody(
      children: [
        PageHeading(
          context.tr('Every step, in view.', 'كل خطوة أمامك.'),
          context.tr(
            'Orders saved on this device. Refresh an order to see the latest.',
            'الطلبات المحفوظة على هذا الجهاز. حدّث الطلب لرؤية آخر المستجدات.',
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => showImportOrder(context),
          icon: const Icon(Icons.add_link_rounded),
          label: Text(context.tr('Open a tracking link', 'فتح رابط تتبع')),
        ),
        const SizedBox(height: 24),
        if (app.storageError != null)
          ErrorNotice(
            context.tr(
              'Saved orders could not be loaded. Restart the app, or use your saved tracking link.',
              'تعذّر تحميل الطلبات المحفوظة. أعد تشغيل التطبيق أو استخدم رابط التتبع المحفوظ.',
            ),
          ),
        if (app.orders.isEmpty)
          EmptyState(
            icon: Icons.route_rounded,
            title: context.tr(
              'Your next journey starts here',
              'رحلتك القادمة تبدأ هنا',
            ),
            message: context.tr(
              'Once you place an order, you can follow its progress here. Have a tracking link? Open it above.',
              'بعد تقديم الطلب ستتمكن من متابعة تقدمه هنا. إذا كان لديك رابط تتبع فافتحه من الأعلى.',
            ),
            action: FilledButton(
              onPressed: () => context.go('/services'),
              child: Text(context.tr('Explore services', 'استكشف الخدمات')),
            ),
          )
        else
          ...app.orders.map(
            (access) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SavedOrderCard(access),
            ),
          ),
      ],
    );
  }
}

class _SavedOrderCard extends ConsumerWidget {
  const _SavedOrderCard(this.access);
  final OrderAccess access;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: mint,
              child: Icon(Icons.receipt_long_outlined, color: emerald),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    access.number.isEmpty
                        ? context.tr(
                            'Check order submission',
                            'تحقق من إرسال الطلب',
                          )
                        : access.number,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    access.slug,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr('Open order', 'فتح الطلب'),
              onPressed: () => context.push('/orders/${access.id}'),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(
            'Private tracking saved on this device',
            'التتبع الخاص محفوظ على هذا الجهاز',
          ),
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, required this.id, this.confirmed = false});
  final String id;
  final bool confirmed;
  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  bool uploading = false;
  bool paying = false;
  bool showTrackingLink = false;
  Object? uploadError;
  Future<void> upload(OrderAccess access) async {
    final doc = await pickDocument(context);
    if (doc == null || !mounted) return;
    setState(() {
      uploading = true;
      uploadError = null;
    });
    try {
      await ref.read(appProvider).api.upload(access, doc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Document sent for office review.',
                'أُرسل المستند لمراجعة المكتب.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => uploadError = e);
    } finally {
      ref.invalidate(trackingProvider(widget.id));
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> copyLink(OrderAccess access) async {
    try {
      await Clipboard.setData(
        ClipboardData(text: ref.read(appProvider).api.trackingUrl(access)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Private tracking link copied.',
                'نُسخ رابط التتبع الخاص.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Could not copy. Select the link to copy it manually.',
                'تعذّر النسخ. حدّد الرابط لنسخه يدوياً.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final access = app.orders.where((o) => o.id == widget.id).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.tr('Back to orders', 'العودة إلى الطلبات'),
          onPressed: () => context.go('/orders'),
          icon: const BackButtonIcon(),
        ),
        title: Text(context.tr('Order details', 'تفاصيل الطلب')),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh order', 'تحديث الطلب'),
            onPressed: () => ref.invalidate(trackingProvider(widget.id)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: access == null
          ? Center(
              child: Text(
                context.tr(
                  'Order is not saved on this device.',
                  'هذا الطلب غير محفوظ على الجهاز.',
                ),
              ),
            )
          : ref
                .watch(trackingProvider(widget.id))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => PageBody(
                    children: [
                      ErrorNotice(
                        errorText(context, e),
                        onRetry: () =>
                            ref.invalidate(trackingProvider(widget.id)),
                      ),
                      Text(
                        context.tr(
                          'If submission was interrupted, wait and refresh before placing another order. Your private tracking key remains saved.',
                          'إذا انقطع الإرسال، انتظر وحدّث الصفحة قبل تقديم طلب آخر. مفتاح التتبع الخاص ما زال محفوظاً.',
                        ),
                        style: const TextStyle(color: muted),
                      ),
                    ],
                  ),
                  data: (order) => RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(trackingProvider(widget.id));
                      await ref.read(trackingProvider(widget.id).future);
                    },
                    child: PageBody(
                      children: [
                        if (widget.confirmed) ...[
                          Panel(
                            color: mint,
                            child: Column(
                              children: [
                                const CircleAvatar(
                                  radius: 32,
                                  backgroundColor: emerald,
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr(
                                    'You’re on your way!',
                                    'طلبك في طريقه للإنجاز!',
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr(
                                    'Your office has received your order. We’ve saved your private tracking link on this device.',
                                    'استلم المكتب طلبك. حُفظ رابط التتبع الخاص على هذا الجهاز.',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        PageHeading(
                          order.number,
                          '${order.vehicle}\n${order.plate}',
                          trailing: const Icon(
                            Icons.directions_car_outlined,
                            size: 34,
                            color: emerald,
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: StatusPill(order.status),
                        ),
                        if (order.declineReason.isNotEmpty)
                          ErrorNotice(order.declineReason),
                        SectionHeading(context.tr('Your services', 'خدماتك')),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Panel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ServiceIcon(item.name, size: 46),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          serviceName(context, item.name),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  StatusPill(item.status),
                                  const SizedBox(height: 16),
                                  _ServiceProgress(status: item.status),
                                  const SizedBox(height: 12),
                                  FeeRow(
                                    context.tr(
                                      'Service total',
                                      'إجمالي الخدمة',
                                    ),
                                    item.total,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SectionHeading(
                          context.tr('Payment overview', 'ملخص الدفع'),
                        ),
                        Panel(
                          child: Column(
                            children: [
                              FeeRow(
                                context.tr('Order total', 'إجمالي الطلب'),
                                order.total,
                              ),
                              FeeRow(
                                context.tr(
                                  'Recorded payments',
                                  'الدفعات المسجلة',
                                ),
                                order.paid,
                              ),
                              const Divider(),
                              FeeRow(
                                context.tr('Remaining', 'المتبقي'),
                                order.total - order.paid,
                                strong: true,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                order.paymentMethod == 'Moamalat'
                                    ? context.tr(
                                        order.paymentStatus == 'PAID'
                                            ? 'Payment confirmed'
                                            : 'Awaiting card payment',
                                        order.paymentStatus == 'PAID'
                                            ? 'تم تأكيد الدفع'
                                            : 'بانتظار الدفع بالبطاقة',
                                      )
                                    : '${serviceName(context, order.paymentMethod)} · ${context.tr('Arranged with your office', 'بالتنسيق مع المكتب')}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (order.paymentMethod == 'Moamalat' &&
                            order.paymentStatus != 'PAID' &&
                            order.status != 'DECLINED')
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: FilledButton.icon(
                              icon: const Icon(Icons.credit_card),
                              label: Text(
                                context.tr(
                                  'Pay with local card',
                                  'الدفع بالبطاقة المحلية',
                                ),
                              ),
                              onPressed: paying
                                  ? null
                                  : () async {
                                      setState(() => paying = true);
                                      await showCardPayment(
                                        context,
                                        app.api,
                                        access,
                                      );
                                      ref.invalidate(
                                        trackingProvider(widget.id),
                                      );
                                      if (mounted) {
                                        setState(() => paying = false);
                                      }
                                    },
                            ),
                          ),
                        SectionHeading(context.tr('Documents', 'المستندات')),
                        Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (order.documents.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: Text(
                                    context.tr(
                                      'No documents uploaded yet. You can add them here.',
                                      'لم تُرفع مستندات بعد. يمكنك إضافتها هنا.',
                                    ),
                                    style: const TextStyle(color: muted),
                                  ),
                                )
                              else
                                ...order.documents.map(
                                  (d) => Padding(
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.description_outlined,
                                              color: emerald,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                d.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          serviceName(context, d.kind),
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        StatusPill(d.status),
                                      ],
                                    ),
                                  ),
                                ),
                              if (order.status != 'DECLINED' &&
                                  order.documents.length < 20)
                                OutlinedButton.icon(
                                  onPressed: uploading
                                      ? null
                                      : () => upload(access),
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: Text(
                                    uploading
                                        ? context.tr(
                                            'Uploading…',
                                            'جارٍ الرفع…',
                                          )
                                        : context.tr(
                                            'Add document',
                                            'إضافة مستند',
                                          ),
                                  ),
                                ),
                              if (order.documents.length >= 20)
                                Text(
                                  context.tr(
                                    'Document limit reached. Contact your office.',
                                    'وصلت إلى الحد الأقصى للمستندات. تواصل مع المكتب.',
                                  ),
                                ),
                              if (uploadError != null) ...[
                                ErrorNotice(errorText(context, uploadError!)),
                                Text(
                                  context.tr(
                                    'Check the refreshed document list before uploading again; an interrupted upload may have arrived.',
                                    'راجع قائمة المستندات المحدثة قبل إعادة الرفع؛ فقد يكون الملف وصل رغم انقطاع الاتصال.',
                                  ),
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SectionHeading(
                          context.tr(
                            'Keep your tracking link',
                            'احتفظ برابط التتبع',
                          ),
                        ),
                        Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  color: emerald,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr(
                                  'Anyone with this link can view your order and send documents. Keep a private copy to recover your order on another device.',
                                  'يمكن لأي شخص لديه هذا الرابط الاطلاع على الطلب وإرسال مستندات. احتفظ بنسخة خاصة لاستعادة الطلب على جهاز آخر.',
                                ),
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => copyLink(access),
                                icon: const Icon(Icons.copy_rounded),
                                label: Text(
                                  context.tr(
                                    'Copy private tracking link',
                                    'نسخ رابط التتبع الخاص',
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(
                                  () => showTrackingLink = !showTrackingLink,
                                ),
                                child: Text(
                                  showTrackingLink
                                      ? context.tr('Hide link', 'إخفاء الرابط')
                                      : context.tr('Show link', 'عرض الرابط'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              if (showTrackingLink)
                                SelectableText(
                                  app.api.trackingUrl(access),
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _ServiceProgress extends StatelessWidget {
  const _ServiceProgress({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    if (['REJECTED', 'CANCELLED', 'ON_HOLD'].contains(status)) {
      return Text(
        context.tr(
          'Contact your office for the next step.',
          'تواصل مع المكتب لمعرفة الخطوة التالية.',
        ),
        style: const TextStyle(color: muted, fontSize: 12),
      );
    }
    final stage = switch (status) {
      'COMPLETED' => 4,
      'READY_FOR_CUSTOMER' || 'APPROVED' => 3,
      'PROCESSING' || 'SUBMITTED_TO_AUTHORITY' || 'AUTHORITY_PROCESSING' => 2,
      'REVIEWING' ||
      'DOCUMENTS_REQUIRED' ||
      'DOCUMENTS_PENDING_REVIEW' ||
      'DOCUMENTS_VERIFIED' => 1,
      _ => 0,
    };
    final labels = [
      context.tr('Received', 'استلام'),
      context.tr('Review', 'مراجعة'),
      context.tr('Processing', 'معالجة'),
      context.tr('Ready', 'جاهز'),
      context.tr('Done', 'مكتمل'),
    ];
    return Column(
      children: [
        Row(
          children: List.generate(
            5,
            (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 5,
                decoration: BoxDecoration(
                  color: i <= stage ? emerald : const Color(0xFFE1EAE3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: List.generate(
            5,
            (i) => Expanded(
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: i <= stage ? emerald : muted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ImportLinkScreen extends ConsumerStatefulWidget {
  const ImportLinkScreen({super.key, required this.link});
  final String link;
  @override
  ConsumerState<ImportLinkScreen> createState() => _ImportLinkScreenState();
}

class _ImportLinkScreenState extends ConsumerState<ImportLinkScreen> {
  Object? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => open());
  }

  Future<void> open() async {
    setState(() => error = null);
    try {
      final access = await ref.read(appProvider).importOrder(widget.link);
      if (mounted) context.go('/orders/${access.id}');
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Open order', 'فتح الطلب'))),
    body: error == null
        ? const Center(child: CircularProgressIndicator())
        : PageBody(
            children: [
              ErrorNotice(errorText(context, error!), onRetry: open),
              TextButton(
                onPressed: () => context.go('/orders'),
                child: Text(
                  context.tr('Go to my orders', 'الانتقال إلى طلباتي'),
                ),
              ),
            ],
          ),
  );
}
