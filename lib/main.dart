import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/Login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import des dashboards
import 'dashboards/ApprenantDashboardScreen.dart';
import 'dashboards/FormateurDashboardScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Duolingo Malagasy',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Si l'utilisateur n'est pas connecté du tout -> Page Login
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Login();
        }

        // 2. Utilisateur connecté -> On va chercher son rôle dans Firestore
        User user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Document introuvable, on renvoie vers le login
              return const Login();
            }

            var data = userSnapshot.data!.data() as Map<String, dynamic>?;
            String role = (data?['role'] ?? 'apprenant').toString().toLowerCase();

            // 3. Affichage direct du bon dashboard selon le rôle
            if (role == "formateur") {
              return const FormateurDashboardScreen();
            } else {
              return const ApprenantDashboardScreen();
            }
          },
        );
      },
    );
  }
}