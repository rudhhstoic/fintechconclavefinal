import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'stock_predict.dart'; // Ensure you import the analysis page

class StockPredictionPage extends StatefulWidget {
  @override
  _StockPredictionPageState createState() => _StockPredictionPageState();
}

class _StockPredictionPageState extends State<StockPredictionPage> {
  String selectedPeriod = '3mo'; // Default to a more useful period
  String? selectedCompany;
  String? stockSymbol;
  String stockName = 'Stock Name';
  double investmentAmount = 0;
  double? predictedAmount;
  double? absoluteReturn;
  double? percentReturn;

  double? niftyreturn;
  bool _isLoading = false;
  String _errorMessage = '';

  final Map<String, String> companyTickerMap = {
    "Reliance Industries": "RELIANCE.NS",
    "Tata Consultancy Services": "TCS.NS",
    "Infosys": "INFY.NS",
    "HDFC Bank": "HDFCBANK.NS",
    "ICICI Bank": "ICICIBANK.NS",
    "State Bank of India": "SBIN.NS",
    "Bharti Airtel": "BHARTIARTL.NS",
    "Hindustan Unilever": "HINDUNILVR.NS",
    "Kotak Mahindra Bank": "KOTAKBANK.NS",
    "Adani Enterprises": "ADANIENT.NS",
  };

  Future<void> calculateReturn() async {
    if (stockSymbol == null || investmentAmount <= 0) {
      setState(() {
        _errorMessage = 'Please select a company and enter a valid investment amount.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      predictedAmount = null;
      percentReturn = null;
      niftyreturn = null;
    });

    final url = Uri.parse('http://192.168.231.10:5000/calculate_return');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'stockName': stockSymbol,
          'investmentAmount': investmentAmount,
          'period': selectedPeriod,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          predictedAmount = data['stock_value'];
          percentReturn = data['absolute_return'];
          niftyreturn = data['nifty_value'];
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'An unknown error occurred.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to the server: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPeriodSelected(String period) {
    setState(() {
      selectedPeriod = period;
    });
  }

  void _onCompanySelected(String? company) {
    setState(() {
      selectedCompany = company;
      stockSymbol = company != null ? companyTickerMap[company] : null;
      stockName = company ?? 'Stock Name';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Stock Investment Analysis',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
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
                    Icons.trending_up,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Smart Investment Calculator',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
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
                  
                  // Company Selection Card
                  _buildInputCard(
                    'Select Company',
                    Icons.business,
                    child: StockCompanyDropdown(
                      selectedCompany: selectedCompany,
                      onChanged: _onCompanySelected,
                      companies: companyTickerMap.keys.toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Investment Amount Card
                  _buildInputCard(
                    'Investment Amount',
                    Icons.account_balance_wallet,
                    child: StockInputField(
                      label: 'Investment Amount',
                      hint: 'Enter your investment amount (e.g., 10000)',
                      icon: Icons.currency_rupee,
                      onChanged: (value) {
                        investmentAmount = double.tryParse(value) ?? 0;
                      },
                      isNumeric: true,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Period Selection Card
                  _buildInputCard(
                    'Investment Period',
                    Icons.schedule,
                    child: PeriodSelector(
                      selectedPeriod: selectedPeriod,
                      onPeriodSelected: _onPeriodSelected,
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Calculate Button
                  Container(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : calculateReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Calculating...',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.analytics, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Calculate Returns',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Error Message Display
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Results Section
                  if (percentReturn != null && predictedAmount != null) ...[
                    const SizedBox(height: 30),
                    
                    // Performance Summary Card
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
                                    Icons.assessment,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Performance Summary',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Return Percentage
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: percentReturn! >= 0
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: percentReturn! >= 0
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${percentReturn!.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: percentReturn! >= 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    'ABSOLUTE RETURN',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: percentReturn! >= 0
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Investment Details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem(
                                  'Initial Investment',
                                  '₹${investmentAmount.toStringAsFixed(0)}',
                                  Icons.input,
                                ),
                                _buildSummaryItem(
                                  'Final Value',
                                  '₹${predictedAmount!.toStringAsFixed(0)}',
                                  Icons.trending_up,
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Analysis Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StockAnalysisPage(
                                        stockSymbol: stockSymbol!,
                                        stockName: stockName,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.analytics_outlined, size: 20),
                                label: const Text(
                                  'View Detailed Analysis',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E40AF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // Comparison Chart
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
                                    Icons.bar_chart,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Return Comparison ($selectedPeriod)',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 300,
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
                                primaryXAxis: CategoryAxis(
                                  axisLabelFormatter: (axisLabelRenderArgs) {
                                    return ChartAxisLabel(
                                      axisLabelRenderArgs.text,
                                      const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                                primaryYAxis: NumericAxis(
                                  title: AxisTitle(
                                    text: 'Value (₹)',
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  labelFormat: '{value}',
                                  minimum: 0,
                                  maximum: (niftyreturn! > predictedAmount!
                                          ? niftyreturn!
                                          : predictedAmount!) * 1.1,
                                ),
                                series: <CartesianSeries>[
                                  ColumnSeries<ChartData, String>(
                                    dataSource: [
                                      ChartData('Nifty 50', investmentAmount, const Color(0xFF60A5FA)),
                                      ChartData(stockName, investmentAmount, const Color(0xFF60A5FA)),
                                    ],
                                    xValueMapper: (ChartData data, _) => data.label,
                                    yValueMapper: (ChartData data, _) => data.value,
                                    name: 'Initial Investment',
                                    pointColorMapper: (ChartData data, _) => data.color,
                                    width: 0.6,
                                    spacing: 0.2,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                  ColumnSeries<ChartData, String>(
                                    dataSource: [
                                      ChartData(
                                        'Nifty 50',
                                        niftyreturn!,
                                        niftyreturn! < investmentAmount
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF22C55E),
                                      ),
                                      ChartData(
                                        stockName,
                                        predictedAmount!,
                                        predictedAmount! < investmentAmount
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF22C55E),
                                      ),
                                    ],
                                    xValueMapper: (ChartData data, _) => data.label,
                                    yValueMapper: (ChartData data, _) => data.value,
                                    name: 'Final Value',
                                    pointColorMapper: (ChartData data, _) => data.color,
                                    width: 0.6,
                                    spacing: 0.2,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(String title, IconData icon, {required Widget child}) {
    return Container(
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
                  child: Icon(
                    icon,
                    color: const Color(0xFF1E40AF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1E40AF), size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}

class StockCompanyDropdown extends StatelessWidget {
  final String? selectedCompany;
  final ValueChanged<String?> onChanged;
  final List<String> companies;

  const StockCompanyDropdown({
    required this.selectedCompany,
    required this.onChanged,
    required this.companies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedCompany,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          hintText: 'Choose a stock to analyze',
          hintStyle: TextStyle(color: Colors.grey),
        ),
        items: companies.map((String company) {
          return DropdownMenuItem<String>(
            value: company,
            child: Text(
              company,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1E40AF)),
        dropdownColor: Colors.white,
      ),
    );
  }
}

class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodSelected;

  const PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final periods = [
      {'code': '1wk', 'label': '1 Week'},
      {'code': '1mo', 'label': '1 Month'},
      {'code': '3mo', 'label': '3 Months'},
      {'code': '6mo', 'label': '6 Months'},
      {'code': '1yr', 'label': '1 Year'},
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: periods.map((period) {
        final isSelected = selectedPeriod == period['code'];
        return GestureDetector(
          onTap: () => onPeriodSelected(period['code']!),
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
              period['label']!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
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

  const StockInputField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.isNumeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: TextField(
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}