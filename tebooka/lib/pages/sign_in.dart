import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import 'login.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void signUp() async {
    setState(() => isLoading = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    String? result = await AuthService().registerWithEmail(email, password);

    setState(() => isLoading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration successful")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
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
                const Text('Create an Account', style: TextStyle(color: kWhite, fontSize: 30)),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: kWhite),
                  decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: kWhite)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: kWhite),
                  decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: kWhite)),
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(onPressed: signUp, child: const Text('Continue')),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                  },
                  child: const Text('Already have an account? Log in', style: TextStyle(color: kWhite)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
