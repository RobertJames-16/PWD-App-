import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/citizen_location_store.dart';
import '../services/pwd_place_service.dart';
import '../widgets/pwd_location_fields.dart';
import 'location_picker_screen.dart';

class CitizenPlacePickerScreen extends StatefulWidget {
  const CitizenPlacePickerScreen({
    this.initialPlace,
    super.key,
  });

  final CitizenPlace? initialPlace;

  @override
  State<CitizenPlacePickerScreen> createState() =>
      _CitizenPlacePickerScreenState();
}

class _CitizenPlacePickerScreenState
    extends State<CitizenPlacePickerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeAddress = TextEditingController();

  PwdAreaSelection? _area;
  String? _mapLocation;

  bool _locating = false;
  bool _addressEdited = false;

  // True when a map/GPS pin exists but district/locality
  // still needs to be completed.
  bool _pinNeedsArea = false;

  int _fieldsVersion = 0;

  static const _orange = Color(0xFFED783E);
  static const _navy = Color(0xFF163844);

  bool get _hasPin => _readPoint(_mapLocation) != null;

  @override
  void initState() {
    super.initState();

    _area = widget.initialPlace?.area;
    _mapLocation = widget.initialPlace?.location;

    _homeAddress.text = _readAddress(_mapLocation ?? '');

    _addressEdited = _homeAddress.text.isNotEmpty;
  }

  @override
  void dispose() {
    _homeAddress.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text.replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOCATION TEXT HELPERS
  // ------------------------------------------------------------

  LatLng? _readPoint(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final match = RegExp(
      r'Latitude:\s*(-?\d+(?:\.\d+)?)'
      r'\s*,\s*Longitude:\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(value);

    if (match == null) {
      return null;
    }

    final latitude = double.tryParse(match.group(1)!);
    final longitude = double.tryParse(match.group(2)!);

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

    return LatLng(latitude, longitude);
  }

  String _readAddress(String value) {
    final coordinateIndex = value.indexOf('Latitude:');

    final addressPart = coordinateIndex >= 0
        ? value.substring(0, coordinateIndex)
        : value;

    return addressPart
        .replaceFirst(
          RegExp(r'^Address:\s*'),
          '',
        )
        .trim();
  }

  String _locationText(
    LatLng point,
    String address,
  ) {
    final cleanAddress = address.trim();

    if (cleanAddress.isEmpty) {
      return 'Latitude: ${point.latitude.toStringAsFixed(6)}, '
          'Longitude: ${point.longitude.toStringAsFixed(6)}';
    }

    return 'Address: $cleanAddress\n'
        'Latitude: ${point.latitude.toStringAsFixed(6)}, '
        'Longitude: ${point.longitude.toStringAsFixed(6)}';
  }

  // ------------------------------------------------------------
  // DISTRICT DETECTION
  // ------------------------------------------------------------

  String _normaliseDistrict(String value) {
    return value
        .toLowerCase()
        .replaceAll(
          RegExp(r'\bdistrict\b'),
          '',
        )
        .replaceAll(
          RegExp(r'[^a-z0-9\u0B80-\u0BFF]'),
          '',
        );
  }

  String? _detectDistrict(String address) {
    final knownNames = <String, String>{
      for (final entry in PwdLocations.districts.entries)
        _normaliseDistrict(entry.value): entry.key,

      // Common alternative names.
      'kanchipuram': 'KAN',
      'kanchipuramdistrict': 'KAN',

      'kanyakumari': 'KAN_CITY',

      'nilgiris': 'NIL',
      'the nilgiris': 'NIL',

      'tiruchirapalli': 'TIR',
      'tiruchirappalli': 'TIR',
      'trichy': 'TIR',
      'trichydistrict': 'TIR',

      'tuticorin': 'THO',
      'thoothukudi': 'THO',

      'tirupattur': 'VEL',
      'tiruppattur': 'TIRUP',

      'tiruvallur': 'TIRUV',
      'thiruvallur': 'TIRUV',

      'tiruvannamalai': 'TIRUVAN',
      'thiruvannamalai': 'TIRUVAN',

      'thiruvarur': 'MAY',

      'villupuram': 'VIL',
      'viluppuram': 'VIL',

      'chengalpet': 'CHE',
      'chengalpattu': 'CHE',

      'chennai': 'CHE_CITY',
    };

    final matches = <String>{};

    // Check comma-separated address components first.
    for (final component in address.split(',')) {
      final normalised = _normaliseDistrict(component);

      final code = knownNames[normalised];

      if (code != null) {
        matches.add(code);
      }
    }

    // If no exact component matched, check the complete text.
    if (matches.isEmpty) {
      final lower = _normaliseDistrict(address);

      for (final entry in knownNames.entries) {
        if (entry.key.isNotEmpty && lower.contains(entry.key)) {
          matches.add(entry.value);
        }
      }
    }

    // Only automatically select if there is exactly one result.
    if (matches.length == 1) {
      return matches.first;
    }

    return null;
  }

  // ------------------------------------------------------------
  // ADDRESS FILL
  // ------------------------------------------------------------

  Future<void> _fillAddress(String found) async {
    if (!mounted || found.trim().isEmpty) {
      return;
    }

    final address = found.trim();
    final current = _homeAddress.text.trim();

    if (_addressEdited &&
        current.isNotEmpty &&
        current != address) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Address found'),
            content: Text(
              '$address\n\n'
              'Replace your entered home address?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('Keep my address'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                child: const Text('Use found address'),
              ),
            ],
          );
        },
      );

      if (!mounted || replace != true) {
        return;
      }
    }

    if (!mounted) return;

    _homeAddress.text = address;
    _addressEdited = false;
  }

  // ------------------------------------------------------------
  // AREA DETECTION
  // ------------------------------------------------------------

  void _setDetectedArea(
    PwdPlace place,
    LatLng selectedPoint,
  ) {
    // This screen uses the PwdPlace.address field.
    final address = place.address.trim();
    final locality = place.name.trim();

    final code = _detectDistrict(address);

    setState(() {
      if (code != null && locality.isNotEmpty) {
        _area = PwdAreaSelection(
          districtCode: code,
          locality: locality,
          location: _locationText(
            selectedPoint,
            address,
          ),
          fullAddress: address,
        );

        _pinNeedsArea = false;
      } else {
        _area = null;
        _pinNeedsArea = true;
      }

      _fieldsVersion++;
    });
  }

  void _areaChanged(
    PwdAreaSelection? selection,
  ) {
    if (_locating) {
      return;
    }

    setState(() {
      _area = selection;

      if (selection?.location != null &&
          selection!.location!.trim().isNotEmpty) {
        // Online place selection may contain location text.
        _mapLocation = selection.location;
        _pinNeedsArea = false;
      } else if (!_pinNeedsArea) {
        // Manual district/locality change invalidates
        // an old map pin.
        _mapLocation = null;
      }

      if (!_addressEdited) {
        if (selection?.fullAddress != null &&
            selection!.fullAddress!.trim().isNotEmpty) {
          _homeAddress.text = selection.fullAddress!;
        } else if (selection?.location != null &&
            selection!.location!.trim().isNotEmpty) {
          _homeAddress.text =
              _readAddress(selection.location!);
        } else if (!_hasPin) {
          _homeAddress.clear();
        }
      }
    });
  }

  // ------------------------------------------------------------
  // CURRENT LOCATION
  // ------------------------------------------------------------

  Future<Position> _currentPosition() async {
    final enabled =
        await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw const PwdPlaceException(
        'Turn on your device location and try again.',
      );
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const PwdPlaceException(
        'Allow location permission to use your current location.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PwdPlaceException(
        'Location permission is blocked. '
        'Allow it in your app settings and try again.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _locating = true;
    });

    try {
      final position = await _currentPosition();

      if (!mounted) return;

      final point = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _mapLocation = _locationText(
          point,
          '',
        );

        _area = null;
        _pinNeedsArea = true;
        _fieldsVersion++;

        if (!_addressEdited) {
          _homeAddress.clear();
        }
      });

      // Reverse geocode GPS position.
      final place = await PwdPlaceService.reverse(
        latitude: point.latitude,
        longitude: point.longitude,
      );

      if (!mounted) return;

      if (place == null) {
        _message(
          'Your map location was found, but no nearby '
          'address was returned. Please enter your '
          'district, locality and address.',
        );
        return;
      }

      // Keep the actual GPS coordinates.
      setState(() {
        _mapLocation = _locationText(
          point,
          place.address,
        );
      });

      _setDetectedArea(
        place,
        point,
      );

      await _fillAddress(
        place.address,
      );

      if (!mounted) return;

      _message(
        _area == null
            ? 'Address found. Please select the '
                'district and locality.'
            : 'Location filled. Please check the '
                'district, locality and house details.',
      );
    } on TimeoutException {
      _message(
        'Getting your location took too long. '
        'Please try again.',
      );
    } on PwdPlaceException catch (error) {
      _message(error.message);
    } catch (error) {
      debugPrint(
        '[PWD citizen location] $error',
      );

      _message(
        'Could not get your location. '
        'Check location permission and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MAP
  // ------------------------------------------------------------

  Future<void> _openMap() async {
    if (_locating) {
      return;
    }

    FocusScope.of(context).unfocus();

    final currentPoint =
        _readPoint(_mapLocation);

    final initial = currentPoint == null
        ? 'Address: ${_homeAddress.text.trim()}'
        : _locationText(
            currentPoint,
            _homeAddress.text.trim(),
          );

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return LocationPickerScreen(
            initialLocation: initial,
          );
        },
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final selectedPoint = _readPoint(result);

    setState(() {
      _locating = true;
      _mapLocation = result;
      _area = null;
      _pinNeedsArea = selectedPoint != null;
      _fieldsVersion++;
    });

    try {
      final mapAddress = _readAddress(result);

      if (mapAddress.trim().isNotEmpty) {
        await _fillAddress(mapAddress);
      }

      if (!mounted) return;

      if (selectedPoint == null) {
        _message(
          'Please choose the district and locality.',
        );
        return;
      }

      // Reverse geocode selected map point.
      final details =
          await PwdPlaceService.reverse(
        latitude: selectedPoint.latitude,
        longitude: selectedPoint.longitude,
      );

      if (!mounted) return;

      if (details == null) {
        _message(
          'Map pin and address retained. '
          'Please choose your district and locality.',
        );
        return;
      }

      // Preserve actual selected map coordinates.
      setState(() {
        _mapLocation = _locationText(
          selectedPoint,
          _readAddress(result),
        );
      });

      _setDetectedArea(
        details,
        selectedPoint,
      );

      if (_area == null) {
        _message(
          'Map location retained. Please choose '
          'the district and locality.',
        );
      }
    } catch (error) {
      debugPrint(
        '[PWD citizen location] District lookup: $error',
      );

      _message(
        'Map pin and address retained. '
        'District lookup failed; choose your '
        'district and locality.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // REMOVE MAP PIN
  // ------------------------------------------------------------

  void _removeMapPin() {
    setState(() {
      _mapLocation = null;
      _pinNeedsArea = false;

      final area = _area;

      if (area != null) {
        _area = PwdAreaSelection(
          districtCode: area.districtCode,
          locality: area.locality,
          fullAddress: area.fullAddress,
        );
      }

      _fieldsVersion++;
    });
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------

  void _confirm() {
    if (_locating) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final area = _area;

    if (area == null) {
      _message(
        'Choose your district and enter your locality.',
      );
      return;
    }

    final address = _homeAddress.text.trim();

    if (address.length < 6) {
      _message(
        'Enter your full home address.',
      );
      return;
    }

    final point = _readPoint(_mapLocation);

    final location = point == null
        ? 'Address: $address'
        : _locationText(
            point,
            address,
          );

    final confirmedArea = PwdAreaSelection(
      districtCode: area.districtCode,
      locality: area.locality,
      location: point == null ? null : location,
      fullAddress: address,
      city: area.city,
      state: area.state,
      latitude: point?.latitude,
      longitude: point?.longitude,
    );

    Navigator.pop(
      context,
      CitizenPlace(
        area: confirmedArea,
        location: location,
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'Choose your location',
        ),
        backgroundColor:
            const Color(0xFFF8FAFB),
        foregroundColor: _navy,
        surfaceTintColor:
            Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 560,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      // ------------------------------------------------
                      // HEADER
                      // ------------------------------------------------

                      Container(
                        padding:
                            const EdgeInsets.all(20),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(0xFFFFEEE4),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons
                                  .location_on_outlined,
                              color: _orange,
                              size: 36,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Set your neighbourhood',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 23,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Search a nearby place, use your '
                              'current location, or simply type '
                              'your home address.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ------------------------------------------------
                      // CURRENT LOCATION
                      // ------------------------------------------------

                      OutlinedButton.icon(
                        onPressed: _locating
                            ? null
                            : _useCurrentLocation,
                        icon: const Icon(
                          Icons.my_location,
                        ),
                        label: Text(
                          _locating
                              ? 'Getting location and address...'
                              : 'Use my current location',
                        ),
                      ),

                      if (_locating) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],

                      const SizedBox(height: 16),

                      // ------------------------------------------------
                      // DISTRICT + AREA
                      // ------------------------------------------------

                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(20),
                          child: AbsorbPointer(
                            absorbing: _locating,
                            child:
                                PwdLocationFields(
                              key: ValueKey(
                                _fieldsVersion,
                              ),
                              initialValue: _area,
                              onChanged:
                                  _areaChanged,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ------------------------------------------------
                      // HOME ADDRESS
                      // ------------------------------------------------

                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding:
                              const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch,
                            children: [
                              const Text(
                                'Home address',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              TextFormField(
                                controller:
                                    _homeAddress,
                                enabled: !_locating,
                                minLines: 3,
                                maxLines: 5,
                                maxLength: 500,
                                textCapitalization:
                                    TextCapitalization
                                        .sentences,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Your full address',
                                  hintText:
                                      'House / flat number, building, street,\n'
                                      'locality, district and PIN code.\n'
                                      'You can include a nearby landmark.',
                                  alignLabelWithHint:
                                      true,
                                  prefixIcon:
                                      Icon(
                                    Icons
                                        .home_outlined,
                                  ),
                                ),
                                onChanged: (value) {
                                  _addressEdited =
                                      value
                                          .trim()
                                          .isNotEmpty;
                                },
                                validator: (value) {
                                  return (value
                                                  ?.trim()
                                                  .length ??
                                              0) <
                                          6
                                      ? 'Enter your full home address.'
                                      : null;
                                },
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              const Text(
                                'Your address does not have to appear '
                                'in the search suggestions.',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ------------------------------------------------
                      // MAP PIN
                      // ------------------------------------------------

                      OutlinedButton.icon(
                        onPressed: _locating
                            ? null
                            : _openMap,
                        icon: const Icon(
                          Icons.map_outlined,
                        ),
                        label: Text(
                          _hasPin
                              ? 'View / adjust map pin'
                              : 'Add a map pin (optional)',
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (_hasPin) ...[
                        const Text(
                          'Map pin selected. Check that it '
                          'matches your home address and district.',
                        ),
                        Align(
                          alignment:
                              Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _locating
                                ? null
                                : _removeMapPin,
                            child: const Text(
                              'Remove map pin',
                            ),
                          ),
                        ),
                      ] else
                        const Text(
                          'No map pin selected. Your address '
                          'will be saved as text only.',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ------------------------------------------------
                      // SAVE
                      // ------------------------------------------------

                      FilledButton(
                        style:
                            FilledButton.styleFrom(
                          backgroundColor:
                              _orange,
                          foregroundColor:
                              Colors.white,
                          padding:
                              const EdgeInsets.all(16),
                        ),
                        onPressed: _locating
                            ? null
                            : _confirm,
                        child: const Text(
                          'Save address',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}