import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/Login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Import des dashboards
import 'dashboards/ApprenantDashboardScreen.dart';
import 'dashboards/FormateurDashboardScreen.dart';

// Instance globale pour les notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialisation des fuseaux horaires pour les notifications programmées
  tz.initializeTimeZones();
  
  // Configuration des notifications locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // Lancement du rappel quotidien automatique
  await _scheduleDailyNotification();

  runApp(const MyApp());
}

// Fonction pour programmer le rappel quotidien style Duolingo
Future<void> _scheduleDailyNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'duo_reminder_channel',
    'Rappels quotidiens',
    channelDescription: 'Notification pour vous rappeler de faire vos exercices',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  // Exemple : Programmer une notification tous les jours à 18h00
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18, 0);
  
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id: 0,
    title: 'C\'est l\'heure de réviser ! 🦉',
    body: 'Maintiens ta série du jour en venant t\'entraîner un peu.',
    scheduledDate: scheduledDate,
    notificationDetails: details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Duolingo Malagasy',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF58CC02),
          primary: const Color(0xFF58CC02),
        ),
      ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF58CC02))),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Login();
        }

        User user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF58CC02))),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Login();
            }

            var data = userSnapshot.data!.data() as Map<String, dynamic>?;
            String role = (data?['role'] ?? 'apprenant').toString().toLowerCase();

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