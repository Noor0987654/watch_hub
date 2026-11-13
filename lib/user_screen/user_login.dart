import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watch_hub/user_screen/bottom_nav.dart';
import 'package:watch_hub/user_screen/user_register.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---- Theme colors (Luxury Black & Gold) ----
  static const Color kPrimaryGold = Color(0xFFD4AF37);
  static const Color kDarkGold = Color(0xFFB8960F);
  static const Color kLightGold = Color(0xFFF5E6A3);
  static const Color kBgBlack = Color(0xFF0A0A0A);
  static const Color kCardBlack = Color(0xFF1A1A1A);
  static const Color kTextGold = Color(0xFFD4AF37);

  Future<void> _loginUser() async {
    if (nameController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all fields"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 🔍 Firestore mein name se user search karein
      QuerySnapshot querySnapshot = await _firestore
          .collection('Users')
          .where('name', isEqualTo: nameController.text.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // ❌ User not found
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("User not found! Please register first."),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() {
          isLoading = false;
        });
        return;
      }

      // ✅ User found - get data
      var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      String storedPassword = userData['password'] ?? '';
      String userEmail = userData['email'] ?? '';

      // 🔑 Password check
      if (storedPassword != passwordController.text.trim()) {
        // ❌ Wrong password
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Wrong password! Please try again."),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() {
          isLoading = false;
        });
        return;
      }

      // ✅ Password match - Now login with email/password using Firebase Auth
      try {
        // Login with stored email and entered password
        await _auth.signInWithEmailAndPassword(
          email: userEmail,
          password: passwordController.text.trim(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Login Successful! Welcome back 👋"),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomNav()),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Firebase Auth error handling
        String message = "Login failed!";
        if (e.code == 'wrong-password') {
          message = "Wrong password!";
        } else if (e.code == 'user-not-found') {
          message = "User not found!";
        } else if (e.code == 'invalid-email') {
          message = "Invalid email format!";
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // // Logo/Icon
              // Center(
              //   child: Container(
              //     width: 80,
              //     height: 80,
              //     decoration: BoxDecoration(
              //       color: kCardBlack,
              //       shape: BoxShape.circle,
              //       border: Border.all(
              //         color: kPrimaryGold.withOpacity(0.3),
              //         width: 2,
              //       ),
              //     ),
              //     child: ClipOval(
              //           child: Image.asset(
              //             'assesst/splash.jpg',
              //             fit: BoxFit.cover,
              //             errorBuilder: (context, error, stackTrace) {
              //               // Fallback to the plain icon if the image isn't found
              //               return const Icon(
              //                 Icons.watch_rounded,
              //                 size: 120,
              //                 color: Colors.white,
              //               );
              //             },
              //           ),
              //         ),
              //   ),
              // ),
              
              const SizedBox(height: 24),
              
              // Header
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryGold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Login with your username & password",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // ✅ Name Field
              Container(
                decoration: BoxDecoration(
                  color: kCardBlack,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kPrimaryGold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: nameController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Username",
                    hintText: "Enter your username",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    labelStyle: TextStyle(color: kPrimaryGold),
                    prefixIcon: Icon(Icons.person, color: kPrimaryGold),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Password Field
              Container(
                decoration: BoxDecoration(
                  color: kCardBlack,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kPrimaryGold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter your password",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    labelStyle: TextStyle(color: kPrimaryGold),
                    prefixIcon: Icon(Icons.lock, color: kPrimaryGold),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _showForgotPasswordDialog();
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: kPrimaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : _loginUser,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserRegister(),
                        ),
                      );
                    },
                    child: Text(
                      "Register",
                      style: TextStyle(
                        color: kPrimaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Forgot Password Dialog
  void _showForgotPasswordDialog() {
    TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kCardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: kPrimaryGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          title: const Text(
            "Reset Password",
            style: TextStyle(
              color: kPrimaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your email to receive reset link",
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: kPrimaryGold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Email address",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                try {
                  await _auth.sendPasswordResetEmail(
                    email: emailController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Reset link sent to your email!"),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }
}