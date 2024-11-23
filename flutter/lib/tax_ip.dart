import 'package:flutter/material.dart';
import 'package:flutter_application_1/tax_calculate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Tax Calculator',
      home: TaxCalculatorInputPage(),
    );
  }
}

class TaxCalculatorInputPage extends StatefulWidget {
  const TaxCalculatorInputPage({super.key});

  @override
  _TaxCalculatorInputPageState createState() => _TaxCalculatorInputPageState();
}

class _TaxCalculatorInputPageState extends State<TaxCalculatorInputPage> {
  String selectedFinancialYear = '2023-24';
  String selectedAgeGroup = 'Below 60';
  String selectedEmploymentStatus = 'Salaried';
  double basicIncome = 0;
  bool hasSpecialIncome = false;

  // Fields for additional income
  double incomeFromSavingsInterest = 0;
  double interestOnDeposits = 0;
  double incomeFromRentals = 0;
  double otherIncome = 0;

  // Salaried specific fields
  double hraReceived = 0;
  double specialAllowance = 0;
  double dearnessAllowance = 0;
  double epfContribution = 0;

  // Capital gains
  double equityInvestments = 0;
  double debtInvestments = 0;
  double realEstateInvestments = 0;
  double unlistedSharesInvestments = 0;

  // Deductions
  double deduction80C = 0;
  double deduction80D = 0;
  double deduction80E = 0;
  double deduction80G = 0;
  void onCalculateTaxPressed() {
    Map<String, dynamic> userInputData = {
      'financial_year': selectedFinancialYear,
      'basic_income': basicIncome,
      'special_income': hasSpecialIncome
          ? incomeFromSavingsInterest +
              interestOnDeposits +
              incomeFromRentals +
              otherIncome
          : 0,
      'hra_received': hraReceived,
      'deductions': {
        'deduction80C': deduction80C,
        'deduction80D': deduction80D,
        'deduction80E': deduction80E,
        'deduction80G': deduction80G,
      },
      'capital_gains': {
        'equityInvestments': equityInvestments,
        'debtInvestments': debtInvestments,
        'realEstateInvestments': realEstateInvestments,
        'unlistedSharesInvestments': unlistedSharesInvestments,
      },
    };

    calculateTax(context, userInputData);
  }

  Future<void> calculateTax(
      BuildContext context, Map<String, dynamic> userData) async {
    final url = Uri.parse(
        'http://127.0.0.1:5006/calculate_tax'); // Update with your backend URL
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaxResultPage(data)),
        );
      } else {
        throw Exception('Failed to calculate tax');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  // Special Income dropdown visibility
  bool showSpecialIncome = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Making the body scrollable
        child: Container(
          color: Colors.white, // Setting background color to white
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading section
              Center(
                child: Text(
                  'Tax Calculator',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Box containing the input fields for Employment Status and Basic Salary
              _buildInputBox(
                leftColumn: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Employment Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedEmploymentStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedEmploymentStatus = value!;
                        });
                      },
                      items: ['Salaried', 'Self-Employed']
                          .map((status) => DropdownMenuItem(
                              value: status, child: Text(status)))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Basic Salary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    _buildTextField(
                      label: 'Enter Basic Salary',
                      onChanged: (value) {
                        basicIncome = double.tryParse(value) ?? 0;
                      },
                    ),
                  ],
                ),
                rightColumn: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Financial Year',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedFinancialYear,
                      onChanged: (value) {
                        setState(() {
                          selectedFinancialYear = value!;
                        });
                      },
                      items: ['2023-24', '2022-23', '2024-25']
                          .map((year) =>
                              DropdownMenuItem(value: year, child: Text(year)))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Age Group',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: selectedAgeGroup,
                      onChanged: (value) {
                        setState(() {
                          selectedAgeGroup = value!;
                        });
                      },
                      items: ['Below 60', '60-80', 'Above 80']
                          .map((age) =>
                              DropdownMenuItem(value: age, child: Text(age)))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSpecialIncomeSection(),
              const SizedBox(height: 20),
              _buildCapitalGainsSection(),
              const SizedBox(height: 20),
              _buildSalariedIncomeSection(),
              const SizedBox(height: 20),
              _buildDeductionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox(
      {required Widget leftColumn, required Widget rightColumn}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black54, // Light black border color
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: leftColumn), // Left side
          const SizedBox(width: 16),
          Expanded(child: rightColumn), // Right side
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required Function(String) onChanged,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSpecialIncomeSection() {
    return _buildSectionBox(
      title: 'Special Income',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: const Text("Include Special Income"),
            value: showSpecialIncome,
            onChanged: (bool? value) {
              setState(() {
                showSpecialIncome = value!;
              });
            },
          ),
          if (showSpecialIncome) ...[
            _buildTextField(
              label: 'Income from Savings Interest',
              onChanged: (value) {
                incomeFromSavingsInterest = double.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Interest on Deposits',
              onChanged: (value) {
                interestOnDeposits = double.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Income from Rentals',
              onChanged: (value) {
                incomeFromRentals = double.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 10),
            _buildTextField(
              label: 'Other Income',
              onChanged: (value) {
                otherIncome = double.tryParse(value) ?? 0;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapitalGainsSection() {
    return _buildSectionBox(
      title: 'Capital Gains',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'Equity Investments',
            onChanged: (value) {
              equityInvestments = double.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'Debt Investments',
            onChanged: (value) {
              debtInvestments = double.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'Real Estate Investments',
            onChanged: (value) {
              realEstateInvestments = double.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'Unlisted Shares Investments',
            onChanged: (value) {
              unlistedSharesInvestments = double.tryParse(value) ?? 0;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSalariedIncomeSection() {
    return _buildSectionBox(
      title: 'Salaried Income',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'HRA Received',
            onChanged: (value) {
              hraReceived = double.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'Special Allowance',
            onChanged: (value) {
              specialAllowance = double.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'Dearness Allowance',
            onChanged: (value) {
              dearnessAllowance = double.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'EPF Contribution',
            onChanged: (value) {
              epfContribution = double.tryParse(value) ?? 0;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsSection() {
    return _buildSectionBox(
      title: 'Deductions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: '80C Deductions',
            onChanged: (value) {
              deduction80C = double.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: '80D Deductions',
            onChanged: (value) {
              deduction80D = double.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: '80E Deductions',
            onChanged: (value) {
              deduction80E = double.tryParse(value) ?? 0;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: '80G Deductions',
            onChanged: (value) {
              deduction80G = double.tryParse(value) ?? 0;
            },
          ),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: onCalculateTaxPressed,
              child: Text('Calculate Tax'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBox({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black54,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
