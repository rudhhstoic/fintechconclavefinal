import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart'; // Import Syncfusion charts

class StockPredictionPage extends StatefulWidget {
  @override
  _StockPredictionPageState createState() => _StockPredictionPageState();
}

class _StockPredictionPageState extends State<StockPredictionPage>
    with TickerProviderStateMixin {
  String selectedPeriod = '1 wk';
  String stockName = 'ENTER THE STOCK NAME';
  double investmentAmount = 0;
  double? predictedAmount;
  double? absoluteReturn;
  double? percentReturn;
  double? niftyreturn;
  late AnimationController _controller;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  // Function to send data to the backend and get prediction result
  Future<void> getPrediction() async {
    final url = Uri.parse('http://127.0.0.1:5002/calculate_return');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "stockName": stockName,
          "investmentAmount": investmentAmount,
          "period": selectedPeriod,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          predictedAmount = result['stock_value'];
          absoluteReturn = result['absolute_return'];
          percentReturn = result['absolute_return'];
          niftyreturn = result['nifty_value'];
        });
      } else {
        throw Exception("Failed to fetch prediction");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB0C4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: Text(
          'Calculate potential returns',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'In $selectedPeriod you would have earned',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            Text(
              predictedAmount != null
                  ? '₹${predictedAmount!.toStringAsFixed(2)}'
                  : '₹0.00',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            Text(
              percentReturn != null
                  ? '${percentReturn!.toStringAsFixed(2)}% ABSOLUTE RETURN'
                  : '0% ABSOLUTE RETURN',
              style: TextStyle(
                color: percentReturn != null && percentReturn! < 0
                    ? Colors.red
                    : Colors.green,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InvestmentInfoCard(
                  amount: predictedAmount != null
                      ? '₹${predictedAmount!.toStringAsFixed(2)}'
                      : '₹0.00',
                  label: stockName,
                ),
                InvestmentInfoCard(
                  amount: niftyreturn != null
                      ? '₹${niftyreturn!.toStringAsFixed(2)}'
                      : '₹0.00',
                  label: 'NIFTY 50',
                ),
              ],
            ),
            SizedBox(height: 20),
            PeriodSelector(
              selectedPeriod: selectedPeriod,
              onPeriodSelected: (period) {
                setState(() {
                  selectedPeriod = period;
                });
              },
            ),
            SizedBox(height: 20),
            StockInputField(
              label: 'Stock name',
              hint: stockName,
              icon: Icons.search,
              onChanged: (value) {
                setState(() {
                  stockName = value;
                });
              },
            ),
            SizedBox(height: 10),
            StockInputField(
              label: 'Your investment amount',
              hint: '₹$investmentAmount',
              icon: Icons.attach_money,
              onChanged: (value) {
                setState(() {
                  investmentAmount = double.tryParse(value) ?? 0.0;
                });
              },
              isNumeric: true,
            ),
            SizedBox(height: 20),
            ScaleTransition(
              scale: _buttonScaleAnimation,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: Colors.black.withOpacity(0.2),
                  elevation: 6,
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _controller.forward().then((_) => _controller.reverse());
                  getPrediction();
                },
                child: Text('Get Graph', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 20),
            // 3D Bar Chart using Syncfusion with conditional colors
            if (predictedAmount != null && niftyreturn != null)
              Container(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  primaryYAxis: NumericAxis(isVisible: false),
                  plotAreaBorderWidth: 0,
                  series: <ChartSeries>[
                    ColumnSeries<ChartData, String>(
                      dataSource: [
                        ChartData(
                          'Nifty 50',
                          niftyreturn!,
                          niftyreturn! < investmentAmount
                              ? Colors.red
                              : Colors.green,
                        ),
                        ChartData(
                          stockName,
                          predictedAmount!,
                          predictedAmount! < investmentAmount
                              ? Colors.red
                              : Colors.green,
                        ),
                      ],
                      xValueMapper: (ChartData data, _) => data.label,
                      yValueMapper: (ChartData data, _) => data.value,
                      pointColorMapper: (ChartData data, _) => data.color,
                      width: 0.5,
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ],
                  tooltipBehavior: TooltipBehavior(enable: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Data model for chart
class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}

class InvestmentInfoCard extends StatelessWidget {
  final String amount;
  final String label;

  InvestmentInfoCard({required this.amount, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Text(
            amount,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodSelected;

  PeriodSelector(
      {required this.selectedPeriod, required this.onPeriodSelected});

  @override
  Widget build(BuildContext context) {
    final periods = ['1wk', '1mo', '3mo', '6mo', '1yr'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: periods.map((period) {
        return GestureDetector(
          onTap: () => onPeriodSelected(period),
          child: Chip(
            label: Text(period),
            backgroundColor:
                selectedPeriod == period ? Colors.blueAccent : Colors.grey[300],
          ),
        );
      }).toList(),
    );
  }
}

class StockInputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final bool isNumeric;

  StockInputField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.isNumeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: onChanged,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
    );
  }
}
