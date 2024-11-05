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

  @override
  void initState() {
    super.initState();
    fetchBudgets();
  }

  Future<void> fetchBudgets() async {
    final response = await http.get(
      Uri.parse('http://10.10.16.104:5004/get_budgets/${widget.serialId}'),
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
      Uri.parse('http://192.168.100.28:5004/set_budget'),
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

  void showSetBudgetDialog(String category) {
    TextEditingController limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Budget for $category"),
        content: TextField(
          controller: limitController,
          decoration: InputDecoration(hintText: "Enter budget limit"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setBudget(category, limitController.text);
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
      appBar: AppBar(title: Text("Budgets")),
      body: isLoading
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
                        Text("Limit: ₹${budget['limit']}"),
                        Text("Spent: ₹${budget['spent']}"),
                        Text("Remaining: ₹${budget['remaining']}"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.green),
                      onPressed: () {
                        showSetBudgetDialog(budget['category']);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showSetBudgetDialog("New Category"); // Customize as needed
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
