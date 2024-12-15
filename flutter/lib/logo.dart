import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() {
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: TextLiquidFillExample(),
    );
  }
}

class TextLiquidFillExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black, // Black background
        child: Center(
          child: SizedBox(
            child: TextLiquidFill(
              text: 'FinBuild', // Text to be animated
              waveColor: Colors.redAccent, // Red accent wave color
              boxBackgroundColor: Colors.black, // Background inside the text
              textStyle: TextStyle(
                fontSize: 70.0, // Font size
                color: Colors.white, // Text color
                fontWeight: FontWeight.bold, // Font weight
                fontFamily: 'Quiska',
              ),
              loadDuration:
                  Duration(seconds: 4), // Duration for the wave effect
              waveDuration:
                  Duration(milliseconds: 800), // Speed of wave movement
            ),
          ),
        ),
      ),
    );
  }
}
