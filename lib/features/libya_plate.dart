import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/design.dart';

String plateDigits(String value) => value.replaceAllMapped(
  RegExp('[٠-٩۰-۹]'),
  (m) =>
      '${m[0]!.codeUnitAt(0) - (m[0]!.codeUnitAt(0) <= 0x669 ? 0x660 : 0x6f0)}',
);
String plateNumber(String value) => int.tryParse(value)?.toString() ?? value;
const _types = [
  ('private', 'Private vehicle', 'مركبة خاصة', ''),
  ('taxi', 'Taxi', 'سيارة أجرة', 'ر'),
  ('commercial', 'Commercial vehicle', 'مركبة تجارية', 'ن'),
  ('agricultural', 'Agricultural vehicle', 'مركبة زراعية', 'ز'),
  ('tractor', 'Tractor / semi-truck', 'رأس جر', 'ج'),
  ('trailer', 'Trailer', 'مقطورة', 'م'),
  ('foreign', 'Foreign-owned vehicle', 'مركبة مملوكة لأجنبي', ''),
  ('diplomatic', 'Diplomatic', 'هيئة سياسية', ''),
  ('legacy', 'Older plate (1998–2012)', 'لوحة قديمة (1998–2012)', ''),
];

class LibyanPlateField extends StatefulWidget {
  const LibyanPlateField({
    super.key,
    required this.api,
    required this.controller,
    required this.enabled,
  });
  final CustomerApi api;
  final TextEditingController controller;
  final bool enabled;
  @override
  State<LibyanPlateField> createState() => _LibyanPlateFieldState();
}

