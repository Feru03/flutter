import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dashboards/formateur/modules/Details.dart';

class Modules extends StatefulWidget {
  const Modules({super.key});

  @override
  State<Modules> createState() => _ModulesState();
}

class _ModulesState extends State<Modules> {
  List<dynamic> _MyModules = [];
  List<Map<String, dynamic>> _allModules = [];

  Future<void> showMyModules() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _MyModules = data['modules'] ?? [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement de vos modules")),
      );
    }
  }

  Future<void> showAllModules() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("modules")
          .get();

      setState(() {
        _allModules = querySnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des modules")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    showMyModules();
    showAllModules();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Première section : Mes modules
          const Text(
            "Mes modules",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _MyModules.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Aucun module affecté pour le moment."),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _MyModules.length,
                  itemBuilder: (context, index) {
                    // Chaque élément est maintenant directement une String (l'ID du module)
                    String moduleId = _MyModules[index].toString();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('modules')
                          .doc(moduleId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(title: Text("Chargement du module...")),
                          );
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        var moduleData = snapshot.data!.data() as Map<String, dynamic>;
                        String moduleTitle = moduleData['titre'] ?? 'Module sans nom';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(moduleTitle),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ModulesDetails(moduleData: moduleId),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),

          const SizedBox(height: 20),

          // Deuxième section : Tous les modules disponibles
          const Text(
            "Tous les modules disponibles",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _allModules.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Aucun module disponible pour le moment."),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allModules.length,
                  itemBuilder: (context, index) {
                    var module = _allModules[index];
                    String moduleName = module['titre'] ?? 'Module sans nom';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(moduleName),
                        trailing: const Icon(Icons.add, size: 20),
                        onTap: () async {
                          String currentUserId = FirebaseAuth.instance.currentUser!.uid;

                          DocumentSnapshot userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUserId)
                              .get();

                          if (!context.mounted) return;

                          if (userDoc.exists) {
                            var userData = userDoc.data() as Map<String, dynamic>;
                            String role = userData['role'] ?? 'apprenant';

                            if (role == 'formateur') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Un formateur ne peut pas s'inscrire à un module.")),
                              );
                              return;
                            }
                          }

                          String moduleId = module['id'];
                          DocumentReference moduleRef = FirebaseFirestore.instance.collection('modules').doc(moduleId);

                          DocumentSnapshot moduleSnap = await moduleRef.get();
                          if (!context.mounted) return;

                          if (moduleSnap.exists) {
                            var moduleData = moduleSnap.data() as Map<String, dynamic>;
                            List<dynamic> apprenantsList = moduleData['apprenants'] ?? [];

                            if (apprenantsList.contains(currentUserId)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Vous êtes déjà inscrit à ce module.")),
                              );
                            } else {
                              await moduleRef.update({
                                'apprenants': FieldValue.arrayUnion([currentUserId]),
                              });

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Inscription réussie !")),
                              );
                            }

                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModulesDetails(moduleData: moduleId),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}