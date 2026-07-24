import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Register.dart';

//import des dashboard
//import '../dashboards/AdminDashboardScreen.dart';
import '../dashboards/FormateurDashboardScreen.dart';
import '../dashboards/ApprenantDashboardScreen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Ici tu mets tes variables et tes contrôleurs
  bool _isObscured = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _LoginFirebase()async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      // Afficher un message d'erreur si les champs sont vides
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      //vérifier si l'écran est toujours actif
      if (!mounted) return;

      // Connexion réussie, tu peux naviguer vers une autre page ou afficher un message de succès
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connexion réussie')));

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("user")
            .doc(user.uid)
            .get();

        if (!mounted) return;

        String role = userDoc["role"];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vous êtes connecté en tant que $role')),
        );

        if (role == "formateur") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const FormateurDashboardScreen(),
            ),
          );
        } else if (role == "apprenant") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ApprenantDashboardScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Rôle inconnu')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la connexion : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ici tu mets le code de l'interface (Scaffold, Column, TextField, etc.

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Center(
        child: Column(
          children: [
            Text('Connexion'),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'aïchasoraya.m@gmail.com',
              ),
            ),
            TextField(
              controller: _passwordController,
              obscureText: _isObscured,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: '********',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _LoginFirebase();
              },
              child: const Text("Se connecter"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Register()),
                );
              },
              child: Text("Pas encore de compte ? Créez un compte"),
            ),
          ],
        ),
      ),
    );
  }
}
