import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vacation Recommendation',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: VacationPage(serialId: 1), // Replace with your actual serialId
    );
  }
}

class VacationPage extends StatefulWidget {
  final int serialId;
  VacationPage({required this.serialId});

  @override
  _VacationPageState createState() => _VacationPageState();
}

class _VacationPageState extends State<VacationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController daysController = TextEditingController();
  final TextEditingController transportCostController = TextEditingController();
  final List<String> places = [
    'Dubai',
    'Pune',
    'Jaipur',
    'Bangkok',
    'Istanbul',
    'London',
    'New York',
    'Paris',
    'Hyderabad',
    'Sydney',
    'Tokyo',
    'Chennai',
    'Singapore',
    'Kerala',
    'Delhi',
    'Bangalore',
    'Rome',
    'Agra',
    'Manali',
    'Shimla',
    'Kolkata',
    'Goa',
    'Mumbai'
  ]; // Example places
  String selectedPlace = "Paris";
  String startPeriod = "JAN";
  String endPeriod = "FEB";
  List<dynamic> recommendations = [];
  List<dynamic> savedVacations = [];

  @override
  void initState() {
    super.initState();
    fetchSavedVacations();
  }

  Future<void> fetchSavedVacations() async {
    final response = await http.get(
      Uri.parse('http://192.168.231.10:5000/get_vacations/${widget.serialId}'),
    );

    if (response.statusCode == 200) {
      setState(() {
        savedVacations = json.decode(response.body);
      });
    } else {
      print("Failed to fetch saved vacations");
    }
  }

  Future<void> getRecommendations() async {
    final response = await http.post(
      Uri.parse('http://192.168.231.10:5000/recommend_vacation'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'serial_id': widget.serialId,
        'place': selectedPlace,
        'budget_range': [0, int.parse(budgetController.text)],
        'time_of_year': '$startPeriod-$endPeriod',
        'days': int.parse(daysController.text),
        'airline_ticket_cost': double.parse(transportCostController.text),
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        recommendations = json.decode(response.body)['recommendations'];
      });
    } else {
      print("Failed to fetch recommendations ${response.body}");
    }
  }

  Future<void> addVacation(Map vacation) async {
    final response = await http.post(
      Uri.parse('http://192.168.231.10:5000/add_vacation'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(vacation),
    );

    if (response.statusCode == 200) {
      print("Vacation added successfully");
      fetchSavedVacations();
      setState(() {
        recommendations = [];
      });
    } else {
      print("Failed to add vacation");
    }
  }

  Future<void> showMonthSelector(bool isStartPeriod) async {
    final selectedMonth = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select a Month"),
          content: SizedBox(
            width: 200, // Set a smaller width
            height: 200, // Set a smaller height
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = [
                  "JAN",
                  "FEB",
                  "MAR",
                  "APR",
                  "MAY",
                  "JUN",
                  "JUL",
                  "AUG",
                  "SEP",
                  "OCT",
                  "NOV",
                  "DEC"
                ][index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, month),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      month,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedMonth != null) {
      setState(() {
        if (isStartPeriod) {
          startPeriod = selectedMonth;
        } else {
          endPeriod = selectedMonth;
        }
      });
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedPlace,
                            items: places.map((String place) {
                              return DropdownMenuItem(
                                  value: place, child: Text(place));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPlace = value!;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: "Select Destination",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => showMonthSelector(true),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: "Start Period",
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(startPeriod),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => showMonthSelector(false),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: "End Period",
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(endPeriod),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: budgetController,
                            decoration: InputDecoration(
                              labelText: "Maximum Budget",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: daysController,
                            decoration: InputDecoration(
                              labelText: "Number of Days",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: transportCostController,
                            decoration: InputDecoration(
                              labelText: "Transport Cost",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                getRecommendations();
                              }
                            },
                            child: Text("Get Recommendations"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text("Saved Plans",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                savedVacations.isEmpty
                    ? Center(child: Text("No saved vacations available."))
                    : ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: savedVacations.length,
                        itemBuilder: (context, index) {
                          final vacation = savedVacations[index];
                          return Card(
                            child: ListTile(
                              title: Text(vacation['place']),
                              subtitle: Text(
                                  "Air Cost: ${vacation['air_cost']} | Days: ${vacation['days']} | Budget Range: ${vacation['budget_range']}"),
                            ),
                          );
                        },
                      ),
                SizedBox(height: 16),
                Text("Recommendations",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                recommendations.isEmpty
                    ? Center(child: Text("No recommendations available."))
                    : ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final rec = recommendations[index];
                          return Card(
                            child: ListTile(
                              title: Text(rec['Place']),
                              subtitle: Text(
                                  "Air Cost: ${rec['Air Cost']} | Days: ${rec['Days']} | Budget Range: ${rec['Budget Range']}"),
                              trailing: IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  addVacation({
                                    'serial_id': widget.serialId,
                                    'place': rec['Place'],
                                    'air_cost': rec['Air Cost'],
                                    'days': rec['Days'],
                                    'budget_range': rec['Budget Range'],
                                    'time_range': rec['Time Range'],
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
