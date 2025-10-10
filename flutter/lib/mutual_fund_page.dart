import 'package:flutter/material.dart';
import 'mutual_fund_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MutualFund {
  final String name;
  final String categoryMain;
  final String categorySub;
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
      return1Month: json['return_1_month'],
      return3Months: json['return_3_month'],
      return6Months: json['return_6_month'],
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 600;
    final padding = isWideScreen ? 32.0 : 16.0;
    final cardRadius = BorderRadius.circular(20.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mutual Funds',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 0, 12, 80), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterCard(padding, cardRadius),
              Expanded(
                child: FutureBuilder<List<MutualFund>>(
                  future: futureFunds,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: TextStyle(color: Colors.red.shade800, fontSize: 16),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "No data available",
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                      );
                    } else {
                      return SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Funds',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              SizedBox(height: padding / 2),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: displayedFunds.length,
                                itemBuilder: (context, index) {
                                  final fund = displayedFunds[index];
                                  return _buildFundCard(fund, padding, cardRadius);
                                },
                              ),
                              if (fundsToShow < allFunds.length)
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: padding),
                                    child: ElevatedButton(
                                      onPressed: showMoreFunds,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade800,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        'Show More Funds',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(double padding, BorderRadius cardRadius) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose based on your need',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              SizedBox(height: padding / 2),
              Divider(color: Colors.blue.shade100),
              SizedBox(height: padding / 2),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      value: selectedCategoryMain.isEmpty ? null : selectedCategoryMain,
                      items: ['EQUITY', 'DEBT', 'TAX SAVER', 'HYBRID'],
                      label: 'Category',
                      icon: Icons.category,
                      onChanged: (value) => toggleFilter('category', value ?? ''),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      value: selectedInvestmentPeriod.isEmpty ? null : selectedInvestmentPeriod,
                      items: ['1 month', '3 months', '6 months', '1 year'],
                      label: 'Period',
                      icon: Icons.access_time,
                      onChanged: (value) => toggleFilter('investmentPeriod', value ?? ''),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildDropdown(
                value: selectedFundSize.isEmpty ? null : selectedFundSize,
                items: ['SMALL', 'MID', 'LARGE', 'ELSS'],
                label: 'Fund Size',
                icon: Icons.pie_chart_outline,
                onChanged: (value) => toggleFilter('fundSize', value ?? ''),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blue.shade800),
          prefixIcon: Icon(icon, color: Colors.blue.shade800),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade800),
      ),
    );
  }

  Widget _buildFundCard(MutualFund fund, double padding, BorderRadius cardRadius) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.only(bottom: padding / 2),
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      child: ExpansionTile(
        title: Text(
          fund.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              fund.categoryMain,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Fund Size: ${fund.categorySub}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(padding / 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReturnChip('1M', fund.return1Month),
                _buildReturnChip('3M', fund.return3Months),
                _buildReturnChip('6M', fund.return6Months),
                _buildReturnChip('1Y', fund.returnPerAnnum),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnChip(String label, String value) {
    final double parsed = double.tryParse(value) ?? 0.0;
    return Chip(
      label: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            '${parsed.toStringAsFixed(1)}%',
            style: TextStyle(
              color: parsed > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }
}