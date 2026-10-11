import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/citizen_location_store.dart';
import 'services/demo_account_store.dart';
import 'services/report_store.dart';
import 'theme/pwd_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to Supabase before starting the app.
  await Supabase.initialize(
    url: 'https://mgfhyoiuwkqpuqvyjlqq.supabase.co',
    publishableKey: 'YOUR_PUBLISHABLE_KEY',
  );

  // A new app run starts from the beginning.
  DemoAccountStore.resetForNewRun();
  ReportAreaStore.reset();

  runApp(const PwdPortalApp());
}

class PwdPortalApp extends StatefulWidget {
  const PwdPortalApp({super.key});

  @override
  State<PwdPortalApp> createState() => _PwdPortalAppState();
}

class _PwdPortalAppState extends State<PwdPortalApp> {
  late final ReportStore _reportStore;

  @override
  void initState() {
    super.initState();

    // No sample complaints or notifications.
    _reportStore = ReportStore([]);
  }

  @override
  void dispose() {
    _reportStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReportStoreScope(
      store: _reportStore,
      child: MaterialApp(
        title: 'PWD Online Portal',
        debugShowCheckedModeBanner: false,
        theme: PwdTheme.data,
        home: const SplashScreen(),
      ),
    );
  }
}