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
      home: UploadPage(),
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
  ];

  Future<void> fetchMutualFunds() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.231.10:5000/mutualfunds'));
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
        Uri.parse('http://192.168.231.10:5000/upload'),
      );

      request.fields['text'] = selectedBank!;
      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
        ));
      } else {
        throw Exception("No valid file data found.");
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseString);

        List<dynamic> dataResponse = jsonResponse['data'] ?? [];
        recommendMessage = jsonResponse['recommend_message'] ?? 'No recommendation available';

        setState(() {
          chartData = dataResponse.map((data) {
            final dateStr = data["Date"] as String? ?? '';
            final balance = data["Balance"] as double? ?? 0.0;
            final date = _parseDate(dateStr);
            return ChartData(date, balance);
          }).toList();
        });
        await fetchMutualFunds();

        double totalCredit = jsonResponse['average_total_credit'] ?? 0.0;
        await fetchBudgetRecommendations(totalCredit);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchBudgetRecommendations(double totalCredit) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final int totalCreditInt = totalCredit.toInt();
      print(totalCreditInt);
      final response = await http.post(
        Uri.parse('http://192.168.231.10:5000/recommend_budgets/$totalCreditInt'),
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

  Future<void> addBudget(String category, double limit) async {
    final serialId = Provider.of<AuthProvider>(context, listen: false).serialId ?? 0;
    try {
      final response = await http.post(
        Uri.parse('http://192.168.231.10:5000/add_budget/$serialId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category': category,
          'recommended_limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          recommendations.removeWhere((rec) => rec['category'] == category);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Budget added successfully'))
        );
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
          'Statement Analyser',
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
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/personalinfo');
            },
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
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
                  _buildUploadSection(screenSize, padding, cardRadius),
                  if (chartData.isNotEmpty) ...[
                    SizedBox(height: padding),
                    _buildChartCard(screenSize, padding, cardRadius),
                  ],
                  if (recommendMessage.isNotEmpty && chartData.isNotEmpty) ...[
                    SizedBox(height: padding),
                    _buildRecommendationMessage(padding, cardRadius),
                  ],
                  if (mutualFunds.isNotEmpty) ...[
                    SizedBox(height: padding),
                    _buildMutualFundsSection(screenSize, padding, cardRadius),
                  ],
                  if (recommendations.isNotEmpty) ...[
                    SizedBox(height: padding),
                    _buildBudgetRecommendationsSection(screenSize, padding, cardRadius),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade800,
        onPressed: () {
          Navigator.pushNamed(context, '/botpopup');
        },
        tooltip: 'Chatbot',
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildUploadSection(Size screenSize, double padding, BorderRadius cardRadius) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Bank Statement',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
            SizedBox(height: padding / 2),
            Divider(color: Colors.blue.shade100),
            SizedBox(height: padding / 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: Text("Select Bank", style: TextStyle(color: Colors.grey.shade700)),
                  value: selectedBank,
                  isExpanded: true,
                  items: banks.map((String bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Text(bank, style: TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBank = value;
                    });
                  },
                  icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade800),
                ),
              ),
            ),
            SizedBox(height: padding),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : uploadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Upload DOCX File',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
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
              'Balance Over Time',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
            SizedBox(height: padding),
            SizedBox(
              height: screenSize.height * 0.35,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  title: AxisTitle(
                    text: 'Date',
                    textStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                  intervalType: DateTimeIntervalType.months,
                  dateFormat: DateFormat('dd MMM'),
                  majorGridLines: MajorGridLines(width: 0),
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(
                    text: 'Balance',
                    textStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                  ),
                  numberFormat: NumberFormat.currency(symbol: '₹'),
                  majorGridLines: MajorGridLines(color: Colors.grey.shade200),
                  labelStyle: TextStyle(fontSize: 0),
                  isVisible: true,
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  LineSeries<ChartData, DateTime>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.date,
                    yValueMapper: (ChartData data, _) => data.balance,
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      color: Colors.blue.shade800,
                      borderColor: Colors.white,
                      borderWidth: 2,
                      height: 8,
                      width: 8,
                    ),
                    color: Colors.blue.shade800,
                    width: 3,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationMessage(double padding, BorderRadius cardRadius) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 32),
            SizedBox(width: padding / 2),
            Expanded(
              child: Text(
                recommendMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutualFundsSection(Size screenSize, double padding, BorderRadius cardRadius) {
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
          Text(
            '${parsed.toStringAsFixed(1)}%',
            style: TextStyle(
              color: parsed > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildBudgetRecommendationsSection(Size screenSize, double padding, BorderRadius cardRadius) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Recommendations',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
        ),
        SizedBox(height: padding / 2),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final recommendation = recommendations[index];
            return Card(
              elevation: 6,
              margin: EdgeInsets.only(bottom: padding / 2),
              shape: RoundedRectangleBorder(borderRadius: cardRadius),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                title: Text(
                  recommendation['category'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
                subtitle: Text(
                  'Recommended Limit',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${recommendation['recommended_limit']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.blue.shade800, size: 32),
                      onPressed: () {
                        addBudget(
                          recommendation['category'],
                          recommendation['recommended_limit'],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ChartData {
  final DateTime date;
  final double balance;

  ChartData(this.date, this.balance);
}