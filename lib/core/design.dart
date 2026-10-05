import 'package:flutter/material.dart';
import 'api.dart';
import 'models.dart';

const emerald = Color(0xFF087F71);
const ink = Color(0xFF183B38);
const muted = Color(0xFF657C77);
const canvas = Color(0xFFF7F9F7);
const mint = Color(0xFFE8F4EF);

extension Copy on BuildContext {
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
  String tr(String en, String ar) => isArabic ? ar : en;
  String price(int value) => money(value, arabic: isArabic);
}

String serviceName(BuildContext context, String name) =>
    !context.isArabic && name == 'Moamalat'
    ? 'Local card — Moamalat'
    : context.isArabic
    ? const {
            'Registration renewal': 'تجديد تسجيل المركبة',
            'Driver license renewal': 'تجديد رخصة القيادة',
            'Insurance renewal': 'تجديد التأمين',
            'Vehicle inspection': 'فحص المركبة',
            'National ID': 'الهوية الوطنية',
            'Registration': 'تسجيل المركبة',
            'Ownership': 'إثبات الملكية',
            'Insurance': 'التأمين',
            'Inspection': 'الفحص',
            'Driver license': 'رخصة القيادة',
            'Other': 'أخرى',
            'Cash': 'نقداً',
            'Bank transfer': 'تحويل مصرفي',
            'Moamalat': 'بطاقة محلية — معاملات',
          }[name] ??
          name
    : name;

String statusName(BuildContext c, String status) {
  const values = <String, (String, String)>{
    'SUBMITTED': ('Order received', 'تم استلام الطلب'),
    'ACCEPTED': ('Accepted by office', 'قبله المكتب'),
    'DECLINED': ('Order declined', 'رُفض الطلب'),
    'REVIEWING': ('Under review', 'قيد المراجعة'),
    'DOCUMENTS_REQUIRED': ('Documents needed', 'مستندات مطلوبة'),
    'DOCUMENTS_PENDING_REVIEW': (
      'Documents in review',
      'المستندات قيد المراجعة',
    ),
    'DOCUMENTS_VERIFIED': ('Documents verified', 'تم التحقق من المستندات'),
    'PROCESSING': ('In progress', 'قيد التنفيذ'),
    'SUBMITTED_TO_AUTHORITY': ('Sent to authority', 'أُرسل إلى الجهة المختصة'),
    'AUTHORITY_PROCESSING': ('Authority processing', 'قيد المعالجة لدى الجهة'),
    'APPROVED': ('Approved', 'تمت الموافقة'),
    'READY_FOR_CUSTOMER': ('Ready to collect', 'جاهز للاستلام'),
    'COMPLETED': ('Completed', 'مكتمل'),
    'ON_HOLD': ('On hold', 'معلّق'),
    'REJECTED': ('Rejected', 'مرفوض'),
    'CANCELLED': ('Cancelled', 'ملغى'),
    'AWAITING_OFFICE_REVIEW': (
      'Awaiting office review',
      'بانتظار مراجعة المكتب',
    ),
    'PENDING': ('Pending review', 'بانتظار المراجعة'),
    'PENDING_VERIFICATION': ('Pending verification', 'بانتظار التحقق'),
    'VERIFIED': ('Verified', 'تم التحقق'),
  };
  final value = values[status];
  return value == null
      ? c.tr('Status updated', 'تم تحديث الحالة')
      : c.tr(value.$1, value.$2);
}

String errorText(BuildContext context, Object error) {
  if (error is FormatException) {
    return context.tr(
      'Paste a valid private tracking link, or a 64-character key with an office selected.',
      'ألصق رابط تتبع خاصاً صالحاً أو رمزاً من ٦٤ حرفاً بعد اختيار المكتب.',
    );
  }
  if (error is ApiFailure) {
    if (!context.isArabic) return error.message;
    if (error.status == 404) {
      return 'لم يتم العثور على المكتب أو الطلب. تحقق من الرابط وحاول مجدداً.';
    }
    if (error.status == 429) {
      return 'محاولات كثيرة. انتظر دقيقة ثم حاول مجدداً.';
    }
    if (error.status == 409) {
      return 'تغيّرت بيانات الطلب أو الرسوم. حدّث البيانات وراجعها قبل المتابعة.';
    }
    if (error.status == 400) {
      return 'تحقق من البيانات والمستندات ثم حاول مجدداً.';
    }
    return 'تعذّر الاتصال. تحقق من الإنترنت وحاول مجدداً.';
  }
  return context.tr(
    'Could not save or load this information. Please try again.',
    'تعذّر حفظ هذه البيانات أو تحميلها. حاول مجدداً.',
  );
}

ThemeData masarTheme(bool arabic) {
  final scheme = ColorScheme.fromSeed(
    seedColor: emerald,
    brightness: Brightness.light,
  ).copyWith(primary: emerald, surface: Colors.white, onSurface: ink);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: canvas,
    fontFamily: arabic ? 'NotoSansArabic' : 'Inter',
    fontFamilyFallback: const ['NotoSansArabic', 'Inter'],
    textTheme: TextTheme(
      headlineLarge: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -1.3,
      ),
      headlineMedium: const TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -.8,
      ),
      titleLarge: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
      ),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 15, height: 1.6),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
      labelLarge: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ).apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE6E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE6E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: emerald, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: Color(0xFFCFDFD7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: mint,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: arabic ? 'NotoSansArabic' : 'Inter',
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? emerald : muted,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5ECE7),
      thickness: 1,
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE4ECE6)),
    ),
    child: child,
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: emerald,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.route_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 10),
        Text(
          context.tr('masar', 'مسار'),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ],
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.controller});
  final List<Widget> children;
  final ScrollController? controller;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1040),
      child: ListView(
        controller: controller,
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
        ),
        children: children,
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.trailing});
  final String title, subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: muted)),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.message, {super.key, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Panel(
      color: const Color(0xFFFFF4ED),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFA45428)),
          const SizedBox(height: 8),
          Text(message),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(context.tr('Try again', 'حاول مجدداً')),
            ),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Panel(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: mint,
            child: Icon(icon, size: 36, color: emerald),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final bad = ['DECLINED', 'REJECTED', 'CANCELLED'].contains(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bad ? const Color(0xFFFFEDE9) : mint,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        statusName(context, status),
        style: TextStyle(
          color: bad ? const Color(0xFF963C2C) : emerald,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

IconData serviceIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('insurance')) return Icons.shield_outlined;
  if (lower.contains('license')) return Icons.badge_outlined;
  if (lower.contains('inspection')) return Icons.car_repair_outlined;
  return Icons.directions_car_outlined;
}

class ServiceIcon extends StatelessWidget {
  const ServiceIcon(this.name, {super.key, this.size = 54});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final isInsurance = name.toLowerCase().contains('insurance');
    final isLicense = name.toLowerCase().contains('license');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isInsurance
            ? const Color(0xFFEDE9F8)
            : isLicense
            ? const Color(0xFFFFF0DC)
            : mint,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(
        serviceIcon(name),
        color: isInsurance
            ? const Color(0xFF7761A4)
            : isLicense
            ? const Color(0xFF977028)
            : emerald,
        size: size * .5,
      ),
    );
  }
}

class FeeRow extends StatelessWidget {
  const FeeRow(this.label, this.amount, {super.key, this.strong = false});
  final String label;
  final int amount;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? ink : muted,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            context.price(amount),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: strong ? 19 : 14,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
