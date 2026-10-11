import 'dart:math';

import '../widgets/pwd_location_fields.dart';
import 'citizen_location_store.dart';

// Local officer directory used while testing.
class OfficerRecord {
  const OfficerRecord(
    this.id,
    this.name,
    this.area,
    this.address,
  );

  final String id;
  final String name;
  final PwdAreaSelection area;
  final String address;
}

class OfficerDirectory {
  static final List<OfficerRecord> records = [
    for (final entry in PwdLocations.districts.entries)
      OfficerRecord(
        'PWD-TN-${entry.key}-0001',
        entry.key == 'CHN'
            ? 'R. Kumar'
            : entry.key == 'MDU'
                ? 'S. Meena'
                : '${entry.value} Officer',
        PwdAreaSelection(
          districtCode: entry.key,
          locality: entry.key == 'CHN'
              ? 'Royapuram'
              : entry.key == 'MDU'
                  ? 'Anna Nagar'
                  : '${entry.value} Town',
        ),
        '${entry.value} PWD office',
      ),
    const OfficerRecord(
      'PWD-TN-CHN-0002',
      'A. Priya',
      PwdAreaSelection(
        districtCode: 'CHN',
        locality: 'Mylapore',
      ),
      'Mylapore PWD office, Chennai',
    ),
    const OfficerRecord(
      'PWD-TN-CHN-0003',
      'K. Ravi',
      PwdAreaSelection(
        districtCode: 'CHN',
        locality: 'Guindy',
      ),
      'Guindy PWD office, Chennai',
    ),
  ];

  static OfficerRecord? find(String id) {
    final cleanId = id.trim().toUpperCase();

    for (final officer in records) {
      if (officer.id == cleanId) return officer;
    }

    return null;
  }

  // Retained for compatibility with other existing screens.
  static OfficerRecord? forArea(PwdAreaSelection area) {
    for (final officer in records) {
      if (officer.area.districtCode == area.districtCode &&
          officer.area.locality.trim().toLowerCase() ==
              area.locality.trim().toLowerCase()) {
        return officer;
      }
    }

    return null;
  }
}

// Existing class name retained so screen imports still work.
// Accounts are stored only in memory for this testing stage.
class DemoAccount {
  DemoAccount({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.officer,
    this.place,
  });

  String name;
  String email;
  String phone;
  String password;

  final OfficerRecord? officer;
  CitizenPlace? place;
}

// The currently signed-in account.
class PwdDemoSession {
  static DemoAccount? current;

  static String get name => current?.name ?? 'Citizen';
  static String get email => current?.email ?? '';
  static String get phone => current?.phone ?? '';

  static String get officerId => current?.officer?.id ?? '';

  static bool get isOfficer => current?.officer != null;

  static PwdAreaSelection? get officerArea =>
      current?.officer?.area;

  static String get officerAddress =>
      current?.officer?.address ?? '';

  static void signOut() {
    // Signing out does not delete complaints.
    current = null;
    CitizenLocationStore.onSave = null;
    CitizenLocationStore.activate(null);
  }
}

class DemoAccountStore {
  static List<DemoAccount> _accounts = _startingAccounts();

  // These accounts are restored after a full app restart.
  static List<DemoAccount> _startingAccounts() {
    return [
      DemoAccount(
        name: 'Citizen',
        email: 'citizen@example.in',
        phone: '9000000000',
        password: 'Demo@123',
      ),
      DemoAccount(
        name: 'R. Kumar',
        email: 'kumar@example.in',
        phone: '9000000001',
        password: 'Demo@123',
        officer: OfficerDirectory.find('PWD-TN-CHN-0001'),
      ),
      DemoAccount(
        name: 'S. Meena',
        email: 'meena@example.in',
        phone: '9000000002',
        password: 'Demo@123',
        officer: OfficerDirectory.find('PWD-TN-MDU-0001'),
      ),
    ];
  }

  // Called once when the application starts.
  static void resetForNewRun() {
    PwdDemoSession.signOut();
    CitizenLocationStore.reset();
    _accounts = _startingAccounts();
  }

  static DemoAccount login(
    String identifier,
    String password,
    bool officer,
  ) {
    final cleanIdentifier = identifier.trim();

    for (final account in _accounts) {
      final bool matches;

      if (officer) {
        matches =
            account.officer?.id == cleanIdentifier.toUpperCase();
      } else {
        matches = account.officer == null &&
            (account.email.toLowerCase() ==
                    cleanIdentifier.toLowerCase() ||
                account.phone == cleanIdentifier);
      }

      if (matches && account.password == password) {
        return account;
      }
    }

    throw const FormatException(
      'Account or password not found. '
      'Check your details or create an account.',
    );
  }

