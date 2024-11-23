import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: UploadPage(), // Replace 123 with the actual serialId
    );
  }
}

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  UploadPageState createState() => UploadPageState();
}

class UploadPageState extends State<UploadPage> {
  List<ChartData> chartData = [];
  bool _isLoading = false;
  String? selectedBank;
  String recommendMessage = '';
  List<dynamic> mutualFunds = [];
  List<dynamic> recommendations = [];

  final List<String> banks = [
    "SBI",
    "Canara",
    "Axis",
    "HDFC",
    "Others"
  ]; // Bank options

  Future<void> fetchMutualFunds() async {
    try {
      final response = await http.get(Uri.parse(
          'http://127.0.0.1:5005/mutualfunds')); // Replace with the correct endpoint
      if (response.statusCode == 200) {
        List<dynamic> fundsData = json.decode(response.body);
        setState(() {
          mutualFunds = fundsData
              .where((fund) => fund['category']['main'] == 'EQUITY')
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

  Future<void> uploadFile() async {
    if (selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a bank.")),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5001/upload'), // Replace with Flask IP
      );

      request.fields['text'] = selectedBank!;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));

      var response = await request.send();
      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();

        var jsonResponse = json.decode(responseString);

        // Parse chart data and recommendation message
        List<dynamic> dataResponse = jsonResponse['data'] ?? [];
        recommendMessage =
            jsonResponse['recommend_message'] ?? 'No recommendation available';

        setState(() {
          chartData = dataResponse.map((data) {
            final dateStr = data["Date"] as String? ?? '';
            final balance = data["Balance"] as double? ?? 0.0;
            final date = _parseDate(dateStr);
            return ChartData(date, balance);
          }).toList();
        });
        await fetchMutualFunds();
        // Calculate total credit based on chart data (last balance)
        double totalCredit = jsonResponse['average_total_credit'] ?? 0.0;

        // Fetch budget recommendations using the calculated totalCredit
        await fetchBudgetRecommendations(totalCredit);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to fetch budget recommendations
  Future<void> fetchBudgetRecommendations(double totalCredit) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final int totalCreditInt = totalCredit.toInt();
      print(totalCreditInt);
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5010/recommend_budgets/$totalCreditInt'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          recommendations = json.decode(response.body);
        });
      } else {
        print('Failed to fetch recommendations');
      }
    } catch (e) {
      print('Error fetching recommendations: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to add a budget
  Future<void> addBudget(String category, double limit) async {
    final serialId =
        Provider.of<AuthProvider>(context, listen: false).serialId ?? 0;
    try {
      final response = await http.post(
        Uri.parse(
            'http://127.0.0.1:5010/add_budget/$serialId'), // Replace '1' with the actual user ID
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category': category,
          'recommended_limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Remove the added budget from the list of recommendations
          recommendations.removeWhere((rec) => rec['category'] == category);
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Budget added successfully')));
      } else {
        print('Failed to add budget');
      }
    } catch (e) {
      print('Error adding budget: $e');
    }
  }

  DateTime _parseDate(String dateStr) {
    final format = dateStr.contains(' ') ? 'd MMM yyyy' : 'dd MMM yyyy';
    return DateFormat(format).parse(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statement Analyzer'),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 18, // Adjust size
              backgroundImage: AssetImage('assets/avatar.png'), // Asset image
            ),
            onPressed: () {
              // Navigate to personal information screen
              Navigator.pushNamed(context, '/personalinfo');
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dropdown for Bank Selection
              DropdownButton<String>(
                hint: Text("Select Bank"),
                value: selectedBank,
                items: banks.map((String bank) {
                  return DropdownMenuItem<String>(
                    value: bank,
                    child: Text(bank),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBank = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : uploadFile,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Upload DOCX File'),
              ),
              const SizedBox(height: 20),
              const Text('Balance Over Time'),
              const SizedBox(height: 10),
              SizedBox(
                child: chartData.isEmpty
                    ? const Text('No data yet.')
                    : SfCartesianChart(
                        primaryXAxis: DateTimeAxis(
                          title: AxisTitle(text: 'Date'),
                          intervalType: DateTimeIntervalType.months,
                          dateFormat: DateFormat('dd MMM yyyy'),
                        ),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Balance'),
                          numberFormat: NumberFormat.currency(symbol: '₹'),
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <ChartSeries>[
                          LineSeries<ChartData, DateTime>(
                            dataSource: chartData,
                            xValueMapper: (ChartData data, _) => data.date,
                            yValueMapper: (ChartData data, _) => data.balance,
                            markerSettings:
                                const MarkerSettings(isVisible: true),
                            color: const Color.fromARGB(255, 51, 50, 50),
                            width: 2,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              // Display the recommendation message
              Text(
                recommendMessage,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20), // First empty line
              if (mutualFunds.isNotEmpty) ...[
                const Text(
                  'Recommended Schemes ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mutualFunds.length,
                  itemBuilder: (context, index) {
                    final fund = mutualFunds[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: const Color.fromARGB(
                          255, 244, 244, 252), // Light background color
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fund['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fund['category']['main'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fund['category']['sub'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    const Text('1M'),
                                    Icon(
                                      Icons.arrow_upward,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    Text(
                                      '${fund['return_1_month']}%',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('3M'),
                                    Icon(
                                      Icons.arrow_upward,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    Text(
                                      '${fund['return_3_month']}%',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('6M'),
                                    Icon(
                                      Icons.arrow_upward,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    Text(
                                      '${fund['return_6_month']}%',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('1Y'),
                                    Icon(
                                      Icons.arrow_upward,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    Text(
                                      '${fund['return_per_annum']}%',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
              const SizedBox(height: 20),
              if (recommendations.isNotEmpty) ...[
                const Text(
                  'Budget Recommendations ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final recommendation = recommendations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: const Color.fromARGB(255, 244, 244, 252),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              recommendation['category'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              '₹${recommendation['recommended_limit']}',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.green),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                addBudget(recommendation['category'],
                                    recommendation['recommended_limit']);
                              },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/botpopup'); // Navigate to chatbot
        },
        tooltip: 'Chatbot',
        child: const Icon(Icons.chat),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class ChartData {
  final DateTime date;
  final double balance;

  ChartData(this.date, this.balance);
}
