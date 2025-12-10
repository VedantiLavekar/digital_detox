import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup.dart';
import 'database_helper.dart';
import 'forgot_password_page.dart';
import 'mode_selector.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final green = const Color(0xFF2E9D8A);
  final bgColor = const Color(0xFFF5F5DC);

  String? emailError;
  String? passError;
  bool _isPasswordVisible = false; // 👁️ Track password visibility

  bool isValidEmail(String e) =>
      RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(e.trim());

  bool isValidPass(String p) => RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_])(?!.*\s).{8,}$',
  ).hasMatch(p);

  void validate() {
    setState(() {
      emailError = email.text.trim().isEmpty
          ? 'Email is required'
          : (!isValidEmail(email.text)
                ? 'Enter a valid email (e.g. abc@gmail.com)'
                : null);

      passError = pass.text.isEmpty
          ? 'Password is required'
          : (!isValidPass(pass.text)
                ? 'Min 8 chars, 1 upper, 1 lower, 1 digit, 1 special, no spaces'
                : null);
    });
  }

  Future<void> handleLogin() async {
    validate();
    if (emailError == null && passError == null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final dbHelper = DatabaseHelper();
        bool loginSuccessful = false;
        String? userId;

        try {
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                email: email.text.trim(),
                password: pass.text,
              );
          loginSuccessful = true;
          userId = userCredential.user?.uid;

          // Update lastLogin timestamp in Firestore
          if (userId != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({'lastLogin': FieldValue.serverTimestamp()});
            print('✅ Login timestamp updated for user: $userId');
          }
        } catch (_) {
          Map<String, dynamic>? user = await dbHelper.loginUser(
            email: email.text.trim(),
            password: pass.text,
          );
          if (user != null) loginSuccessful = true;
        }

        if (mounted) Navigator.of(context).pop();

        if (loginSuccessful) {
          if (mounted) {
            // Always show mode selector after login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ModeSelector()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid email or password'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) Navigator.of(context).pop();
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password provided.';
            break;
          default:
            errorMessage = 'An error occurred. Please try again.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    email.addListener(() {
      if (emailError != null) validate();
    });
    pass.addListener(() {
      if (passError != null) validate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Digital Detox Login"),
        backgroundColor: green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email, color: green),
                errorText: emailError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: pass,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock, color: green),
                errorText: passError,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: green,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: green),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                  child: Text("Sign Up", style: TextStyle(color: green)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text("Login", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
