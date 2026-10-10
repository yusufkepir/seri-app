import 'package:flutter/material.dart';

import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(HabitApp(store: store));
}

class HabitApp extends StatelessWidget {
  final AppStore store;
  const HabitApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3F51B5),
      ),
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) => store.track == null
            ? OnboardingScreen(store: store)
            : HomeScreen(store: store),
      ),
    );
  }
}
