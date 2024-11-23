import 'dart:async';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final List<String> _options = [
    'Spending Analysis',
    'Budget Planning',
    'Stock Prediction',
    'Mutual Fund Recommendation',
    'Tax Calculator',
    'Remainder Calendar',
    'Articles',
  ];

  final List<String> _images = [
    'assets/image6.jpg',
    'assets/image12.jpg',
    'assets/image7.jpg',
    'assets/image8.jpg',
    'assets/image9.jpg',
    'assets/image10.jpg',
    'assets/image11.png',
  ];

  final List<String> _descriptions = [
    'Analyze your spending habits to better manage your finances.',
    'Plan your budget effectively to save for your future goals.',
    'Predict stock trends and make informed investment decisions.',
    'Get recommendations for mutual funds to grow your investments.',
    'Calculate your taxes easily and avoid last-minute hassles.',
    'Keep track of important dates and reminders in one place.',
    'Read the articles and become expertise',
  ];

  final PageController _pageController = PageController();
  late Timer _scrollTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.toInt() + 1;
        _pageController.animateToPage(
          nextPage % _options.length,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _scrollTimer.cancel();
  }

  @override
  void dispose() {
    _scrollTimer.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'FinBuild',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.redAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome to Money Matters!',
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _stopAutoScroll,
                onPanDown: (_) => _stopAutoScroll(),
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        String option = _options[index];
                        Navigator.pushNamed(
                          context,
                          {
                            'Spending Analysis': '/statement_analyse',
                            'Budget Planning': '/management',
                            'Stock Prediction': '/stock',
                            'Mutual Fund Recommendation': '/mutualfunds',
                            'Tax Calculator': '/tax',
                            'Remainder Calendar': '/reminder',
                            'Articles': '/article',
                          }[option]!,
                        );
                      },
                      child: Center(
                        child: Container(
                          width: 400,
                          height: 400,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: Colors.redAccent, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
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
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _options[index],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Playfair Display',
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _descriptions[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.redAccent,
          onPressed: () {
            Navigator.pushNamed(context, '/botpopup');
          },
          tooltip: 'Chatbot',
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }
}
