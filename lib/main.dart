import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dimple_erp/all pages/firebase_optional.dart';
import 'package:dimple_erp/ready stock/LoginScreen.dart';
import 'package:dimple_erp/all screen/MainScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sizer/sizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print("❌ Firebase init error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ERP System',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: const AppModeHandler(),
        );
      },
    );
  }
}

class AppModeHandler extends StatelessWidget {
  const AppModeHandler({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('settings')
              .doc('app_mode')
              .snapshots(),
          builder: (context, modeSnapshot) {

            if (!modeSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 🔥 Get mode
            String mode = "live";
            if (modeSnapshot.data!.data() != null) {
              mode = modeSnapshot.data!.get('mode') ?? "live";
            }

            final user = authSnapshot.data;

            print("🔥 CURRENT MODE: $mode");

            // =========================
            // 🔴 DEMO MODE
            // =========================
           if (mode == "demo") {
  return const LoginScreen(isDemo: true);
}


            // =========================
            // 🟢 LIVE MODE
            // =========================
         if (user != null) {
  return const MainScreen();
} else {
  return const LoginScreen(isDemo: false);
}
          },
        );
      },
    );
  }
}