  static DemoAccount register({
    required String name,
    required String email,
    required String phone,
    required String password,
    OfficerRecord? officer,
    CitizenPlace? place,
  }) {
    final cleanEmail = email.trim();
    final cleanPhone = phone.trim();

    final alreadyExists = _accounts.any(
      (account) =>
          account.email.toLowerCase() ==
              cleanEmail.toLowerCase() ||
          account.phone == cleanPhone ||
          (officer != null &&
              account.officer?.id == officer.id),
    );

    if (alreadyExists) {
      throw const FormatException(
        'This email, phone or officer ID is already registered. '
        'Sign in instead.',
      );
    }

    final account = DemoAccount(
      name: officer?.name ?? name.trim(),
      email: cleanEmail,
      phone: cleanPhone,
      password: password,
      officer: officer,
      place: place,
    );

    _accounts.add(account);
    return account;
  }

  static void activate(DemoAccount account) {
    PwdDemoSession.current = account;
    CitizenLocationStore.activate(account.place);

    CitizenLocationStore.onSave = (place) {
      final currentAccount = PwdDemoSession.current;

      if (currentAccount != null &&
          currentAccount.officer == null) {
        currentAccount.place = place;
      }
    };
  }

  static void updateProfile({
    required String name,
    required String email,
    required String phone,
  }) {
    final account = PwdDemoSession.current;

    if (account == null) {
      throw const FormatException(
        'Sign in before editing your profile.',
      );
    }

    final cleanEmail = email.trim();
    final cleanPhone = phone.trim();

    final alreadyExists = _accounts.any(
      (other) =>
          !identical(other, account) &&
          (other.email.toLowerCase() ==
                  cleanEmail.toLowerCase() ||
              other.phone == cleanPhone),
    );

    if (alreadyExists) {
      throw const FormatException(
        'This email or phone is already used by another account.',
      );
    }

    // Officers cannot edit their directory name or officer ID here.
    if (account.officer == null) {
      account.name = name.trim();
    }

    account.email = cleanEmail;
    account.phone = cleanPhone;
  }

  // Local OTP flow; no email or SMS is sent.
  static DemoResetChallenge requestPasswordReset(String email) {
    final cleanEmail = email.trim().toLowerCase();

    for (final account in _accounts) {
      if (account.email.toLowerCase() == cleanEmail) {
        return DemoResetChallenge._(account);
      }
    }

    throw const FormatException(
      'No account is registered with this email address.',
    );
  }
}

// One password-reset request.
class DemoResetChallenge {
  DemoResetChallenge._(this._account)
      : demoCode =
            (100000 + Random.secure().nextInt(900000)).toString();

  final DemoAccount _account;
  final String demoCode;

  final DateTime expiresAt =
      DateTime.now().add(const Duration(minutes: 5));

  int _attempts = 0;
  bool _verified = false;
  bool _used = false;

  void _checkActive() {
    if (_used) {
      throw const FormatException(
        'This code was already used. Request another code.',
      );
    }

    if (!DateTime.now().isBefore(expiresAt)) {
      throw const FormatException(
        'Code expired. Request another code.',
      );
    }

    if (_attempts >= 5) {
      throw const FormatException(
        'Too many incorrect attempts. Request another code.',
      );
    }
  }

  void verify(String code) {
    _checkActive();

    if (code.trim() != demoCode) {
      _attempts++;

      throw FormatException(
        _attempts >= 5
            ? 'Too many incorrect attempts. Request another code.'
            : 'Incorrect code. '
                '${5 - _attempts} attempts remaining.',
      );
    }

    _verified = true;
  }

  void resetPassword(String password) {
    _checkActive();

    if (!_verified) {
      throw const FormatException('Verify the code first.');
    }

    final valid = password.length >= 6 &&
        RegExp(r'^[A-Z]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9\s]').hasMatch(password) &&
        !RegExp(r'\s').hasMatch(password);

    if (!valid) {
      throw const FormatException(
        'Use at least 6 characters, start with a capital letter '
        'and include a symbol. No spaces.',
      );
    }

    _account.password = password;
    _used = true;
  }
}