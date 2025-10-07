import 'package:flutter/material.dart';
import 'dart:math';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _arrowController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  final ScrollController _scrollController = ScrollController();
  bool _showFeatures = false;

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Spending Analysis',
      'description': 'AI-powered breakdown of spending habits.',
      'icon': Icons.analytics,
      'color': Colors.redAccent,
      'route': '/statement_analyse',
    },
    {
      'title': 'Budget Planning',
      'description': 'Plan monthly budgets with ease.',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
      'route': '/management',
    },
    {
      'title': 'Stock Prediction',
      'description': 'Smart forecasts for stock trends.',
      'icon': Icons.trending_up,
      'color': Colors.green,
      'route': '/stock',
    },
    {
      'title': 'Mutual Funds',
      'description': 'Personalized recommendations.',
      'icon': Icons.pie_chart,
      'color': Colors.orange,
      'route': '/mutualfunds',
    },
    {
      'title': 'Reminders',
      'description': 'Never miss bills & payments.',
      'icon': Icons.calendar_today,
      'color': Colors.purple,
      'route': '/reminder',
    },
    {
      'title': 'Tax Calculator',
      'description': 'Save more with smart tax tools.',
      'icon': Icons.calculate,
      'color': Colors.teal,
      'route': '/tax',
    },
  ];

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _arrowController =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _heroController, curve: Curves.easeInOut));

    _slideUp = Tween<double>(begin: 40.0, end: 0.0).animate(
        CurvedAnimation(parent: _heroController, curve: Curves.easeOutBack));

    _scrollController.addListener(() {
      if (_scrollController.offset > 250 && !_showFeatures) {
        setState(() => _showFeatures = true);
      }
    });

    _heroController.forward();
    _arrowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _heroController.dispose();
    _arrowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 8, 49),
              Colors.black,
              Colors.redAccent.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(isMobile),
              _buildHero(isMobile),
              _buildFeatures(isMobile),
              _buildGrowthSection(isMobile),
              _buildStudentSection(isMobile),
              _buildFooter(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: isMobile ? 12 : 30, vertical: isMobile ? 30 : 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("FINTECH",
              style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Row(children: [
            _headerBtn("Login", false, () {
              Navigator.pushNamed(context, '/login');
            }, isMobile),
            SizedBox(width: 10),
            _headerBtn("Sign Up", true, () {
              Navigator.pushNamed(context, '/signup');
            }, isMobile),
          ])
        ],
      ),
    );
  }

  Widget _headerBtn(
      String txt, bool filled, VoidCallback onTap, bool isMobile) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? Colors.redAccent : Colors.transparent,
        side: BorderSide(color: Colors.redAccent, width: 1.5),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 22, vertical: isMobile ? 8 : 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 18 : 25)),
      ),
      child: Text(txt,
          style: TextStyle(fontSize: isMobile ? 12 : 16)),
    );
  }

  Widget _buildHero(bool isMobile) {
    return Container(
      height: isMobile ? 320 : 500,
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _fadeIn,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeIn.value,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("FINTECH",
                      style: TextStyle(
                          fontSize: isMobile ? 40 : 90,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 6)),
                  SizedBox(height: 12),
                  Text("Empowering Financial Growth",
                      style: TextStyle(
                          fontSize: isMobile ? 14 : 20,
                          color: Colors.white70)),
                  SizedBox(height: 25),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 18 : 28,
                                  vertical: isMobile ? 10 : 14)),
                          child: Text("Get Started",
                              style: TextStyle(
                                  fontSize: isMobile ? 13 : 16,
                                  fontWeight: FontWeight.bold))),
                      OutlinedButton(
                          onPressed: () => _scrollController.animateTo(
                              MediaQuery.of(context).size.height,
                              duration: Duration(seconds: 1),
                              curve: Curves.easeInOut),
                          style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white, width: 1.5),
                              padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 18 : 28,
                                  vertical: isMobile ? 10 : 14)),
                          child: Text("Explore Features",
                              style: TextStyle(
                                  fontSize: isMobile ? 13 : 16,
                                  color: Colors.white)))
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatures(bool isMobile) {
    int crossCount = isMobile ? 2 : 3;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Column(
        children: [
          Text("Specialized & Powerful",
              style: TextStyle(
                  fontSize: isMobile ? 20 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _features.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isMobile ? 0.9 : 1.1,
            ),
            itemBuilder: (context, i) => _featureCard(_features[i], isMobile),
          )
        ],
      ),
    );
  }

  Widget _featureCard(Map<String, dynamic> feat, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: feat['color'].withOpacity(0.5), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(feat['icon'], size: isMobile ? 26 : 40, color: feat['color']),
          SizedBox(height: 6),
          Text(feat['title'],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isMobile ? 12 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 4),
          Text(feat['description'],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isMobile ? 10 : 13, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildGrowthSection(bool isMobile) {
    final items = [
      {"icon": Icons.trending_up, "title": "Stocks"},
      {"icon": Icons.attach_money, "title": "Money"},
      {"icon": Icons.school, "title": "Students"},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Column(
        children: [
          Text("Your Growth Journey",
              style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: items
                .map((e) => Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                          radius: isMobile ? 28 : 40,
                          child: Icon(e["icon"] as IconData,
                              size: isMobile ? 26 : 40,
                              color: Colors.redAccent),
                        ),
                        SizedBox(height: 8),
                        Text(e["title"] as String,
                            style: TextStyle(
                                fontSize: isMobile ? 12 : 16,
                                color: Colors.white))
                      ],
                    ))
                .toList(),
          )
        ],
      ),
    );
  }

  Widget _buildStudentSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Column(
        children: [
          Text("Our Motive",
              style: TextStyle(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 12),
          Text(
            "Our platform is built to help students manage their money smartly. "
            "From budgeting pocket expenses to learning investments, we provide "
            "a step-by-step way to develop strong financial habits. This ensures "
            "you start your professional life with confidence and financial health.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: isMobile ? 12 : 15,
                color: Colors.white70,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border(top: BorderSide(color: Colors.redAccent))),
      child: Column(
        children: [
          Text("Start Your Journey",
              style: TextStyle(
                  fontSize: isMobile ? 16 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 12),
          ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 40,
                      vertical: isMobile ? 10 : 16)),
              child: Text("Get Started",
                  style: TextStyle(
                      fontSize: isMobile ? 13 : 16,
                      fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }
}
