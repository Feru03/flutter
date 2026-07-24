import 'package:flutter/material.dart';
import 'formateur/Cours.dart';
import 'formateur/Exos.dart';
import '../pages/Modules.dart';
import '../pages/Profil.dart';

class FormateurDashboardScreen extends StatefulWidget {
  const FormateurDashboardScreen({super.key});

  @override
  State<FormateurDashboardScreen> createState() =>
      _FormateurDashboardScreenState();
}

class _FormateurDashboardScreenState extends State<FormateurDashboardScreen> {
  // Ici tu mets tes variables et tes contrôleurs
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Modules(),
    Cours(),
    Exos(),
    Profil(),
  ];

  @override
  Widget build(BuildContext context) {
    // Ici tu mets le code de l'interface (Scaffold, Column, TextField, etc.)

    return Scaffold(
      appBar: AppBar(title: const Text('Espace formateur')),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // Nécessaire pour 4 éléments ou plus
        selectedItemColor: Colors.green, // Icône et texte actifs en vert
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Mes Modules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Mes cours'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Mes exos'
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
