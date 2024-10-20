import 'package:flutter/material.dart';
//import 'base_scaffold.dart'; // Assuming you have a BaseScaffold or Scaffold-based class

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceHidden = true;
  String _selectedTimeOption = 'Today';

  // Dummy data for category-wise spending
  final Map<String, double> _categorySpending = {
    'Food': 200,
    'Transport': 100,
    'Groceries': 300,
    'Savings': 500,
    'Recharge': 50,
    'Bills': 150,
    'Other': 300,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile and account summary section
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/avatar.png'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Lorem Name',
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Lorem ipsum dolor',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: const Color.fromRGBO(255, 25, 25, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            ' Savings Account',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            ' **** **** **** 1234',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isBalanceHidden ? ' ₹XXXXXX' : ' ₹236,678.25',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isBalanceHidden
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isBalanceHidden = !_isBalanceHidden;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Statistics',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            // Options: Today, Weekly, Monthly, Yearly
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: _selectedTimeOption == 'Today',
                    onSelected: (isSelected) {
                      setState(() {
                        _selectedTimeOption = 'Today';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Weekly'),
                    selected: _selectedTimeOption == 'Weekly',
                    onSelected: (isSelected) {
                      setState(() {
                        _selectedTimeOption = 'Weekly';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Monthly'),
                    selected: _selectedTimeOption == 'Monthly',
                    onSelected: (isSelected) {
                      setState(() {
                        _selectedTimeOption = 'Monthly';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Yearly'),
                    selected: _selectedTimeOption == 'Yearly',
                    onSelected: (isSelected) {
                      setState(() {
                        _selectedTimeOption = 'Yearly';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Placeholder for line chart
            Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Text('Line Chart Placeholder')),
            ),
            const SizedBox(height: 20),

            // Category-wise Spending
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Category-wise Spending',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: _categorySpending.entries.map((entry) {
                  return ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(entry.key),
                    trailing: Text('\$${entry.value.toStringAsFixed(2)}'),
                  );
                }).toList(),
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
}
