import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/*void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Income & Expense Analysis',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}*/

class HomePage extends StatelessWidget {
  final int serialId;
  HomePage({required this.serialId});
  @override
  Widget build(BuildContext context) {
    return AnalysisPage(serialId: serialId);
  }
}

class AnalysisPage extends StatefulWidget {
  final int serialId;

  const AnalysisPage({Key? key, required this.serialId}) : super(key: key);

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String selectedAnalysis = 'Income Category Analysis';
  List<ChartData> chartData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnalysisData(); // Initial fetch
  }

  Future<void> fetchAnalysisData() async {
    setState(() => isLoading = true); // Show loading

    String url;
    switch (selectedAnalysis) {
      case 'Income Category Analysis':
        url =
            'http://192.168.231.10:5000/income_category_analysis/${widget.serialId}';
        break;
      case 'Expense Category Analysis':
        url =
            'http://192.168.231.10:5000/expense_category_analysis/${widget.serialId}';
        break;
      case 'Income vs Expense Analysis':
        url =
            'http://192.168.231.10:5000/income_vs_expense_analysis/${widget.serialId}';
        break;
      default:
        return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          chartData = selectedAnalysis == 'Income vs Expense Analysis'
              ? [
                  ChartData('Income', data['total_income'] as double),
                  ChartData('Expense', data['total_expense'] as double),
                ]
              : (data as List)
                  .map((item) => ChartData(
                        item['category'] as String,
                        (item['total_amount'] as num).toDouble(),
                      ))
                  .toList();
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() => isLoading = false); // Hide loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white], // Blue to white gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedAnalysis,
              items: [
                'Income Category Analysis',
                'Expense Category Analysis',
                'Income vs Expense Analysis',
              ].map((String analysis) {
                return DropdownMenuItem<String>(
                  value: analysis,
                  child: Text(analysis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAnalysis = value!;
                  fetchAnalysisData(); // Fetch data based on selected analysis
                });
              },
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : chartData.isEmpty
                      ? Center(child: Text('No data available'))
                      : SfCircularChart(
                          legend: Legend(isVisible: true),
                          series: <PieSeries<ChartData, String>>[
                            PieSeries<ChartData, String>(
                              dataSource: chartData,
                              xValueMapper: (ChartData data, _) =>
                                  data.category,
                              yValueMapper: (ChartData data, _) => data.amount,
                              dataLabelSettings:
                                  DataLabelSettings(isVisible: true),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String category;
  final double amount;

  ChartData(this.category, this.amount);
}
