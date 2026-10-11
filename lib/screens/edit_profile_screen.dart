import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/demo_account_store.dart';
import '../services/citizen_location_store.dart';
import '../widgets/pwd_widgets.dart';

import 'citizen_place_picker_screen.dart';

class ProfileDetails {
  const ProfileDetails({
    required this.name,
    required this.email,
    required this.phone,
    this.officerId = '',
  });

  final String name;
  final String email;
  final String phone;
  final String officerId;
}

class DemoProfiles {
  static ProfileDetails get citizen => current;
  static ProfileDetails get officer => current;

  static ProfileDetails get current => ProfileDetails(
        name: PwdDemoSession.name,
        email: PwdDemoSession.email,
        phone: PwdDemoSession.phone,
        officerId: PwdDemoSession.officerId,
      );

  static set citizen(ProfileDetails value) => _save(value);
  static set officer(ProfileDetails value) => _save(value);

  static void _save(ProfileDetails value) {
    DemoAccountStore.updateProfile(
      name: value.name,
      email: value.email,
      phone: value.phone,
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.details,
    this.isOfficer = false,
    super.key,
  });

  final ProfileDetails details;
  final bool isOfficer;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _officerId;

  CitizenPlace? _home;

  @override
  void initState() {
    super.initState();

    _name = TextEditingController(text: widget.details.name);
    _email = TextEditingController(text: widget.details.email);
    _phone = TextEditingController(text: widget.details.phone);
    _officerId = TextEditingController(text: PwdDemoSession.officerId);

    _home = PwdDemoSession.current?.place;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _officerId.dispose();
    super.dispose();
  }

  Future<void> _editHomeAddress() async {
    final result = await Navigator.push<CitizenPlace>(
      context,
      MaterialPageRoute(
        builder: (_) => CitizenPlacePickerScreen(initialPlace: _home),
      ),
    );

    if (!mounted || result == null) return;

    setState(() => _home = result);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final account = PwdDemoSession.current;

    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }

    // Keep the Officer ID from the signed-in account.
    final details = ProfileDetails(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      officerId: PwdDemoSession.officerId,
    );

    try {
      // Save the address first, then updateProfile saves the account.
      account.place = _home;

      if (!widget.isOfficer && _home != null) {
        CitizenLocationStore.save(_home!);
      }

      DemoAccountStore.updateProfile(
        name: details.name,
        email: details.email,
        phone: details.phone,
      );

      if (!mounted) return;
      Navigator.pop(context, details);
    } on FormatException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes not saved. Check storage and retry.'),
        ),
      );
    }
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';

    final allowed = RegExp(r"^[A-Za-z\u00C0-\u024F\u0B80-\u0BFF .'-]+$");
    final hasLetter = RegExp(r'[A-Za-z\u00C0-\u024F\u0B80-\u0BFF]');

    if (text.length < 2 ||
        !allowed.hasMatch(text) ||
        !hasLetter.hasMatch(text)) {
      return 'Enter a valid name using letters and spaces.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PwdPage(
      title: 'Edit profile',
      back: () => Navigator.pop(context),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        readOnly: widget.isOfficer,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final valid = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value?.trim() ?? '');

                          return valid
                              ? null
                              : 'Enter a valid email address.';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          final valid = RegExp(
                            r'^[0-9]{10}$',
                          ).hasMatch(value?.trim() ?? '');

                          return valid ? null : 'Enter exactly 10 digits.';
                        },
                      ),

                      // Officers can see their ID, but cannot change it.
                      if (widget.isOfficer) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _officerId,
                          readOnly: true,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Officer ID',
                            prefixIcon: Icon(Icons.badge_outlined),
                            suffixIcon: Icon(Icons.lock_outline),
                            helperText:
                                'Assigned by the department. Cannot be edited.',
                            helperMaxLines: 2,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Text(
                        'Home address',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_home?.address ?? 'No home address saved.'),
                      if (_home != null) ...[
                        const SizedBox(height: 4),
                        Text(_home!.area.label),
                      ],
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _editHomeAddress,
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Edit home address'),
                      ),

                      if (widget.isOfficer) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Department assignment',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Assigned area: '
                          '${PwdDemoSession.officerArea?.label ?? "Not assigned"}',
                        ),
                        const SizedBox(height: 4),
                        Text(PwdDemoSession.officerAddress),
                        const SizedBox(height: 8),
                        const Text(
                          'Your officer ID and assigned area cannot be '
                          'changed from this page.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 24),
                      PwdButton(
                        'Save changes',
                        onPressed: _saveProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}