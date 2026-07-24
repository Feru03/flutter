import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Ici tu mets tes variables et tes contrôleurs
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Bienvenue sur les cours de Malgache')),
    const Center(child: Text('Gestion des cours')),
    const Center(child: Text('Profil')),
  ];

  @override
  Widget build(BuildContext context) {
    // Ici tu mets le code de l'interface (Scaffold, Column, TextField, etc.)

    return Scaffold(
      appBar: AppBar(title: const Text('Espace formateur')),
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
            label: 'Mes modules'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_4_rounded),
            label: 'Profil',
          )
        ],
      ),
    );
  }
}
