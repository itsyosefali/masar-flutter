import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/design.dart';
import '../core/models.dart';

Future<UploadDocument?> pickDocument(BuildContext context) =>
    showModalBottomSheet<UploadDocument>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _DocumentSheet(),
    );

class _DocumentSheet extends StatefulWidget {
  const _DocumentSheet();
  @override
  State<_DocumentSheet> createState() => _DocumentSheetState();
}

class _DocumentSheetState extends State<_DocumentSheet> {
  String kind = documentKinds.first;
  DateTime? expiry;
  bool busy = false;
  String? error;
  Future<void> choose() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (file == null) return;
      final size = await file.length();
      if (size == null || size == 0 || size > 5 * 1024 * 1024) {
        if (mounted) {
          setState(
            () => error = context.tr(
              'Choose a non-empty file up to 5 MB.',
              'اختر ملفاً غير فارغ بحجم لا يتجاوز ٥ ميغابايت.',
            ),
          );
        }
        return;
      }
      final bytes = await file.readAsBytes();
      if (mounted) {
        Navigator.pop(
          context,
          UploadDocument(
            name: file.name,
            bytes: bytes,
            kind: kind,
            expiresOn: expiry == null
                ? ''
                : '${expiry!.year}-${expiry!.month.toString().padLeft(2, '0')}-${expiry!.day.toString().padLeft(2, '0')}',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = context.tr(
            'Could not read that file. Please choose another.',
            'تعذّرت قراءة الملف. اختر ملفاً آخر.',
          ),
        );
      }
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
            context.tr('Add a document', 'إضافة مستند'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'PDF, JPEG or PNG · up to 5 MB',
              'PDF أو JPEG أو PNG · حتى ٥ ميغابايت',
            ),
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: kind,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('Document type', 'نوع المستند'),
            ),
            items: documentKinds
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(serviceName(context, k)),
                  ),
                )
                .toList(),
            onChanged: busy ? null : (value) => setState(() => kind = value!),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: expiry ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null && mounted) setState(() => expiry = date);
                  },
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              expiry == null
                  ? context.tr(
                      'Expiry date (optional)',
                      'تاريخ الانتهاء (اختياري)',
                    )
                  : MaterialLocalizations.of(context).formatMediumDate(expiry!),
            ),
          ),
          if (expiry != null)
            TextButton(
              onPressed: busy ? null : () => setState(() => expiry = null),
              child: Text(
                context.tr('Clear expiry date', 'مسح تاريخ الانتهاء'),
              ),
            ),
          if (error != null) ErrorNotice(error!),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy ? null : choose,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(
              busy
                  ? context.tr('Reading file…', 'جارٍ قراءة الملف…')
                  : context.tr('Choose file', 'اختر ملفاً'),
            ),
          ),
        ],
      ),
    ),
  );
}
