// Enhanced tax_ip.dart - Improved responsiveness, added form validation, currency formatting, collapsible sections, professional styling

import 'package:flutter/material.dart';
import 'package:flutter_application_1/tax_calculate.dart'; // Update to match your file structure
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tax Calculator',
      theme: ThemeData(
        primaryColor: Colors.blue.shade800,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          prefixStyle: TextStyle(color: Colors.grey.shade900),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const TaxCalculatorInputPage(),
    );
  }
}

class TaxCalculatorInputPage extends StatefulWidget {
  const TaxCalculatorInputPage({super.key});

  @override
  _TaxCalculatorInputPageState createState() => _TaxCalculatorInputPageState();
}

class _TaxCalculatorInputPageState extends State<TaxCalculatorInputPage> {
  final _formKey = GlobalKey<FormState>();
  String selectedFinancialYear = '2023-24';
  String selectedAgeGroup = 'Below 60';
  String selectedEmploymentStatus = 'Salaried';
  final NumberFormat currencyFormat = NumberFormat('#,###');

  // Input controllers for better control
  final TextEditingController basicIncomeController = TextEditingController();
  final TextEditingController savingsInterestController = TextEditingController();
  final TextEditingController depositsInterestController = TextEditingController();
  final TextEditingController rentalsIncomeController = TextEditingController();
  final TextEditingController otherIncomeController = TextEditingController();
  final TextEditingController hraController = TextEditingController();
  final TextEditingController specialAllowanceController = TextEditingController();
  final TextEditingController dearnessAllowanceController = TextEditingController();
  final TextEditingController epfController = TextEditingController();
  final TextEditingController equityController = TextEditingController();
  final TextEditingController debtController = TextEditingController();
  final TextEditingController realEstateController = TextEditingController();
  final TextEditingController unlistedSharesController = TextEditingController();
  final TextEditingController ded80CController = TextEditingController();
  final TextEditingController ded80DController = TextEditingController();
  final TextEditingController ded80EController = TextEditingController();
  final TextEditingController ded80GController = TextEditingController();

  bool showSpecialIncome = false;

  @override
  void dispose() {
    // Dispose controllers
    basicIncomeController.dispose();
    savingsInterestController.dispose();
    depositsInterestController.dispose();
    rentalsIncomeController.dispose();
    otherIncomeController.dispose();
    hraController.dispose();
    specialAllowanceController.dispose();
    dearnessAllowanceController.dispose();
    epfController.dispose();
    equityController.dispose();
    debtController.dispose();
    realEstateController.dispose();
    unlistedSharesController.dispose();
    ded80CController.dispose();
    ded80DController.dispose();
    ded80EController.dispose();
    ded80GController.dispose();
    super.dispose();
  }

  void onCalculateTaxPressed() {
    if (_formKey.currentState!.validate()) {
      final userInputData = {
        'financial_year': selectedFinancialYear,
        'basic_income': _parseCurrency(basicIncomeController.text),
        'special_income': showSpecialIncome
            ? _parseCurrency(savingsInterestController.text) +
              _parseCurrency(depositsInterestController.text) +
              _parseCurrency(rentalsIncomeController.text) +
              _parseCurrency(otherIncomeController.text)
            : 0.0,
        'hra_received': _parseCurrency(hraController.text),
        'deductions': {
          'deduction80C': _parseCurrency(ded80CController.text),
          'deduction80D': _parseCurrency(ded80DController.text),
          'deduction80E': _parseCurrency(ded80EController.text),
          'deduction80G': _parseCurrency(ded80GController.text),
        },
        'capital_gains': {
          'equityInvestments': _parseCurrency(equityController.text),
          'debtInvestments': _parseCurrency(debtController.text),
          'realEstateInvestments': _parseCurrency(realEstateController.text),
          'unlistedSharesInvestments': _parseCurrency(unlistedSharesController.text),
        },
      };

      calculateTax(context, userInputData);
    }
  }

  double _parseCurrency(String value) {
    return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
  }

