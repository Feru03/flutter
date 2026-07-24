import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Exos extends StatefulWidget {
  const Exos({Key? key}) : super(key: key);

  @override
  State<Exos> createState() => _ExosState();
}

class _ExosState extends State<Exos> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs généraux
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  
  String _selectedExerciseType = 'quiz'; // Valeur par défaut
  final List<String> _exerciseTypes = [
    'quiz', 
    '4 images 1 mot', 
    'phrases à trou', 
    'mot à relier',
    'audio' // Nouveau type ajouté
  ];

  // Spécifique à "quiz"
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, dynamic>> _quizOptions = [
    {'text': TextEditingController(), 'isCorrect': false},
    {'text': TextEditingController(), 'isCorrect': false},
  ];

  // Spécifique à "4 images 1 mot"
  final List<TextEditingController> _imageControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final TextEditingController _reponse4ImagesController = TextEditingController();

  // Spécifique à "phrases à trou"
  final TextEditingController _phraseTroueeController = TextEditingController();

  // Spécifique à "mot à relier"
  final List<Map<String, TextEditingController>> _pairesPaires = [
    {
      'gauche': TextEditingController(),
      'droite': TextEditingController(),
    }
  ];

  // Spécifique à "audio" (Prononciation)
  final TextEditingController _audioUrlController = TextEditingController();
  final TextEditingController _audioTexteReferenceController = TextEditingController();

  void _addQuizOption() {
    setState(() {
      _quizOptions.add({'text': TextEditingController(), 'isCorrect': false});
    });
  }

  void _removeQuizOption(int index) {
    setState(() {
      _quizOptions[index]['text'].dispose();
      _quizOptions.removeAt(index);
    });
  }

  void _addPaire() {
    setState(() {
      _pairesPaires.add({
        'gauche': TextEditingController(),
        'droite': TextEditingController(),
      });
    });
  }

  void _removePaire(int index) {
    setState(() {
      _pairesPaires[index]['gauche']!.dispose();
      _pairesPaires[index]['droite']!.dispose();
      _pairesPaires.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    _questionController.dispose();
    for (var option in _quizOptions) {
      option['text'].dispose();
    }
    for (var controller in _imageControllers) {
      controller.dispose();
    }
    _reponse4ImagesController.dispose();
    _phraseTroueeController.dispose();
    for (var p in _pairesPaires) {
      p['gauche']!.dispose();
      p['droite']!.dispose();
    }
    _audioUrlController.dispose();
    _audioTexteReferenceController.dispose();
    super.dispose();
  }

  Future<void> _publishExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedExerciseType == 'quiz') {
      bool hasCorrect = _quizOptions.any((opt) => opt['isCorrect'] == true);
      if (!hasCorrect) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tu dois cocher au moins une bonne réponse pour le quiz !")),
        );
        return;
      }
    }

    Map<String, dynamic> exerciseData = {
      'title': _titleController.text.trim(),
      'points': int.tryParse(_pointsController.text.trim()) ?? 10,
      'type': _selectedExerciseType,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (_selectedExerciseType == 'quiz') {
      exerciseData['question'] = _questionController.text.trim();
      exerciseData['options'] = _quizOptions.map((opt) {
        return {
          'text': opt['text'].text.trim(),
          'isCorrect': opt['isCorrect'],
        };
      }).toList();
    } 
    else if (_selectedExerciseType == '4 images 1 mot') {
      exerciseData['images'] = _imageControllers.map((c) => c.text.trim()).toList();
      exerciseData['reponse'] = _reponse4ImagesController.text.trim();
    } 
    else if (_selectedExerciseType == 'phrases à trou') {
      exerciseData['phrase'] = _phraseTroueeController.text.trim();
    } 
    else if (_selectedExerciseType == 'mot à relier') {
      exerciseData['paires'] = _pairesPaires.map((paire) {
        return {
          'gauche': paire['gauche']!.text.trim(),
          'droite': paire['droite']!.text.trim(),
        };
      }).toList();
    }
    else if (_selectedExerciseType == 'audio') {
      exerciseData['audioUrl'] = _audioUrlController.text.trim();
      exerciseData['texteReference'] = _audioTexteReferenceController.text.trim();
    }

    try {
      await FirebaseFirestore.instance.collection('exercises').add(exerciseData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Exercice publié avec succès !")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la publication : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un exercice"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Titre de l'exercice"),
                validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Points attribués"),
                validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedExerciseType,
                items: _exerciseTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExerciseType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Type d'exercice"),
              ),
              const SizedBox(height: 20),

              // ================= QUIZ =================
              if (_selectedExerciseType == 'quiz') ...[
                const Text("Configuration du Quiz", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(labelText: "Question"),
                  validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Options de réponse"),
                    ElevatedButton(
                      onPressed: _addQuizOption,
                      child: const Text("Ajouter une option"),
                    ),
                  ],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quizOptions.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        Checkbox(
                          value: _quizOptions[index]['isCorrect'],
                          onChanged: (val) {
                            setState(() {
                              _quizOptions[index]['isCorrect'] = val ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _quizOptions[index]['text'],
                            decoration: InputDecoration(labelText: "Option ${index + 1}"),
                            validator: (value) => value == null || value.isEmpty ? "Requis" : null,
                          ),
                        ),
                        if (_quizOptions.length > 2)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeQuizOption(index),
                          ),
                      ],
                    );
                  },
                ),
              ],

              // ================= 4 IMAGES 1 MOT =================
              if (_selectedExerciseType == '4 images 1 mot') ...[
                const Text("Configuration 4 images 1 mot", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      controller: _imageControllers[index],
                      decoration: InputDecoration(labelText: "URL de l'image ${index + 1}"),
                      validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reponse4ImagesController,
                  decoration: const InputDecoration(labelText: "Mot réponse final"),
                  validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
                ),
              ],

              // ================= PHRASES À TROU =================
              if (_selectedExerciseType == 'phrases à trou') ...[
                const Text("Configuration de la phrase à trou", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phraseTroueeController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Phrase avec les trous",
                    hintText: "Ex: Ny trano dia [tsara]",
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
                ),
              ],

              // ================= MOT À RELIER =================
              if (_selectedExerciseType == 'mot à relier') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Paires à relier", style: TextStyle(fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: _addPaire,
                      child: const Text("Ajouter une paire"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pairesPaires.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pairesPaires[index]['gauche'],
                              decoration: InputDecoration(labelText: "Élément ${index + 1} (Gauche)"),
                              validator: (value) => value == null || value.isEmpty ? "Requis" : null,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.arrow_forward),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _pairesPaires[index]['droite'],
                              decoration: InputDecoration(labelText: "Correspondance ${index + 1}"),
                              validator: (value) => value == null || value.isEmpty ? "Requis" : null,
                            ),
                          ),
                          if (_pairesPaires.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removePaire(index),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // ================= AUDIO (PRONONCIATION) =================
              if (_selectedExerciseType == 'audio') ...[
                const Text("Configuration Exercice Audio", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _audioUrlController,
                  decoration: const InputDecoration(
                    labelText: "URL du fichier Audio du professeur",
                    hintText: "http://...",
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _audioTexteReferenceController,
                  decoration: const InputDecoration(
                    labelText: "Texte de référence à répéter",
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Champ requis" : null,
                ),
              ],

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _publishExercise,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Publier l'exercice", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}