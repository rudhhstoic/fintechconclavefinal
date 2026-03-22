// tax_planner_page.dart
// Full CA Tax Planner — design matches article.dart exactly:
//   • extendBodyBehindAppBar + transparent AppBar with dark-blue → transparent gradient
//   • Body: blue.shade800 → white LinearGradient background
//   • Cards: elevation 6, radius 20, InkWell on tap, white → blue.shade50 gradient fill
//   • Typography: Lobster AppBar title, blue.shade900 headings, grey.shade600/800 body
//   • Responsive: isWideScreen = width > 600
// Responsive: mobile = single column | tablet/web = form left + results right

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'tax_planner_provider.dart';
import 'tax_planner_model.dart';

// ─── Helper ───────────────────────────────────────────────────────
String _fmt(double v) =>
    '₹${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

// ─── Category metadata ────────────────────────────────────────────
const _catMeta = {
  'regime':        {'icon': Icons.compare_arrows_rounded,   'color': Color(0xFF1565C0)},
  'investment':    {'icon': Icons.trending_up_rounded,      'color': Color(0xFF2E7D32)},
  'insurance':     {'icon': Icons.health_and_safety_outlined,'color': Color(0xFF00838F)},
  'housing':       {'icon': Icons.home_outlined,            'color': Color(0xFF6A1B9A)},
  'retirement':    {'icon': Icons.savings_outlined,         'color': Color(0xFFE65100)},
  'business':      {'icon': Icons.business_center_outlined, 'color': Color(0xFF4E342E)},
  'capital_gains': {'icon': Icons.show_chart_rounded,       'color': Color(0xFFAD1457)},
  'compliance':    {'icon': Icons.assignment_outlined,      'color': Color(0xFF37474F)},
  'senior':        {'icon': Icons.elderly_outlined,         'color': Color(0xFF558B2F)},
};

IconData _catIcon(String cat) =>
    (_catMeta[cat]?['icon'] as IconData?) ?? Icons.lightbulb_outline;
Color _catColor(String cat) =>
    (_catMeta[cat]?['color'] as Color?) ?? Colors.blue.shade700;

// ═══════════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════════
class TaxCalculatorInputPage extends StatelessWidget {
  const TaxCalculatorInputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaxPlannerProvider(),
      child: const _TaxPlannerShell(),
    );
  }
}

// ─── Shell ────────────────────────────────────────────────────────
class _TaxPlannerShell extends StatelessWidget {
  const _TaxPlannerShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tax Planner',
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 0, 12, 80), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide ? _WideLayout() : _NarrowLayout();
            },
          ),
        ),
      ),
    );
  }
}

// ─── Narrow: stacked ──────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TaxPlannerProvider>(
      builder: (context, p, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FormCard(),
            if (p.isLoading) ...[const SizedBox(height: 16), const _LoadingCard()],
            if (p.hasError) ...[const SizedBox(height: 16), _ErrorCard(message: p.errorMessage)],
            if (p.hasResult) ...[const SizedBox(height: 16), _ResultsView(result: p.result!)],
          ],
        ),
      ),
    );
  }
}

