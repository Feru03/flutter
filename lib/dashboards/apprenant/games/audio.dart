import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

class Audio extends StatefulWidget {
  final Map<String, dynamic> exerciseData;

  const Audio({Key? key, required this.exerciseData}) : super(key: key);

  @override
  State<Audio> createState() => _AudioState();
}

class _AudioState extends State<Audio> {
  late AudioPlayer _audioPlayer;
  late AudioRecorder _audioRecorder;
  
  bool isPlaying = false;
  bool isRecording = false;
  String? recordedFilePath;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioRecorder = AudioRecorder();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // Écouter l'audio du prof
  Future<void> _playTeacherAudio() async {
    String audioUrl = widget.exerciseData['audioUrl'] ?? '';
    if (audioUrl.isNotEmpty) {
      await _audioPlayer.play(UrlSource(audioUrl));
    }
  }

  // Démarrer / Arrêter l'enregistrement de l'élève
  Future<void> _toggleRecord() async {
    if (isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        isRecording = false;
        recordedFilePath = path;
      });
    } else {
      if (await _audioRecorder.hasPermission()) {
        // Enregistre dans un fichier temporaire
        await _audioRecorder.start(const RecordConfig(), path: '');
        setState(() {
          isRecording = true;
          recordedFilePath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.exerciseData['title'] ?? 'Exercice de prononciation';
    String referenceText = widget.exerciseData['texteReference'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.record_voice_over, size: 80, color: Color(0xFF58CC02)),
            const SizedBox(height: 20),
            const Text(
              "Écoute bien le professeur, puis répète la phrase ci-dessous en t'enregistrant.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            // Phrase de référence
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF58CC02)),
              ),
              child: Text(
                referenceText,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),

            // Bouton pour écouter le prof
            ElevatedButton.icon(
              onPressed: _playTeacherAudio,
              icon: Icon(isPlaying ? Icons.pause : Icons.volume_up),
              label: Text(isPlaying ? "Lecture en cours..." : "Écouter le modèle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 30),

            // Bouton d'enregistrement de l'élève
            GestureDetector(
              onTap: _toggleRecord,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording ? Colors.red : const Color(0xFF58CC02),
                ),
                child: Icon(
                  isRecording ? Icons.stop : Icons.mic,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isRecording ? "Enregistrement... Appuie pour stopper" : "Appuie pour t'enregistrer",
              style: TextStyle(color: isRecording ? Colors.red : Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),

            if (recordedFilePath != null)
              const Text("Enregistrement réussi ! Tu peux valider ton exercice.", 
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
              ),

            const Spacer(),

            // Bouton valider
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: recordedFilePath == null ? null : () {
                  // Logique de validation ou d'envoi vers ton serveur local
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Exercice validé avec succès !")),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58CC02),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Valider ma réponse", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}