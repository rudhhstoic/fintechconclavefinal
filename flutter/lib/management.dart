import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'budgets.dart';
import 'vacation.dart';
import 'analysis.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

/*void main() {
  runApp(Management());
}

class Management extends StatelessWidget {
  const Management({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blueGrey,
        ),
        scaffoldBackgroundColor: Color(0xFFbdd0dc),
      ),
      home: HomeManage(),
    );
  }
}*/

class HomeManage extends StatefulWidget {
  const HomeManage({super.key});
  @override
  HomeManageState createState() => HomeManageState();
}

class HomeManageState extends State<HomeManage> {
  int _selectedIndex = 0;
  DateTime selectedDate = DateTime.now();
  List transactions = []; // Stores the transactions fetched
  List filteredTransactions = []; // Stores filtered transactions for the selected month
  double totalIncome = 0.0; // To store total income
  double totalExpense = 0.0; // To store total expense

  @override
  void initState() {
    super.initState();
    fetchTransactions(); // Fetch transactions when page loads
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
      fetchTransactions();
    });
  }

  void _goToNextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
      fetchTransactions();
    });
  }

  Future<void> fetchTransactions() async {
    final serialId =
        Provider.of<AuthProvider>(context, listen: false).serialId ?? 0;
    final url =
        'http://192.168.231.10:5000/get_transaction/${serialId}'; // Replace with actual Flask URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        transactions =
            json.decode(response.body); // Parse and store transactions
        filteredTransactions = transactions.where((t) {
          DateTime date = DateFormat('EEE, dd MMM yyyy').parse(t['transaction_date']);
          return date.month == selectedDate.month && date.year == selectedDate.year;
        }).toList();
        calculateTotals();
      });
    }
  }

  void calculateTotals() {
    totalIncome = 0.0;
    totalExpense = 0.0;
    for (var transaction in filteredTransactions) {
      final amount = double.parse(transaction['amount']);
      if (transaction['transaction_type'] == 'Income') {
        totalIncome += amount;
      } else if (transaction['transaction_type'] == 'Expense') {
        totalExpense += amount;
      }
    }
  }

  Widget _buildScreenContent() {
    final serialId =
        Provider.of<AuthProvider>(context, listen: false).serialId ?? 0;
    switch (_selectedIndex) {
      case 1:
        return HomePage(serialId: serialId); // Display the Analysis screen
      case 2:
        return BudgetPage(serialId: serialId); // Display the Budgets screen
      case 3:
        return VacationPage(serialId: serialId);
      default:
        return buildHomeScreen(); // Default to the main screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 12, 80),
        title: const Text(
          'Budget Planning',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(
            color: Colors.white), // Set back button color to white
      ),
      body: _buildScreenContent(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTransactionPage()),
                ).then((_) {
                  fetchTransactions(); // Fetch transactions again after adding a new one
                });
              },
              child: Icon(Icons.add),
              backgroundColor: Color(0xFF2d3e54),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mobile_friendly),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Savings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 0, 12, 80),
        unselectedItemColor: const Color.fromARGB(255, 45, 46, 46),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget buildHomeScreen() {
    String monthYear = DateFormat('MMMM yyyy').format(selectedDate);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: _goToPreviousMonth,
              ),
              Text(
                monthYear,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                onPressed: _goToNextMonth,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Text(
                  'Income',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Expense',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Text(
                  '₹${totalIncome.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '₹${totalExpense.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '₹${(totalIncome - totalExpense).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: (totalIncome - totalExpense) >= 0
                        ? Colors.green
                        : Colors.red,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Text(
                      'No transactions available',
                      style: TextStyle(fontSize: 18, color: Color(0xFF547788)),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      final isIncome = transaction['transaction_type'] ==
                          'Income'; // Determine if it's income
                      return ListTile(
                        title: Text(transaction['category']),
                        subtitle: Text('${transaction['transaction_date']}'),
                        trailing: Text(
                          '${isIncome ? '+' : '-'} ₹${transaction['amount']}',
                          style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red, // Set color
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});
  @override
  AddTransactionPageState createState() => AddTransactionPageState();
}

class AddTransactionPageState extends State<AddTransactionPage> {
  bool isIncome = true;
  String selectedCategory = 'Select Category';
  String notes = '';
  String displayText = '0';
  double firstOperand = 0.0;
  double secondOperand = 0.0;
  String operator = '';
  bool shouldResetDisplay = false;

  Future<void> _saveTransaction() async {
    final serialId =
        Provider.of<AuthProvider>(context, listen: false).serialId ?? 0;
    final transactionType = isIncome ? 'Income' : 'Expense';
    final url = 'http://192.168.231.10:5000/add_transaction';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'serial_id': serialId, // Replace with dynamic serial_id if available
        'transaction_type': transactionType,
        'category': selectedCategory,
        'amount': double.parse(displayText),
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true); // Return `true` to indicate success
    }
  }

  void _selectCategory() {
    List<Map<String, dynamic>> categories = isIncome
        ? [
            {'name': 'Salary', 'icon': Icons.attach_money},
            {'name': 'Interest', 'icon': Icons.savings},
            {'name': 'Awards', 'icon': Icons.emoji_events},
            {'name': 'Gifts', 'icon': Icons.card_giftcard},
          ]
        : [
            {'name': 'Beauty', 'icon': Icons.brush},
            {'name': 'Bills', 'icon': Icons.receipt},
            {'name': 'Automobile', 'icon': Icons.directions_car},
            {'name': 'Clothing', 'icon': Icons.checkroom},
            {'name': 'Education', 'icon': Icons.school},
            {'name': 'Entertainment', 'icon': Icons.movie},
            {'name': 'Food', 'icon': Icons.fastfood},
            {'name': 'Health', 'icon': Icons.local_hospital},
            {'name': 'Home', 'icon': Icons.home},
            {'name': 'Insurance', 'icon': Icons.security},
            {'name': 'Groceries', 'icon': Icons.shopping_cart},
            {'name': 'Tax', 'icon': Icons.account_balance},
            {'name': 'Recharge', 'icon': Icons.phone_android},
            {'name': 'Transportation', 'icon': Icons.emoji_transportation},
            {'name': 'Charity', 'icon': Icons.volunteer_activism},
          ];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(categories[index]['icon']),
                  title: Text(categories[index]['name']),
                  onTap: () {
                    setState(() {
                      selectedCategory = categories[index]['name'];
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        displayText = '0';
        firstOperand = 0.0;
        secondOperand = 0.0;
        operator = '';
        shouldResetDisplay = false;
      } else if (buttonText == '←') {
        // Backspace functionality
        if (displayText.length > 1) {
          displayText = displayText.substring(0, displayText.length - 1);
        } else {
          displayText = '0';
        }
      } else if (buttonText == '+' ||
          buttonText == '-' ||
          buttonText == '*' ||
          buttonText == '/') {
        operator = buttonText;
        firstOperand = double.parse(displayText);
        shouldResetDisplay = true;
      } else if (buttonText == '=') {
        secondOperand = double.parse(displayText);
        switch (operator) {
          case '+':
            displayText = (firstOperand + secondOperand).toString();
            break;
          case '-':
            displayText = (firstOperand - secondOperand).toString();
            break;
          case '*':
            displayText = (firstOperand * secondOperand).toString();
            break;
          case '/':
            displayText = secondOperand != 0
                ? (firstOperand / secondOperand).toString()
                : 'Error';
            break;
        }
        operator = '';
        shouldResetDisplay = true;
      } else {
        if (shouldResetDisplay) {
          displayText = buttonText;
          shouldResetDisplay = false;
        } else {
          displayText =
              displayText == '0' ? buttonText : displayText + buttonText;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budget Planning',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 12, 80),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: _saveTransaction,
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        iconTheme: IconThemeData(color: Colors.white),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIncomeExpenseButton('Income', true),
                  SizedBox(width: 16),
                  _buildIncomeExpenseButton('Expense', false),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 137, 180, 201),
                ),
                child: Text(
                  selectedCategory,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Notes',
                  filled: true,
                  fillColor: Color(0xFFeadfd6),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() {
                  notes = value;
                }),
              ),
              SizedBox(height: 16),
              TextField(
                controller: TextEditingController(text: displayText),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  filled: true,
                  fillColor: Color(0xFFeadfd6),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              SizedBox(height: 16),
              _buildCalculator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseButton(String label, bool isIncomeOption) {
    return ElevatedButton.icon(
      onPressed: () => setState(() {
        isIncome = isIncomeOption;
      }),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isIncome == isIncomeOption ? Colors.green : Color(0xFF547788),
      ),
      icon: Icon(
        isIncome == isIncomeOption ? Icons.check : Icons.money_off,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildCalculator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCalcButton('7'),
            _buildCalcButton('8'),
            _buildCalcButton('9'),
            _buildCalcButton('+'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCalcButton('4'),
            _buildCalcButton('5'),
            _buildCalcButton('6'),
            _buildCalcButton('-'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCalcButton('1'),
            _buildCalcButton('2'),
            _buildCalcButton('3'),
            _buildCalcButton('*'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCalcButton('0'),
            _buildCalcButton('C'),
            _buildCalcButton('←'),
            _buildCalcButton('/'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCalcButton('='), // Additional row for the equals button
          ],
        ),
      ],
    );
  }

  Widget _buildCalcButton(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => _onButtonPressed(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2d3e54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
          ),
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget buildIncomeOrExpenseButton(String label, bool isIncomeOption) {
    return ElevatedButton.icon(
      onPressed: () => setState(() {
        isIncome = isIncomeOption;
      }),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isIncome == isIncomeOption ? Colors.green : Color(0xFF547788),
      ),
      icon: Icon(
        isIncome == isIncomeOption ? Icons.check : Icons.money_off,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
