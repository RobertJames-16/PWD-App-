import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PwdPlace {
  const PwdPlace({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.city,
    this.district,
    this.state,
    this.locality,
    this.suburb,
    this.street,
    this.postcode,
  });

  final String name;
  final String address;

  final double latitude;
  final double longitude;

  final String? city;
  final String? district;
  final String? state;
  final String? locality;
  final String? suburb;
  final String? street;
  final String? postcode;

  String get locationText {
    return 'Address: $address\n'
        'Latitude: ${latitude.toStringAsFixed(6)}, '
        'Longitude: ${longitude.toStringAsFixed(6)}';
  }

  /// Best available locality/area name.
  String get areaName {
    final values = [
      locality,
      suburb,
      district,
      city,
      name,
    ];

    for (final value in values) {
      final text = value?.trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  /// Best available city/district name.
  String get cityName {
    final values = [
      city,
      district,
      locality,
    ];

    for (final value in values) {
      final text = value?.trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  static PwdPlace? fromJson(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final geometry = value['geometry'];
    final properties = value['properties'];

    if (geometry is! Map || properties is! Map) {
      return null;
    }

    if (geometry['type'] != 'Point') {
      return null;
    }

    final coordinates = geometry['coordinates'];

    if (coordinates is! List || coordinates.length < 2) {
      return null;
    }

    double? readNumber(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString());
    }

    // GeoJSON coordinates are:
    //
    // longitude, latitude
    //
    final longitude = readNumber(coordinates[0]);
    final latitude = readNumber(coordinates[1]);

    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    String property(String key) {
      final value = properties[key];

      if (value == null) {
        return '';
      }

      return value.toString().trim();
    }

    final countryCode = property('countrycode').toUpperCase();

    // Only keep Indian results when Photon provides a country code.
    if (countryCode.isNotEmpty && countryCode != 'IN') {
      return null;
    }

    final name = property('name');
    final city = property('city');
    final district = property('district');
    final state = property('state');
    final locality = property('locality');
    final suburb = property('suburb');
    final street = property('street');
    final postcode = property('postcode');
    final country = property('country');
    final housenumber = property('housenumber');
    final county = property('county');

    final addressParts = <String>[];
    final seen = <String>{};

    void addPart(String value) {
      final text = value.trim();

      if (text.isEmpty) {
        return;
      }

      final key = text.toLowerCase();

      if (seen.add(key)) {
        addressParts.add(text);
      }
    }

    addPart(housenumber);
    addPart(street);
    addPart(name);
    addPart(locality);
    addPart(suburb);
    addPart(district);
    addPart(city);
    addPart(county);
    addPart(state);
    addPart(postcode);
    addPart(country);

    final address = addressParts.join(', ');

    if (address.isEmpty) {
      return null;
    }

    return PwdPlace(
      name: name.isNotEmpty ? name : address,
      address: address,
      latitude: latitude,
      longitude: longitude,
      city: city.isNotEmpty ? city : null,
      district: district.isNotEmpty ? district : null,
      state: state.isNotEmpty ? state : null,
      locality: locality.isNotEmpty ? locality : null,
      suburb: suburb.isNotEmpty ? suburb : null,
      street: street.isNotEmpty ? street : null,
      postcode: postcode.isNotEmpty ? postcode : null,
    );
  }
}

class PwdPlaceException implements Exception {
  const PwdPlaceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PwdPlaceService {
  static const String _host = 'photon.komoot.io';

  // ============================================================
  // TEMPORARY INTERNET TEST
  // ============================================================

  static Future<void> testInternet() async {
    final uri = Uri.parse('https://example.com');

    try {
      debugPrint('[PWD internet test] Starting: $uri');

      final response = await http
          .get(
            uri,
            headers: const {
              'Accept': 'text/html',
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );

      debugPrint(
        '[PWD internet test] SUCCESS: '
        '${response.statusCode} ${response.reasonPhrase}',
      );
    } catch (error) {
      debugPrint(
        '[PWD internet test] ERROR: $error',
      );
    }
  }

  // ============================================================
  // CACHE
  // ============================================================

  static final Map<String, List<PwdPlace>> _cache = {};

  static final Map<String, Future<List<PwdPlace>>> _pending = {};

  // ============================================================
  // SEARCH
  // ============================================================

  static Future<List<PwdPlace>> search(
    String query, {
    String? district,
    double? latitude,
    double? longitude,
  }) async {
    final text = query.trim();

    if (text.length < 3) {
      return const <PwdPlace>[];
    }

    final parts = <String>[text];

    final districtName = district?.trim() ?? '';

    if (districtName.isNotEmpty &&
        !text.toLowerCase().contains(
          districtName.toLowerCase(),
        )) {
      parts.add(districtName);
    }

    if (!parts.join(', ').toLowerCase().contains('tamil nadu')) {
      parts.add('Tamil Nadu');
    }

    final parameters = <String, String>{
      'q': parts.join(', '),
      'limit': '10',
      'lang': 'en',
    };

    if (latitude != null && longitude != null) {
      parameters['lat'] = latitude.toString();
      parameters['lon'] = longitude.toString();
    }

    final uri = Uri.https(
      _host,
      '/api/',
      parameters,
    );

    return _request(uri);
  }

  // ============================================================
  // REVERSE GEOCODING
  // ============================================================

  static Future<PwdPlace?> reverse({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      _host,
      '/reverse',
      {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'limit': '1',
        'lang': 'en',
      },
    );

    final places = await _request(uri);

    if (places.isEmpty) {
      return null;
    }

    return places.first;
  }

  // ============================================================
  // REQUEST
  // ============================================================

  static Future<List<PwdPlace>> _request(Uri uri) async {
    final key = uri.toString();

    final cached = _cache[key];

    if (cached != null) {
      return cached;
    }

    final existing = _pending[key];

    if (existing != null) {
      return existing;
    }

    final future = _fetch(uri);

    _pending[key] = future;

    try {
      final places = await future;

      if (_cache.length >= 80) {
        _cache.remove(_cache.keys.first);
      }

      _cache[key] = places;

      return places;
    } finally {
      _pending.remove(key);
    }
  }

  // ============================================================
  // FETCH
  // ============================================================

  static Future<List<PwdPlace>> _fetch(Uri uri) async {
    final client = http.Client();

    try {
      debugPrint('[PWD places] Request URL: $uri');

      final response = await client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'PWD-Online-Portal/1.0',
              'Accept-Language': 'en-US,en;q=0.9',
            },
          )
          .timeout(
            const Duration(seconds: 20),
          );

      debugPrint(
        '[PWD places] Response: '
        '${response.statusCode} ${response.reasonPhrase}',
      );

      if (response.statusCode != 200) {
        final body = response.body;

        final preview = body.substring(
          0,
          body.length > 250 ? 250 : body.length,
        );

        debugPrint(
          '[PWD places] HTTP ${response.statusCode}: $preview',
        );

        if (response.statusCode == 429) {
          throw const PwdPlaceException(
            'Too many location requests. '
            'Please wait and try again.',
          );
        }

        if (response.statusCode == 403) {
          throw const PwdPlaceException(
            'The location service refused this request. '
            'Please try again later.',
          );
        }

        throw PwdPlaceException(
          'The location service returned HTTP '
          '${response.statusCode}. Please try again.',
        );
      }

      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is! Map ||
          decoded['features'] is! List) {
        throw const FormatException(
          'The location response does not contain a features list.',
        );
      }

      final features = decoded['features'] as List;

      final results = <PwdPlace>[];

      for (final feature in features) {
        final place = PwdPlace.fromJson(feature);

        if (place != null) {
          results.add(place);
        }
      }

      debugPrint(
        '[PWD places] Found ${results.length} places',
      );

      return results;
    } on PwdPlaceException {
      rethrow;
    } on TimeoutException catch (error) {
      debugPrint(
        '[PWD places] Timeout: $error',
      );

      throw const PwdPlaceException(
        'The address service took too long. '
        'Please try again.',
      );
    } on http.ClientException catch (error) {
      debugPrint(
        '[PWD places] Connection error: $error',
      );

      throw const PwdPlaceException(
        'Could not connect to the address service. '
        'Check your internet connection and retry.',
      );
    } on FormatException catch (error) {
      debugPrint(
        '[PWD places] Response format error: $error',
      );

      throw const PwdPlaceException(
        'The address service returned an unreadable response. '
        'Please try again.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[PWD places] Unexpected error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      throw const PwdPlaceException(
        'Location lookup failed. '
        'Please retry or enter the address.',
      );
    } finally {
      client.close();
    }
  }
}