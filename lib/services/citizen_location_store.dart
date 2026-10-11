import 'package:flutter/foundation.dart';

import '../widgets/pwd_location_fields.dart';
import 'demo_account_store.dart';

// Citizen's selected address and service area.
class CitizenPlace {
  const CitizenPlace({
    required this.area,
    required this.location,
  });

  final PwdAreaSelection area;
  final String location;

  // Hide coordinate lines when displaying the readable address.
  String get address {
    return location
        .replaceFirst(RegExp(r'^Address:\s*'), '')
        .split('\nLatitude:')
        .first
        .trim();
  }
}

// Address saved during the current app session.
class CitizenLocationStore {
  static final ValueNotifier<CitizenPlace?> savedPlace =
      ValueNotifier<CitizenPlace?>(null);

  static void Function(CitizenPlace)? onSave;

  static void activate(CitizenPlace? place) {
    savedPlace.value = place;
  }

  static void save(CitizenPlace place) {
    onSave?.call(place);
    savedPlace.value = place;
  }

  static void clear() {
    savedPlace.value = null;
  }

  static void reset() {
    onSave = null;
    savedPlace.value = null;
  }
}

// Stores complaint locations and assigned officer IDs in memory.
class ReportAreaStore {
  static final Map<String, CitizenPlace> _places = {};

  static final Map<String, String> _assignedOfficerIds = {};

  static void save(String reportId, CitizenPlace place) {
    _places[reportId] = place;
  }

  static CitizenPlace? find(String reportId) {
    return _places[reportId];
  }

  static void assignOfficer(String reportId, String officerId) {
    _assignedOfficerIds[reportId] = officerId.trim().toUpperCase();
  }

  static String? assignedOfficerId(String reportId) {
    return _assignedOfficerIds[reportId];
  }

  // Existing officer screens already call this method.
  // For this testing flow, match by the signed-in officer's ID.
  // The area argument remains so existing screens need no changes.
  static bool matches(
    String reportId,
    PwdAreaSelection officerArea,
  ) {
    final signedInOfficerId =
        PwdDemoSession.officerId.trim().toUpperCase();

    if (signedInOfficerId.isEmpty) return false;

    return _assignedOfficerIds[reportId] == signedInOfficerId;
  }

  static void reset() {
    _places.clear();
    _assignedOfficerIds.clear();
  }
}