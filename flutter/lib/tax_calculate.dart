import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class TaxResultPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final double actualTax;
  final double totalDeductions;
  final double taxAfterDeductions;

  TaxResultPage(this.data)
      : actualTax = data['total_tax_liability'] ?? 0.0,
        totalDeductions = data['total_deductions'] ?? 0.0,
        taxAfterDeductions = data['actual_tax'] ?? 0.0;

  @override
  _TaxResultPageState createState() => _TaxResultPageState();
}

class _TaxResultPageState extends State<TaxResultPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  List<dynamic> mutualFunds = []; // List to store mutual fund schemes

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..forward();
    fetchMutualFunds(); // Fetch mutual funds when the page loads
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Function to fetch mutual fund data from the API
  Future<void> fetchMutualFunds() async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:5000/mutualfunds'));
      if (response.statusCode == 200) {
        List<dynamic> fundsData = json.decode(response.body);
        setState(() {
          mutualFunds = fundsData
              .where((fund) => fund['category']['sub'] == 'ELSS')
              .take(3)
              .toList();
        });
      } else {
        print('Failed to load mutual funds');
      }
    } catch (e) {
      print('Error fetching mutual funds: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 12, 80),
        title: const Text(
          'Tax Calculator',
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
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    constraints: BoxConstraints(
                      minWidth: double.infinity,
                      minHeight: 200,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax Calculation Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Actual Tax: ₹${widget.actualTax.toStringAsFixed(2)}',
                          style:
                              TextStyle(fontSize: 16, color: Color(0xFF333333)),
                        ),
                        Text(
                          'Total Deductions: ₹${widget.totalDeductions.toStringAsFixed(2)}',
                          style:
                              TextStyle(fontSize: 16, color: Color(0xFF333333)),
                        ),
                        Text(
                          'Tax After Deductions: ₹${widget.taxAfterDeductions.toStringAsFixed(2)}',
                          style:
                              TextStyle(fontSize: 16, color: Color(0xFF333333)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                color: Colors.white,
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax vs Deductions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 10),
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        series: <CartesianSeries>[
                          ColumnSeries<_TaxData, String>(
                            dataSource: [
                              _TaxData('Actual Tax', widget.actualTax),
                              _TaxData('Deductions', widget.totalDeductions),
                              _TaxData('Tax After Deductions',
                                  widget.taxAfterDeductions),
                            ],
                            xValueMapper: (_TaxData data, _) => data.label,
                            yValueMapper: (_TaxData data, _) => data.amount,
                            dataLabelSettings:
                                DataLabelSettings(isVisible: true),
                            pointColorMapper: (_TaxData data, index) {
                              if (index == 0) return Colors.red;
                              if (index == 1) return Colors.yellow;
                              return Colors.blue;
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Display mutual fund recommendations
              if (mutualFunds.isNotEmpty) ...[
                SizedBox(height: 20),
                Text(
                  'Recommended Mutual Fund Schemes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: mutualFunds.length,
                  itemBuilder: (context, index) {
                    final fund = mutualFunds[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: Color.fromARGB(255, 244, 244, 252),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fund['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              fund['category']['main'],
                              style:
                                  TextStyle(fontSize: 14, color: Colors.blue),
                            ),
                            SizedBox(height: 4),
                            Text(
                              fund['category']['sub'],
                              style:
                                  TextStyle(fontSize: 14, color: Colors.orange),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text('1M'),
                                    Icon(Icons.arrow_upward,
                                        color: Colors.green, size: 16),
                                    Text('${fund['return_1_month']}%'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('3M'),
                                    Icon(Icons.arrow_upward,
                                        color: Colors.green, size: 16),
                                    Text('${fund['return_3_month']}%'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('6M'),
                                    Icon(Icons.arrow_upward,
                                        color: Colors.green, size: 16),
                                    Text('${fund['return_6_month']}%'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('1Y'),
                                    Icon(Icons.arrow_upward,
                                        color: Colors.green, size: 16),
                                    Text('${fund['return_per_annum']}%'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxData {
  final String label;
  final double amount;

  _TaxData(this.label, this.amount);
}
