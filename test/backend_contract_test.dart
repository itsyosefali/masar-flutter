import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/core/api.dart';
import 'package:masar/core/models.dart';

void main() {
  final origin = Platform.environment['MASAR_TEST_API'];
  test(
    'Go API: catalog, multipart checkout, retry, staff acceptance and document upload',
    () async {
      final api = CustomerApi(baseUrl: origin);
      final office = await api.office('al-najah-demo');
      expect(office.services, isNotEmpty);
      final service = office.services.first;
      final key = randomKey();
      final access = OrderAccess(
        id: randomKey(12),
        slug: office.slug,
        key: key,
        number: '',
      );
      final details = <String, dynamic>{
        'name': 'Flutter integration customer',
        'phone': '0912345678',
        'email': '',
        'plate': '5-${DateTime.now().microsecondsSinceEpoch % 9999999 + 1}',
        'make': 'Toyota',
        'model': 'Corolla',
        'year': 2024,
        'vin': '',
        'notes': 'Isolated Flutter API validation',
        'service_ids': [service.id],
        'expected_total': service.total,
        'payment_method': 'Cash',
      };
      final file = UploadDocument(
        name: 'registration.pdf',
        bytes: Uint8List.fromList('%PDF-1.4\nIntegration document'.codeUnits),
        kind: 'Registration',
      );
      final number = await api.checkout(office.slug, key, details, [file]);
      expect(number, startsWith('ORD-'));
      expect(await api.checkout(office.slug, key, details, [file]), number);
      var order = await api.track(access);
      expect(order.total, service.total);
      expect(order.status, 'SUBMITTED');
      expect(order.documents.length, 1);
      await expectLater(
        api.checkout(office.slug, key, {...details, 'name': 'Changed'}, [file]),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 409)),
      );
      await expectLater(
        api.track(
          OrderAccess(
            id: 'bad',
            slug: office.slug,
            key: randomKey(),
            number: number,
          ),
        ),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 404)),
      );
      await api.upload(
        access,
        UploadDocument(
          name: 'insurance.pdf',
          bytes: file.bytes,
          kind: 'Insurance',
        ),
      );
      expect((await api.track(access)).documents.length, 2);
      final staff = Dio(BaseOptions(baseUrl: origin!));
      final login = await staff.post<dynamic>(
        '/api/auth/login',
        data: {
          'slug': office.slug,
          'email': 'demo@masar.local',
          'password': 'Explore-Masar-2026!',
        },
      );
      staff.options.headers['Cookie'] = login.headers['set-cookie']!.first
          .split(';')
          .first;
      final orders = (await staff.get<List<dynamic>>('/api/orders')).data!;
      final saved = orders.where((o) => o['number'] == number).toList();
      expect(saved, hasLength(1));
      await staff.post<dynamic>(
        '/api/orders/${saved.single['id']}/accept',
        data: <String, dynamic>{},
      );
      order = await api.track(access);
      expect(order.status, 'ACCEPTED');
      expect(order.items, hasLength(1));
      expect(order.paid, 0);
    },
    skip: origin == null
        ? 'Use scripts/test-mobile-api.sh with an isolated demo database.'
        : false,
  );
}
