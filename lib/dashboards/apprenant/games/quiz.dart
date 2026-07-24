import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizPage extends StatefulWidget {
  final Map<String, dynamic> exerciseData;

  const QuizPage({super.key, required this.exerciseData});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final DateTime _startTime;
  bool _isSubmitting = false;
  int? _selectedOptionIndex;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _validateAnswer(List<dynamic> options) async {
    if (_selectedOptionIndex == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final selectedOption = options[_selectedOptionIndex!];
    final bool isCorrect = selectedOption['isCorrect'] ?? false;

    if (isCorrect) {
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
            SnackBar(content: Text("Bonne réponse ! +$earnedXp XP gagnés.")),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mauvaise réponse, retente !")),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.exerciseData['title'] ?? 'Quiz';
    final String question = widget.exerciseData['question'] ?? '';
    final List<dynamic> options = widget.exerciseData['options'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final opt = options[index];
                  return RadioListTile<int>(
                    title: Text(opt['text'] ?? ''),
                    value: index,
                    groupValue: _selectedOptionIndex,
                    onChanged: (val) {
                      setState(() => _selectedOptionIndex = val);
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _validateAnswer(options),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Valider la réponse"),
            ),
          ],
        ),
      ),
    );
  }
}