import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

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

  final List<String> banks = [
    "SBI",
    "Canara",
    "Axis",
    "HDFC",
    "Others"
  ]; // Bank options

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
        Uri.parse('http://192.168.100.28:5001/upload'), // Replace with Flask IP
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
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            Expanded(
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
                          markerSettings: const MarkerSettings(isVisible: true),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20), // First empty line
          ],
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
