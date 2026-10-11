import 'package:flutter/material.dart';

import '../models/pwd_report.dart';
import '../services/citizen_location_store.dart';
import '../services/report_store.dart';

import 'auth_screen.dart';
import 'citizen_place_picker_screen.dart';
import 'citizen_profile_screen.dart';
import 'issue_details_screen.dart';
import 'notification_screen.dart';
import 'report_progress_screen.dart';

// Change these colours to customise this dashboard.
class _DashboardColors {
  static const orange = Color(0xFFED783E);
  static const navy = Color(0xFF163844);
  static const muted = Color(0xFF687880);
  static const background = Color(0xFFF8FAFB);
  static const softOrange = Color(0xFFFFEEE4);
  static const border = Color(0xFFDDE5E9);
}

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() =>
      _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState
    extends State<CitizenDashboardScreen> {
  int _selectedTab = 0;

  Future<void> _chooseLocation() async {
    final place = await Navigator.push<CitizenPlace>(
      context,
      MaterialPageRoute(
        builder: (_) => CitizenPlacePickerScreen(
          initialPlace: CitizenLocationStore.savedPlace.value,
        ),
      ),
    );

    if (!mounted || place == null) return;

    CitizenLocationStore.save(place);
  }

  Future<void> _openComplaint(String category) async {
    if (CitizenLocationStore.savedPlace.value == null) {
      await _chooseLocation();
    }

    if (!mounted ||
        CitizenLocationStore.savedPlace.value == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IssueDetailsScreen(category: category),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CitizenProfileScreen(),
      ),
    );

    if (mounted) setState(() {});
  }

  void _logout() {
    PwdDemoSession.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  void _showReports() {
    setState(() => _selectedTab = 1);
  }

  @override
  Widget build(BuildContext context) {
    final store = ReportStoreScope.of(context);

    return Scaffold(
      backgroundColor: _DashboardColors.background,
      appBar: AppBar(
        leading: _selectedTab == 1
    ? IconButton(
        tooltip: 'Back to Home',
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _selectedTab = 0; // Return to the Home tab.
          });
        },
      )
    : null,
        backgroundColor: _DashboardColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _DashboardColors.navy,
        title: Text(
          ['PWD Citizen Portal', 'My reports', 'My profile'][
              _selectedTab],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Notifications only; no top-right profile button.
        actions: [
          AnimatedBuilder(
            animation: store,
            builder: (context, _) => IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (store.unreadNotificationCount > 0)
                    const Positioned(
                      top: -2,
                      right: -2,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: _DashboardColors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: _DashboardColors.softOrange,
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home,
              color: _DashboardColors.orange,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(
              Icons.assignment,
              color: _DashboardColors.orange,
            ),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person,
              color: _DashboardColors.orange,
            ),
            label: 'Profile',
          ),
        ],
      ),

      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              // Keep desktop content centred and phone content spacious.
              final horizontalPadding =
                  constraints.maxWidth > 900
                      ? (constraints.maxWidth - 860) / 2
                      : 16.0;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  24,
                ),
                children: [
                  if (_selectedTab == 0)
                    ..._homeContent(store),
                  if (_selectedTab == 1)
                    ..._reportsContent(store),
                  if (_selectedTab == 2)
                    ..._profileContent(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _homeContent(ReportStore store) {
    return [
      _locationCard(),
      const SizedBox(height: 24),

      Text(
        'Hello, ${PwdDemoSession.name}',
        style: const TextStyle(
          color: _DashboardColors.navy,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Let’s make your neighbourhood better.',
        style: TextStyle(
          color: _DashboardColors.muted,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 20),

      _heroCard(),
      const SizedBox(height: 24),

      _sectionTitle(
        'Report an issue',
        action: TextButton(
          onPressed: _showReports,
          child: Text(
            '${store.citizenReports.length} reports',
            style: const TextStyle(
              color: _DashboardColors.orange,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),

      // Cards have natural height instead of a fixed grid height.
      LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 520;
          final width = twoColumns
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _categoryCard(
                width,
                'Pothole / Road',
                'Damaged road surface',
                Icons.add_road,
              ),
              _categoryCard(
                width,
                'Drainage',
                'Blocked or damaged drain',
                Icons.water_damage_outlined,
              ),
              _categoryCard(
                width,
                'Street light',
                'Light not working',
                Icons.lightbulb_outline,
              ),
              _categoryCard(
                width,
                'Pavement',
                'Footpath needs repair',
                Icons.directions_walk_outlined,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 12),

      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: _DashboardColors.orange,
          side: const BorderSide(
            color: _DashboardColors.border,
          ),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _openComplaint('Other issue'),
        icon: const Icon(Icons.edit_note),
        label: const Text('Report another issue'),
      ),
      const SizedBox(height: 24),

      _sectionTitle(
        'Recent reports',
        action: TextButton(
          onPressed: _showReports,
          child: const Text(
            'View all',
            style: TextStyle(color: _DashboardColors.orange),
          ),
        ),
      ),
      const SizedBox(height: 12),

      if (store.citizenReports.isEmpty) _emptyReports(),
      ...store.citizenReports.take(2).map(_reportCard),
    ];
  }

  Widget _locationCard() {
    return ValueListenableBuilder<CitizenPlace?>(
      valueListenable: CitizenLocationStore.savedPlace,
      builder: (context, place, _) => _whiteCard(
        child: InkWell(
          onTap: _chooseLocation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _iconBox(Icons.location_on_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR LOCATION',
                        style: TextStyle(
                          color: _DashboardColors.muted,
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        place?.area.label ?? 'Choose your location',
                        style: const TextStyle(
                          color: _DashboardColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (place != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          place.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _DashboardColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: _DashboardColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _DashboardColors.softOrange,
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A better street\nstarts with a report.',
                style: TextStyle(
                  color: _DashboardColors.navy,
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Report public works issues and follow '
                'the department’s progress.',
                style: TextStyle(
                  color: _DashboardColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          );

          final illustration = SizedBox(
            width: 190,
            height: 145,
            child: CustomPaint(
              painter: _StreetIllustrationPainter(),
            ),
          );

          // Stack the illustration below text on narrow screens.
          if (constraints.maxWidth < 580) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: illustration,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 20),
              illustration,
            ],
          );
        },
      ),
    );
  }

  Widget _categoryCard(
    double width,
    String title,
    String description,
    IconData icon,
  ) {
    return SizedBox(
      width: width,
      child: _whiteCard(
        child: InkWell(
          onTap: () => _openComplaint(title),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _iconBox(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _DashboardColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(
                          color: _DashboardColors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: _DashboardColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _reportsContent(ReportStore store) {
    return [
      const Text(
        'Track your complaints',
        style: TextStyle(
          color: _DashboardColors.navy,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Open a report to view its status and progress.',
        style: TextStyle(color: _DashboardColors.muted),
      ),
      const SizedBox(height: 20),
      if (store.citizenReports.isEmpty) _emptyReports(),
      ...store.citizenReports.map(_reportCard),
    ];
  }

  Widget _reportCard(PwdReport report) {
    final statusColor = switch (report.status) {
      ReportStatus.completed => const Color(0xFF19864C),
      ReportStatus.rejected => const Color(0xFFCF4444),
      ReportStatus.inProgress => const Color(0xFF2563EB),
      _ => const Color(0xFFB97716),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _whiteCard(
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportProgressScreen(report: report),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      report.id,
                      style: const TextStyle(
                        color: _DashboardColors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  report.category,
                  style: const TextStyle(
                    color: _DashboardColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DashboardColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Track progress',
                        style: TextStyle(
                          color: _DashboardColors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: _DashboardColors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyReports() {
    return _whiteCard(
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 44,
              color: _DashboardColors.muted,
            ),
            SizedBox(height: 12),
            Text(
              'No reports yet',
              style: TextStyle(
                color: _DashboardColors.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your submitted complaints will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _DashboardColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _profileContent() {
    return [
      _whiteCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: _DashboardColors.softOrange,
                child: Icon(
                  Icons.person_outline,
                  size: 38,
                  color: _DashboardColors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                PwdDemoSession.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _DashboardColors.navy,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (PwdDemoSession.email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  PwdDemoSession.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _DashboardColors.muted,
                  ),
                ),
              ],
              if (PwdDemoSession.phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  PwdDemoSession.phone,
                  style: const TextStyle(
                    color: _DashboardColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      _profileAction(
        'View / edit profile',
        Icons.manage_accounts_outlined,
        _openProfile,
      ),
      _profileAction(
        'Change saved location',
        Icons.location_on_outlined,
        _chooseLocation,
      ),
      _profileAction(
        'Switch account / log out',
        Icons.logout,
        _logout,
      ),
    ];
  }

  Widget _profileAction(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _whiteCard(
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: _iconBox(icon),
          title: Text(
            title,
            style: const TextStyle(
              color: _DashboardColors.navy,
              fontSize: 14,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? action}) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _DashboardColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DashboardColors.softOrange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 24,
        color: _DashboardColors.orange,
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: _DashboardColors.border,
        ),
      ),
      child: child,
    );
  }
}

// Draws a simple 2D street illustration.
// No image file or extra package is required.
class _StreetIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Design coordinates are scaled to the widget size.
    canvas.scale(size.width / 190, size.height / 145);

    final paint = Paint();

    paint.color = const Color(0xFFDFF1F6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 190, 145),
        const Radius.circular(24),
      ),
      paint,
    );

    paint.color = const Color(0xFFED783E);
    canvas.drawCircle(const Offset(160, 28), 18, paint);

    paint.color = const Color(0xFF79C5BE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 50, 55, 83),
        const Radius.circular(6),
      ),
      paint,
    );

    paint.color = const Color(0xFF163844);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(105, 28, 50, 105),
        const Radius.circular(6),
      ),
      paint,
    );

    // Building windows.
    paint.color = const Color(0xFFFFEAA7);

    for (final x in [42.0, 64.0]) {
      for (final y in [61.0, 83.0, 105.0]) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, 10, 13),
          paint,
        );
      }
    }

    for (final x in [115.0, 136.0]) {
      for (final y in [40.0, 64.0, 88.0]) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, 9, 13),
          paint,
        );
      }
    }

    // Ground.
    paint.color = const Color(0xFF238264);
    canvas.drawRect(
      const Rect.fromLTWH(0, 122, 190, 23),
      paint,
    );

    // Tree trunk and leaves.
    paint.color = const Color(0xFF876650);
    canvas.drawRect(
      const Rect.fromLTWH(17, 94, 7, 35),
      paint,
    );

    paint.color = const Color(0xFF238264);
    canvas.drawCircle(const Offset(20, 92), 20, paint);

    // Road.
    paint.color = const Color(0xFF354D5E);
    final road = Path()
      ..moveTo(65, 145)
      ..lineTo(166, 104)
      ..lineTo(190, 104)
      ..lineTo(190, 145)
      ..close();

    canvas.drawPath(road, paint);

    // Road markings.
    paint
      ..color = Colors.white
      ..strokeWidth = 4;

    canvas.drawLine(
      const Offset(111, 133),
      const Offset(128, 125),
      paint,
    );
    canvas.drawLine(
      const Offset(146, 119),
      const Offset(163, 111),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _StreetIllustrationPainter oldDelegate,
  ) {
    return false;
  }
}
