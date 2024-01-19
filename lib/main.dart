import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flash_chat/screens/login_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:flash_chat/screens/chat_screen.dart';

late final FirebaseApp app;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  app = await Firebase.initializeApp();

  runApp(FlashChat());
}

class FlashChat extends StatelessWidget {
  const FlashChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black54),
        ),
      ),
      initialRoute: WelcomeScreen.id, // Set the initial route
      routes: {
        WelcomeScreen.id: (context) => WelcomeScreen(), // Define the home route
        LoginScreen.id: (context) => const LoginScreen(), // Define a login route
        RegistrationScreen.id: (context) =>
            const RegistrationScreen(), // Define a registration route
        ChatScreen.id: (context) => ChatScreen(), // Define a chat screen
      },
    );
  }
}
