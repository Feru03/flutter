import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _fetchFormateurModules();
  }

  Future<void> _fetchFormateurModules() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('modules')
          .where('formateurs', arrayContains: user.uid)
          .get();

      setState(() {
        _formateurModules = querySnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
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

  // Uploader les fichiers sur Firebase Storage et récupérer leurs URL
  Future<List<String>> _uploadFilesToStorage() async {
    List<String> downloadUrls = [];
    User? user = FirebaseAuth.instance.currentUser;

    for (var file in _selectedFiles) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + "_" + file.path.split('/').last;
      Reference ref = FirebaseStorage.instance.ref().child('lessons_files/${user?.uid}/$fileName');
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    return downloadUrls;
  }

  Future<void> _publishLesson() async {
    if (!_formKey.currentState!.validate() || _selectedModuleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir les champs obligatoires et choisir un module.")),
      );
      return;
    }

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez ajouter au moins un fichier à la leçon.")),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      // 1. Upload des fichiers sur Firebase Storage
      List<String> uploadedFileUrls = await _uploadFilesToStorage();

      // 2. Création du document de la leçon
      DocumentReference lessonRef = await FirebaseFirestore.instance.collection('lessons').add({
        'titre': _titreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fichier': uploadedFileUrls, // Liste des URL stockées
        'formateur_id': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Liaison de l'ID de la leçon au module choisi
      await FirebaseFirestore.instance.collection('modules').doc(_selectedModuleId).update({
        'lessons': FieldValue.arrayUnion([lessonRef.id]),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Leçon publiée avec succès !")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la publication.")),
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
      appBar: AppBar(title: const Text("Créer une leçon")),
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

                    TextFormField(
                      controller: _titreController,
                      decoration: const InputDecoration(labelText: "Titre de la leçon"),
                      validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: "Description"),
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
                      onPressed: isSaving ? null : _publishLesson,
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Publier la leçon"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}