import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeoapifyPlaceSuggestion {
  final String formattedAddress;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;
  final double latitude;
  final double longitude;
  final String? placeId;

  const GeoapifyPlaceSuggestion({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.addressLine1,
    this.city,
    this.state,
    this.country,
    this.postcode,
    this.placeId,
  });

  factory GeoapifyPlaceSuggestion.fromFeature(Map<String, dynamic> feature) {
    final props = feature['properties'];
    if (props is! Map) {
      throw const FormatException('Geoapify feature missing properties');
    }
    final p = Map<String, dynamic>.from(props);

    double? lat = _asDouble(p['lat']);
    double? lon = _asDouble(p['lon']);

    final geometry = feature['geometry'];
    if ((lat == null || lon == null) && geometry is Map) {
      final coords = geometry['coordinates'];
      if (coords is List && coords.length >= 2) {
        lon ??= _asDouble(coords[0]);
        lat ??= _asDouble(coords[1]);
      }
    }

    if (lat == null || lon == null) {
      throw const FormatException('Geoapify feature missing coordinates');
    }

    final formatted = (p['formatted'] as String?)?.trim();
    final line1 = (p['address_line1'] as String?)?.trim();
    final name = (p['name'] as String?)?.trim();

    return GeoapifyPlaceSuggestion(
      formattedAddress: (formatted != null && formatted.isNotEmpty)
          ? formatted
          : (line1 != null && line1.isNotEmpty
              ? line1
              : (name ?? '$lat, $lon')),
      addressLine1: line1,
      city: p['city'] as String? ??
          p['town'] as String? ??
          p['village'] as String?,
      state: p['state'] as String? ?? p['county'] as String?,
      country: p['country'] as String?,
      postcode: p['postcode']?.toString(),
      latitude: lat,
      longitude: lon,
      placeId: p['place_id']?.toString(),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class GeoapifyService {
  static const String _baseUrl = 'https://api.geoapify.com/v1/geocode';
  static const Duration _timeout = Duration(seconds: 8);

  final Dio _dio;
  final String? _apiKeyOverride;

  GeoapifyService({Dio? dio, String? apiKey})
      : _apiKeyOverride = apiKey,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: _timeout,
                receiveTimeout: _timeout,
                sendTimeout: _timeout,
                responseType: ResponseType.json,
              ),
            );

  String? get _apiKey {
    final override = _apiKeyOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
    try {
      final fromEnv = dotenv.env['GEOAPIFY_API_KEY']?.trim();
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    } catch (_) {}
    return null;
  }

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  Future<List<GeoapifyPlaceSuggestion>> autocomplete({
    required String query,
    String lang = 'en',
    int limit = 8,
    double? biasLat,
    double? biasLon,
    CancelToken? cancelToken,
  }) async {
    final text = query.trim();
    if (text.length < 2) return const [];

    final key = _apiKey;
    if (key == null || key.isEmpty) {
      throw GeoapifyException('api_key_missing');
    }

    final params = <String, dynamic>{
      'text': text,
      'apiKey': key,
      'limit': limit,
      'lang': lang,
    };

    if (biasLat != null && biasLon != null) {
      params['bias'] = 'proximity:$biasLon,$biasLat';
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/autocomplete',
        queryParameters: params,
        cancelToken: cancelToken,
      );

      final features = response.data?['features'];
      if (features is! List) return const [];

      final results = <GeoapifyPlaceSuggestion>[];
      for (final item in features) {
        if (item is! Map) continue;
        try {
          results.add(
            GeoapifyPlaceSuggestion.fromFeature(
              Map<String, dynamic>.from(item),
            ),
          );
        } catch (e) {
          debugPrint('Geoapify: skip invalid feature: $e');
        }
      }
      return results;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      debugPrint(
        'Geoapify autocomplete failed: ${e.type} ${e.response?.statusCode}',
      );
      throw GeoapifyException(_mapDioError(e));
    }
  }

  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
    String lang = 'en',
    CancelToken? cancelToken,
  }) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      throw GeoapifyException('api_key_missing');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'apiKey': key,
          'lang': lang,
        },
        cancelToken: cancelToken,
      );

      final features = response.data?['features'];
      if (features is List && features.isNotEmpty) {
        final first = features.first;
        if (first is Map) {
          final props = first['properties'];
          if (props is Map) {
            final formatted = props['formatted']?.toString().trim();
            if (formatted != null && formatted.isNotEmpty) return formatted;

            final line1 = props['address_line1']?.toString().trim();
            if (line1 != null && line1.isNotEmpty) return line1;
          }
        }
      }

      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      debugPrint(
        'Geoapify reverse failed: ${e.type} ${e.response?.statusCode}',
      );
      throw GeoapifyException(_mapDioError(e));
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'timeout';
      case DioExceptionType.connectionError:
        return 'network';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) return 'invalid_api_key';
        return 'api_error';
      default:
        return 'api_error';
    }
  }
}

class GeoapifyException implements Exception {
  final String code;
  const GeoapifyException(this.code);

  @override
  String toString() => 'GeoapifyException($code)';
}
