import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class StockAnalysisPage extends StatefulWidget {
  final String stockSymbol;
  final String stockName;

  const StockAnalysisPage(
      {super.key, required this.stockSymbol, required this.stockName});
  @override
  StockAnalysisPageState createState() => StockAnalysisPageState();
}

class StockAnalysisPageState extends State<StockAnalysisPage> {
  final _timeRanges = ['1 Month', '3 Months', '6 Months', '1 Year'];
  String? _selectedRange = '3 Months'; // Default selection
  DateTime? _startDate;
  // End date is yesterday to ensure all data is closed and available
  DateTime? _endDate = DateTime.now().subtract(const Duration(days: 1)); 
  
  List<double> actualStockPrices = [];
  List<double> predictedStockPrices = [];
  Map<String, dynamic> stockInfo = {};
  bool _isLoading = false;
  String _errorMessage = '';
  bool _modelTrained = false;

  @override
  void initState() {
    super.initState();
    _setDateRange(_selectedRange!);
  }

  void _setDateRange(String option) {
    setState(() {
      _selectedRange = option; // Highlight selected option
      _endDate = DateTime.now().subtract(const Duration(days: 1));
      switch (option) {
        case '1 Month':
          _startDate = DateTime(_endDate!.year, _endDate!.month - 1, _endDate!.day);
          break;
        case '3 Months':
          _startDate = DateTime(_endDate!.year, _endDate!.month - 3, _endDate!.day);
          break;
        case '6 Months':
          _startDate = DateTime(_endDate!.year, _endDate!.month - 6, _endDate!.day);
          break;
        case '1 Year':
          _startDate = DateTime(_endDate!.year - 1, _endDate!.month, _endDate!.day);
          break;
        default:
          _startDate = _endDate!.subtract(const Duration(days: 90)); // Default to 3 months
      }
      // Automatically fetch data when range changes
      fetchStockData();
    });
  }
  
  // Helper to format dates for Python (yyyy-MM-dd is required by yfinance)
  String getFormattedDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> fetchStockData() async {
    if (_startDate == null || _endDate == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      actualStockPrices.clear();
      predictedStockPrices.clear();
      stockInfo.clear();
      _modelTrained = false;
    });

    final url = Uri.parse('http://127.0.0.1:5011/analyse_stock');
    final String startDateStr = getFormattedDate(_startDate!);
    final String endDateStr = getFormattedDate(_endDate!);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'stock_name': widget.stockSymbol,
          'start_date': startDateStr,
          'end_date': endDateStr,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          actualStockPrices = List<double>.from(data['actual_stock_price'] ?? []);
          predictedStockPrices = List<double>.from(data['predicted_stock_price'] ?? []);
          stockInfo = Map<String, dynamic>.from(data['stock_info'] ?? {});
          _modelTrained = data['model_trained'] ?? false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Analysis failed. Try a different date range or stock.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to the server or process data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.stockName} Analysis'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Time Range Selector
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _timeRanges.map((range) {
                  return ChoiceChip(
                    label: Text(range),
                    selected: _selectedRange == range,
                    onSelected: (selected) {
                      if (selected) _setDateRange(range);
                    },
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(
                      color: _selectedRange == range ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Loading/Error State
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.indigo))
              else if (_errorMessage.isNotEmpty)
                Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (!_modelTrained)
                const Center(
                  child: Text(
                    'Insufficient data to train the prediction model for the selected period.',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Stock Information
              if (stockInfo.isNotEmpty && _modelTrained)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stockInfo['longName'] ?? widget.stockName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Divider(),
                        Text('Symbol: ${widget.stockSymbol}', style: const TextStyle(fontSize: 16)),
                        Text('Sector: ${stockInfo['sector']}', style: const TextStyle(fontSize: 16)),
                        Text('Industry: ${stockInfo['industry']}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        Text('Market Cap: ${NumberFormat.compactCurrency(symbol: '₹').format(stockInfo['marketCap'])}'),
                        Text('P/E ratio: ${stockInfo['priceToEarningsRatio']?.toStringAsFixed(2) ?? 'N/A'}'),
                        Text('ROE: ${(stockInfo['returnOnEquity'] * 100).toStringAsFixed(2)}%'),
                        Text('Dividend Yield: ${(stockInfo['dividendYield'] * 100).toStringAsFixed(2)}%'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Stock Price Chart
              if (actualStockPrices.isNotEmpty && predictedStockPrices.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 400, // Maintain large chart size
                    child: SfCartesianChart(
                      title: ChartTitle(text: 'Actual vs. Predicted Price'),
                      legend: const Legend( // ENABLED LEGEND
                        isVisible: true,
                        position: LegendPosition.bottom,
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      primaryXAxis: NumericAxis(
                        title: AxisTitle(text: 'Data Points (Time)'),
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'Price (₹)'),
                        labelFormat: '{value}',
                      ),
                      series: <CartesianSeries>[
                        // 1. Actual Stock Price Line
                        LineSeries<double, int>(
                          name: 'Actual Price',
                          dataSource: actualStockPrices,
                          xValueMapper: (double price, int index) => index,
                          yValueMapper: (double price, _) => price,
                          color: Colors.blue, // Actual Price in Blue
                          dataLabelSettings:
                              const DataLabelSettings(isVisible: false),
                        ),
                        // 2. Predicted Stock Price Line (ADDED THIS SERIES)
                        LineSeries<double, int>(
                          name: 'Predicted Price',
                          dataSource: predictedStockPrices,
                          xValueMapper: (double price, int index) => index,
                          yValueMapper: (double price, _) => price,
                          color: Colors.red, // Predicted Price in Red
                          dataLabelSettings:
                              const DataLabelSettings(isVisible: false),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}