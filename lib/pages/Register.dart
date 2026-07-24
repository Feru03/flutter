import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  // 1. TOUTES les variables et contrôleurs se déclarent ici, en haut de la classe State
  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedRole = 'apprenant'; // Valeur par défaut du select

  Future<void> _RegisterFirebase() async {
    final pseudo = _pseudoController.text;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final role = _selectedRole;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || pseudo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    try {
      // 1. Création du compte dans Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Vérification de sécurité après l'asynchronisme
      if (!mounted) return;

      // Récupération de l'utilisateur qui vient d'être créé
      User? user = userCredential.user;

      if (user != null) {
        // 2. Enregistrement des informations complémentaires dans Firestore
        await FirebaseFirestore.instance.collection("user").doc(user.uid).set({
          'pseudo': pseudo,
          'email': email,
          'role': role,
          'createdAt':
              FieldValue.serverTimestamp(), // Optionnel : pratique pour savoir quand le compte a été créé
        });

        if (!mounted) return;

        // 3. Message de succès et redirection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte créé avec succès !')),
        );

        // Redirection vers le dashboard correspondant ou le Login
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (context) => AuthCheckScreen())
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'inscription : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
      ), // Corrigé : "Inscription" au lieu de "Connexion"
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Inscription",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pseudoController,
              decoration: const InputDecoration(
                labelText: 'Pseudo',
                hintText: 'Feru',
              ),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'exemple@gmail.com',
              ),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                hintText: '**********',
              ),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmation de mot de passe',
                hintText: '**********',
              ),
            ),
            const SizedBox(height: 10),
            // 2. Le DropdownButtonFormField est placé correctement ici dans la Column
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: const [
                DropdownMenuItem(value: 'apprenant', child: Text('Apprenant')),
                DropdownMenuItem(value: 'formateur', child: Text('Formateur')),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                _RegisterFirebase();
              },
              child: const Text("S'inscrire"),
            ),
          ],
        ),
      ),
    );
  }
}
