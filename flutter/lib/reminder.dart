// WORKINGGG FINAL main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeReminder(),
    );
  }
}

class HomeReminder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 12, 80),
        title: const Text(
          'Manage Reminders',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white], // Blue to white gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReminderPage()),
              );
            },
            child: Text('Manage Reminders'),
          ),
        ),
      ),
    );
  }
}

class ReminderService {
  final String baseUrl = 'http://192.168.231.10:5000';

  Future<void> setReminder(
      int userId, String date, String description, String mobileno) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/set_reminder/${userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'date': date,
          'description': description,
          'mobileno': mobileno,
        }),
      );

      if (response.statusCode == 200) {
        print('Reminder set successfully!');
      } else {
        throw Exception('Failed to set reminder: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Could not set reminder. Please try again.');
    }
  }

  Future<List<dynamic>> getReminders(int serialId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/get_reminders/${serialId}'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load reminders: ${response.body}');
      }
    } catch (e) {
      print('Error fetching reminders: $e');
      throw Exception('Could not fetch reminders. Please try again.');
    }
  }

  Future<void> updateReminder(int id, String date, String description) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update_reminder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': id,
          'date': date,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        print('Reminder updated successfully!');
      } else {
        throw Exception('Failed to update reminder: ${response.body}');
      }
    } catch (e) {
      print('Error updating reminder: $e');
      throw Exception('Could not update reminder. Please try again.');
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_reminder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id}),
      );

      if (response.statusCode == 200) {
        print('Reminder deleted successfully!');
      } else {
        throw Exception('Failed to delete reminder: ${response.body}');
      }
    } catch (e) {
      print('Error deleting reminder: $e');
      throw Exception('Could not delete reminder. Please try again.');
    }
  }
}

class ReminderPage extends StatefulWidget {
  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final _mobilenoController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reminderService = ReminderService();
  bool _isLoading = false;
  List<dynamic> _reminders = [];

  @override
  void initState() {
    super.initState();
    _fetchReminders(); // Load reminders when the page is loaded
  }

  // Fetch all reminders
  void _fetchReminders() async {
    final serialId =
        Provider.of<AuthProvider>(context, listen: false).serialId ?? 0;
    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> reminders = await _reminderService.getReminders(serialId);
      setState(() {
        _reminders = reminders;
      });
    } catch (e) {
      print('Error fetching reminders: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to fetch reminders')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Set reminder
  void _setReminder() async {
    final serialId =
        Provider.of<AuthProvider>(context, listen: false).serialId ?? 0;
    final mobileno = _mobilenoController.text;
    final date = _dateController.text;
    final description = _descriptionController.text;

    if (mobileno.isEmpty || date.isEmpty || description.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _reminderService.setReminder(
          serialId, date, description, mobileno); // Assuming user_id=1
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Reminder set successfully!')));
      _fetchReminders(); // Refresh the list after setting the reminder
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to set reminder')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Update reminder
  void _updateReminder(int id) async {
    final mobileno = _mobilenoController.text;
    final date = _dateController.text;
    final description = _descriptionController.text;

    if (mobileno.isEmpty || date.isEmpty || description.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _reminderService.updateReminder(id, date, description);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder updated successfully!')));
      _fetchReminders(); // Refresh the list after update
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update reminder')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Delete reminder
  void _deleteReminder(int id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _reminderService.deleteReminder(id);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder deleted successfully!')));
      _fetchReminders(); // Refresh the list after deletion
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete reminder')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 12, 80),
        title: const Text(
          'Finance Bot',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white], // Blue to white gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fields for creating or updating a reminder
              TextField(
                controller: _mobilenoController,
                decoration: InputDecoration(labelText: 'Mobile Number'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _dateController,
                decoration:
                    InputDecoration(labelText: 'Date (yyyy-mm-dd hh:mm:ss)'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _setReminder,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Set Reminder'),
              ),
              SizedBox(height: 20),
              // Display the existing reminders
              _isLoading
                  ? CircularProgressIndicator()
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _reminders.length,
                        itemBuilder: (context, index) {
                          final reminder = _reminders[index];
                          return ListTile(
                            title: Text(reminder['description']),
                            subtitle: Text('Date: ${reminder['date']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    _mobilenoController.text =
                                        reminder['mobileno'];
                                    _dateController.text = reminder['date'];
                                    _descriptionController.text =
                                        reminder['description'];
                                    _updateReminder(reminder['id']);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                  ),
                                  onPressed: () {
                                    _deleteReminder(reminder['id']);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
