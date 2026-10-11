import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/pwd_place_service.dart';
import '../widgets/pwd_widgets.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    required this.initialLocation,
    super.key,
  });

  final String initialLocation;

  @override
  State<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _tamilNaduCenter = LatLng(10.8, 78.5);

  LatLng? _selectedPoint;
  double? _accuracy;

  bool _mapReady = false;
  bool _searching = false;
  bool _locating = false;
  bool _findingAddress = false;

  String? _searchMessage;
  List<PwdPlace> _results = [];

  bool get _busy => _searching || _locating || _findingAddress;

  @override
  void initState() {
    super.initState();

    _restoreLocation();

    // TEMPORARY INTERNET CONNECTION TEST
    PwdPlaceService.testInternet();
  }

  void _restoreLocation() {
    final match = RegExp(
      r'Latitude:\s*(-?\d+(?:\.\d+)?)'
      r'\s*,\s*Longitude:\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(widget.initialLocation);

    if (match != null) {
      final latitude = double.tryParse(match.group(1)!);
      final longitude = double.tryParse(match.group(2)!);

      if (latitude != null &&
          longitude != null &&
          latitude.isFinite &&
          longitude.isFinite &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180) {
        _selectedPoint = LatLng(latitude, longitude);
      }
    }

    final addressMatch = RegExp(
      r'^Address:\s*([\s\S]*?)\nLatitude:',
    ).firstMatch(widget.initialLocation);

    if (addressMatch != null) {
      _addressController.text = addressMatch.group(1)!.trim();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _errorMessage(Object error) {
    if (error is PwdPlaceException) {
      return error.message;
    }

    return 'Location lookup failed. Please try again.';
  }

  Future<void> _searchPlaces() async {
    if (_busy) return;

    final query = _searchController.text.trim();

    if (query.length < 3) {
      _message('Enter at least 3 characters to search.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _searching = true;
      _searchMessage = null;
      _results = [];
    });

    try {
      final focusPoint = _selectedPoint ?? _tamilNaduCenter;

      final places = await PwdPlaceService.search(
        query,
        latitude: focusPoint.latitude,
        longitude: focusPoint.longitude,
      );

      if (!mounted) return;

      setState(() {
        _results = places;
        _searchMessage = places.isEmpty
            ? 'No matching places found. Try adding the town '
                'or district name.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _searchMessage = _errorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  void _choosePlace(PwdPlace place) {
    if (_busy || !_mapReady) return;

    FocusScope.of(context).unfocus();

    final point = LatLng(place.latitude, place.longitude);

    setState(() {
      _selectedPoint = point;
      _accuracy = null;
      _addressController.text = place.address;
      _results = [];
      _searchMessage = null;
    });

    _mapController.move(point, 16);
  }

  void _chooseMapPoint(LatLng point) {
    if (_busy) return;

    setState(() {
      _selectedPoint = point;
      _accuracy = null;

      // An old address must not remain attached to a new pin.
      _addressController.clear();

      _results = [];
      _searchMessage = null;
    });
  }

  Future<void> _findAddress() async {
    final point = _selectedPoint;

    if (point == null || _findingAddress || _searching) return;

    setState(() => _findingAddress = true);

    try {
      final place = await PwdPlaceService.reverse(
        latitude: point.latitude,
        longitude: point.longitude,
      );

      if (!mounted) return;

      if (place == null) {
        _message(
          'No nearby address was found. '
          'Please enter the address or landmark.',
        );
        return;
      }

      // Keep the user's exact selected coordinates.
      // Reverse geocoding supplies an address, not a replacement pin.
      _addressController.text = place.address;

      _message(
        'Nearby address found. Please check it and add house details.',
      );
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _findingAddress = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_busy || !_mapReady) return;

    FocusScope.of(context).unfocus();
    setState(() => _locating = true);

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!enabled) {
        _message('Turn on your device location and try again.');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        _message('Allow location permission to use this option.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _message(
          kIsWeb
              ? 'Allow location in your browser site settings.'
              : 'Allow location permission in your phone app settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      final point = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedPoint = point;
        _accuracy = position.accuracy;
        _addressController.clear();
        _results = [];
        _searchMessage = null;
      });

      _mapController.move(point, 16);

      // Fetch a readable address after obtaining coordinates.
      await _findAddress();
    } on TimeoutException {
      _message(
        'Getting your location took too long. '
        'Try again or select a point on the map.',
      );
    } catch (error) {
      debugPrint('[PWD location] GPS error: $error');

      _message(
        'Could not get your current location. '
        'Check location permission and device location settings.',
      );
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  void _changeZoom(double amount) {
    if (!_mapReady) return;

    final camera = _mapController.camera;
    final zoom = (camera.zoom + amount).clamp(5.0, 19.0).toDouble();

    _mapController.move(camera.center, zoom);
  }

  Future<void> _openCredits() async {
    try {
      final opened = await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
      );

      if (!opened) {
        _message('Could not open the map credits.');
      }
    } catch (_) {
      _message('Could not open the map credits.');
    }
  }

  void _confirmLocation() {
    final point = _selectedPoint;

    if (point == null || _busy) return;
    if (!_formKey.currentState!.validate()) return;

    final result =
        'Address: ${_addressController.text.trim()}\n'
        'Latitude: ${point.latitude.toStringAsFixed(6)}, '
        'Longitude: ${point.longitude.toStringAsFixed(6)}';

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return PwdPage(
      title: 'Select location',
      back: () => Navigator.pop(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;

          final mapHeight =
              (availableHeight * 0.5).clamp(240.0, 440.0).toDouble();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Search for a place, use your current location, '
                  'or tap the map to select the problem area.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  enabled: !_busy,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchPlaces(),
                  decoration: const InputDecoration(
                    labelText: 'Search place or address',
                    hintText: 'Example: Santhome, Chennai',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                PwdButton(
                  _searching ? 'Searching...' : 'Search places',
                  icon: Icons.search,
                  onPressed: _busy ? null : _searchPlaces,
                ),
                if (_searchMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_searchMessage!),
                  ),
                if (_results.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Tap a result to select it',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (final place in _results)
                    Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.location_on_outlined),
                        title: Text(place.address),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: _mapReady
                            ? () => _choosePlace(place)
                            : null,
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: mapHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                _selectedPoint ?? _tamilNaduCenter,
                            initialZoom:
                                _selectedPoint == null ? 7 : 16,
                            minZoom: 5,
                            maxZoom: 19,
                            onMapReady: () {
                              if (!mounted) return;

                              setState(() => _mapReady = true);

                              // If the previous screen passed GPS coordinates
                              // without an address, look up the address now.
                              if (_selectedPoint != null &&
                                  _addressController.text.trim().isEmpty &&
                                  !_busy) {
                                _findAddress();
                              }
                            },
                            onTap: (_, point) {
                              _chooseMapPoint(point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/'
                                  '{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'pwd_online_portal_flutter',
                              maxNativeZoom: 19,
                            ),
                            MarkerLayer(
                              markers: [
                                if (_selectedPoint != null)
                                  Marker(
                                    point: _selectedPoint!,
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.topCenter,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Material(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                            elevation: 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Zoom in',
                                  onPressed: () => _changeZoom(1),
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  tooltip: 'Zoom out',
                                  onPressed: () => _changeZoom(-1),
                                  icon: const Icon(Icons.remove),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: _openCredits,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                child: Text(
                                  '© OpenStreetMap contributors',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PwdButton(
                  _locating
                      ? 'Getting your location...'
                      : 'Use my current location',
                  icon: Icons.my_location,
                  onPressed: _busy || !_mapReady
                      ? null
                      : _useCurrentLocation,
                ),
                if (_busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 20),
                const SectionHeading('Address or landmark'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  enabled: _selectedPoint != null && !_busy,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Selected address',
                    hintText: 'Enter the address or nearby landmark',
                    helperText:
                        'Check the address and add house details if needed.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an address or nearby landmark.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _selectedPoint == null || _busy
                      ? null
                      : _findAddress,
                  icon: const Icon(Icons.place_outlined),
                  label: Text(
                    _findingAddress
                        ? 'Finding address...'
                        : 'Find address for selected pin',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Place search and addresses: Photon / OpenStreetMap.',
                  style: TextStyle(fontSize: 12),
                ),
                if (_selectedPoint != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected coordinates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Latitude: '
                            '${_selectedPoint!.latitude.toStringAsFixed(6)}',
                          ),
                          Text(
                            'Longitude: '
                            '${_selectedPoint!.longitude.toStringAsFixed(6)}',
                          ),
                          if (_accuracy != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Reported location accuracy: '
                              '${_accuracy!.toStringAsFixed(0)} metres',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                PwdButton(
                  'Confirm location',
                  icon: Icons.check,
                  onPressed: _selectedPoint == null || _busy
                      ? null
                      : _confirmLocation,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}