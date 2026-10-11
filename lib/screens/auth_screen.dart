import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/citizen_location_store.dart';
import '../services/demo_account_store.dart';
import '../services/report_store.dart';
import '../widgets/pwd_location_fields.dart';

import 'citizen_dashboard_screen.dart';
import 'citizen_place_picker_screen.dart';
import 'officer_dashboard_screen.dart';

export '../services/demo_account_store.dart' show PwdDemoSession;

// Change the authentication screen colours here.
class _AuthColors {
  static const orange = Color(0xFFED783E);
  static const navy = Color(0xFF163844);
  static const muted = Color(0xFF687880);
  static const background = Color(0xFFF8FAFB);
  static const border = Color(0xFFDDE5E9);
  static const softOrange = Color(0xFFFFEEE4);
}

// Password rules used for registration and password reset.
String? _passwordError(String? value) {
  final password = value ?? '';

  if (password.length < 6) {
    return 'Use at least 6 characters.';
  }

  if (!RegExp(r'^[A-Z]').hasMatch(password)) {
    return 'Start with a capital letter.';
  }

  if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(password)) {
    return 'Include a symbol, such as @ or #.';
  }

  if (RegExp(r'\s').hasMatch(password)) {
    return 'Do not use spaces.';
  }

  return null;
}

// Check whether the email has a valid format.
String? _emailError(String? value) {
  final email = value?.trim() ?? '';

  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
      ? null
      : 'Enter a valid email address.';
}

