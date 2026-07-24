import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'games/4images1mot.dart';
import 'games/motArelier.dart';
import 'games/phraseAtrou.dart';
import 'games/quiz.dart';
import 'games/audio.dart';

class Exercices extends StatefulWidget {
  const Exercices({super.key});

  @override
  State<Exercices> createState() => _ExercicesState();
}

class _ExercicesState extends State<Exercices> {
  String? _selectedModuleFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- SECTION FILTRES ---
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('exercises')
                .snapshots(),
            builder: (context, snapshot) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Filtrer : ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedModuleFilter,
                    hint: const Text("Tous les exercices"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Tous")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedModuleFilter = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),

        // --- LISTE DES EXERCICES DEPUIS FIRESTORE ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedModuleFilter == null
                ? FirebaseFirestore.instance.collection('exercises').snapshots()
                : FirebaseFirestore.instance
                      .collection('exercises')
                      .where('module', isEqualTo: _selectedModuleFilter)
                      .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Aucun exercice disponible pour le moment."),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final String title = data['title'] ?? 'Exercice sans titre';
                  final String type = data['type'] ?? 'quiz';
                  final int points = data['points'] ?? 10;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(_getIconForType(type), color: Colors.green),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Type : $type | Valeur : $points pts"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _navigateToExercise(context, type, data);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case '4 images 1 mot':
        return Icons.image;
      case 'quiz':
        return Icons.quiz;
      case 'phrases à trou':
        return Icons.edit;
      case 'mot à relier':
        return Icons.alt_route;
      case 'audio':
        return Icons.record_voice_over;
      default:
        return Icons.school;
    }
  }

  void _navigateToExercise(
    BuildContext context,
    String type,
    Map<String, dynamic> exerciseData,
  ) {
    Widget targetPage;

    switch (type) {
      case '4 images 1 mot':
        targetPage = Exercice4Images1MotPage(exerciseData: exerciseData);
        break;
      case 'quiz':
        targetPage = QuizPage(exerciseData: exerciseData);
        break;
      case 'phrases à trou':
        targetPage = PhraseATrouPage(exerciseData: exerciseData);
        break;
      case 'mot à relier':
        targetPage = MotARelierPage(exerciseData: exerciseData);
        break;
      case 'audio':
        targetPage = Audio(exerciseData: exerciseData);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Type d'exercice inconnu.")),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }
}