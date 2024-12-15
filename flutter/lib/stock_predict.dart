import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class StockAnalysisPage extends StatefulWidget {
  const StockAnalysisPage({super.key});
  @override
  StockAnalysisPageState createState() => StockAnalysisPageState();
}

class StockAnalysisPageState extends State<StockAnalysisPage> {
  final _stocks = ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'MARUTI.NS'];
  String? _selectedStock;
  DateTime? _startDate;
  DateTime? _endDate = DateTime.now().subtract(const Duration(days: 1));
  List<double> actualStockPrices = [];
  List<double> predictedStockPrices = [];
  Map<String, dynamic> stockInfo = {};
  String? _selectedRange;

  void _setDateRange(String option) {
    setState(() {
      _selectedRange = option; // Highlight selected option
      _endDate = DateTime.now().subtract(const Duration(days: 1));
      switch (option) {
        case '1 Week':
          _startDate = _endDate!.subtract(const Duration(days: 7));
          break;
        case '1 Month':
          _startDate =
              DateTime(_endDate!.year, _endDate!.month - 1, _endDate!.day);
          break;
        case '1 Year':
          _startDate =
              DateTime(_endDate!.year - 1, _endDate!.month, _endDate!.day);
          break;
        case '3 Years':
          _startDate =
              DateTime(_endDate!.year - 3, _endDate!.month, _endDate!.day);
          break;
        case '5 Years':
          _startDate =
              DateTime(_endDate!.year - 5, _endDate!.month, _endDate!.day);
          break;
      }
    });
  }

  Future<void> fetchStockData() async {
    if (_selectedStock != null && _startDate != null && _endDate != null) {
      final url = Uri.parse('http://127.0.0.1:5000/analyze_stock');
      final dateFormat = DateFormat('MM/dd/yyyy');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'stock_name': _selectedStock,
          'start_date': dateFormat.format(_startDate!).toString(),
          'end_date': dateFormat.format(_endDate!).toString(),
        }),
      );

      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          actualStockPrices = List<double>.from(data['actual_stock_price']);
          predictedStockPrices =
              List<double>.from(data['predicted_stock_price']);
          stockInfo = data['stock_info'];
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch data')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Analysis'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Stock'),
                items: _stocks.map((String stock) {
                  return DropdownMenuItem<String>(
                    value: stock,
                    child: Text(stock),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedStock = value),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  for (var option in [
                    '1 Week',
                    '1 Month',
                    '1 Year',
                    '3 Years',
                    '5 Years'
                  ])
                    ChoiceChip(
                      label: Text(option),
                      selected: _selectedRange == option,
                      onSelected: (selected) => _setDateRange(option),
                      selectedColor: const Color.fromARGB(255, 72, 211, 146),
                      backgroundColor: const Color.fromARGB(255, 243, 221, 221),
                      labelStyle: TextStyle(
                          color: _selectedRange == option
                              ? Colors.white
                              : Colors.black),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchStockData,
                child: const Text('Analyze Stock'),
              ),
              const SizedBox(height: 20),
              if (stockInfo.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stock Info:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Name: ${stockInfo['longName']}'),
                    Text('Industry: ${stockInfo['industry']}'),
                    Text('Sector: ${stockInfo['sector']}'),
                    Text('Market Cap: ${stockInfo['marketCap']}'),
                    Text('ROE: ${stockInfo['returnOnEquity']}'),
                    Text('Dividend Yield: ${stockInfo['dividendYield']}'),
                    Text('P/E ratio: ${stockInfo['priceToEarningsRatio']}'),
                  ],
                ),
              const SizedBox(height: 20),
              if (actualStockPrices.isNotEmpty &&
                  predictedStockPrices.isNotEmpty)
                SizedBox(
                  height: 400, // Maintain large chart size
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Stock Prices Analysis'),
                    legend: Legend(
                      isVisible: false,
                      position: LegendPosition
                          .bottom, // Position legend below the chart
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <ChartSeries>[
                      LineSeries<double, int>(
                        name: 'Price',
                        dataSource: actualStockPrices,
                        xValueMapper: (double price, int index) => index,
                        yValueMapper: (double price, _) => price,
                        dataLabelSettings:
                            const DataLabelSettings(isVisible: false),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
