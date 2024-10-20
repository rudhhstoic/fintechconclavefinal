import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  PersonalInfoScreenState createState() => PersonalInfoScreenState();
}

class PersonalInfoScreenState extends State<PersonalInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Padding(
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
                    Color.fromRGBO(175, 25, 25, 1), // Start color
                    Color.fromARGB(255, 211, 148, 12), // End color
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/avatar.png'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Lorem Name',
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Customer ID : 123456',
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
                  _buildOptionTile(Icons.show_chart, 'My Stocks', () {
                    // Handle navigation or action for My Stocks
                  }),
                  _buildOptionTile(Icons.assignment, 'My Plans', () {
                    // Handle navigation or action for My Plans
                  }),
                  _buildOptionTile(Icons.lock, 'Change Login Credentials', () {
                    // Handle navigation for changing login credentials
                  }),
                  _buildOptionTile(Icons.settings, 'Settings', () {
                    // Handle navigation for settings
                  }),
                  _buildOptionTile(Icons.help_outline, 'Need Help', () {
                    // Handle navigation or action for Need Help
                  }),
                  _buildOptionTile(Icons.logout, 'Logout', () {
                    // Handle logout action
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/botpopup'); // Navigate to chatbot
        },
        tooltip: 'Chatbot',
        child: const Icon(Icons.chat),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Helper widget to build option tiles
  ListTile _buildOptionTile(IconData icon, String title, Function onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => onTap(),
    );
  }
}
