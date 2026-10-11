import 'package:flutter/material.dart';

import '../models/pwd_report.dart';
import '../services/citizen_location_store.dart';
import '../services/report_store.dart';
import '../widgets/pwd_location_fields.dart';

import 'auth_screen.dart';
import 'officer_complaint_details_screen.dart';
import 'officer_profile_screen.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() =>
      _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  static const _orange = Color(0xFFED783E);
  static const _navy = Color(0xFF163844);
  static const _muted = Color(0xFF687880);
  static const _background = Color(0xFFF8FAFB);
  static const _softOrange = Color(0xFFFFEEE4);

  int _tab = 0;
  PwdAreaSelection? _area;

  @override
  void initState() {
    super.initState();
    _area = PwdDemoSession.officerArea;
  }

  void _logout() {
    PwdDemoSession.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  Future<void> _editProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OfficerProfileScreen()),
    );
    if (mounted) setState(() {});
  }

  List<PwdReport> _reportsForArea(ReportStore store) {
    final area = _area;
    if (area == null) return [];

    return store.reports
        .where((report) => ReportAreaStore.matches(report.id, area))
        .toList();
  }

  void _openReport(PwdReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfficerComplaintDetailsScreen(
          report: report,
          officerId: PwdDemoSession.officerId,
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDDE5E9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  // Displays the officer's assigned area without opening a transfer page.
  Widget _serviceAreaCard() {
    return _card(
      ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: _softOrange,
          child: Icon(Icons.location_on_outlined, color: _orange),
        ),
        title: const Text(
          'Your service area',
          style: TextStyle(fontWeight: FontWeight.bold, color: _navy),
        ),
        subtitle: Text(_area == null ? 'Not assigned' : _area!.label),
      ),
    );
  }

  Widget _stat(
    double width,
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: width,
      child: _card(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(title, style: const TextStyle(color: _muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportCard(PwdReport report) {
    final color = switch (report.status) {
      ReportStatus.completed => const Color(0xFF19864C),
      ReportStatus.rejected => const Color(0xFFCF4444),
      ReportStatus.inProgress => const Color(0xFF2563EB),
      _ => const Color(0xFFB97716),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        InkWell(
          onTap: () => _openReport(report),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                        color: _orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.status.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
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
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  ReportAreaStore.find(report.id)?.area.label ??
                      report.location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text('Urgency: ${report.urgency}'),
                    Text('${report.mediaCount} attachments'),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Review complaint',
                        style: TextStyle(
                          color: _orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: _orange, size: 20),
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
    return _card(
      const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, color: _muted, size: 44),
            SizedBox(height: 12),
            Text(
              'No complaints in this area',
              textAlign: TextAlign.center,
              style: TextStyle(color: _navy, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'New complaints matching your district and locality '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _home(List<PwdReport> reports) {
    final active = reports
        .where(
          (report) =>
              report.status != ReportStatus.completed &&
              report.status != ReportStatus.rejected,
        )
        .length;

    final working = reports
        .where((report) => report.status == ReportStatus.inProgress)
        .length;

    final completed = reports
        .where((report) => report.status == ReportStatus.completed)
        .length;

    return [
      Text(
        'Welcome, ${PwdDemoSession.name}',
        style: const TextStyle(
          color: _navy,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Review complaints and keep your community informed.',
        style: TextStyle(color: _muted),
      ),
      const SizedBox(height: 20),
      _serviceAreaCard(),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _softOrange,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.engineering_outlined, color: _orange, size: 46),
            const SizedBox(height: 14),
            const Text(
              'Better public works.\nStronger communities.',
              style: TextStyle(
                color: _navy,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Inspect the complaint, review the evidence '
              'and update the work status.',
              style: TextStyle(color: _muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => setState(() => _tab = 1),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('View complaints'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Overview',
        style: TextStyle(
          color: _navy,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 600 ? 4 : 2;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _stat(
                width,
                'Total',
                reports.length,
                Icons.assignment_outlined,
                _orange,
              ),
              _stat(
                width,
                'Active',
                active,
                Icons.pending_actions,
                const Color(0xFFB97716),
              ),
              _stat(
                width,
                'In progress',
                working,
                Icons.construction,
                const Color(0xFF2563EB),
              ),
              _stat(
                width,
                'Completed',
                completed,
                Icons.task_alt,
                const Color(0xFF19864C),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      const Text(
        'Recent complaints',
        style: TextStyle(
          color: _navy,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      if (reports.isEmpty) _emptyReports(),
      ...reports.take(3).map(_reportCard),
      if (reports.length > 3)
        TextButton(
          onPressed: () => setState(() => _tab = 1),
          child: const Text('View all complaints'),
        ),
    ];
  }

  List<Widget> _profile() {
    return [
      _card(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: _softOrange,
                child: Icon(Icons.badge_outlined, color: _orange, size: 38),
              ),
              const SizedBox(height: 16),
              Text(
                PwdDemoSession.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(PwdDemoSession.officerId),
              if (PwdDemoSession.email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(PwdDemoSession.email, textAlign: TextAlign.center),
              ],
              if (PwdDemoSession.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(PwdDemoSession.phone),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      _serviceAreaCard(),
      const SizedBox(height: 16),
      _card(
        ListTile(
          leading: const Icon(Icons.edit_outlined, color: _orange),
          title: const Text('Edit profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _editProfile,
        ),
      ),
      const SizedBox(height: 16),
      _card(
        ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: const Icon(Icons.logout, color: _orange),
          title: const Text('Switch account / log out'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _logout,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final store = ReportStoreScope.of(context);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _navy,

        // Show a back arrow on the Complaints tab.
        leading: _tab == 1
            ? IconButton(
                tooltip: 'Back to Home',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _tab = 0;
                  });
                },
              )
            : null,

        title: Text(
          ['PWD Officer Portal', 'Area complaints', 'Officer profile'][_tab],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: _softOrange,
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: _orange),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: _orange),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _orange),
            label: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final reports = _reportsForArea(store);

            return LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth > 900
                    ? (constraints.maxWidth - 860) / 2
                    : 16.0;

                return ListView(
                  padding: EdgeInsets.fromLTRB(padding, 16, padding, 24),
                  children: [
                    if (_tab == 0) ..._home(reports),
                    if (_tab == 1) ...[
                      _serviceAreaCard(),
                      const SizedBox(height: 24),
                      Text(
                        '${reports.length} complaints in your area',
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (reports.isEmpty) _emptyReports(),
                      ...reports.map(_reportCard),
                    ],
                    if (_tab == 2) ..._profile(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}