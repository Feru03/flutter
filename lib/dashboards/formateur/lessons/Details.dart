import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonViewer extends StatelessWidget {
  final Map<String, dynamic> lessonData;

  const LessonViewer({super.key, required this.lessonData});

  // Fonction pour aller chercher le pseudo du formateur dans Firestore
  Future<String> _fetchFormateurPseudo(String formateurId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(formateurId)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        return data['pseudo'] ?? 'Formateur inconnu';
      }
    } catch (e) {
      // Gérer l'erreur silencieusement si besoin
    }
    return 'Formateur inconnu';
  }

  @override
  Widget build(BuildContext context) {
    String titre = lessonData['titre'] ?? 'Sans titre';
    String description = lessonData['description'] ?? 'Aucune description';
    String? fichierUrl = lessonData['fichier'];
    String formateurId = lessonData['formateur_id'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Affichage dynamique du pseudo du formateur
            FutureBuilder<String>(
              future: _fetchFormateurPseudo(formateurId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    "Publié par : Chargement...",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  );
                }
                return Text(
                  "Publié par : ${snapshot.data ?? 'Inconnu'}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                );
              },
            ),

            const Divider(height: 30),

            const Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),

            const Text(
              "Média / Document attaché",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            fichierUrl == null || fichierUrl.isEmpty
                ? const Text("Aucun fichier attaché à cette leçon.")
                : Row(
                    children: [
                      // Bouton Visualiser
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final Uri url = Uri.parse(fichierUrl);
                            bool canLaunch = await canLaunchUrl(url);

                            if (!context.mounted) return;

                            if (canLaunch) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Impossible d'ouvrir le fichier",
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text("Visualiser"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Bouton Télécharger
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final Uri url = Uri.parse(fichierUrl);
                            bool canLaunch = await canLaunchUrl(url);

                            if (!context.mounted) return;

                            if (canLaunch) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Impossible de télécharger le fichier",
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Télécharger"),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}