// ─── Wide: side-by-side ───────────────────────────────────────────
// FIX BUG 6: Row must be wrapped in SizedBox.expand so each Expanded
// child's SingleChildScrollView has a bounded height to scroll within.
class _WideLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TaxPlannerProvider>(
      builder: (context, p, _) => SizedBox.expand(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: const _FormCard(),
              ),
            ),
            Container(width: 1, color: Colors.white.withOpacity(0.3)),
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: p.isLoading
                    ? const _LoadingCard()
                    : p.hasError
                        ? _ErrorCard(message: p.errorMessage)
                        : p.hasResult
                            ? _ResultsView(result: p.result!)
                            : const _EmptyState(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INPUT FORM  (article.dart card style)
// ═══════════════════════════════════════════════════════════════════
class _FormCard extends StatefulWidget {
  const _FormCard();

  @override
  State<_FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<_FormCard> {
  final _formKey = GlobalKey<FormState>();
  String _empType = 'Salaried';
  String _cityType = 'non_metro';
  int _activeSection = 0; // for step indicator

  // Controllers
  final _age         = TextEditingController();
  final _income      = TextEditingController();
  final _hra         = TextEditingController();
  final _rentPaid    = TextEditingController();
  final _otherInc    = TextEditingController();
  final _grossRec    = TextEditingController();
  final _actualExp   = TextEditingController();
  final _c80c        = TextEditingController();
  final _npsExtra    = TextEditingController();
  final _empNps      = TextEditingController();
  final _d80dSelf    = TextEditingController();
  final _d80dParents = TextEditingController();
  final _parentsAge  = TextEditingController();
  final _d80e        = TextEditingController();
  final _d80eea      = TextEditingController();
  final _d80eeb      = TextEditingController();
  final _d80g        = TextEditingController();
  final _homeLoan    = TextEditingController();
  final _stcgEq      = TextEditingController();
  final _ltcgEq      = TextEditingController();

  @override
  void dispose() {
    for (final c in [_age, _income, _hra, _rentPaid, _otherInc, _grossRec,
        _actualExp, _c80c, _npsExtra, _empNps, _d80dSelf, _d80dParents,
        _parentsAge, _d80e, _d80eea, _d80eeb, _d80g, _homeLoan, _stcgEq, _ltcgEq]) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0.0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final isSalaried = _empType == 'Salaried';
    context.read<TaxPlannerProvider>().calculate(TaxInputModel(
      age: int.parse(_age.text.trim()),
      employmentType: _empType,
      cityType: _cityType,
      annualIncome: isSalaried ? _v(_income) : 0,
      grossReceipts: !isSalaried ? _v(_grossRec) : 0,
      actualExpenses: _v(_actualExp),
      hra: _v(_hra),
      rentPaid: _v(_rentPaid),
      otherIncome: _v(_otherInc),
      d80c: _v(_c80c),
      npsExtra: _v(_npsExtra),
      employerNps: _v(_empNps),
      d80dSelf: _v(_d80dSelf),
      d80dParents: _v(_d80dParents),
      parentsAge: int.tryParse(_parentsAge.text.trim()) ?? 0,
      d80e: _v(_d80e),
      d80eea: _v(_d80eea),
      d80eeb: _v(_d80eeb),
      d80g: _v(_d80g),
      homeLoanInterest: _v(_homeLoan),
      stcgEquity: _v(_stcgEq),
      ltcgEquity: _v(_ltcgEq),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isSalaried = _empType == 'Salaried';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header (matches article.dart 'Latest Finance News')
          Text(
            'Your Financial Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 76, 104, 146),
            ),
          ),
          const SizedBox(height: 12),

          _buildSection('Personal Details', Icons.person_outline, [
            _field(_age, 'Age', Icons.cake_outlined,
                digits: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final a = int.tryParse(v);
                  if (a == null || a < 18 || a > 100) return 'Enter valid age (18–100)';
                  return null;
                }),
            const SizedBox(height: 12),
            _dropdown('Employment Type', Icons.work_outline, _empType,
                ['Salaried', 'Freelancer', 'Business'],
                (v) => setState(() => _empType = v!)),
            const SizedBox(height: 12),
            _dropdown('City Type (for HRA)', Icons.location_city_outlined, _cityType,
                ['metro', 'non_metro'],
                (v) => setState(() => _cityType = v!),
                labels: ['Metro (Mumbai/Delhi/Chennai/Kolkata)', 'Non-Metro']),
          ]),

          const SizedBox(height: 12),
          _buildSection('Income Details', Icons.account_balance_wallet_outlined, [
            if (isSalaried) ...[
              _currField(_income, 'Annual Salary (Basic + Allowances)', required: true),
              const SizedBox(height: 12),
              _currField(_hra, 'HRA Received'),
              const SizedBox(height: 12),
              _currField(_rentPaid, 'Rent Actually Paid'),
            ] else ...[
              _currField(_grossRec, 'Gross Receipts / Turnover', required: true),
              const SizedBox(height: 12),
              _currField(_actualExp, 'Actual Business Expenses'),
            ],
            const SizedBox(height: 12),
            _currField(_otherInc, 'Other Income (interest, rental, etc.)'),
          ]),

          const SizedBox(height: 12),
          _buildSection('Chapter VI-A Deductions', Icons.savings_outlined, [
            _sectionLabel('80C Bucket (max ₹1.5L total)'),
            _currField(_c80c, 'PPF / ELSS / LIC / EPF / NSC / Tax-FD'),
            const SizedBox(height: 12),
            _sectionLabel('NPS — Beyond 80C'),
            _currField(_npsExtra, '80CCD(1B) — NPS Self (extra ₹50K)'),
            const SizedBox(height: 12),
            _currField(_empNps, '80CCD(2) — Employer NPS Contribution'),
            const SizedBox(height: 12),
            _sectionLabel('Health Insurance — Section 80D'),
            _currField(_d80dSelf, 'Self + Family (max ₹25K / ₹50K if 60+)'),
            const SizedBox(height: 12),
            _currField(_d80dParents, 'Parents Insurance (max ₹25K / ₹50K if 60+)'),
            const SizedBox(height: 12),
            _field(_parentsAge, 'Parents\' Age (for 80D limit)', Icons.family_restroom_outlined,
                digits: true),
            const SizedBox(height: 12),
            _sectionLabel('Other Deductions'),
            _currField(_d80e, '80E — Education Loan Interest (no limit)'),
            const SizedBox(height: 12),
            _currField(_d80eea, '80EEA — Affordable Housing Loan Interest'),
            const SizedBox(height: 12),
            _currField(_d80eeb, '80EEB — Electric Vehicle Loan Interest'),
            const SizedBox(height: 12),
            _currField(_d80g, '80G — Charitable Donations'),
            const SizedBox(height: 12),
            _currField(_homeLoan, 'Sec 24(b) — Home Loan Interest (max ₹2L)'),
          ]),

          const SizedBox(height: 12),
          _buildSection('Capital Gains', Icons.show_chart_rounded, [
            _currField(_stcgEq, 'STCG — Equity / Mutual Funds (taxed @20%)'),
            const SizedBox(height: 12),
            _currField(_ltcgEq, 'LTCG — Equity / Mutual Funds (₹1.25L exempt, @12.5%)'),
          ]),

          const SizedBox(height: 20),
          _CalculateButton(onPressed: _submit),
        ],
      ),
    );
  }

  // ─── Form Section Card ───────────────────────────────────────────
  // FIX: ExpansionTile must sit DIRECTLY in Card — no InkWell/Container
  // wrapper around it. InkWell + Container padding cause RenderBox layout
  // failures. The gradient goes on the Card's Material via a ClipRRect.
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            // FIX: standard tilePadding, no custom trailing (ExpansionTile
            // animates its own chevron — overriding it breaks layout)
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            initiallyExpanded: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            // No trailing: — let ExpansionTile use its default animated chevron
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
              letterSpacing: 0.3,
            )),
      );

  Widget _currField(TextEditingController ctrl, String label,
      {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
      decoration: _dec(label, Icons.currency_rupee).copyWith(
        //prefixText: '₹ ',
        prefixStyle: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600),
      ),
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return 'Required';
              if ((double.tryParse(v.replaceAll(',', '')) ?? 0) <= 0) return 'Enter a valid amount';
              return null;
            }
          : null,
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool digits = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: digits ? TextInputType.number : TextInputType.text,
      inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: _dec(label, icon),
      validator: validator,
    );
  }

  Widget _dropdown(String label, IconData icon, String value, List<String> items,
      ValueChanged<String?> onChanged, {List<String>? labels}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _dec(label, icon),
      items: items.asMap().entries
          .map((e) => DropdownMenuItem(
                value: e.value,
                child: Text(labels != null ? labels[e.key] : e.value),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700, size: 18),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        isDense: true,
      );
}

