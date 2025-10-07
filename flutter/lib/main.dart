import 'package:flutter/material.dart';
import 'package:flutter_application_1/management.dart';
//import 'dashboard.dart';
import 'botpopup.dart';
import 'personalinfo.dart';
import 'statement_analyse.dart';
import 'stock.dart';
import 'auth_provider.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'mutual_fund_page.dart';
import 'tax_ip.dart';
import 'reminder.dart';
import 'article.dart';
import 'theme_provider.dart';
import 'home.dart'; 
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) =>
                AuthProvider()), // Auth Provider for state management
        ChangeNotifierProvider(
            create: (_) =>
                ThemeProvider()), // Theme Provider for dark/light mode
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'FinBuild',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(255, 22, 1, 58),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(255, 22, 1, 58),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeProvider.themeMode,
          routes: {
            '/': (context) => LandingPage(),
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/dashboard': (context) => HomePage(),
            //'/dashboard': (context) => const DashboardScreen(),
            '/botpopup': (context) => const ChatbotScreen(),
            '/personalinfo': (context) => const PersonalInfoScreen(),
            '/statement_analyse': (context) => UploadPage(),
            '/stock': (context) => StockPredictionPage(),
            '/management': (context) => const HomeManage(),
            '/mutualfunds': (context) => MutualFundPage(),
            '/tax': (context) => TaxCalculatorInputPage(),
            '/reminder': (context) => ReminderPage(),
            '/article': (context) => FinanceHomePage(),
          },
          initialRoute: '/',
        );
      },
    );
  }
}
/*
class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 18, // Adjust size
              backgroundImage: AssetImage('assets/avatar.png'), // Asset image
            ),
            onPressed: () {
              // Navigate to personal information screen
              Navigator.pushNamed(context, '/personalinfo');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to Money Matters!',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: const Text('Go to Dashboard'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/statement_analyse');
              },
              child: const Text('Go to Upload Page'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/stock_predict');
              },
              child: const Text('Go to Stocks'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/management');
              },
              child: const Text('Go to management'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/botpopup');
        },
        tooltip: 'Chatbot',
        child: const Icon(Icons.chat),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
*/