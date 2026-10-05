import 'dart:math';
import 'dart:typed_data';

String randomKey([int bytes = 32]) {
  final random = Random.secure();
  return List.generate(
    bytes,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

String money(int amount, {bool arabic = false}) {
  final whole = amount ~/ 1000;
  final fraction = (amount.abs() % 1000).toString().padLeft(3, '0');
  return '$whole.$fraction ${arabic ? 'د.ل' : 'LYD'}';
}

class Service {
  const Service({
    required this.id,
    required this.name,
    required this.governmentFee,
    required this.officeFee,
    required this.hours,
    required this.requirements,
  });
  factory Service.fromJson(Map<String, dynamic> j) => Service(
    id: j['id'] as String,
    name: j['name'] as String,
    governmentFee: (j['government_fee'] as num).toInt(),
    officeFee: (j['office_fee'] as num).toInt(),
    hours: (j['sla_hours'] as num).toInt(),
    requirements: List<String>.from(j['requirements'] as List),
  );
  final String id, name;
  final int governmentFee, officeFee, hours;
  final List<String> requirements;
  int get total => governmentFee + officeFee;
}

class Office {
  const Office(
    this.slug,
    this.name,
    this.services, {
    this.cardPaymentEnabled = false,
    this.cardPaymentSandbox = false,
  });
  factory Office.fromJson(Map<String, dynamic> j) => Office(
    j['office']['slug'] as String,
    j['office']['name'] as String,
    (j['services'] as List)
        .map((s) => Service.fromJson(Map<String, dynamic>.from(s)))
        .toList(),
    cardPaymentEnabled: j['card_payment_enabled'] == true,
    cardPaymentSandbox: j['card_payment_sandbox'] == true,
  );
  final bool cardPaymentEnabled, cardPaymentSandbox;
  final String slug, name;
  final List<Service> services;
}

class OrderAccess {
  const OrderAccess({
    required this.id,
    required this.slug,
    required this.key,
    required this.number,
  });
  factory OrderAccess.fromJson(Map<String, dynamic> j) => OrderAccess(
    id: j['id'] as String,
    slug: j['slug'] as String,
    key: j['key'] as String,
    number: j['number'] as String,
  );
  final String id, slug, key, number;
  OrderAccess withNumber(String value) =>
      OrderAccess(id: id, slug: slug, key: key, number: value);
  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'key': key,
    'number': number,
  };
}

class TrackingLink {
  const TrackingLink(this.slug, this.key);
  final String slug, key;
  static TrackingLink parse(String value, {String? currentOffice}) {
    final input = value.trim();
    if (RegExp(r'^[a-f0-9]{64}$').hasMatch(input) &&
        currentOffice != null &&
        currentOffice.isNotEmpty) {
      return TrackingLink(currentOffice, input);
    }
    final uri = Uri.tryParse(input);
    final slug = uri?.queryParameters['office'];
    final fragment = uri == null
        ? <String, String>{}
        : Uri.splitQueryString(uri.fragment);
    final key = fragment['track'];
    if (slug == null ||
        slug.isEmpty ||
        key == null ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(key)) {
      throw const FormatException('Invalid tracking link');
    }
    return TrackingLink(slug, key);
  }
}

class UploadDocument {
  const UploadDocument({
    required this.name,
    required this.bytes,
    required this.kind,
    this.expiresOn = '',
  });
  final String name, kind, expiresOn;
  final Uint8List bytes;
  Map<String, dynamic> get metadata => {'kind': kind, 'expires_on': expiresOn};
}

const documentKinds = [
  'National ID',
  'Registration',
  'Ownership',
  'Insurance',
  'Inspection',
  'Driver license',
  'Other',
];

class OrderItem {
  OrderItem.fromJson(Map<String, dynamic> j)
    : name = j['service_name'] as String,
      status = j['status'] as String,
      governmentFee = (j['government_fee'] as num).toInt(),
      officeFee = (j['office_fee'] as num).toInt(),
      paid = (j['paid'] as num).toInt();
  final String name, status;
  final int governmentFee, officeFee, paid;
  int get total => governmentFee + officeFee;
}

class OrderDocument {
  OrderDocument.fromJson(Map<String, dynamic> j)
    : name = j['filename'] as String,
      kind = j['kind'] as String,
      status = j['status'] as String;
  final String name, kind, status;
}

class TrackedOrder {
  TrackedOrder.fromJson(Map<String, dynamic> j)
    : number = j['order']['number'] as String,
      status = j['order']['status'] as String,
      plate = j['order']['plate'] as String,
      vehicle =
          '${j['order']['make']} ${j['order']['model']} · ${j['order']['year']}',
      total = (j['order']['total'] as num).toInt(),
      paymentMethod = j['order']['payment_method'] as String,
      paymentStatus = j['order']['payment_status'] as String? ?? 'UNPAID',
      onlinePaid = (j['order']['online_paid'] as num?)?.toInt() ?? 0,
      declineReason = j['order']['decline_reason'] as String? ?? '',
      items = (j['items'] as List)
          .map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      documents = (j['documents'] as List)
          .map((i) => OrderDocument.fromJson(Map<String, dynamic>.from(i)))
          .toList();
  final String number,
      status,
      plate,
      vehicle,
      paymentMethod,
      declineReason,
      paymentStatus;
  final int onlinePaid;
  final int total;
  final List<OrderItem> items;
  final List<OrderDocument> documents;
  int get paid =>
      max(onlinePaid, items.fold(0, (sum, item) => sum + item.paid));
}
