import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_hub/user_screen/layout_screen.dart';
import 'package:flutter/material.dart';
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB5RNFBf5kQyMb9S0u83NbqgB0c79DrUDo",
        authDomain: "crudnoor.firebaseapp.com",
        projectId: "watchhub-d42cf",
        storageBucket: "crudnoor.firebasestorage.app",
        messagingSenderId: "778684177776",
        appId: "1:778684177776:android:8fdfe570ac287861d303b5",
        measurementId: "G-6CRK8Y2X68",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyADrnUnslFheyYy6wOeVvpmcA_MUmZ_920",
        authDomain: "watchhub-d42cf.firebaseapp.com",
        projectId: "watchhub-d42cf",
        storageBucket: "watchhub-d42cf.firebasestorage.app",
        messagingSenderId: "778684177776",
        appId: "1:778684177776:web:03801d26d713748ad303b5",
        measurementId: "G-QWQPWPLKZN",
      ),
    );
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  navigatorObservers: [routeObserver],  
      debugShowCheckedModeBanner: false,
      title: 'WatchHub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const layout_screen(),
    );
  }
}