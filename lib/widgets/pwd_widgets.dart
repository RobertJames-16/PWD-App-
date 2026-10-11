import 'package:flutter/material.dart';

import '../models/pwd_report.dart';
import '../theme/pwd_theme.dart';

// Shared screen background, app bar, and optional bottom navigation.
class PwdPage extends StatelessWidget {
  const PwdPage({
    required this.title,
    required this.child,
    this.back,
    this.bottomNavigationBar,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback? back;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    // Allow more title space when the phone uses larger text.
    final titleHeight = MediaQuery.textScalerOf(context).scale(19);

    final toolbarHeight =
        (titleHeight * 2 + 16).clamp(56.0, double.infinity).toDouble();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: PwdColors.background,
      appBar: AppBar(
        toolbarHeight: toolbarHeight,
        backgroundColor: PwdColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        leading: back == null
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: back,
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: PwdColors.pageGradient,
        ),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PwdSizes.contentMaxWidth,
              ),
              child: SizedBox(
                width: double.infinity,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Bottom navigation used by the citizen and officer screens.
class PwdBottomNavigationBar extends StatelessWidget {
  const PwdBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: Colors.white,
      indicatorColor: PwdColors.softOrange,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(
            Icons.home,
            color: PwdColors.darkOrange,
          ),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(
            Icons.assignment,
            color: PwdColors.darkOrange,
          ),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(
            Icons.person,
            color: PwdColors.darkOrange,
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}

// Centers selection buttons.
// Wrap moves buttons to another line when space is limited.
class PwdChoiceButtons extends StatelessWidget {
  const PwdChoiceButtons({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: options.map((option) {
              final selected = option == value;

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                ),
                child: ChoiceChip(
                  label: Text(
                    option,
                    textAlign: TextAlign.center,
                  ),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: PwdColors.softOrange,
                  backgroundColor: Colors.white,
                  labelStyle: const TextStyle(
                    color: PwdColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  onSelected: (_) => onChanged(option),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// Compact banner with a small illustration beside its heading.
// No fixed height is applied to the text or the entire banner.
class PwdIllustrationBanner extends StatelessWidget {
  const PwdIllustrationBanner({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            PwdColors.softOrange,
            Color(0xFFFFF8F0),
          ],
        ),
        borderRadius: BorderRadius.circular(
          PwdSizes.cardCornerRadius,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final illustrationWidth =
              constraints.maxWidth < 280 ? 56.0 : 80.0;

          final largeText =
              MediaQuery.textScalerOf(context).scale(18) > 27;

          // On very narrow screens or with much larger text,
          // give the heading the full width.
          final stackIllustration =
              constraints.maxWidth < 220 || largeText;

          const headingStyle = TextStyle(
            color: PwdColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.3,
          );

          final illustration = SizedBox(
            width: illustrationWidth,
            height: 64,
            child: const CustomPaint(
              painter: _CityRoadPainter(),
            ),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stackIllustration)
                Text(title, style: headingStyle)
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: headingStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    illustration,
                  ],
                ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  color: PwdColors.muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (stackIllustration) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: illustration,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// Draws the decorative city illustration using Flutter shapes.
class _CityRoadPainter extends CustomPainter {
  const _CityRoadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..isAntiAlias = true;

    // Sky.
    paint.color = const Color(0xFFDDF1F6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(12),
      ),
      paint,
    );

    // Sun.
    paint.color = PwdColors.orange;
    canvas.drawCircle(
      Offset(w * .82, h * .22),
      h * .12,
      paint,
    );

    // First building.
    paint.color = const Color(0xFF7CC7C2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * .12,
          h * .35,
          w * .3,
          h * .48,
        ),
        const Radius.circular(4),
      ),
      paint,
    );

    // Second building.
    paint.color = PwdColors.navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * .48,
          h * .2,
          w * .28,
          h * .63,
        ),
        const Radius.circular(4),
      ),
      paint,
    );

    // Windows.
    paint.color = const Color(0xFFFFE8A8);

    for (final x in [.18, .3, .54, .65]) {
      for (final y in [.4, .55, .7]) {
        canvas.drawRect(
          Rect.fromLTWH(
            w * x,
            h * y,
            w * .05,
            h * .08,
          ),
          paint,
        );
      }
    }

    // Grass.
    paint.color = PwdColors.statusGreen;
    canvas.drawRect(
      Rect.fromLTWH(0, h * .82, w, h * .18),
      paint,
    );

    // Road.
    paint.color = const Color(0xFF34495E);

    final road = Path()
      ..moveTo(w * .25, h)
      ..lineTo(w * .86, h * .65)
      ..lineTo(w, h * .65)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(road, paint);

    // Road markings.
    paint
      ..color = Colors.white
      ..strokeWidth = w * .025;

    canvas.drawLine(
      Offset(w * .6, h * .9),
      Offset(w * .7, h * .83),
      paint,
    );

    canvas.drawLine(
      Offset(w * .8, h * .78),
      Offset(w * .9, h * .71),
      paint,
    );

    // Tree trunk.
    paint.color = const Color(0xFF795548);
    canvas.drawRect(
      Rect.fromLTWH(
        w * .08,
        h * .65,
        w * .035,
        h * .2,
      ),
      paint,
    );

    // Tree leaves.
    paint.color = PwdColors.statusGreen;
    canvas.drawCircle(
      Offset(w * .095, h * .59),
      w * .1,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CityRoadPainter oldDelegate) => false;
}

// Shared main action button.
// A minimum height lets the button grow when its text wraps.
class PwdButton extends StatelessWidget {
  const PwdButton(
    this.label, {
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? PwdColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, PwdSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              PwdSizes.inputCornerRadius,
            ),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Heading used above sections such as Location and My reports.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: PwdColors.navy,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// Colored label showing a report's current status.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReportStatus.submitted => PwdColors.navy,
      ReportStatus.underReview => Colors.deepPurple,
      ReportStatus.workAssigned => PwdColors.statusGreen,
      ReportStatus.inProgress => PwdColors.amber,
      ReportStatus.completed => PwdColors.statusGreen,
      ReportStatus.rejected => PwdColors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          PwdSizes.statusPillRadius,
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: PwdSizes.statusPillFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// Report information uses the full card width and wraps naturally.
class ReportCard extends StatelessWidget {
  const ReportCard({
    required this.report,
    this.onTap,
    super.key,
  });

  final PwdReport report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${report.id} · ${report.category}',
                style: const TextStyle(
                  color: PwdColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(report.location),
              const SizedBox(height: 10),
              StatusPill(report.status),
            ],
          ),
        ),
      ),
    );
  }
}

// Message displayed when a list contains no reports.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 48,
            color: PwdColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}