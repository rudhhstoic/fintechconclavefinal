import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: BudgetPage(serialId: 1), // Replace 123 with the actual serialId
    );
  }
}

class BudgetPage extends StatefulWidget {
  final int serialId; // Add user's serial ID for API calls
  BudgetPage({required this.serialId});

  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<dynamic> budgets = [];
  bool isLoading = true;
  final List<String> categories = [
    'Beauty',
    'Bills',
    'Automobile',
    'Clothing',
    'Education',
    'Entertainment',
    'Food',
    'Health',
    'Home',
    'Insurance',
    'Groceries',
    'Tax',
    'Recharge',
    'Transportation',
    'Charity'
  ];
  String selectedCategory = 'Food';

  @override
  void initState() {
    super.initState();
    fetchBudgets();
  }

  Future<void> fetchBudgets() async {
    final response = await http.get(
      Uri.parse('http://192.168.231.10:5000/get_budgets/${widget.serialId}'),
    );

    if (response.statusCode == 200) {
      setState(() {
        budgets = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print("Failed to load budgets");
    }
  }

  Future<void> setBudget(String category, String limit) async {
    final response = await http.post(
      Uri.parse('http://192.168.231.10:5000/set_budget'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'serial_id': widget.serialId,
        'category': category,
        'limit': limit,
      }),
    );

    if (response.statusCode == 200) {
      print("Budget set successfully");
      fetchBudgets(); // Refresh budgets
    } else {
      print("Failed to set budget");
    }
  }

  void showSetBudgetDialog({String? initialCategory}) {
    TextEditingController limitController = TextEditingController();
    selectedCategory = categories.contains(initialCategory)
        ? initialCategory!
        : categories.first;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Budget"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                });
              },
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              decoration: InputDecoration(labelText: "Select Category"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: limitController,
              decoration: InputDecoration(hintText: "Enter budget limit"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setBudget(selectedCategory, limitController.text);
              Navigator.of(context).pop();
            },
            child: Text("Set"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white], // Blue to white gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      leading: Icon(Icons.category, color: Colors.orange),
                      title: Text(budget['category']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Limit: ₹${budget['budget_limit']}"),
                          Text("Spent: ₹${budget['spent']}"),
                          Text("Remaining: ₹${budget['remaining']}"),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.green),
                        onPressed: () {
                          showSetBudgetDialog(
                              initialCategory: budget['category']);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showSetBudgetDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
