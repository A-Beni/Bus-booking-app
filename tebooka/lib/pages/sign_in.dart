import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import 'login.dart';
import 'email_verification_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SignInPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'passenger'; // Default role
  bool isLoading = false;

  void signUp() async {
    setState(() => isLoading = true);

    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("First and Last names cannot be empty")),
      );
      setState(() => isLoading = false);
      return;
    }

    String? result = await AuthService()
        .registerWithEmail(email, password, firstName, lastName, role);

    setState(() => isLoading = false);

    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    } else {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Registration successful. Check your email for verification.")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationHandlerPage(
            isDarkMode: widget.isDarkMode,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlue,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Create an Account',
                    style: TextStyle(color: kWhite, fontSize: 30)),
                const SizedBox(height: 20),

                // First Name
                TextField(
                  controller: firstNameController,
                  style: const TextStyle(color: kWhite),
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    labelStyle: TextStyle(color: kWhite),
                  ),
                ),
                const SizedBox(height: 10),

                // Last Name
                TextField(
                  controller: lastNameController,
                  style: const TextStyle(color: kWhite),
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: TextStyle(color: kWhite),
                  ),
                ),
                const SizedBox(height: 10),

                // Email
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: kWhite),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: kWhite),
                  ),
                ),
                const SizedBox(height: 10),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: kWhite),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: kWhite),
                  ),
                ),
                const SizedBox(height: 20),

                // Role selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Register as: ",
                        style: TextStyle(color: kWhite)),
                    DropdownButton<String>(
                      dropdownColor: kBlue,
                      value: role,
                      items: const [
                        DropdownMenuItem(
                          value: 'passenger',
                          child: Text('Passenger',
                              style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: 'driver',
                          child: Text('Driver',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          role = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Button
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: signUp,
                        child: const Text('Continue'),
                      ),
                const SizedBox(height: 10),

                // Login Redirect
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginPage(
                          isDarkMode: widget.isDarkMode,
                          onThemeChanged: widget.onThemeChanged,
                        ),
                      ),
                    );
                  },
                  child: const Text('Already have an account? Log in',
                      style: TextStyle(color: kWhite)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
