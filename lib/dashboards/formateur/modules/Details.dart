import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lessons/Details.dart';

class ModulesDetails extends StatefulWidget {
  final dynamic moduleData;

  const ModulesDetails({super.key, required this.moduleData});

  @override
  State<ModulesDetails> createState() => _ModulesDetailsState();
}

class _ModulesDetailsState extends State<ModulesDetails> {
  Map<String, dynamic>? moduleDetails;
  List<Map<String, dynamic>> lessonsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchModuleDetails();
  }

  Future<void> fetchModuleDetails() async {
    try {
      // 1. Récupérer le document du module
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("modules")
          .doc(widget.moduleData)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          moduleDetails = data;
        });

        // 2. Récupérer les leçons si la liste d'ID n'est pas vide
        List<dynamic> lessonIds = data['lessons'] ?? [];
        if (lessonIds.isNotEmpty) {
          QuerySnapshot lessonsQuery = await FirebaseFirestore.instance
              .collection("lessons") // Assure-toi que c'est le nom de ta collection de leçons
              .where(FieldPath.documentId, whereIn: lessonIds)
              .get();

          setState(() {
            lessonsList = lessonsQuery.docs.map((lDoc) {
              var lData = lDoc.data() as Map<String, dynamic>;
              lData['id'] = lDoc.id;
              return lData;
            }).toList();
          });
        }
      }
    } catch (e) {
      // Gérer l'erreur si besoin
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(moduleDetails?['titre'] ?? "Détails du module"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : moduleDetails == null
              ? const Center(child: Text("Module introuvable"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moduleDetails!['titre'] ?? 'Sans nom',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text("Description : ${moduleDetails!['description'] ?? 'Aucune description'}"),
                      const SizedBox(height: 20),
                      Text(
                        "Leçons (${lessonsList.length})",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      
                      // Liste des leçons
                      Expanded(
                        child: lessonsList.isEmpty
                            ? const Text("Aucune leçon disponible pour ce module.")
                            : ListView.builder(
                                itemCount: lessonsList.length,
                                itemBuilder: (context, index) {
                                  var lesson = lessonsList[index];
                                  String lessonTitle = lesson['titre'] ?? 'Leçon sans titre';

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: const Icon(Icons.book, color: Colors.blue),
                                      title: Text(lessonTitle),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                      onTap: () {
                                        Navigator.push(
                                          context, 
                                          MaterialPageRoute(
                                            builder: (context) => LessonViewer(lessonData: lesson))
                                          );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}