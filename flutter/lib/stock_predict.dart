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

    final url = Uri.parse('http://192.168.231.10:5000/analyse_stock');
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '${widget.stockName} Analysis',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  const Icon(
                    Icons.analytics,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Technical Analysis for ${widget.stockName}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 10),
                  
                  // Time Range Selector Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.08),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E40AF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.date_range,
                                  color: Color(0xFF1E40AF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Select Time Range',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _timeRanges.map((range) {
                              final isSelected = _selectedRange == range;
                              return GestureDetector(
                                onTap: () {
                                  if (!_isLoading) _setDateRange(range);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF1E40AF) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF1E40AF) : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    range,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Loading/Error State
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: const [
                          CircularProgressIndicator(
                            color: Color(0xFF1E40AF),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Analyzing stock data...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!_modelTrained)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_outlined, color: Colors.orange.shade600, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Insufficient data to train the prediction model for the selected period.',
                              style: const TextStyle(
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Stock Information Card
                  if (stockInfo.isNotEmpty && _modelTrained) ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.blue.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E40AF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stockInfo['longName'] ?? widget.stockName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        'Symbol: ${widget.stockSymbol}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Stock Details Grid
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoItem(
                                          'Sector',
                                          stockInfo['sector'] ?? 'N/A',
                                          Icons.business,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildInfoItem(
                                          'Industry',
                                          stockInfo['industry'] ?? 'N/A',
                                          Icons.factory,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoItem(
                                          'Market Cap',
                                          NumberFormat.compactCurrency(symbol: '₹').format(stockInfo['marketCap'] ?? 0),
                                          Icons.account_balance,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildInfoItem(
                                          'P/E Ratio',
                                          stockInfo['priceToEarningsRatio']?.toStringAsFixed(2) ?? 'N/A',
                                          Icons.trending_up,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoItem(
                                          'ROE',
                                          '${((stockInfo['returnOnEquity'] ?? 0) * 100).toStringAsFixed(2)}%',
                                          Icons.percent,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildInfoItem(
                                          'Dividend Yield',
                                          '${((stockInfo['dividendYield'] ?? 0) * 100).toStringAsFixed(2)}%',
                                          Icons.attach_money,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],

                  // Stock Price Chart
                  if (actualStockPrices.isNotEmpty && predictedStockPrices.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.08),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E40AF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.show_chart,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Price Prediction Chart',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 400,
                              child: SfCartesianChart(
                                legend: Legend(
                                  isVisible: true,
                                  position: LegendPosition.bottom,
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                tooltipBehavior: TooltipBehavior(
                                  enable: true,
                                  color: const Color(0xFF1E40AF),
                                  textStyle: const TextStyle(color: Colors.white),
                                ),
                                primaryXAxis: NumericAxis(
                                  title: AxisTitle(
                                    text: 'Time Points',
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  axisLine: const AxisLine(width: 1),
                                  majorTickLines: const MajorTickLines(width: 1),
                                ),
                                primaryYAxis: NumericAxis(
                                  title: AxisTitle(
                                    text: 'Price (₹)',
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  labelFormat: '{value}',
                                  axisLine: const AxisLine(width: 1),
                                  majorTickLines: const MajorTickLines(width: 1),
                                ),
                                series: <CartesianSeries>[
                                  LineSeries<double, int>(
                                    name: 'Actual Price',
                                    dataSource: actualStockPrices,
                                    xValueMapper: (double price, int index) => index,
                                    yValueMapper: (double price, _) => price,
                                    color: const Color(0xFF3B82F6),
                                    width: 3,
                                    markerSettings: const MarkerSettings(
                                      isVisible: false,
                                    ),
                                  ),
                                  LineSeries<double, int>(
                                    name: 'Predicted Price',
                                    dataSource: predictedStockPrices,
                                    xValueMapper: (double price, int index) => index,
                                    yValueMapper: (double price, _) => price,
                                    color: const Color(0xFFEF4444),
                                    width: 3,
                                    dashArray: <double>[5, 5],
                                    markerSettings: const MarkerSettings(
                                      isVisible: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: const Color(0xFF1E40AF),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}