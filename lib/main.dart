import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiznetic_flutter/services/auth_service.dart';
import 'package:quiznetic_flutter/screens/difficulty_screen.dart';
import 'package:quiznetic_flutter/screens/home_screen.dart';
import 'package:quiznetic_flutter/screens/quiz_screen.dart';
import 'package:quiznetic_flutter/screens/result_screen.dart';
import 'package:quiznetic_flutter/screens/user_profile_screen.dart';
import 'package:quiznetic_flutter/screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Attempt anonymous sign-in using AuthService (which handles Firestore doc creation)
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      // Let AuthService handle both auth and Firestore doc creation
      final authService = AuthService();
      final cred = await authService.signInAnonymously();
      debugPrint('✅ Signed in and created user ${cred.user!.uid}');
    } else {
      debugPrint('✅ Using existing auth: ${auth.currentUser!.uid}');
    }
  } on FirebaseAuthException catch (e) {
    // Handle known Firebase auth errors
    debugPrint('🔐 Auth error [${e.code}]: ${e.message}');
  } catch (e) {
    // Catch anything else
    debugPrint('❌ Unexpected auth error: $e');
  }
  runApp(const QuizNetic());
}

class QuizNetic extends StatelessWidget {
  const QuizNetic({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Build the ColorScheme once:
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6A1B9A),
      brightness: Brightness.light,
    );

    // Override just the roles we want:
    final scheme = base.copyWith(
      secondary: Colors.green, // correct-answer green
      onSecondary: Colors.white, // text on the green
      error: Colors.red, // wrong-answer red
      onError: Colors.white, // text on red
      surfaceContainerHighest: Colors.grey.shade300, // unselected button grey
      onSurfaceVariant: Colors.black87, // text on grey
    );

    return MaterialApp(
      title: 'QuizNetic',
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        QuizScreen.routeName: (_) => const QuizScreen(),
        ResultScreen.routeName: (_) => const ResultScreen(),
        DifficultyScreen.routeName: (_) => const DifficultyScreen(),
        UserProfileScreen.routeName: (_) => const UserProfileScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
      },
      theme: ThemeData(
        // Opt in to Material 3 so background/onBackground are honored:
        useMaterial3: true,

        // Supply your generated scheme:
        colorScheme: scheme,

        // Now you can reference scheme.background without error:
        scaffoldBackgroundColor: scheme.surface,
        // Button styling uses scheme.primary / scheme.onPrimary:
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(48),
          ),
        ),

        // AppBar uses scheme.surface / scheme.onSurface:
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
