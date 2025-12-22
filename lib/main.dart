import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ower_project/pages/Admin_Dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://knbgdstmexoujmoejnbe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuYmdkc3RtZXhvdWptb2VqbmJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzMzYxNTQsImV4cCI6MjA4MTkxMjE1NH0.tHyGySUAFn4DaWb1tLWauVHtaQzXDl5_VbTibTIWC4I',
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