import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    "Adani Green Energy": "ADANIGREEN.NS",
    "Adani Ports": "ADANIPORTS.NS",
    "ITC": "ITC.NS",
    "Tata Steel": "TATASTEEL.NS",
    "Wipro": "WIPRO.NS",
    "Maruti Suzuki": "MARUTI.NS",
    "Axis Bank": "AXISBANK.NS",
    "HCL Technologies": "HCLTECH.NS",
    "Larsen & Toubro": "LT.NS",
    "Asian Paints": "ASIANPAINT.NS",
    "UltraTech Cement": "ULTRACEMCO.NS",
    "Titan Company": "TITAN.NS",
    "Sun Pharmaceutical": "SUNPHARMA.NS",
    "Dr. Reddy's Laboratories": "DRREDDY.NS",
    "Mahindra & Mahindra": "M&M.NS",
    "Power Grid Corporation": "POWERGRID.NS",
    "Bajaj Finance": "BAJFINANCE.NS",
    "Hindalco Industries": "HINDALCO.NS",
    "Tata Motors": "TATAMOTORS.NS",
    "Coal India": "COALINDIA.NS",
    "NTPC": "NTPC.NS",
    "Grasim Industries": "GRASIM.NS",
    "Nestle India": "NESTLEIND.NS",
    "SBI Life Insurance": "SBILIFE.NS",
    "Bajaj Finserv": "BAJAJFINSV.NS",
    "Divi's Laboratories": "DIVISLAB.NS",
    "Britannia Industries": "BRITANNIA.NS",
    "HDFC Life Insurance": "HDFCLIFE.NS",
    "IndusInd Bank": "INDUSINDBK.NS",
    "Eicher Motors": "EICHERMOT.NS"
  };

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
    final url = Uri.parse('http://127.0.0.1:5000/calculate_return');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "stockName": stockSymbol,
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
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 12, 80),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: const Text(
          'Finance Bot',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.red),
            onPressed: () {},
            tooltip:
                "Stock predictions are not guaranteed. Consult a financial advisor before investing.",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white], // Blue to white gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
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
                  fontWeight: FontWeight.bold,
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
                    label: 'Nifty 50',
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
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select company',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: companyTickerMap.keys.map((company) {
                  return DropdownMenuItem<String>(
                    value: company,
                    child: Text(company),
                  );
                }).toList(),
                value: selectedCompany,
                onChanged: (value) {
                  setState(() {
                    selectedCompany = value;
                    stockSymbol = companyTickerMap[value];
                    stockName =
                        value ?? 'Stock Name'; // Update displayed stock name
                  });
                },
              ),

              SizedBox(height: 10),
              StockInputField(
                label: 'Your investment amount',
                hint: '₹$investmentAmount', // Updated hint text
                icon: Icons.currency_rupee, // Updated icon to rupee symbol
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
                    primaryXAxis: CategoryAxis(
                      isVisible: true,
                      axisLine: AxisLine(
                        color: Colors.black, // Dark color for the X-axis line
                        width: 1, // Increase the width for a bolder line
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black, // Darken the X-axis labels
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      isVisible: true,
                      axisLine: AxisLine(
                        color: Colors.black, // Dark color for the Y-axis line
                        width: 1, // Increase the width for a bolder line
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black, // Darken the Y-axis labels
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    plotAreaBorderWidth: 0,
                    legend: Legend(isVisible: true),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <ChartSeries>[
                      StackedColumnSeries<ChartData, String>(
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
                        name: 'Investment',
                        pointColorMapper: (ChartData data, _) => data.color,
                        width: 0.5,
                        borderWidth: 1.5, // Set the border width
                        borderColor: Colors.black, // Set the border color
                      ),
                      StackedColumnSeries<ChartData, String>(
                        dataSource: [
                          ChartData('Nifty 50', investmentAmount,
                              const Color.fromARGB(255, 17, 111, 169)),
                          ChartData(stockName, investmentAmount,
                              const Color.fromARGB(255, 17, 111, 169)),
                        ],
                        xValueMapper: (ChartData data, _) => data.label,
                        yValueMapper: (ChartData data, _) => data.value,
                        name: 'Return',
                        pointColorMapper: (ChartData data, _) => data.color,
                        width: 0.5,
                        borderWidth: 1.5, // Set the border width
                        borderColor: Colors.black, // Set the border color
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
