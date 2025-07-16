import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login.dart';
import 'email_verification_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- Add FCM import

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
  String role = 'passenger';
  bool isLoading = false;
  bool showPassword = false;

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } else {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save user data in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Get and save FCM token for push notifications
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': fcmToken ?? '',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Registration successful. Check your email for verification."),
      ));
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

  Widget buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    bool showToggle = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(bottom: 8),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: obscure && !showPassword,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            border: InputBorder.none,
            icon: Icon(icon, color: Colors.grey, size: 18),
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13),
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                      size: 18,
                    ),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Curved image spanning behind status bar at the top
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: Image.asset(
                'assets/amahoro.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Scrollable content with extra top padding to lower the title below image
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 320, 25, 25), // increased top padding to push down content
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "CREATE AN ACCOUNT",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Enjoy bus rides in Kigali with TEBOOKA",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 10),

                buildTextField(hint: 'First Name', icon: Icons.person, controller: firstNameController),
                buildTextField(hint: 'Last Name', icon: Icons.person_outline, controller: lastNameController),
                buildTextField(hint: 'Email', icon: Icons.email, controller: emailController),
                buildTextField(
                  hint: 'Password',
                  icon: Icons.lock,
                  controller: passwordController,
                  obscure: true,
                  showToggle: true,
                ),

                const SizedBox(height: 6),

                // Reduced-size Role Picker
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: role,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      items: const [
                        DropdownMenuItem(
                          value: 'passenger',
                          child: Text("Passenger", style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'driver',
                          child: Text("Driver", style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (value) => setState(() => role = value!),
                    ),
                  ),
                ),

                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Sign In", style: TextStyle(fontSize: 14)),
                      ),

                const SizedBox(height: 6),

                OutlinedButton(
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
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: Colors.black),
                  ),
                  child: const Text("Login", style: TextStyle(color: Colors.black, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
