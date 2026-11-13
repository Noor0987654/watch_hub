import 'package:flutter/material.dart';
import 'package:watch_hub/Admin/Admin_login.dart';
import 'package:watch_hub/user_screen/splash_screen.dart';

class layout_screen extends StatelessWidget {
  const layout_screen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Agar screen size 600 se badi hai (Web/Desktop) toh direct login page
      if (constraints.maxWidth > 600) {
        return const LoginPage();
      } else {
        // Agar screen size choti hai (Mobile) toh pehle Splash Screen dikhao
        return const SplashScreen();
      }
    });
  }
}