// ─── Calculate button ─────────────────────────────────────────────
class _CalculateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CalculateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaxPlannerProvider>(
      builder: (_, p, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: p.isLoading
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [Colors.blue.shade700, Colors.blue.shade900],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.blue.shade900.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: p.isLoading ? null : onPressed,
            child: Center(
              child: p.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calculate_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Calculate My Tax',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RESULTS VIEW
// ═══════════════════════════════════════════════════════════════════
class _ResultsView extends StatefulWidget {
  final TaxResultModel result;
  const _ResultsView({required this.result});

  @override
  State<_ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<_ResultsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  int _selectedTab = 0; // 0=Summary 1=Breakdown 2=CA Advice

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your Tax Analysis',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),

            // ── Tab switcher (styled like article 'Read Article' badge)
            _TabSwitcher(
              selected: _selectedTab,
              onTap: (i) => setState(() => _selectedTab = i),
            ),
            const SizedBox(height: 16),

            if (_selectedTab == 0) ...[
              _SummaryCard(result: r),
              const SizedBox(height: 12),
              _RegimeCard(result: r),
              const SizedBox(height: 12),
              _SavingsBanner(savings: r.taxSavings),
              const SizedBox(height: 16),
              _SaveButton(result: r),
            ] else if (_selectedTab == 1) ...[
              _BreakdownCard(label: 'Old Regime', bd: r.oldBreakdown,
                  isBest: r.bestRegime.toLowerCase() == 'old', gross: r.grossIncome),
              const SizedBox(height: 12),
              _BreakdownCard(label: 'New Regime', bd: r.newBreakdown,
                  isBest: r.bestRegime.toLowerCase() == 'new', gross: r.grossIncome),
            ] else ...[
              _CaAdviceList(advice: r.caAdvice),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tab Switcher ─────────────────────────────────────────────────
class _TabSwitcher extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _TabSwitcher({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Summary', 'Breakdown', 'CA Advice'];
    return Row(
      children: tabs.asMap().entries.map((e) {
        final active = e.key == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onTap(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? Colors.blue.shade800 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.blue.shade800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final TaxResultModel result;
  const _SummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return _ArticleCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.receipt_long_outlined, 'Tax Summary', Colors.blue.shade800),
          const SizedBox(height: 16),
          _summaryRow('Gross Income', _fmt(result.grossIncome), Colors.grey.shade800),
          const Divider(height: 20),
          _summaryRow('Taxable Income', _fmt(result.taxableIncome), Colors.blue.shade900),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Best Regime',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade400),
                ),
                child: Text('${result.bestRegime} Regime',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800)),
              ),
            ],
          ),
          const Divider(height: 20),
          _summaryRow('Tax Payable', _fmt(result.taxPayable), Colors.red.shade700,
              bold: true),
        ],
      ),
    );
  }
}

