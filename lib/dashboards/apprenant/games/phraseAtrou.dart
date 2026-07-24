import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhraseATrouPage extends StatefulWidget {
  final Map<String, dynamic> exerciseData;

  const PhraseATrouPage({super.key, required this.exerciseData});

  @override
  State<PhraseATrouPage> createState() => _PhraseATrouPageState();
}

class _PhraseATrouPageState extends State<PhraseATrouPage> {
  final TextEditingController _answerController = TextEditingController();
  late final DateTime _startTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _validateAnswer() async {
    if (_isSubmitting) return;

    final String userAnswer = _answerController.text.trim().toLowerCase();
    final String rawPhrase = widget.exerciseData['phrase'] ?? '';

    final RegExp regExp = RegExp(r'\[(.*?)\]');
    final match = regExp.firstMatch(rawPhrase);
    final String correctAnswer = match != null ? match.group(1)!.trim().toLowerCase() : '';

    if (userAnswer.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Écris une réponse.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    if (userAnswer == correctAnswer) {
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
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Correct ! +$earnedXp XP gagnés.")),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ce n'est pas le bon mot.")),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.exerciseData['title'] ?? 'Phrase à trou';
    final String phrase = widget.exerciseData['phrase'] ?? '';
    final String displayPhrase = phrase.replaceAll(RegExp(r'\[.*?\]'), '____');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Complète la phrase :", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text(
              displayPhrase,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: "Mot manquant",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _validateAnswer,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Valider"),
            ),
          ],
        ),
      ),
    );
  }
}