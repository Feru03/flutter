import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Cours extends StatefulWidget {
  const Cours({super.key});

  @override
  State<Cours> createState() => _CoursState();
}

class _CoursState extends State<Cours> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // On stocke les fichiers sélectionnés localement
  final List<File> _selectedFiles = [];
  
  String? _selectedModuleId;
  List<Map<String, dynamic>> _formateurModules = [];
  bool isLoading = true;
  bool isSaving = false;
  bool _isExam = false; // Option pour basculer entre Leçon et Examen final

  @override
  void initState() {
    super.initState();
    _fetchFormateurModules();
  }

  Future<void> _fetchFormateurModules() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Récupération sécurisée via le document utilisateur et son tableau de modules
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() { isLoading = false; });
        return;
      }

      var userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> moduleIds = userData['modules'] ?? [];

      if (moduleIds.isEmpty) {
        setState(() { isLoading = false; });
        return;
      }

      List<Map<String, dynamic>> loadedModules = [];
      for (var id in moduleIds) {
        DocumentSnapshot modDoc = await FirebaseFirestore.instance
            .collection('modules')
            .doc(id.toString().trim())
            .get();

        if (modDoc.exists) {
          var modData = modDoc.data() as Map<String, dynamic>;
          modData['id'] = modDoc.id;
          loadedModules.add(modData);
        }
      }

      setState(() {
        _formateurModules = loadedModules;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement de vos modules")),
      );
    }
  }

  // Ouvrir l'explorateur de fichiers pour sélectionner un ou plusieurs documents
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp3', 'mp4'],
    );

    if (result != null) {
      setState(() {
        for (var path in result.paths) {
          if (path != null) {
            _selectedFiles.add(File(path));
          }
        }
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  // Envoi des fichiers vers le Google Drive via ton script Apps Script
  Future<List<String>> _processFileLinks() async {
    List<String> fileUrls = [];

    for (var file in _selectedFiles) {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://script.google.com/macros/s/AKfycbxJXf-wOmXbOnK_YrEFGe_7cur6FXn-5OwMhFV3LCQZ2EirHm9JPI2KdiKEU9bSYFy-cg/exec')
      );
      
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String downloadUrl = data['downloadUrl']; 
        fileUrls.add(downloadUrl);
      } else {
        throw Exception("Erreur lors de l'envoi du fichier vers le Drive");
      }
    }

    return fileUrls;
  }

  Future<void> _publishContent() async {
    if (!_formKey.currentState!.validate() || _selectedModuleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir les champs obligatoires et choisir un module.")),
      );
      return;
    }

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez ajouter au moins un fichier.")),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      // 1. Upload des fichiers vers Google Drive et récupération des liens directs
      List<String> fileUrls = await _processFileLinks();

      // 2. Détermination de la collection cible selon s'il s'agit d'un examen ou d'une leçon
      String targetCollection = _isExam ? 'exams' : 'lessons';
      String targetArrayField = _isExam ? 'exams' : 'lessons';

      // 3. Création du document dans Firestore
      DocumentReference docRef = await FirebaseFirestore.instance.collection(targetCollection).add({
        'titre': _titreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fichier': fileUrls, // Liste des URL Google Drive stockées
        'formateur_id': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Liaison de l'ID au module choisi
      await FirebaseFirestore.instance.collection('modules').doc(_selectedModuleId).update({
        targetArrayField: FieldValue.arrayUnion([docRef.id]),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isExam ? "Examen final publié avec succès !" : "Leçon publiée avec succès !")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la publication : $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isExam ? "Publier un Examen Final" : "Créer une leçon")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _formateurModules.isEmpty
                        ? const Text("Vous n'êtes affecté à aucun module.")
                        : DropdownButtonFormField<String>(
                            value: _selectedModuleId,
                            hint: const Text("Sélectionner un module"),
                            items: _formateurModules.map((module) {
                              return DropdownMenuItem<String>(
                                value: module['id'],
                                child: Text(module['titre'] ?? 'Sans titre'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedModuleId = value;
                              });
                            },
                            validator: (value) => value == null ? "Champ requis" : null,
                          ),
                    const SizedBox(height: 16),

                    // --- SWITCH POUR BASCULER EN EXAMEN FINAL ---
                    SwitchListTile(
                      title: const Text("Est-ce un examen final ?"),
                      subtitle: const Text("Active pour envoyer le sujet PDF de l'examen"),
                      value: _isExam,
                      activeColor: Colors.green,
                      onChanged: (bool value) {
                        setState(() {
                          _isExam = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _titreController,
                      decoration: InputDecoration(
                        labelText: _isExam ? "Titre de l'examen" : "Titre de la leçon",
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: "Description / Consignes"),
                      validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Fichiers joints (PDF, MP3, MP4)",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Sélectionner des fichiers"),
                    ),
                    const SizedBox(height: 10),

                    // Liste des fichiers locaux choisis
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        String fileName = _selectedFiles[index].path.split('/').last;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(fileName, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFile(index),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _isExam ? Colors.orange : Colors.green),
                      onPressed: isSaving ? null : _publishContent,
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isExam ? "Publier l'examen final" : "Publier la leçon",
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}