class _LibyanPlateFieldState extends State<LibyanPlateField> {
  final serial = TextEditingController(), extra = TextEditingController();
  String type = 'private';
  String? code;
  List<PlateMunicipality> municipalities = [];
  bool failed = false, loading = true;
  bool get hasMunicipality => type != 'diplomatic';
  bool get hasExtra => ['foreign', 'diplomatic', 'legacy'].contains(type);
  int get maxDigits => type == 'diplomatic'
      ? 2
      : type == 'foreign'
      ? 4
      : type == 'legacy'
      ? 5
      : type == 'private' && code == '5'
      ? 7
      : 6;
  String get prefix => _types.firstWhere((row) => row.$1 == type).$4;
  @override
  void initState() {
    super.initState();
    final value = plateDigits(widget.controller.text);
    final regular = RegExp(
      r'^([زنرجم]?)(\d{1,2})-(\d{1,7})$',
    ).firstMatch(value);
    final foreign = RegExp(
      r'^(\d{2,3})/(\d{1,2})-(\d{1,4})$',
    ).firstMatch(value);
    final legacy = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{1,5})$').firstMatch(value);
    final diplomatic = RegExp(
      r'^(\d{1,2})-(\d{2,3}) هيئة سياسية$',
    ).firstMatch(value);
    if (regular != null) {
      type = _types.firstWhere((row) => row.$4 == regular[1]).$1;
      code = regular[2];
      serial.text = regular[3]!;
    } else if (foreign != null || legacy != null) {
      final match = foreign ?? legacy!;
      type = foreign != null ? 'foreign' : 'legacy';
      extra.text = match[1]!;
      code = match[2];
      serial.text = match[3]!;
    } else if (diplomatic != null) {
      type = 'diplomatic';
      serial.text = diplomatic[1]!;
      extra.text = diplomatic[2]!;
    }
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final result = await widget.api.plateMunicipalities();
      if (!mounted) return;
      setState(() {
        municipalities = result;
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          failed = true;
          loading = false;
        });
      }
    }
  }

  void update() {
    final s = plateNumber(serial.text), e = plateNumber(extra.text);
    var plate = '$prefix${code ?? ''}-$s';
    if (type == 'foreign') plate = '$e/$plate';
    if (type == 'legacy') plate = '$e-$plate';
    if (type == 'diplomatic') plate = '$s-$e هيئة سياسية';
    widget.controller.text = plate;
    setState(() {});
  }

  @override
  void dispose() {
    serial.dispose();
    extra.dispose();
    super.dispose();
  }

  Widget numberField(
    TextEditingController controller,
    String label,
    int max, {
    int min = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: widget.enabled,
      textDirection: TextDirection.ltr,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      inputFormatters: [
        TextInputFormatter.withFunction(
          (old, next) => next.copyWith(text: plateDigits(next.text)),
        ),
      ],
      validator: (value) {
        final input = value ?? '';
        if (!RegExp('^[0-9]{$min,$max}\$').hasMatch(input) ||
            (int.tryParse(input) ?? 0) < (min == 2 ? 10 : 1)) {
          return context.tr(
            'Enter $min–$max digits, greater than zero',
            'أدخل من $min إلى $max خانات برقم أكبر من صفر',
          );
        }
        return null;
      },
      onChanged: (_) => update(),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final isDiplomatic = type == 'diplomatic';
    final s = plateNumber(serial.text), e = plateNumber(extra.text);
    var numbers = '$prefix${code ?? '—'} - ${s.isEmpty ? '—' : s}';
    if (type == 'foreign') numbers = '${e.isEmpty ? '—' : e} / $numbers';
    if (type == 'legacy') numbers = '${e.isEmpty ? '—' : e} - $numbers';
    if (isDiplomatic) {
      numbers = '${s.isEmpty ? '—' : s} - ${e.isEmpty ? '—' : e}';
    }
    final ink = isDiplomatic ? Colors.white : const Color(0xff17201c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            initialValue: type,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('Plate type', 'نوع اللوحة'),
            ),
            items: _types
                .map(
                  (row) => DropdownMenuItem(
                    value: row.$1,
                    child: Text(context.tr(row.$2, row.$3)),
                  ),
                )
                .toList(),
            onChanged: widget.enabled
                ? (value) {
                    type = value!;
                    update();
                  }
                : null,
          ),
        ),
        if (hasMunicipality)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DropdownButtonFormField<String>(
              key: ValueKey('municipality-${municipalities.length}'),
              initialValue: municipalities.any((row) => row.code == code)
                  ? code
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr('Municipality', 'البلدية'),
              ),
              hint: Text(context.tr('Choose a municipality', 'اختر البلدية')),
              items: municipalities
                  .map(
                    (row) => DropdownMenuItem(
                      value: row.code,
                      child: Text(
                        '${context.tr(row.nameEn, row.nameAr)} · ${row.code}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.enabled && !loading
                  ? (value) {
                      code = value;
                      update();
                    }
                  : null,
              validator: (value) => value == null
                  ? context.tr('Choose a municipality', 'اختر البلدية')
                  : null,
            ),
          ),
        if (loading) const LinearProgressIndicator(),
        if (failed)
          TextButton.icon(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            label: Text(
              context.tr(
                'Could not load municipalities. Retry',
                'تعذّر تحميل البلديات. أعد المحاولة',
              ),
            ),
          ),
        if (hasExtra)
          numberField(
            extra,
            type == 'legacy'
                ? context.tr('Subdivision code', 'رمز التقسيم الفرعي')
                : context.tr('Country code', 'رمز الدولة'),
            type == 'legacy' ? 2 : 3,
            min: type == 'legacy' ? 1 : 2,
          ),
        numberField(
          serial,
          context.tr('Plate number', 'رقم اللوحة'),
          maxDigits,
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isDiplomatic
                  ? const Color(0xffb72e29)
                  : prefix.isNotEmpty
                  ? const Color(0xfff9d65c)
                  : Colors.white,
              border: Border.all(color: const Color(0xff202a26), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      numbers,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 14),
                    padding: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: ink)),
                    ),
                    child: Text(
                      isDiplomatic
                          ? 'هيئة سياسية'
                          : type == 'legacy'
                          ? 'الجماهيرية'
                          : 'ليبيا',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            context.tr(
              'Registration number: 1–$maxDigits digits. Arabic digits are accepted.',
              'رقم التسجيل: من 1 إلى $maxDigits خانات. يمكنك إدخال الأرقام العربية.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
