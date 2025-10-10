import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import this for JSON encoding/decoding

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ChatbotScreenState createState() => ChatbotScreenState();
}

class ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  void _sendMessage(String message, {bool isBot = false}) {
    setState(() {
      _messages.add({
        'message': message,
        'isBot': isBot,
        'time': DateTime.now()
            .toLocal()
            .toString()
            .substring(11, 16), // HH:mm format
      });
    });
  }

  Future<void> _sendUserMessage() async {
    if (_messageController.text.isNotEmpty) {
      String userMessage = _messageController.text;
      _sendMessage(userMessage); // Add user message
      _messageController.clear(); // Clear the input field

      // Send the message to the Flask backend
      try {
        final response = await http.post(
          Uri.parse(
              'http://192.168.231.10:5000/chatbot'), // Replace with your Flask backend URL
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'message': userMessage,
          }),
        );

        if (response.statusCode == 200) {
          // If the server returns a 200 OK response
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          String botResponse = responseData[
              'response']; // Adjust based on your Flask response format
          _sendMessage(botResponse, isBot: true); // Add bot response
        } else {
          // If the server did not return a 200 OK response
          _sendMessage('Error: Unable to get a response.', isBot: true);
        }
      } catch (e) {
        // Handle any errors
        _sendMessage('Error: $e', isBot: true);
      }
    }
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
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true, // To keep the latest message at the bottom
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final messageData =
                      _messages[_messages.length - 1 - index]; // Reverse order
                  final isBot = messageData['isBot'];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: isBot
                          ? Alignment.centerLeft
                          : Alignment.centerRight, // Align bot messages left
                      child: Column(
                        crossAxisAlignment: isBot
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isBot
                                  ? const Color.fromARGB(183, 255, 255, 255)
                                  : Colors.blueAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              messageData['message'],
                              style: TextStyle(
                                color: isBot ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            messageData['time'],
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  isBot ? Colors.black54 : Colors.blueGrey[200],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.blueAccent,
                    onPressed:
                        _sendUserMessage, // Send message when button is pressed
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