// ─── Regime Comparison Card ───────────────────────────────────────
class _RegimeCard extends StatelessWidget {
  final TaxResultModel result;
  const _RegimeCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final maxT = max(result.oldRegimeTax, result.newRegimeTax);
    final oldBest = result.bestRegime.toLowerCase() == 'old';
    return _ArticleCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.compare_arrows_rounded, 'Regime Comparison', Colors.blue.shade800),
          const SizedBox(height: 16),
          _RegimeBar(label: 'Old Regime', amount: result.oldRegimeTax,
              ratio: maxT > 0 ? result.oldRegimeTax / maxT : 0,
              isBest: oldBest,
              color: oldBest ? Colors.green.shade600 : Colors.orange.shade500),
          const SizedBox(height: 14),
          _RegimeBar(label: 'New Regime', amount: result.newRegimeTax,
              ratio: maxT > 0 ? result.newRegimeTax / maxT : 0,
              isBest: !oldBest,
              color: !oldBest ? Colors.green.shade600 : Colors.orange.shade500),
          const SizedBox(height: 16),
          _MiniChart(
              oldTax: result.oldRegimeTax,
              newTax: result.newRegimeTax,
              oldBest: oldBest),
        ],
      ),
    );
  }
}

class _RegimeBar extends StatelessWidget {
  final String label;
  final double amount;
  final double ratio;
  final bool isBest;
  final Color color;
  const _RegimeBar(
      {required this.label, required this.amount, required this.ratio,
       required this.isBest, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      fontSize: 14)),
              if (isBest) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Best',
                      style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ]
            ]),
            Text(_fmt(amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

class _MiniChart extends StatelessWidget {
  final double oldTax, newTax;
  final bool oldBest;
  const _MiniChart(
      {required this.oldTax, required this.newTax, required this.oldBest});

  @override
  Widget build(BuildContext context) {
    final maxT = max(oldTax, newTax);
    final oldH = maxT > 0 ? (oldTax / maxT) * 90 : 0.0;
    final newH = maxT > 0 ? (newTax / maxT) * 90 : 0.0;
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Bar(h: oldH, label: 'Old',
              color: oldBest ? Colors.green.shade500 : Colors.orange.shade400),
          _Bar(h: newH, label: 'New',
              color: !oldBest ? Colors.green.shade500 : Colors.orange.shade400),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double h;
  final String label;
  final Color color;
  const _Bar({required this.h, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: h),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Container(
          width: 52, height: v,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: Colors.grey.shade700)),
    ]);
  }
}

