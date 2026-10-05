import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.status});
  final String message;
  final int? status;
}

String defaultApiUrl() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  if (kIsWeb) return Uri.base.origin;
  return defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8080'
      : 'http://127.0.0.1:8080';
}

class CustomerApi {
  CustomerApi({String? baseUrl, Dio? client})
    : baseUrl = baseUrl ?? defaultApiUrl(),
      _dio = client ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 35),
      sendTimeout: const Duration(seconds: 40),
      headers: {'Accept': 'application/json'},
    );
  }
  final String baseUrl;
  final Dio _dio;
  String _path(String slug) =>
      '/api/public/offices/${Uri.encodeComponent(slug)}';
  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ApiFailure(
        data is Map && data['error'] is String
            ? data['error'] as String
            : 'Connection interrupted. Please try again.',
        status: e.response?.statusCode,
      );
    }
  }

  Future<List<PlateMunicipality>> plateMunicipalities() => _request(() async {
    final response = await _dio.get<dynamic>('/api/public/libya-plates');
    return (response.data['municipalities'] as List)
        .map(
          (row) =>
              PlateMunicipality(row['code'], row['name_en'], row['name_ar']),
        )
        .toList();
  });

  Future<VehiclePhoto?> vehiclePhoto(String make, String model) =>
      _request(() async {
        final response = await _dio.get<dynamic>(
          '/api/public/vehicle-photo',
          queryParameters: {'make': make, 'model': model},
        );
        final data = response.data['photo'];
        return data == null
            ? null
            : VehiclePhoto.fromJson(Map<String, dynamic>.from(data));
      });

  Future<List<VehicleOption>> vehicleMakes(String query) =>
      _vehicleCatalog('', query);
  Future<List<VehicleOption>> vehicleModels(int makeId, String query) =>
      _vehicleCatalog('/$makeId/models', query);
  Future<List<VehicleOption>> _vehicleCatalog(String path, String query) =>
      _request(() async {
        final response = await _dio.get<List<dynamic>>(
          '/api/public/vehicle-makes$path',
          queryParameters: {'q': query.trim()},
        );
        return response.data!
            .map(
              (row) => VehicleOption(row['id'] as int, row['name'] as String),
            )
            .toList();
      });

  Future<Office> office(String slug) => _request(
    () async => Office.fromJson(
      Map<String, dynamic>.from((await _dio.get<dynamic>(_path(slug))).data),
    ),
  );
  Future<String> checkout(
    String slug,
    String key,
    Map<String, dynamic> details,
    List<UploadDocument> documents,
  ) => _request(() async {
    final body = FormData.fromMap({
      'order': jsonEncode({
        ...details,
        'documents': documents.map((d) => d.metadata).toList(),
      }),
    });
    for (final doc in documents) {
      body.files.add(
        MapEntry(
          'documents',
          MultipartFile.fromBytes(doc.bytes, filename: doc.name),
        ),
      );
    }
    final response = await _dio.post<dynamic>(
      '${_path(slug)}/orders',
      data: body,
      options: Options(headers: {'X-Order-Key': key}),
    );
    return response.data['number'] as String;
  });
  Future<String> paymentUrl(OrderAccess access) => _request(() async {
    final response = await _dio.post<dynamic>(
      '${_path(access.slug)}/order/payment',
      data: {},
      options: Options(headers: {'Authorization': 'Bearer ${access.key}'}),
    );
    final url = Uri.parse(baseUrl).resolve(response.data['url'] as String);
    if (url.origin != Uri.parse(baseUrl).origin || url.path != '/pay/') {
      throw const ApiFailure('Invalid payment URL');
    }
    return url.toString();
  });

  Future<TrackedOrder> track(OrderAccess access) => _request(
    () async => TrackedOrder.fromJson(
      Map<String, dynamic>.from(
        (await _dio.get<dynamic>(
          '${_path(access.slug)}/order',
          options: Options(headers: {'Authorization': 'Bearer ${access.key}'}),
        )).data,
      ),
    ),
  );
  Future<void> upload(OrderAccess access, UploadDocument document) =>
      _request(() async {
        await _dio.post<dynamic>(
          '${_path(access.slug)}/order/documents',
          data: FormData.fromMap({
            ...document.metadata,
            'file': MultipartFile.fromBytes(
              document.bytes,
              filename: document.name,
            ),
          }),
          options: Options(headers: {'Authorization': 'Bearer ${access.key}'}),
        );
      });
  String trackingUrl(OrderAccess access) => Uri.parse(baseUrl)
      .replace(
        path: '/portal/',
        queryParameters: {'office': access.slug},
        fragment: 'track=${access.key}',
      )
      .toString();
}

class VehicleOption {
  const VehicleOption(this.id, this.name);
  final int id;
  final String name;
}

class VehiclePhoto {
  VehiclePhoto.fromJson(Map<String, dynamic> data)
    : bytes = base64Decode(data['data'] as String),
      author = data['author'] as String,
      license = data['license'] as String,
      licenseUrl = data['license_url'] as String,
      sourceUrl = data['source_url'] as String;
  final Uint8List bytes;
  final String author, license, licenseUrl, sourceUrl;
}

class PlateMunicipality {
  const PlateMunicipality(this.code, this.nameEn, this.nameAr);
  final String code, nameEn, nameAr;
}
