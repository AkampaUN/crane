import 'package:crane/Screens/home_screen.dart';
import 'package:crane/Screens/mymanager_screen.dart';
import 'package:flutter/material.dart';
import 'Screens/login_screen.dart';
import 'package:crane/Screens/signup_screen.dart';
import 'package:crane/models/task_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
//import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Awesome Notifications
  await _initializeNotifications();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: Text(
          'Oops! ${details.exceptionAsString()}',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => TaskProvider())],
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeNotifications() async {
  await AwesomeNotifications().initialize(
    null, // Use default app icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic alerts',
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelKey: 'task_reminders',
        channelName: 'Task Reminders',
        channelDescription: 'Notification channel for task reminders',
        defaultColor: Colors.green,
        ledColor: Colors.green,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelKey: 'messages_channel',
        channelName: 'Messages',
        channelDescription: 'Channel for message notifications',
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        importance: NotificationImportance.High,
      ),
    ],
    debug: true, // Only for development
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CirroCloud Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            );
          }

          return snapshot.hasData ? const HomeScreen() : const LoginScreen();
        },
      ),
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/time-management': (context) => const MyManagerScreen(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('Page not found!'))),
      ),
    );
  }
}