// ─── Savings Banner ───────────────────────────────────────────────
class _SavingsBanner extends StatelessWidget {
  final double savings;
  const _SavingsBanner({required this.savings});

  @override
  Widget build(BuildContext context) {
    final has = savings > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: has
              ? [Colors.green.shade700, Colors.green.shade400]
              : [Colors.grey.shade600, Colors.grey.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: (has ? Colors.green : Colors.grey).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(has ? Icons.savings_rounded : Icons.info_outline,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Regime Savings',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(has ? _fmt(savings) : 'Both regimes equal',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: has ? 24 : 15,
                    fontWeight: FontWeight.bold)),
            if (has)
              const Text('saved by choosing the better regime',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

// ─── Breakdown Card ───────────────────────────────────────────────
// FIX BUG 4: _cardHeader returns a Row with an Expanded child.
// Putting that inside another Row causes unbounded width crash.
// Solution: use a Column for the header area, not Row.
class _BreakdownCard extends StatelessWidget {
  final String label;
  final RegimeBreakdown bd;
  final bool isBest;
  final double gross;
  const _BreakdownCard(
      {required this.label, required this.bd, required this.isBest, required this.gross});

  @override
  Widget build(BuildContext context) {
    final accentColor = isBest ? Colors.green.shade700 : Colors.blue.shade800;
    return _ArticleCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: header + badge in a Column so no Row-inside-Row issue
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calculate_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              if (isBest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Recommended',
                      style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _bRow('Gross Income', _fmt(gross)),
          if (bd.standardDeduction > 0)
            _bRow('(-) Standard Deduction', _fmt(bd.standardDeduction), sub: true),
          if (bd.hraExemption > 0)
            _bRow('(-) HRA Exemption', _fmt(bd.hraExemption), sub: true),
          if (bd.totalDeductions > 0)
            _bRow('(-) Total Deductions', _fmt(bd.totalDeductions),
                sub: true, bold: true),
          const Divider(height: 16),
          _bRow('Taxable Income', _fmt(bd.taxableIncome), bold: true),
          const SizedBox(height: 4),
          _bRow('Base Tax', _fmt(bd.baseTax)),
          if (bd.rebate87a > 0)
            _bRow('(-) Rebate 87A', _fmt(bd.rebate87a), sub: true),
          if (bd.surcharge > 0)
            _bRow('(+) Surcharge', _fmt(bd.surcharge)),
          _bRow('(+) Cess 4%', _fmt(bd.cess)),
          if (bd.cgTax > 0)
            _bRow('(+) Capital Gains Tax', _fmt(bd.cgTax)),
          const Divider(height: 16),
          _bRow('Total Tax Payable', _fmt(bd.totalTax),
              bold: true,
              color: isBest ? Colors.green.shade700 : Colors.red.shade700),
        ],
      ),
    );
  }

  Widget _bRow(String l, String v,
      {bool sub = false, bool bold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(sub ? 12 : 0, 4, 0, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(l,
                style: TextStyle(
                    fontSize: sub ? 13 : 14,
                    color: sub ? Colors.grey.shade500 : Colors.grey.shade700)),
          ),
          Text(v,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: color ?? Colors.grey.shade800)),
        ],
      ),
    );
  }
}

