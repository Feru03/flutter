import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Exercice4Images1MotPage extends StatefulWidget {
  final Map<String, dynamic> exerciseData;

  const Exercice4Images1MotPage({super.key, required this.exerciseData});

  @override
  State<Exercice4Images1MotPage> createState() => _Exercice4Images1MotPageState();
}

class _Exercice4Images1MotPageState extends State<Exercice4Images1MotPage> {
  final TextEditingController _reponseController = TextEditingController();
  late final DateTime _startTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _reponseController.dispose();
    super.dispose();
  }

  Future<void> _validateAnswer() async {
    if (_isSubmitting) return;

    final String userAnswer = _reponseController.text.trim().toLowerCase();
    final String correctAnswer = (widget.exerciseData['reponse'] ?? '').toString().trim().toLowerCase();

    if (userAnswer.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tu dois écrire une réponse !")),
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
        const SnackBar(content: Text("Mauvaise réponse, essaie encore !")),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.exerciseData['images'] ?? [];
    final String title = widget.exerciseData['title'] ?? '4 images 1 mot';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Trouve le mot commun à ces 4 images :",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length > 4 ? 4 : images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                String imageUrl = images[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image, size: 50)),
                        )
                      : const Center(child: Icon(Icons.image, size: 50)),
                );
              },
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _reponseController,
              decoration: const InputDecoration(
                labelText: "Votre réponse",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _validateAnswer,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Valider", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}