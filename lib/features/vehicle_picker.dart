import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/design.dart';

class VehiclePicker extends StatefulWidget {
  const VehiclePicker({
    super.key,
    required this.api,
    required this.make,
    required this.model,
    required this.enabled,
  });
  final CustomerApi api;
  final TextEditingController make, model;
  final bool enabled;
  @override
  State<VehiclePicker> createState() => _VehiclePickerState();
}

class _VehiclePickerState extends State<VehiclePicker> {
  final makeFocus = FocusNode(), modelFocus = FocusNode();
  Timer? timer;
  int version = 0;
  List<VehicleOption> suggestions = [];
  VehicleOption? chosen;
  bool loading = false;
  String? message;
  VehiclePhoto? photo;
  bool photoLoading = false;
  String photoKey = '';
  int photoVersion = 0;
  void resetPhoto() {
    photoVersion++;
    setState(() {
      photo = null;
      photoKey = '';
      photoLoading = false;
    });
  }

  Future<void> loadPhoto() async {
    final makeName = widget.make.text.trim(),
        modelName = widget.model.text.trim();
    if (makeName.isEmpty || modelName.isEmpty) return;
    final key = '${makeName.toLowerCase()}|${modelName.toLowerCase()}';
    if (key == photoKey) return;
    final current = ++photoVersion;
    setState(() {
      photoKey = key;
      photo = null;
      photoLoading = true;
    });
    VehiclePhoto? result;
    try {
      result = await widget.api.vehiclePhoto(makeName, modelName);
    } catch (_) {}
    if (!mounted || current != photoVersion) return;
    setState(() {
      photo = result;
      photoLoading = false;
    });
  }

  void photoCredits() {
    final item = photo;
    if (item == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Photo credits', 'مصدر الصورة')),
        content: SingleChildScrollView(
          child: SelectableText(
            '${item.author}\n${item.license}\n\n${item.sourceUrl}\n\n${item.licenseUrl}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Close', 'إغلاق')),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    makeFocus.addListener(focusChanged);
    modelFocus.addListener(focusChanged);
    if (widget.make.text.isNotEmpty && widget.model.text.isNotEmpty) {
      loadPhoto();
    }
  }

  void focusChanged() {
    if (!modelFocus.hasFocus) loadPhoto();
    if (makeFocus.hasFocus) {
      schedule(true);
    } else if (modelFocus.hasFocus) {
      schedule(false);
    } else {
      clear();
    }
  }

  void clear() {
    timer?.cancel();
    version++;
    if (mounted) {
      setState(() {
        suggestions = [];
        loading = false;
        message = null;
      });
    }
  }

  void schedule(bool isMake) {
    clear();
    final query = (isMake ? widget.make : widget.model).text.trim();
    if (query.length < 2 || !widget.enabled) return;
    final current = version;
    timer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => loading = true);
      try {
        List<VehicleOption> result;
        if (isMake) {
          result = await widget.api.vehicleMakes(query);
        } else {
          final makeName = widget.make.text.trim();
          var make = chosen;
          if (make?.name.toLowerCase() != makeName.toLowerCase()) {
            final matches = makeName.length < 2
                ? <VehicleOption>[]
                : await widget.api.vehicleMakes(makeName);
            if (!mounted || current != version) return;
            make = matches
                .where(
                  (item) => item.name.toLowerCase() == makeName.toLowerCase(),
                )
                .firstOrNull;
          }
          result = make == null
              ? []
              : await widget.api.vehicleModels(make.id, query);
        }
        if (!mounted || current != version) return;
        setState(() {
          suggestions = result;
          loading = false;
          message = result.isEmpty ? 'empty' : null;
        });
      } catch (_) {
        if (!mounted || current != version) return;
        setState(() {
          loading = false;
          message = 'error';
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    makeFocus.removeListener(focusChanged);
    modelFocus.removeListener(focusChanged);
    makeFocus.dispose();
    modelFocus.dispose();
    super.dispose();
  }

  Widget field(bool isMake) {
    final controller = isMake ? widget.make : widget.model;
    final focus = isMake ? makeFocus : modelFocus;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFieldTapRegion(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controller,
              focusNode: focus,
              enabled: widget.enabled,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: isMake
                    ? context.tr('Make', 'الشركة المصنعة')
                    : context.tr('Model', 'الطراز'),
                hintText: isMake
                    ? context.tr(
                        'Start typing a make…',
                        'اكتب اسم الشركة المصنعة…',
                      )
                    : context.tr('Start typing a model…', 'اكتب اسم الطراز…'),
                counterText: '',
                prefixIcon: const Icon(Icons.directions_car_outlined, size: 22),
                suffixIcon: focus.hasFocus && loading
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search, size: 20),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.tr('This field is required', 'هذا الحقل مطلوب')
                  : null,
              onChanged: (_) {
                resetPhoto();
                if (isMake) {
                  chosen = null;
                  widget.model.clear();
                }
                schedule(isMake);
              },
            ),
            if (focus.hasFocus && suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDCE4E9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 42,
                        height: 34,
                        decoration: BoxDecoration(
                          color: mint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: emerald,
                          size: 25,
                        ),
                      ),
                      title: Text(item.name),
                      onTap: () {
                        resetPhoto();
                        controller.text = item.name;
                        if (isMake) {
                          chosen = item;
                          widget.model.clear();
                        }
                        clear();
                        focus.unfocus();
                        if (!isMake) loadPhoto();
                      },
                    );
                  },
                ),
              ),
            if (focus.hasFocus && message != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  message == 'error'
                      ? context.tr(
                          'Suggestions unavailable. You can still enter your vehicle.',
                          'الاقتراحات غير متاحة. يمكنك كتابة بيانات مركبتك.',
                        )
                      : context.tr(
                          'No matches. You can enter the name directly.',
                          'لا توجد نتائج. يمكنك كتابة الاسم مباشرة.',
                        ),
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      field(true),
      field(false),
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 62,
              child: photo == null
                  ? const Icon(
                      Icons.directions_car_rounded,
                      color: emerald,
                      size: 48,
                    )
                  : Image.memory(
                      photo!.bytes,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.directions_car_rounded,
                        color: emerald,
                        size: 48,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.model.text.isEmpty
                        ? context.tr('Your vehicle', 'مركبتك')
                        : '${widget.make.text} ${widget.model.text}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    photoKey.isEmpty
                        ? context.tr(
                            'Choose a model to see its photo',
                            'اختر الطراز لعرض صورته',
                          )
                        : photoLoading
                        ? context.tr(
                            'Looking for a photo…',
                            'جارٍ البحث عن صورة…',
                          )
                        : photo == null
                        ? context.tr(
                            'No model photo available',
                            'لا تتوفر صورة لهذا الطراز',
                          )
                        : context.tr(
                            'Illustrative photo · year and trim may differ',
                            'صورة توضيحية · قد تختلف سنة الصنع والفئة',
                          ),
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                  if (photo != null)
                    TextButton(
                      onPressed: photoCredits,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: AlignmentDirectional.centerStart,
                      ),
                      child: Text(
                        '${photo!.author} · ${photo!.license}',
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
