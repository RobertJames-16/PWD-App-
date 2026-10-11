import 'package:flutter/material.dart';

import '../theme/pwd_theme.dart';
import '../services/citizen_location_store.dart';
import '../widgets/pwd_widgets.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';

// Displays citizen profile details and opens the edit form.
class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  // This profile stays in memory while the app is open.
  ProfileDetails _profile = DemoProfiles.citizen;

  Future<void> _openEditProfile() async {
    final updatedProfile = await Navigator.push<ProfileDetails>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(details: _profile),
      ),
    );

    // The editor returns null if the user presses Back without saving.
    if (mounted && updatedProfile != null) {
      setState(() {
        _profile = updatedProfile;
        DemoProfiles.citizen = updatedProfile;
      });
    }
  }

  void _logOut() {
    PwdDemoSession.signOut();
    // Remove the profile and dashboard pages, then show sign in.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PwdPage(
      title: 'My profile',
      back: () => Navigator.pop(context),
      child: Center(
        // The page can scroll on short screens and stays a comfortable width on tablets.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),
              const CircleAvatar(
                radius: 42,
                child: Icon(Icons.person_outline, size: 46),
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
              _ProfileLine(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: _profile.phone,
              ),
              _ProfileLine(
                icon: Icons.email_outlined,
                label: 'Email',
                value: _profile.email,
              ),
              ValueListenableBuilder<CitizenPlace?>(
                valueListenable: CitizenLocationStore.savedPlace,
                builder: (_, place, __) => _ProfileLine(icon: Icons.location_on_outlined,
                  label: 'Address', value: place == null ? 'No saved address' : '${place.address}\n${place.area.label}'),
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

// One row of profile information, displayed as a card.
class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
