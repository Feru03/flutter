import 'package:flutter/material.dart';
import '../pages/Profil.dart'; 
import '../pages/Modules.dart';
import '../dashboards/apprenant/Exercices.dart';

class ApprenantDashboardScreen extends StatefulWidget {
  const ApprenantDashboardScreen({super.key});

  @override
  State<ApprenantDashboardScreen> createState() =>
      _ApprenantDashboardScreenState();
}

class _ApprenantDashboardScreenState extends State<ApprenantDashboardScreen> {
  int _currentIndex = 0;

  // Liste des pages de l'apprenant
  final List<Widget> _pages = [
    Modules(),
    Exercices(), // Ici tu mettras la vue des cours
    Profil(), // On réutilise directement la page de profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace Apprenant')),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Mes modules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}