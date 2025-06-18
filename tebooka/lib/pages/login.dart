import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import 'sign_in.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    loadSavedEmail();
  }

  Future<void> loadSavedEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberMe = prefs.getBool('rememberMe') ?? false;
      if (rememberMe) {
        emailController.text = prefs.getString('savedEmail') ?? '';
      }
    });
  }

  Future<void> login() async {
    setState(() => isLoading = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (rememberMe) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', true);
      await prefs.setString('savedEmail', email);
    }

    String? result = await AuthService().signInWithEmail(email, password);

    setState(() => isLoading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  void forgotPassword() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter your email first")));
      return;
    }

    await AuthService().sendPasswordReset(email);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset email sent")));
  }

  void resendVerification() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter your email first")));
      return;
    }

    await AuthService().resendVerificationEmail(email);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verification email sent again")));
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
                const Text('Login', style: TextStyle(color: kWhite, fontSize: 30)),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (val) {
                        setState(() => rememberMe = val!);
                      },
                      activeColor: Colors.white,
                      checkColor: Colors.black,
                    ),
                    const Text("Remember me", style: TextStyle(color: kWhite)),
                    const Spacer(),
                    TextButton(
                      onPressed: forgotPassword,
                      child: const Text("Forgot Password?", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: login,
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: resendVerification,
                  child: const Text("Resend verification email", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInPage()));
                  },
                  child: const Text('Don\'t have an account? Sign up', style: TextStyle(color: kWhite)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
