import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tax Calculation Result'),
        backgroundColor: Colors.lightBlue, // Light Blue AppBar
      ),
      body: Container(
        color: Color(0xFFEDE7F6), // Cool Gray background color
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
                      minHeight: 200, // Increase this height as needed
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax Calculation Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333), // Charcoal text color
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Actual Tax: \$${widget.actualTax.toStringAsFixed(2)}',
                          style:
                              TextStyle(fontSize: 16, color: Color(0xFF333333)),
                        ),
                        Text(
                          'Total Deductions: \$${widget.totalDeductions.toStringAsFixed(2)}',
                          style:
                              TextStyle(fontSize: 16, color: Color(0xFF333333)),
                        ),
                        Text(
                          'Tax After Deductions: \$${widget.taxAfterDeductions.toStringAsFixed(2)}',
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
                          color: Color(0xFF333333), // Charcoal text color
                        ),
                      ),
                      SizedBox(height: 10),
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        series: <ChartSeries>[
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
