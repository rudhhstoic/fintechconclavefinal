import 'package:flutter/material.dart';

class NudgeCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final bool isDemo;

  static const _navy = Color(0xFF0A0E2E);
  static const _darkBg = Color(0xFF050818);
  static const _cardBg = Color(0xFF0D1B4B);
  static const _blue = Color(0xFF1565C0);
  static const _red = Color(0xFFC62828);
  static const _green = Color(0xFF00C853);

  const NudgeCard({
    super.key,
    required this.report,
    this.isDemo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _blue.withOpacity(0.15), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Red accent line
          Positioned(top: 0, left: 0, right: 0, child: Container(height: 3, color: _red)),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_navy, _cardBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "${report['month'] ?? 'March'} Report",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (isDemo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                        child: const Text("Demo Report", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Center(
                  child: Column(
                    children: [
                      const Text("TOTAL SAVED THIS MONTH", style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(
                        "₹${report['savings'] ?? 0}",
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Color(0x6600E676), blurRadius: 15)],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatChip("INCOME", "₹${report['total_income'] ?? 0}"),
                    _buildStatChip("EXPENSES", "₹${report['total_expenses'] ?? 0}"),
                    _buildStatChip("SAVINGS RATE", "${report['savings_rate_percent'] ?? 0}%"),
                  ],
                ),
                const SizedBox(height: 32),
                const Text("VS LAST MONTH", style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _buildComparisonRow(report['vs_last_month'] ?? []),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    const Text("AI INSIGHTS", style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 12),
                ...((report['nudges'] as List?)?.map((n) => _buildNudgeItem(n.toString())) ?? []),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("View Full Report"),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ).borderRadius(24),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(List<dynamic> vsLast) {
    return Column(
      children: vsLast.take(2).map((comp) {
        final change = (comp['change_percent'] as num? ?? 0);
        final isNegative = change < 0; 
        final category = comp['category'] ?? "Other";
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                isNegative ? Icons.south_east : Icons.north_east,
                color: isNegative ? _green : _red,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                "$category spent ${change.abs()}% ${isNegative ? 'less' : 'more'}",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNudgeItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.amber, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates, color: Colors.amber, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget borderRadius(double radius) => ClipRRect(borderRadius: BorderRadius.circular(radius), child: this);
}