// ─── CA Advice List ───────────────────────────────────────────────
class _CaAdviceList extends StatelessWidget {
  final List<CaAdviceItem> advice;
  const _CaAdviceList({required this.advice});

  @override
  Widget build(BuildContext context) {
    if (advice.isEmpty) {
      return const Center(child: Text('No advice available.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${advice.length} personalised tips from your CA',
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        ...advice.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AdviceCard(item: a),
            )),
      ],
    );
  }
}

class _AdviceCard extends StatefulWidget {
  final CaAdviceItem item;
  const _AdviceCard({required this.item});

  @override
  State<_AdviceCard> createState() => _AdviceCardState();
}

class _AdviceCardState extends State<_AdviceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.item;
    final catColor = _catColor(a.category);
    final catIcon  = _catIcon(a.category);

    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row — mirrors article.dart article card layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: catColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(catIcon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.folder_outlined,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(a.section,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                          if (a.potentialSaving > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Save ${_fmt(a.potentialSaving)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800),
                              ),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  //Icon(
                  //  _expanded ? Icons.expand_less : Icons.expand_more,
                  //  color: Colors.blue.shade800, size: 20,
                  //),
                ],
              ),

              // Expanded detail
              if (_expanded) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    a.advice,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.5),
                  ),
                ),
              ],

              const SizedBox(height: 10),
              // Bottom badge row — mirrors 'Read Article' badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_expanded ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 13, color: Colors.blue.shade800),
                        const SizedBox(width: 4),
                        Text(
                          _expanded ? 'Hide Detail' : 'View Detail',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  //Icon(Icons.arrow_forward_ios, size: 13, color: Colors.blue.shade800),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Save Button + Bottom Sheet ───────────────────────────────────
class _SaveButton extends StatelessWidget {
  final TaxResultModel result;
  const _SaveButton({required this.result});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _show(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.blue.shade700, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(Icons.bookmark_add_outlined, color: Colors.blue.shade700),
      label: Text('Save Tax Plan',
          style: TextStyle(
              color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tax Plan Summary',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900)),
            const SizedBox(height: 16),
            _planRow('Best Regime', '${result.bestRegime} Regime'),
            _planRow('Gross Income', _fmt(result.grossIncome)),
            _planRow('Taxable Income', _fmt(result.taxableIncome)),
            _planRow('Total Tax', _fmt(result.taxPayable)),
            _planRow('Regime Savings', _fmt(result.taxSavings)),
            _planRow('CA Tips', '${result.caAdvice.length} personalised tips'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('✅ Tax plan saved!'),
                    backgroundColor: Colors.green,
                  ));
                },
                icon: const Icon(Icons.save_alt, color: Colors.white),
                label: const Text('Save Plan',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planRow(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            Text(v,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED ARTICLE-STYLE CARD
// ═══════════════════════════════════════════════════════════════════
// FIX: removed unused accentColor parameter that caused confusion
class _ArticleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Shared header row (icon + title) ─────────────────────────────
Widget _cardHeader(IconData icon, String title, Color color) {
  return Row(children: [
    Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Text(title,
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900)),
    ),
  ]);
}

Widget _summaryRow(String label, String value, Color color,
    {bool bold = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      Text(value,
          style: TextStyle(
              fontSize: 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color)),
    ],
  );
}

// ─── Loading ──────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Column(
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.blue.shade800),
                strokeWidth: 3),
            const SizedBox(height: 18),
            Text('Your CA is calculating...',
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
              colors: [Colors.white, Colors.red.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 12),
            Text('Calculation Failed',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold,
                    color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => context.read<TaxPlannerProvider>().reset(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(Icons.refresh, color: Colors.blue.shade700, size: 18),
              label: Text('Try Again',
                  style: TextStyle(color: Colors.blue.shade700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state (wide layout) ────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.calculate_outlined,
                  size: 52, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 18),
            Text('Fill the form and\nhit Calculate',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}