import 'package:masar/core/api.dart';
import 'package:masar/core/models.dart';
import 'package:masar/core/storage.dart';

const testServices = [
  Service(
    id: 'registration',
    name: 'Registration renewal',
    governmentFee: 350000,
    officeFee: 50000,
    hours: 48,
    requirements: ['National ID', 'Registration'],
  ),
  Service(
    id: 'insurance',
    name: 'Insurance renewal',
    governmentFee: 200000,
    officeFee: 35000,
    hours: 24,
    requirements: [],
  ),
];
const testOffice = Office('test-office', 'Test Office', testServices);
final orderJson = <String, dynamic>{
  'order': {
    'number': 'ORD-TEST',
    'status': 'ACCEPTED',
    'plate': '5-12345',
    'make': 'Toyota',
    'model': 'Corolla',
    'year': 2022,
    'total': 400000,
    'payment_method': 'Cash',
    'decline_reason': '',
  },
  'items': [
    {
      'service_name': 'Registration renewal',
      'government_fee': 350000,
      'office_fee': 50000,
      'paid': 100000,
      'status': 'REVIEWING',
    },
  ],
  'documents': [],
};

class MemoryVault implements OrderVault {
  List<OrderAccess> orders = [];
  bool fail = false;
  @override
  Future<List<OrderAccess>> read() async => List.of(orders);
  @override
  Future<void> write(List<OrderAccess> value) async {
    if (fail) throw StateError('storage failed');
    orders = List.of(value);
  }
}

class FakeApi extends CustomerApi {
  FakeApi() : super(baseUrl: 'https://masar.test');
  final keys = <String>[];
  final payloads = <Map<String, dynamic>>[];
  bool loseFirstResponse = false;
  bool limitRetry = false;
  bool created = false;
  MemoryVault? vault;
  final catalogQueries = <String>[];
  final photoQueries = <String>[];
  @override
  Future<List<PlateMunicipality>> plateMunicipalities() async => [
    const PlateMunicipality('5', 'Tripoli', 'طرابلس'),
    const PlateMunicipality('8', 'Benghazi', 'بنغازي'),
  ];
  @override
  Future<VehiclePhoto?> vehiclePhoto(String make, String model) async {
    photoQueries.add('$make $model');
    return null;
  }

  @override
  Future<List<VehicleOption>> vehicleMakes(String query) async {
    catalogQueries.add('make:$query');
    return [
          const VehicleOption(448, 'Toyota'),
          const VehicleOption(474, 'Honda'),
        ]
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<VehicleOption>> vehicleModels(int makeId, String query) async {
    catalogQueries.add('model:$makeId:$query');
    return (makeId == 448
            ? [const VehicleOption(1, 'Corolla')]
            : [const VehicleOption(2, 'Civic')])
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<Office> office(String slug) async => testOffice;
  @override
  Future<String> checkout(
    String slug,
    String key,
    Map<String, dynamic> details,
    List<UploadDocument> documents,
  ) async {
    if (vault != null && !vault!.orders.any((o) => o.key == key)) {
      throw StateError('Capability was not persisted before submission');
    }
    keys.add(key);
    payloads.add(Map.of(details));
    created = true;
    if (loseFirstResponse && keys.length == 1) {
      throw const ApiFailure('Connection interrupted. Please try again.');
    }
    if (limitRetry && keys.length > 1) {
      throw const ApiFailure('Too many attempts', status: 429);
    }
    return 'ORD-TEST';
  }

  @override
  Future<TrackedOrder> track(OrderAccess access) async {
    if (!created) throw const ApiFailure('Order not found', status: 404);
    return TrackedOrder.fromJson(orderJson);
  }
}
