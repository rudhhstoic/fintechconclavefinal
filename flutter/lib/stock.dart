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

class _StockPredictionPageState extends State<StockPredictionPage>
    with TickerProviderStateMixin {
  String selectedPeriod = '3mo'; // Default to a more useful period
  String? selectedCompany;
  String? stockSymbol;
  String stockName = 'Stock Name';
  double investmentAmount = 0;
  double? predictedAmount;
  double? absoluteReturn;
  double? percentReturn;

  double? niftyreturn;
  late AnimationController _controller;
  late Animation<double> _buttonScaleAnimation;
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

    final url = Uri.parse('http://127.0.0.1:5000/calculate_return');
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
      appBar: AppBar(
        title: const Text('Stock Investment Comparison'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Input Fields and Company Selection
              StockCompanyDropdown(
                selectedCompany: selectedCompany,
                onChanged: _onCompanySelected,
                companies: companyTickerMap.keys.toList(),
              ),
              const SizedBox(height: 10),
              StockInputField(
                label: 'Investment Amount',
                hint: 'Enter your investment amount (e.g., 1000)',
                icon: Icons.monetization_on,
                onChanged: (value) {
                  investmentAmount = double.tryParse(value) ?? 0;
                },
                isNumeric: true,
              ),
              const SizedBox(height: 10),
              PeriodSelector(
                selectedPeriod: selectedPeriod,
                onPeriodSelected: _onPeriodSelected,
              ),
              const SizedBox(height: 20),

              // Calculate Button
              ScaleTransition(
                scale: _buttonScaleAnimation,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : calculateReturn,
                  icon: const Icon(Icons.calculate),
                  label: _isLoading
                      ? const Text('Calculating...')
                      : const Text('Calculate Return'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Error Message Display
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Results and Chart
              if (percentReturn != null && predictedAmount != null) ...[
                // Absolute Return Text
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Performance Summary',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          percentReturn != null
                              ? '${percentReturn!.toStringAsFixed(2)}% ABSOLUTE RETURN'
                              : '0% ABSOLUTE RETURN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: percentReturn! < 0
                                ? Colors.red.shade800
                                : Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Final Value: ₹${predictedAmount!.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to the analysis page
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
                          icon: const Icon(Icons.analytics),
                          label: const Text('View Price Prediction & Analysis'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Comparison Chart
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
                    height: 300,
                    child: SfCartesianChart(
                      title: ChartTitle(text: 'Return Comparison ($selectedPeriod)'),
                      legend: const Legend(
                          isVisible: true, position: LegendPosition.bottom),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      primaryXAxis: CategoryAxis(),
                      primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Value (₹)'),
                          labelFormat: '{value}',
                          minimum: 0,
                          maximum: (niftyreturn! > predictedAmount!
                                  ? niftyreturn!
                                  : predictedAmount!) *
                              1.1),
                      series: <CartesianSeries>[
                        // Series 1: Initial Investment (Fixed Blue Color)
                        ColumnSeries<ChartData, String>(
                          dataSource: [
                            ChartData('Nifty 50', investmentAmount,
                                const Color.fromARGB(255, 17, 111, 169)),
                            ChartData(stockName, investmentAmount,
                                const Color.fromARGB(255, 17, 111, 169)),
                          ],
                          xValueMapper: (ChartData data, _) => data.label,
                          yValueMapper: (ChartData data, _) => data.value,
                          name: 'Initial Investment',
                          pointColorMapper: (ChartData data, _) => data.color,
                          width: 0.7,
                          spacing: 0.1,
                          borderWidth: 1.5,
                          borderColor: Colors.black,
                        ),
                        // Series 2: Final Value (Gain/Loss Color)
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
                          name: 'Final Value',
                          pointColorMapper: (ChartData data, _) => data.color,
                          width: 0.7,
                          spacing: 0.1,
                          borderWidth: 1.5,
                          borderColor: Colors.black,
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

  const StockCompanyDropdown(
      {required this.selectedCompany,
      required this.onChanged,
      required this.companies});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCompany,
      decoration: InputDecoration(
        labelText: 'Select Company',
        prefixIcon: const Icon(Icons.business),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      hint: const Text('Choose a stock to analyze'),
      items: companies.map((String company) {
        return DropdownMenuItem<String>(
          value: company,
          child: Text(company),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodSelected;

  const PeriodSelector(
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
            labelStyle: TextStyle(
                color: selectedPeriod == period ? Colors.white : Colors.black),
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
    return TextField(
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}