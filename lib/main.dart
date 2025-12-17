import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ower_project/pages/Admin_Dashboard.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uni Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginFormLayout(),
      routes: {
        '/login': (context) => const LoginFormLayout(),
        "/adminDashboard": (context) => const AdminDashboard(),
      },
    );
  }
}