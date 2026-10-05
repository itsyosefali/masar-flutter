import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/controller.dart';
import '../core/design.dart';
import '../core/models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  Future<void> forget(
    BuildContext context,
    WidgetRef ref,
    OrderAccess access,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          c.tr('Remove from this device?', 'حذف الطلب من هذا الجهاز؟'),
        ),
        content: Text(
          c.tr(
            'This does not cancel your order. Keep a copy of the private tracking link first; it is the only way to recover access.',
            'هذا لا يلغي الطلب. احتفظ بنسخة من رابط التتبع الخاص أولاً؛ فهو الوسيلة الوحيدة لاستعادة الوصول.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.tr('Keep order', 'الاحتفاظ بالطلب')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.tr('Remove', 'حذف')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(appProvider).forgetOrder(access.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorText(context, e))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return PageBody(
      children: [
        PageHeading(
          context.tr('Make yourself at home.', 'مسار على طريقتك.'),
          context.tr(
            'A few preferences for a smoother experience.',
            'تفضيلات بسيطة لتجربة أسهل.',
          ),
        ),
        SectionHeading(context.tr('Language', 'اللغة')),
        Panel(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'ar', label: Text('العربية')),
            ],
            selected: {context.isArabic ? 'ar' : 'en'},
            onSelectionChanged: (value) async {
              try {
                await app.setLocale(value.first);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorText(context, e))),
                  );
                }
              }
            },
          ),
        ),
        SectionHeading(context.tr('Your service office', 'مكتب خدماتك')),
        Panel(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.storefront_outlined, color: emerald),
            title: Text(
              ref.watch(officeProvider).valueOrNull?.name ??
                  context.tr('Choose an office', 'اختر مكتباً'),
            ),
            subtitle: Text(app.officeSlug ?? ''),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/office'),
          ),
        ),
        SectionHeading(
          context.tr('Saved on this device', 'محفوظ على هذا الجهاز'),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(
                  'Orders are saved privately on this device. A saved tracking link lets you reopen an order elsewhere. Contact and vehicle details are not saved as a profile.',
                  'تُحفظ الطلبات بشكل خاص على هذا الجهاز. يتيح لك رابط التتبع المحفوظ فتح الطلب على جهاز آخر. لا تُحفظ بيانات الاتصال والمركبة كملف شخصي.',
                ),
                style: const TextStyle(color: muted),
              ),
              ...app.orders.map(
                (access) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    access.number.isEmpty
                        ? context.tr('Pending submission', 'إرسال قيد التحقق')
                        : access.number,
                  ),
                  subtitle: Text(access.slug),
                  trailing: IconButton(
                    tooltip: context.tr(
                      'Remove saved order',
                      'حذف الطلب المحفوظ',
                    ),
                    onPressed: () => forget(context, ref, access),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        const Center(child: Brand()),
        const SizedBox(height: 10),
        Text(
          context.tr(
            'A little less paperwork. A lot more peace of mind.',
            'معاملات أسهل. وراحة بال أكثر.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
