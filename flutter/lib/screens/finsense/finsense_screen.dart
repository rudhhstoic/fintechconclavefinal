import 'package:flutter/material.dart';
import '../../services/setu_service.dart';
import 'package:provider/provider.dart';
import '../../auth_provider.dart';
import 'chat_screen.dart';
import 'nudge_card.dart';

class FinsenseScreen extends StatefulWidget {
  const FinsenseScreen({super.key});

  @override
  State<FinsenseScreen> createState() => _FinsenseScreenState();
}

class _FinsenseScreenState extends State<FinsenseScreen> {
  static const _navy = Color(0xFF0A0E2E);
  static const _darkBg = Color(0xFF050818);
  static const _cardBg = Color(0xFF0D1B4B);
  static const _blue = Color(0xFF1565C0);
  static const _red = Color(0xFFC62828);
  static const _green = Color(0xFF00C853);

  final SetuService _api = SetuService();
  bool _isLoading = false;
  List<dynamic> _warnings = [];
  List<dynamic> _reminders = [];
  Map<String, dynamic> _report = {};
  DateTime _lastSynced = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).serialId.toString();
    setState(() => _isLoading = true);
    try {
      final warnings = await _api.getWarnings(userId);
      final reminders = await _api.getReminders(userId);
      final report = await _api.getReport(userId);
      setState(() {
        _warnings = warnings;
        _reminders = reminders;
        _report = report;
        _isLoading = false;
        _lastSynced = DateTime.now();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _navy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _buildSettingsTile(Icons.notifications_active_outlined, "Manage Reminders", () {
              Navigator.pop(context);
              _showManageReminders();
            }),
            _buildSettingsTile(Icons.sync, "Re-sync Bank Data", () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/aa_connect');
            }),
            _buildSettingsTile(Icons.settings_outlined, "Notification Settings", () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings screen coming soon!")));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade300),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showManageReminders() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _navy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Manage Reminders", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white12, height: 32),
            Expanded(
              child: _reminders.isEmpty 
                ? const Center(child: Text("No reminders found", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final r = _reminders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(r['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text("₹${r['amount']} - Day ${r['due_day'] ?? 1}", style: TextStyle(color: Colors.blue.shade300)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: _red),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deletion not implemented in demo")));
                            },
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminder() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = "Bill";
    int dueDay = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _navy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Payment Reminder", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(nameCtrl, "Description (e.g. Rent, Jio Bill)"),
            const SizedBox(height: 12),
            _buildTextField(amountCtrl, "Amount", isNumber: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDropdown<int>(dueDay, List.generate(31, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text("Day $d"))).toList(), (v) => dueDay = v!)),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown<String>(type, ["SIP", "EMI", "Bill"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), (v) => type = v!)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final userId = Provider.of<AuthProvider>(context, listen: false).serialId.toString();
                  await _api.saveReminder(userId, {
                    "name": nameCtrl.text,
                    "amount": double.tryParse(amountCtrl.text) ?? 0.0,
                    "due_day": dueDay,
                    "type": type,
                  });
                  Navigator.pop(context);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Create Reminder", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: _cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue)),
      ),
    );
  }

  Widget _buildDropdown<T>(T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: _navy,
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.arrow_drop_down, color: _blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool showReport = now.day >= 28 || _report.isNotEmpty;

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: _navy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("FinSense AI", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(
              "Last synced: ${now.difference(_lastSynced).inMinutes} mins ago",
              style: TextStyle(fontSize: 11, color: Colors.blue.shade300, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _showSettings, icon: const Icon(Icons.settings_outlined, color: Colors.white)),
        ],
        shape: const Border(bottom: BorderSide(color: _blue, width: 0.5)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: _navy,
        color: _blue,
        child: _isLoading && _warnings.isEmpty && _reminders.isEmpty && _report.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : CustomScrollView(
              slivers: [
                if (showReport)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: NudgeCard(report: _report, isDemo: now.day < 28),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        const Text("ALERTS", style: TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(width: 6),
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 150,
                    child: _warnings.isEmpty 
                      ? const Center(child: Text("No immediate alerts", style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _warnings.length,
                          itemBuilder: (context, index) {
                            final w = _warnings[index];
                            final isCritical = w['severity'] == 'critical';
                            final progress = (w['percentage_used'] ?? 0.0) / 100.0;
                            
                            return Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: isCritical 
                                    ? [const Color(0xFF7F0000), const Color(0xFFB71C1C)]
                                    : [const Color(0xFF4A3000), const Color(0xFFE65100)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(isCritical ? Icons.campaign : Icons.warning_amber, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(w['type'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                        child: Text(w['category'] ?? "General", style: const TextStyle(color: Colors.white, fontSize: 9)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(w['message'], style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const Spacer(),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress > 1.0 ? 1.0 : progress,
                                            backgroundColor: Colors.white.withOpacity(0.2),
                                            valueColor: AlwaysStoppedAnimation<Color>(isCritical ? _red : Colors.orange),
                                            minHeight: 4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text("${w['percentage_used']}%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                    child: const Text("UPCOMING PAYMENTS", style: TextStyle(color: _blue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                if (_reminders.isEmpty)
                  const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text("All clear for now!", style: TextStyle(color: Colors.white38))))),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final r = _reminders[index];
                      IconData icon = Icons.receipt;
                      if (r['type'] == 'SIP') icon = Icons.trending_up;
                      if (r['type'] == 'EMI') icon = Icons.home;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _blue.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(color: _blue.withOpacity(0.15), blurRadius: 12, spreadRadius: 2),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_blue, Color(0xFF0D47A1)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                            child: Icon(icon, color: Colors.white, size: 22),
                          ),
                          title: Text(r['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text("${r['type']} • Due Day ${r['due_day'] ?? 1}", style: TextStyle(color: Colors.blue.shade300, fontSize: 12)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("₹${r['amount']}", style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              if (r['days_left'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8)),
                                  child: Text("${r['days_left']}d left", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _reminders.length,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
      ),
      bottomSheet: Container(
        height: 88,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        color: _navy,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [_blue, Color(0xFF0D47A1)]),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/finsense/chat'),
              borderRadius: BorderRadius.circular(12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Ask FinSense AI", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84.0),
        child: FloatingActionButton(
          onPressed: _showAddReminder,
          backgroundColor: _red,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: _red.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)]),
            child: const Icon(Icons.add, size: 30),
          ),
        ),
      ),
    );
  }
}