  Future<void> calculateTax(BuildContext context, Map<String, dynamic> userData) async {
    final url = Uri.parse('http://192.168.231.10:5000/calculate_tax');
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 600;
    final padding = isWideScreen ? 32.0 : 16.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Tax Calculator',
          style: TextStyle(fontFamily: 'Lobster', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 0, 12, 80), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(padding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildBasicInfoSection(screenSize, padding, isWideScreen),
                      SizedBox(height: padding),
                      _buildExpandableSection('Special Income', _buildSpecialIncomeFields(padding)),
                      SizedBox(height: padding),
                      _buildExpandableSection('Capital Gains', _buildCapitalGainsFields(padding)),
                      SizedBox(height: padding),
                      _buildExpandableSection('Salaried Income', _buildSalariedIncomeFields(padding)),
                      SizedBox(height: padding),
                      _buildExpandableSection('Deductions', _buildDeductionsFields(padding)),
                      SizedBox(height: padding),
                      Center(
                        child: ElevatedButton(
                          onPressed: onCalculateTaxPressed,
                          child: const Text('Calculate Tax'),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(Size screenSize, double padding, bool isWideScreen) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: isWideScreen
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildEmploymentColumn(padding)),
                  SizedBox(width: padding),
                  Expanded(child: _buildYearAgeColumn(padding)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmploymentColumn(padding),
                  SizedBox(height: padding),
                  _buildYearAgeColumn(padding),
                ],
              ),
      ),
    );
  }

  Widget _buildEmploymentColumn(double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Employment Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedEmploymentStatus,
          onChanged: (value) => setState(() => selectedEmploymentStatus = value!),
          items: ['Salaried', 'Self-Employed'].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
        ),
        SizedBox(height: padding),
        Text('Basic Salary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
        SizedBox(height: 8),
        _buildCurrencyField(basicIncomeController, 'Enter Basic Salary'),
      ],
    );
  }

  Widget _buildYearAgeColumn(double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Financial Year', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedFinancialYear,
          onChanged: (value) => setState(() => selectedFinancialYear = value!),
          items: ['2023-24', '2022-23', '2024-25'].map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
        ),
        SizedBox(height: padding),
        Text('Age Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedAgeGroup,
          onChanged: (value) => setState(() => selectedAgeGroup = value!),
          items: ['Below 60', '60-80', 'Above 80'].map((age) => DropdownMenuItem(value: age, child: Text(age))).toList(),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(String title, Widget content) {
    return Card(
      child: ExpansionTile(
        title: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
        children: [content],
      ),
    );
  }

  Widget _buildSpecialIncomeFields(double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Include Special Income', style: TextStyle(color: Colors.grey.shade800)),
            value: showSpecialIncome,
            activeColor: Colors.blue.shade700,
            onChanged: (value) => setState(() => showSpecialIncome = value),
          ),
          if (showSpecialIncome) ...[
            SizedBox(height: padding / 2),
            _buildCurrencyField(savingsInterestController, 'Savings Interest'),
            SizedBox(height: padding / 2),
            _buildCurrencyField(depositsInterestController, 'Deposits Interest'),
            SizedBox(height: padding / 2),
            _buildCurrencyField(rentalsIncomeController, 'Rental Income'),
            SizedBox(height: padding / 2),
            _buildCurrencyField(otherIncomeController, 'Other Income'),
          ],
        ],
      ),
    );
  }

  Widget _buildCapitalGainsFields(double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildCurrencyField(equityController, 'Equity Investments'),
          SizedBox(height: padding / 2),
          _buildCurrencyField(debtController, 'Debt Investments'),
          SizedBox(height: padding / 2),
          _buildCurrencyField(realEstateController, 'Real Estate'),
          SizedBox(height: padding / 2),
          _buildCurrencyField(unlistedSharesController, 'Unlisted Shares'),
        ],
      ),
    );
  }

  Widget _buildSalariedIncomeFields(double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildCurrencyField(hraController, 'HRA Received'),
          SizedBox(height: padding / 2),
          _buildCurrencyField(specialAllowanceController, 'Special Allowance'),
          SizedBox(height: padding / 2),
          _buildCurrencyField(dearnessAllowanceController, 'Dearness Allowance'),
          SizedBox(height: padding / 2),
          _buildCurrencyField(epfController, 'EPF Contribution'),
        ],
      ),
    );
  }

  Widget _buildDeductionsFields(double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildCurrencyField(ded80CController, '80C Deductions'),
          SizedBox(height: padding / 2),
          _buildCurrencyField(ded80DController, '80D Deductions'),
          SizedBox(height: padding / 2),
          _buildCurrencyField(ded80EController, '80E Deductions'),
          SizedBox(height: padding / 2),
          _buildCurrencyField(ded80GController, '80G Deductions'),
        ],
      ),
    );
  }

  Widget _buildCurrencyField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final cleanValue = value.replaceAll(',', '');
        final formatted = currencyFormat.format(double.tryParse(cleanValue) ?? 0);
        if (formatted != value) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
      validator: (value) {
        if (value != null && value.isNotEmpty && double.tryParse(value.replaceAll(',', '')) == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }
}