import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  PersonalInfoScreenState createState() => PersonalInfoScreenState();
}

class PersonalInfoScreenState extends State<PersonalInfoScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final name = authProvider.name ?? 'Unknown';
    final serialId = authProvider.serialId ?? 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 12, 80),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white], // Blue to white gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Customer info in a rectangular box
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue, // Start color
                      Color.fromARGB(255, 0, 12, 80), // End color
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/avatar.png'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: TextStyle(fontSize: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Customer ID : $serialId',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // List of options below
              Expanded(
                child: ListView(
                  children: [
                    _buildOptionTile(Icons.assignment, 'My Activity', () {
                      // Handle navigation or action for My Plans
                    }),
                    _buildOptionTile(Icons.lock, 'Change Login Credentials',
                        () {
                      // Handle navigation for changing login credentials
                    }),
                    _buildOptionTile(Icons.settings, 'Settings', () {
                      // Handle navigation for settings
                    }),
                    _buildOptionTile(Icons.help_outline, 'Need Help', () {
                      // Handle navigation or action for Need Help
                    }),
                    _buildOptionTile(Icons.logout, 'Logout', () {
                      Navigator.pushNamed(context, '/login');
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.pushNamed(context, '/botpopup'); // Navigate to chatbot
        },
        tooltip: 'Chatbot',
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Helper widget to build option tiles
  ListTile _buildOptionTile(IconData icon, String title, Function onTap) {
    return ListTile(
      leading: Icon(icon, color: Color.fromARGB(255, 0, 12, 80)),
      title: Text(title),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color.fromARGB(150, 0, 12, 80),
      ),
      onTap: () => onTap(),
    );
  }
}
