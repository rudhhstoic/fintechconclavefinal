import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final List<String> _options = [
    'Spending Analysis',
    'Budget Planning',
    'Stock Prediction',
    'Mutual Fund Recommendation',
    'Tax Calculator',
    'Remainder Calendar',
  ];

  final List<Color> _colors = [
    Colors.redAccent,
    Colors.greenAccent,
    const Color.fromARGB(255, 205, 255, 68),
    Colors.orangeAccent,
    Colors.purple,
    Colors.lightGreen,
  ];

  final List<String> _images = [
    'assets/image6.jpg',
    'assets/image12.jpg',
    'assets/image7.jpg',
    'assets/image8.jpg',
    'assets/image9.jpg',
    'assets/image10.jpg',
  ];

  final List<String> _descriptions = [
    'Analyze your spending habits to better manage your finances.',
    'Plan your budget effectively to save for your future goals.',
    'Predict stock trends and make informed investment decisions.',
    'Get recommendations for mutual funds to grow your investments.',
    'Calculate your taxes easily and avoid last-minute hassles.',
    'Keep track of important dates and reminders in one place.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Money Matters',
          style: TextStyle(
            fontFamily:
                'Playfair Display', // Using Playfair Display for elegance
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Move "Go to Dashboard" to app bar
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard');
            },
            child: const Text(
              'Dashboard',
              style: TextStyle(
                fontFamily: 'Playfair Display', // Using Playfair Display
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
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
      ),
      body: Column(
        children: [
          // Welcome text at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome to Money Matters!',
              style: TextStyle(
                fontFamily:
                    'Playfair Display', // Using Playfair Display for elegance
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Vertical scrolling section
          Expanded(
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _options.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Navigate to statement analyzer if "Spending Analysis" is selected
                    if (_options[index] == 'Spending Analysis') {
                      Navigator.pushNamed(context, '/statement_analyse');
                    } else if (_options[index] == 'Budget Planning') {
                      Navigator.pushNamed(context, '/management');
                    } else if (_options[index] == 'Stock Prediction') {
                      Navigator.pushNamed(context, '/stock');
                    } else if (_options[index] ==
                        'Mutual Fund Recommendation') {
                      Navigator.pushNamed(context, '/mutualfunds');
                    } else if (_options[index] == 'Tax Calculator') {
                      Navigator.pushNamed(context, '/tax');
                    } else if (_options[index] == 'Remainder Calendar') {
                      Navigator.pushNamed(context, '/reminder');
                    }
                  },
                  child: Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: _colors[index],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            _images[index],
                            width: 300,
                            height: 200,
                          ),
                          SizedBox(height: 10),
                          Text(
                            _options[index],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily:
                                  'Playfair Display', // Using Playfair Display
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            _descriptions[index],
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              physics: ClampingScrollPhysics(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/botpopup');
        },
        tooltip: 'Chatbot',
        child: const Icon(Icons.chat),
      ),
    );
  }
}