// Mobile numbers must contain exactly 10 digits.
String? _phoneError(String? value) {
  return RegExp(r'^[0-9]{10}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter exactly 10 digits.';
}

// SIGN-IN AND REGISTRATION SCREEN
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers read the values entered in the fields.
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _login = TextEditingController();
  final _officerId = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _isLogin = true;
  bool _isOfficer = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _acceptedTerms = false;
  bool _busy = false;

  String _stage = '';

  CitizenPlace? _registrationPlace;
  OfficerRecord? _record;

  @override
  void dispose() {
    // Release controllers when this screen closes.
    for (final controller in [
      _name,
      _email,
      _phone,
      _login,
      _officerId,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.length < 2) {
      return 'Enter at least 2 characters.';
    }

    final allowed = RegExp(
      r"^[A-Za-z\u00C0-\u024F\u0B80-\u0BFF .'-]+$",
    );

    final hasLetter = RegExp(
      r'[A-Za-z\u00C0-\u024F\u0B80-\u0BFF]',
    );

    if (!allowed.hasMatch(name) || !hasLetter.hasMatch(name)) {
      return 'Use letters and spaces. Numbers are not allowed.';
    }

    return null;
  }

  // Citizens can sign in using either email or mobile number.
  String? _validateLogin(String? value) {
    return (value ?? '').contains('@')
        ? _emailError(value)
        : _phoneError(value);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  // Switch between Citizen and PWD Officer.
  void _changeRole(bool officer) {
    if (_busy || officer == _isOfficer) return;

    _formKey.currentState?.reset();

    setState(() {
      _isOfficer = officer;
      _record = OfficerDirectory.find(_officerId.text);

      if (_isOfficer && !_isLogin) {
        _name.text = _record?.name ?? '';
      }
    });
  }

  // Switch between sign-in and account creation.
  void _changeMode() {
    if (_busy) return;

    _formKey.currentState?.reset();

    setState(() {
      _isLogin = !_isLogin;
      _acceptedTerms = false;
      _record = OfficerDirectory.find(_officerId.text);

      if (_isOfficer && !_isLogin) {
        _name.text = _record?.name ?? '';
      }
    });
  }

  // Find the officer's details when an ID is entered.
  void _idChanged(String value) {
    final record = OfficerDirectory.find(value);

    setState(() {
      _record = record;

      if (!_isLogin) {
        _name.text = record?.name ?? '';
      }
    });
  }

  // Open the address picker and receive the selected address.
  Future<void> _chooseRegistrationAddress() async {
    final place = await Navigator.push<CitizenPlace>(
      context,
      MaterialPageRoute(
        builder: (_) => CitizenPlacePickerScreen(
          initialPlace: _registrationPlace,
        ),
      ),
    );

    if (!mounted || place == null) return;

    setState(() => _registrationPlace = place);
  }

  // Runs when Sign in or Create account is pressed.
  Future<void> _continue() async {
    if (_busy || !_formKey.currentState!.validate()) return;

    final record = _isOfficer
        ? OfficerDirectory.find(_officerId.text)
        : null;

    if (_isOfficer && record == null) {
      _message(
        'Officer ID is not in the approved directory. '
        'Contact the administrator.',
      );
      return;
    }

    if (!_isLogin && !_acceptedTerms) {
      _message('Accept the Terms and Privacy Policy to continue.');
      return;
    }

    if (!_isLogin && !_isOfficer && _registrationPlace == null) {
      _message('Choose your address before creating an account.');
      return;
    }

    final store = ReportStoreScope.of(context);

    setState(() {
      _busy = true;
      _stage = 'Checking account…';
    });

    try {
      // Brief pauses make the loading steps visible.
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted) return;

      final DemoAccount account;

      if (_isLogin) {
        account = DemoAccountStore.login(
          _isOfficer ? _officerId.text : _login.text,
          _password.text,
          _isOfficer,
        );
      } else {
        account = DemoAccountStore.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          officer: record,
          place: _isOfficer ? null : _registrationPlace,
        );
      }

      setState(() {
        _stage = _isOfficer
            ? 'Fetching name, assigned zone and office address…'
            : 'Fetching name and saved address…';
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 350),
      );

      if (!mounted) return;

      DemoAccountStore.activate(account);

      // Preserve the existing report-store behaviour.
      if (record != null) {
        store.seedOfficerExamples(record);
      }

      setState(() => _stage = 'Welcome, ${account.name}');

      await Future<void>.delayed(
        const Duration(milliseconds: 450),
      );

      if (!mounted) return;

      if (_isLogin) {
        _openDashboard(context, _isOfficer);
      } else {
        // New accounts see the registration success screen first.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => _RegistrationCompleteScreen(
              name: account.name,
              isOfficer: _isOfficer,
            ),
          ),
          (_) => false,
        );
      }
    } on FormatException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) {
        _message('Could not complete sign in. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _stage = '';
        });
      }
    }
  }

  // Shared appearance for the input boxes.
  InputDecoration _decoration(
    String hint,
    IconData icon, {
    Widget? suffix,
    String? helper,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _AuthColors.border),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _AuthColors.muted,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        size: 21,
        color: _AuthColors.muted,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FBFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: _AuthColors.orange,
          width: 1.5,
        ),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.red),
      ),
      helperText: helper,
      helperMaxLines: 4,
      errorMaxLines: 3,
    );
  }

  // Display a label above a field.
  Widget _field(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _AuthColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _roleButton(String label, bool officer) {
    final selected = _isOfficer == officer;

    return OutlinedButton(
      onPressed: () => _changeRole(officer),
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? _AuthColors.softOrange : Colors.white,
        foregroundColor:
            selected ? _AuthColors.orange : _AuthColors.muted,
        side: BorderSide(
          color: selected ? _AuthColors.orange : _AuthColors.border,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  // Used for both Password and Confirm password.
  Widget _passwordField({bool confirmation = false}) {
    final hidden = confirmation ? _hideConfirmation : _hidePassword;

    return _field(
      confirmation ? 'Confirm password' : 'Password',
      TextFormField(
        controller: confirmation ? _confirmPassword : _password,
        obscureText: hidden,
        autocorrect: false,
        enableSuggestions: false,
        decoration: _decoration(
          confirmation ? 'Re-enter password' : 'Enter password',
          Icons.lock_outline,
          helper: confirmation
              ? null
              : 'First letter capital · Minimum 6 characters · '
                  'One symbol · Numbers optional · No spaces',
          suffix: IconButton(
            tooltip: hidden ? 'Show password' : 'Hide password',
            icon: Icon(
              hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 21,
            ),
            onPressed: () {
              setState(() {
                if (confirmation) {
                  _hideConfirmation = !_hideConfirmation;
                } else {
                  _hidePassword = !_hidePassword;
                }
              });
            },
          ),
        ),
        validator: confirmation
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your password.';
                }

                return value == _password.text
                    ? null
                    : 'Passwords do not match.';
              }
            : _passwordError,
      ),
    );
  }

  // Emblem and welcome text.
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _AuthColors.softOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/images/emblem.png',
              width: 52,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance,
                size: 52,
                color: _AuthColors.orange,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'PWD PUBLIC WORKS PORTAL',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _AuthColors.orange,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isLogin ? 'Welcome back' : 'Join your community',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _AuthColors.navy,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to report issues and track progress.'
              : 'Create an account to help improve your area.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _AuthColors.muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Additional fields shown during account creation.
  List<Widget> _registrationFields() {
    return [
      _field(
        'Full name',
        TextFormField(
          controller: _name,
          readOnly: _isOfficer,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration(
            'Enter your full name',
            Icons.person_outline,
            helper: 'At least 2 characters. No numbers.',
          ),
          validator: _validateName,
        ),
      ),
      _field(
        'Email address',
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: _decoration(
            'name@example.com',
            Icons.mail_outline,
          ),
          validator: _emailError,
        ),
      ),
      _field(
        'Mobile number',
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: _decoration(
            '10-digit mobile number',
            Icons.phone_outlined,
            helper: 'Enter exactly 10 digits.',
          ),
          validator: _phoneError,
        ),
      ),
    ];
  }

  // Officer ID and the matching officer's details.
  List<Widget> _officerFields() {
    return [
      _field(
        'Officer ID',
        TextFormField(
          controller: _officerId,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: _decoration(
            'PWD-TN-CHN-0001',
            Icons.badge_outlined,
            helper: 'Format: PWD-TN-district code-4 digits.',
          ),
          validator: PwdLocations.validateOfficerId,
          onChanged: _idChanged,
        ),
      ),
      Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _AuthColors.border),
        ),
        child: Text(
          _record == null
              ? 'Enter an approved ID to fetch name, zone '
                  'and office address. Example: PWD-TN-CHN-0002.'
              : '${_record!.name}\n'
                  '${_record!.area.label}\n'
                  '${_record!.address}\n'
                  'Matched in directory; '
                  'not government verification.',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AuthColors.background,
      appBar: AppBar(
        backgroundColor: _AuthColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _AuthColors.navy,
        elevation: 0,
        title: Text(_isLogin ? 'Sign in' : 'Create account'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth < 380 ? 16.0 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                padding,
                12,
                padding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _AuthColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08023047),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AbsorbPointer(
                      absorbing: _busy,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _header(),
                            const SizedBox(height: 24),

                            // Account type buttons.
                            Row(
                              children: [
                                Expanded(
                                  child: _roleButton('Citizen', false),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _roleButton('PWD Officer', true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            if (!_isLogin) ..._registrationFields(),

                            // Citizen sign-in field.
                            if (_isLogin && !_isOfficer)
                              _field(
                                'Mobile number or email',
                                TextFormField(
                                  controller: _login,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  decoration: _decoration(
                                    'Enter your mobile number or email',
                                    Icons.person_outline,
                                  ),
                                  validator: _validateLogin,
                                ),
                              ),

                            if (_isOfficer) ..._officerFields(),

                            // Citizen registration address.
                            if (!_isLogin && !_isOfficer)
                              _field(
                                'Your address',
                                OutlinedButton.icon(
                                  onPressed: _chooseRegistrationAddress,
                                  icon: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  label: Text(
                                    _registrationPlace?.address ??
                                        'Type / search your address',
                                  ),
                                ),
                              ),

                            // Loading indicator and current step.
                            if (_busy) ...[
                              const LinearProgressIndicator(),
                              const SizedBox(height: 10),
                              Text(
                                _stage,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                            ],

                            _passwordField(),

                            if (!_isLogin) ...[
                              _passwordField(confirmation: true),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: _AuthColors.orange,
                                value: _acceptedTerms,
                                title: const Text(
                                  'I agree to the Terms and Privacy Policy',
                                  style: TextStyle(fontSize: 13),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _acceptedTerms = value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Open password reset.
                            if (_isLogin) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const _PasswordResetScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: _AuthColors.orange,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Submit the sign-in or registration form.
                            FilledButton(
                              onPressed: _busy ? null : _continue,
                              style: FilledButton.styleFrom(
                                backgroundColor: _AuthColors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 17,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _isLogin ? 'Sign in' : 'Create account',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextButton(
                              onPressed: _changeMode,
                              child: Text(
                                _isLogin
                                    ? 'New here? Create an account'
                                    : 'Already registered? Sign in',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _AuthColors.orange,
                                ),
                              ),
                            ),

                            // The temporary-account footer was removed.
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Open the correct dashboard and remove the authentication screens.
void _openDashboard(BuildContext context, bool officer) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => officer
          ? const OfficerDashboardScreen()
          : const CitizenDashboardScreen(),
    ),
    (_) => false,
  );
}

// REGISTRATION SUCCESS SCREEN
class _RegistrationCompleteScreen extends StatelessWidget {
  const _RegistrationCompleteScreen({
    required this.name,
    required this.isOfficer,
  });

  final String name;
  final bool isOfficer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AuthColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 42,
                        backgroundColor: Color(0xFFE8F6EC),
                        child: Icon(
                          Icons.check,
                          color: Color(0xFF19864C),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Registration successful',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _AuthColors.navy,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome, $name.\n'
                        'Your account details are ready.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _AuthColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _AuthColors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _openDashboard(context, isOfficer);
                        },
                        child: const Text('Go to dashboard'),
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

// PASSWORD RESET SCREEN
class _PasswordResetScreen extends StatefulWidget {
  const _PasswordResetScreen();

  @override
  State<_PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<_PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  DemoResetChallenge? _challenge;

  Timer? _timer;
  DateTime? _resendAt;

  int _cooldown = 0;

  // 0 = enter email, 1 = verify OTP, 2 = set new password.
  int _step = 0;

  bool _hidePassword = true;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  // Generate a code using the existing local account store.
  void _requestCode() {
    if (_cooldown > 0) return;

    if (_step == 0 && !_formKey.currentState!.validate()) {
      return;
    }

    try {
      final challenge =
          DemoAccountStore.requestPasswordReset(_email.text);

      _otp.clear();
      _password.clear();
      _confirm.clear();

      setState(() {
        _challenge = challenge;
        _step = 1;
        _cooldown = 30;
        _resendAt = DateTime.now().add(
          const Duration(seconds: 30),
        );
      });

      _timer?.cancel();

      // Update the resend countdown every second.
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          final milliseconds =
              _resendAt!.difference(DateTime.now()).inMilliseconds;

          final seconds = (milliseconds / 1000).ceil();

          setState(() {
            _cooldown = seconds > 0 ? seconds : 0;
          });

          if (_cooldown == 0) timer.cancel();
        },
      );
    } on FormatException catch (error) {
      _message(error.message);
    }
  }

  // Check the six-digit code.
  void _verifyCode() {
    if (!_formKey.currentState!.validate()) return;

    try {
      _challenge!.verify(_otp.text);
      setState(() => _step = 2);
    } on FormatException catch (error) {
      _message(error.message);
    }
  }

  // Save the new password using the existing account store.
  void _savePassword() {
    if (!_formKey.currentState!.validate()) return;

    try {
      _challenge!.resetPassword(_password.text);

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed. Sign in with your new password.',
          ),
        ),
      );
    } on FormatException catch (error) {
      _message(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Forgot your password?',
      'Verify your code',
      'Create a new password',
    ];

    final buttonLabels = [
      'Request OTP',
      'Verify OTP',
      'Save new password',
    ];

    return Scaffold(
      backgroundColor: _AuthColors.background,
      appBar: AppBar(
        title: const Text('Reset password'),
        backgroundColor: _AuthColors.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.lock_reset,
                            size: 52,
                            color: _AuthColors.orange,
                          ),
                          const SizedBox(height: 20),

                          Text(
                            titles[_step],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _AuthColors.navy,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            _step == 0
                                ? 'Enter the email used to register.'
                                : 'Account: ${_email.text.trim()}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // STEP 1: Email address.
                          if (_step == 0)
                            TextFormField(
                              key: const ValueKey('reset-email'),
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: _emailError,
                            ),

                          // STEP 2: Display and verify the OTP.
                          if (_step == 1) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _AuthColors.softOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'OTP: ${_challenge!.demoCode}\n'
                                'No email was sent. '
                                'Valid for 5 minutes.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              key: const ValueKey('reset-otp'),
                              controller: _otp,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              decoration: const InputDecoration(
                                labelText: '6-digit OTP',
                                prefixIcon: Icon(Icons.pin_outlined),
                              ),
                              validator: (value) {
                                return RegExp(r'^\d{6}$')
                                        .hasMatch(value ?? '')
                                    ? null
                                    : 'Enter all 6 digits.';
                              },
                            ),
                          ],

                          // STEP 3: New password and confirmation.
                          if (_step == 2) ...[
                            TextFormField(
                              key: const ValueKey('reset-password'),
                              controller: _password,
                              obscureText: _hidePassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: InputDecoration(
                                labelText: 'New password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                ),
                                helperText:
                                    'First letter capital · '
                                    'Minimum 6 characters · '
                                    'One symbol · Numbers optional · '
                                    'No spaces',
                                helperMaxLines: 4,
                                suffixIcon: IconButton(
                                  tooltip: _hidePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () {
                                    setState(() {
                                      _hidePassword = !_hidePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: _passwordError,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              key: const ValueKey('reset-confirm'),
                              controller: _confirm,
                              obscureText: _hidePassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                labelText: 'Confirm new password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value != _password.text) {
                                  return 'Passwords must match.';
                                }

                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 24),

                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _AuthColors.orange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _step == 0
                                ? _requestCode
                                : _step == 1
                                    ? _verifyCode
                                    : _savePassword,
                            child: Text(buttonLabels[_step]),
                          ),

                          if (_step > 0)
                            TextButton(
                              onPressed:
                                  _cooldown == 0 ? _requestCode : null,
                              child: Text(
                                _cooldown > 0
                                    ? 'Request another code in '
                                        '${_cooldown}s'
                                    : 'Request another code',
                              ),
                            ),

                          // The password-reset footer was removed.
                        ],
                      ),
                    ),
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