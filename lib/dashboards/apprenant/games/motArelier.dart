import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MotARelierPage extends StatefulWidget {
  final Map<String, dynamic> exerciseData;

  const MotARelierPage({super.key, required this.exerciseData});

  @override
  State<MotARelierPage> createState() => _MotARelierPageState();
}

class _MotARelierPageState extends State<MotARelierPage> {
  late final DateTime _startTime;
  bool _isSubmitting = false;

  late final List<dynamic> _paires;
  late final List<String> _leftItems;
  late final List<String> _rightItems;

  // Stocke les associations choisies par l'apprenant (index gauche -> index droite)
  final Map<int, int> _userAssociations = {};
  int? _selectedLeftIndex;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Initialisation sécurisée dans le initState pour éviter les recalculs dans le build
    _paires = widget.exerciseData['paires'] ?? [];
    _leftItems = _paires.map((p) => p['gauche'].toString()).toList();
    _rightItems = _paires.map((p) => p['droite'].toString()).toList();
  }

  Future<void> _validateAnswer() async {
    if (_userAssociations.length < _paires.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tu dois relier toutes les paires avant de valider.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Vérification de la justesse : chaque paire a un ordre initial exact (gauche[i] va avec droite[i])
    bool allCorrect = true;
    for (int i = 0; i < _paires.length; i++) {
      if (_userAssociations[i] != i) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      final int durationInSeconds = DateTime.now().difference(_startTime).inSeconds;
      int earnedXp = 50 - (durationInSeconds ~/ 5);
      if (earnedXp < 5) earnedXp = 5;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'progression': FieldValue.increment(earnedXp),
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Bravo, tout est correct ! +$earnedXp XP.")),
          );
          Navigator.pop(context);
        } catch (e) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Il y a des erreurs dans tes associations.")),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.exerciseData['title'] ?? 'Mots à relier';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Associe chaque élément de gauche à sa correspondance :", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: [
                  // Colonne Gauche
                  Expanded(
                    child: ListView.builder(
                      itemCount: _leftItems.length,
                      itemBuilder: (context, index) {
                        final bool isSelected = _selectedLeftIndex == index;
                        final bool isAssigned = _userAssociations.containsKey(index);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedLeftIndex = index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isAssigned
                                  ? Colors.green.shade100
                                  : isSelected
                                      ? Colors.blue.shade100
                                      : Colors.grey.shade200,
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_leftItems[index], textAlign: TextAlign.center),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Colonne Droite
                  Expanded(
                    child: ListView.builder(
                      itemCount: _rightItems.length,
                      itemBuilder: (context, index) {
                        final bool isTargetAssigned = _userAssociations.containsValue(index);

                        return GestureDetector(
                          onTap: () {
                            if (_selectedLeftIndex != null) {
                              setState(() {
                                _userAssociations[_selectedLeftIndex!] = index;
                                _selectedLeftIndex = null; // Reset selection
                              });
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isTargetAssigned ? Colors.green.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_rightItems[index], textAlign: TextAlign.center),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _validateAnswer,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Valider les associations"),
            ),
          ],
        ),
      ),
    );
  }
}