import 'package:flutter/material.dart';
import 'mutual_fund_service.dart';
import 'package:flutter_svg/flutter_svg.dart'; // For using icons

class MutualFund {
  final String name;
  final String categoryMain; // Main category like "EQUITY"
  final String categorySub; // Subcategory like "SMALL CAP"
  final String amc;
  final String currentValue;
  final String returnPerAnnum;
  final String expenseRatio;
  final String age;
  final String return1Month;
  final String return3Months;
  final String return6Months;

  MutualFund({
    required this.name,
    required this.categoryMain,
    required this.categorySub,
    required this.amc,
    required this.currentValue,
    required this.return1Month,
    required this.return3Months,
    required this.return6Months,
    required this.returnPerAnnum,
    required this.expenseRatio,
    required this.age,
  });

  factory MutualFund.fromJson(Map<String, dynamic> json) {
    return MutualFund(
      name: json['name'],
      categoryMain: json['category']['main'],
      categorySub: json['category']['sub'],
      amc: json['amc'],
      currentValue: json['current_value'],
      return1Month:
          json['return_1_month'], // Ensure this matches the backend JSON key
      return3Months: json['return_3_month'], // Same here
      return6Months: json['return_6_month'], // And here
      returnPerAnnum: json['return_per_annum'],
      expenseRatio: json['expense_ratio'],
      age: json['age'],
    );
  }
}

class MutualFundPage extends StatefulWidget {
  @override
  _MutualFundPageState createState() => _MutualFundPageState();
}

class _MutualFundPageState extends State<MutualFundPage> {
  late Future<List<MutualFund>> futureFunds;
  List<MutualFund> allFunds = [];
  List<MutualFund> displayedFunds = [];
  int fundsToShow = 20;

  // Filters
  String selectedCategoryMain = '';
  String selectedInvestmentPeriod = '';
  String selectedFundSize = '';

  @override
  void initState() {
    super.initState();
    futureFunds = MutualFundService().fetchMutualFunds();
    futureFunds.then((funds) {
      setState(() {
        allFunds = funds;
        displayedFunds = allFunds.take(fundsToShow).toList();
      });
    });
  }

  void applyFilters() {
    setState(() {
      final filteredFunds = allFunds.where((fund) {
        final categoryMatch = selectedCategoryMain.isEmpty ||
            fund.categoryMain == selectedCategoryMain;
        final fundSizeMatch = selectedFundSize.isEmpty ||
            fund.categorySub.contains(selectedFundSize);

        return categoryMatch && fundSizeMatch;
      }).toList();

      filteredFunds.sort((a, b) {
        switch (selectedInvestmentPeriod) {
          case '1 month':
            return b.return1Month.compareTo(a.return1Month);
          case '3 months':
            return b.return3Months.compareTo(a.return3Months);
          case '6 months':
            return b.return6Months.compareTo(a.return6Months);
          case '1 year':
            return b.returnPerAnnum.compareTo(a.returnPerAnnum);
          default:
            return 0;
        }
      });

      displayedFunds = filteredFunds.take(fundsToShow).toList();
    });
  }

  void toggleFilter(String filterType, String value) {
    setState(() {
      switch (filterType) {
        case 'category':
          selectedCategoryMain = selectedCategoryMain == value ? '' : value;
          break;
        case 'investmentPeriod':
          selectedInvestmentPeriod =
              selectedInvestmentPeriod == value ? '' : value;
          break;
        case 'fundSize':
          selectedFundSize = selectedFundSize == value ? '' : value;
          break;
      }
      applyFilters();
    });
  }

  void showMoreFunds() {
    setState(() {
      fundsToShow += 20;
      displayedFunds = allFunds.take(fundsToShow).toList();
    });
  }

  Widget buildReturnRow(String return1Month, String return3Months,
      String return6Months, String returnPerAnnum) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildReturnColumn('1M', return1Month),
        _buildReturnColumn('3M', return3Months),
        _buildReturnColumn('6M', return6Months),
        _buildReturnColumn('1Y', returnPerAnnum),
      ],
    );
  }

  Widget _buildReturnColumn(String label, String returnValue) {
    final double returnPercent = double.tryParse(returnValue) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        Row(
          children: [
            Icon(
              returnPercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              color: returnPercent >= 0 ? Colors.green : Colors.red,
              size: 16,
            ),
            Text(
              "$returnValue%",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 12, 80),
        title: const Text(
          'Mutual Funds',
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
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Choose it based on your need',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategoryMain.isEmpty
                                  ? null
                                  : selectedCategoryMain,
                              items: ['EQUITY', 'DEBT', 'TAX SAVER', 'HYBRID']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                toggleFilter('category', value ?? '');
                              },
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedInvestmentPeriod.isEmpty
                                  ? null
                                  : selectedInvestmentPeriod,
                              items:
                                  ['1 month', '3 months', '6 months', '1 year']
                                      .map((period) => DropdownMenuItem(
                                            value: period,
                                            child: Text(period),
                                          ))
                                      .toList(),
                              onChanged: (value) {
                                toggleFilter('investmentPeriod', value ?? '');
                              },
                              decoration: InputDecoration(
                                labelText: 'Investment Period',
                                prefixIcon: Icon(Icons.access_time),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedFundSize.isEmpty
                                  ? null
                                  : selectedFundSize,
                              items: [
                                'SMALL',
                                'MID',
                                'LARGE',
                                'ELSS',
                              ]
                                  .map((size) => DropdownMenuItem(
                                        value: size,
                                        child: Text(size),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                toggleFilter('fundSize', value ?? '');
                              },
                              decoration: InputDecoration(
                                labelText: 'Fund Size',
                                prefixIcon: Icon(Icons.pie_chart_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.pie_chart,
                              color: Colors
                                  .white), // Bright icon for the fund size
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<MutualFund>>(
                future: futureFunds,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No data available"));
                  } else {
                    return ListView.builder(
                      itemCount: displayedFunds.length + 1,
                      itemBuilder: (context, index) {
                        if (index == displayedFunds.length) {
                          return TextButton(
                            onPressed: showMoreFunds,
                            child: Text(
                              "Show ${fundsToShow < allFunds.length ? 'More' : 'All'} Funds",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        }

                        final fund = displayedFunds[index];
                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fund.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            fund.categoryMain,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            'Fund Size: ${fund.categorySub}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.deepOrangeAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SvgPicture.asset(
                                      'assets/fund_icon.svg',
                                      height: 50,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                buildReturnRow(
                                    fund.return1Month,
                                    fund.return3Months,
                                    fund.return6Months,
                                    fund.returnPerAnnum),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
