import 'package:flutter/material.dart';

import '../theme/pwd_theme.dart';
import '../widgets/pwd_widgets.dart';

// This remains a sample map until a real map service is connected.
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  String _location = 'Guindy Zone · Ward 168';

  static const _areas = [
    'Guindy Zone · Ward 168',
    'Adyar Zone',
    'Velachery Zone',
  ];

  Future<void> _changeArea() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeading('Choose a sample area'),
                ..._areas.map(
                  (area) => ListTile(
                    title: Text(area),
                    onTap: () {
                      Navigator.pop(sheetContext, area);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _location = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PwdPage(
      title: 'Select on map',
      back: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Only the artwork uses an aspect ratio; no form text is inside it.
          ClipRRect(
            borderRadius: BorderRadius.circular(
              PwdSizes.cardCornerRadius,
            ),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(
                    painter: _SampleMapPainter(),
                  ),
                  const Center(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.location_pin,
                        size: 38,
                        color: PwdColors.locationPin,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Sample map preview'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading('Sample area'),
                  Text(
                    _location,
                    style: const TextStyle(
                      color: PwdColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _changeArea,
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Change area'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PwdButton(
            'Confirm location',
            icon: Icons.check,
            onPressed: () {
              Navigator.pop(context, _location);
            },
          ),
        ],
      ),
    );
  }
}

// Road shapes scale with the map's available width and height.
class _SampleMapPainter extends CustomPainter {
  const _SampleMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..isAntiAlias = true;

    paint.color = PwdColors.mapBackground;
    canvas.drawRect(Offset.zero & size, paint);

    paint
      ..color = Colors.white
      ..strokeWidth = w * .07;

    canvas.drawLine(
      Offset(-w * .1, h * .45),
      Offset(w * 1.1, h * .25),
      paint,
    );

    canvas.drawLine(
      Offset(w * .3, h * 1.1),
      Offset(w * .95, -h * .1),
      paint,
    );

    paint.color = PwdColors.softGreen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * .62,
          h * .63,
          w * .27,
          h * .22,
        ),
        const Radius.circular(18),
      ),
      paint,
    );

    paint.color = PwdColors.statusGreen;
    canvas.drawCircle(
      Offset(w * .76, h * .74),
      w * .05,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SampleMapPainter oldDelegate) => false;
}