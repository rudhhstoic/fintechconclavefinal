// Enhanced tax_calculate.dart - Removed rotation animation, improved layout, added responsiveness, refined styles for professional look

import 'dart:convert';
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

class _TaxResultPageState extends State<TaxResultPage> {
  List<dynamic> mutualFunds = [];

  @override
  void initState() {
    super.initState();
    fetchMutualFunds();
  }

  Future<void> fetchMutualFunds() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.231.10:5000/mutualfunds'));
      if (response.statusCode == 200) {
        List<dynamic> fundsData = json.decode(response.body);
        setState(() {
          mutualFunds = fundsData.where((fund) => fund['category']['sub'] == 'ELSS').take(3).toList();
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
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 600;
    final padding = isWideScreen ? 32.0 : 16.0;
    final cardRadius = BorderRadius.circular(20.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tax Results',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCard(screenSize, padding, cardRadius),
                  SizedBox(height: padding),
                  _buildChartCard(screenSize, padding, cardRadius),
                  if (mutualFunds.isNotEmpty) ...[
                    SizedBox(height: padding),
                    _buildRecommendationsSection(screenSize, padding, cardRadius),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Size screenSize, double padding, BorderRadius cardRadius) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tax Summary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
            SizedBox(height: padding / 2),
            Divider(color: Colors.blue.shade100),
            SizedBox(height: padding / 2),
            _buildSummaryItem('Actual Tax', widget.actualTax),
            _buildSummaryItem('Total Deductions', widget.totalDeductions),
            _buildSummaryItem('Tax After Deductions', widget.taxAfterDeductions, isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 18, color: Colors.grey.shade800)),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.blue.shade900 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(Size screenSize, double padding, BorderRadius cardRadius) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tax Breakdown',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
            SizedBox(height: padding),
            SizedBox(
              height: screenSize.height * 0.35,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  majorGridLines: MajorGridLines(width: 0),
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                ),
                primaryYAxis: NumericAxis(
                  labelFormat: '{value}',
                  majorGridLines: MajorGridLines(color: Colors.grey.shade200),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  BarSeries<_TaxData, String>(
                    dataSource: [
                      _TaxData('Actual Tax', widget.actualTax),
                      _TaxData('Deductions', widget.totalDeductions),
                      _TaxData('Final Tax', widget.taxAfterDeductions),
                    ],
                    xValueMapper: (_TaxData data, _) => data.label,
                    yValueMapper: (_TaxData data, _) => data.amount,
                    dataLabelSettings: DataLabelSettings(isVisible: true, textStyle: TextStyle(fontWeight: FontWeight.bold)),
                    pointColorMapper: (_TaxData data, index) {
                      return [Colors.redAccent, Colors.amberAccent, Colors.greenAccent][index];
                    },
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(Size screenSize, double padding, BorderRadius cardRadius) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Investment Recommendations',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
        ),
        SizedBox(height: padding / 2),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: mutualFunds.length,
          itemBuilder: (context, index) {
            final fund = mutualFunds[index];
            return Card(
              elevation: 6,
              margin: EdgeInsets.only(bottom: padding / 2),
              shape: RoundedRectangleBorder(borderRadius: cardRadius),
              child: ExpansionTile(
                title: Text(
                  fund['name'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
                subtitle: Text(
                  '${fund['category']['main']} - ${fund['category']['sub']}',
                  style: TextStyle(color: Colors.blue.shade600),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(padding / 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildReturnChip('1M', fund['return_1_month']),
                        _buildReturnChip('3M', fund['return_3_month']),
                        _buildReturnChip('6M', fund['return_6_month']),
                        _buildReturnChip('1Y', fund['return_per_annum']),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReturnChip(String label, dynamic value) {
    final double parsed = double.tryParse(value.toString()) ?? 0.0;
    return Chip(
      label: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text('${parsed.toStringAsFixed(1)}%', style: TextStyle(color: parsed > 0 ? Colors.green : Colors.red)),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

class _TaxData {
  final String label;
  final double amount;

  _TaxData(this.label, this.amount);
}