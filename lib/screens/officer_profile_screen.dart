import 'package:flutter/material.dart';

import '../theme/pwd_theme.dart';
import '../widgets/pwd_widgets.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';

// Shows officer details and lets the officer edit their contact information.
class OfficerProfileScreen extends StatefulWidget {
  const OfficerProfileScreen({super.key});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  // This profile stays in memory while the app is open.
  ProfileDetails _profile = DemoProfiles.officer;

  Future<void> _openEditProfile() async {
    final updatedProfile = await Navigator.push<ProfileDetails>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          details: _profile,
          isOfficer: true,
        ),
      ),
    );

    if (mounted && updatedProfile != null) {
      setState(() {
        _profile = updatedProfile;
        DemoProfiles.officer = updatedProfile;
      });
    }
  }

  void _logOut() {
    PwdDemoSession.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PwdPage(
      title: 'Officer profile',
      back: () => Navigator.pop(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),
              const CircleAvatar(
                radius: 42,
                child: Icon(Icons.badge_outlined, size: 46),
              ),
              const SizedBox(height: 10),
              Text(
                _profile.name,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _OfficerDetail(label: 'Officer ID', value: _profile.officerId),
              _OfficerDetail(label: 'Email', value: _profile.email),
              _OfficerDetail(label: 'Phone', value: _profile.phone),
              const _OfficerDetail(
                label: 'Department',
                value: 'Public Works Department',
              ),
              _OfficerDetail(
                label: 'Assigned zone',
                value: PwdDemoSession.officerArea?.label ?? 'Not assigned',
              ),
              const SizedBox(height: 12),
              PwdButton(
                'Edit profile',
                icon: Icons.edit_outlined,
                onPressed: _openEditProfile,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _logOut,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PwdColors.logout,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable card for one officer profile field.
class _OfficerDetail extends StatelessWidget {
  const _OfficerDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
