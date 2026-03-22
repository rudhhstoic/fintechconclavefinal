import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kBg        = Color(0xFF000000);
const Color _kBg2       = Color(0xFF0D0005);
const Color _kSurface   = Color(0xFF130008);
const Color _kAccent    = Color(0xFFE53935);
const Color _kAccentSft = Color(0xFFFF5252);
const Color _kGlow      = Color(0x44FF1744);
const Color _kBorder    = Color(0x33FF5252);
const Color _kWhite60   = Color(0x99FFFFFF);
const Color _kWhite30   = Color(0x4DFFFFFF);

// ─────────────────────────────────────────────────────────────────────────────
//  FEATURE DATA
// ─────────────────────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> kFeatures = [
  {
    'title':    'Spending Analysis',
    'subtitle': 'Know exactly where your money goes',
    'tag':      'AI',
    'icon':     Icons.bar_chart_rounded,
    'points': [
      'Upload bank statements in PDF or CSV',
      'AI auto-categorises every transaction',
      'Visual charts: food, rent, leisure and more',
      'Month-on-month comparison and saving tips',
    ],
  },
  {
    'title':    'Budget Planning',
    'subtitle': 'Plan every rupee before you spend it',
    'tag':      'PLAN',
    'icon':     Icons.account_balance_wallet_outlined,
    'points': [
      'Set monthly income and expense limits',
      'Real-time burn rate tracker per category',
      'Alerts when nearing your spending limit',
      'Visual progress bars for each budget',
    ],
  },
  {
    'title':    'Stock Prediction',
    'subtitle': 'AI-driven market intelligence',
    'tag':      'ML',
    'icon':     Icons.trending_up_rounded,
    'points': [
      'ML price forecasts for NSE and BSE stocks',
      'Buy / Hold / Sell signal indicators',
      'Historical trend visualisation on charts',
      'Confidence score for each prediction',
    ],
  },
  {
    'title':    'Mutual Fund Picks',
    'subtitle': 'Personalised fund recommendations',
    'tag':      'SMART',
    'icon':     Icons.pie_chart_outline_rounded,
    'points': [
      'Quick risk-profile quiz to match your goals',
      'Top fund recommendations across categories',
      'Expected returns and risk ratings shown',
      'One-tap deep-dive into fund details',
    ],
  },
  {
    'title':    'Tax Calculator',
    'subtitle': 'Save more, stress less at tax time',
    'tag':      'TAX',
    'icon':     Icons.calculate_outlined,
    'points': [
      'Old vs New tax regime instant comparison',
      'Input income, HRA, 80C and 80D deductions',
      'Clear liability breakdown with charts',
      'Tips to maximise your tax refund',
    ],
  },
  {
    'title':    'Reminder Calendar',
    'subtitle': 'Never miss a payment again',
    'tag':      'ALERTS',
    'icon':     Icons.notifications_active_outlined,
    'points': [
      'Schedule EMI, SIP, and bill reminders',
      'Custom alert timing before due dates',
      'Monthly financial event overview',
      'Never pay a late fee again',
    ],
  },
  {
    'title':    'Finance Articles',
    'subtitle': 'Learn while you build wealth',
    'tag':      'LEARN',
    'icon':     Icons.menu_book_outlined,
    'points': [
      'Curated articles on investing and tax',
      'Beginner to advanced personal finance guides',
      'Weekly picks from top finance writers',
      'Bookmark and revisit anytime',
    ],
  },
  {
    'title':    'AI Finance Chatbot',
    'subtitle': 'Your 24/7 personal finance advisor',
    'tag':      'GPT',
    'icon':     Icons.smart_toy_outlined,
    'points': [
      'Ask anything — budgets, stocks, tax, funds',
      'Contextual answers trained on financial data',
      'Remembers your profile for tailored advice',
      'Available anytime, right inside the app',
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────────────
//  LANDING PAGE
// ─────────────────────────────────────────────────────────────────────────────
class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<double>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _openFeature(int index) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => FeatureDetailPage(initialIndex: index),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0.06, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 340),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final w      = mq.size.width;
    final mobile = w < 600;

    return Scaffold(
      backgroundColor: _kBg,
      body: _GradBg(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: AnimatedBuilder(
              animation: _slide,
              builder: (_, child) => Transform.translate(
                  offset: Offset(0, _slide.value), child: child),
              child: Column(
                children: [
                  _TopNav(mobile: mobile),
                  Expanded(child: _HeroBody(mobile: mobile, w: w)),
                  _TileStrip(mobile: mobile, onSelect: _openFeature),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero body ─────────────────────────────────────────────────────────────────
class _HeroBody extends StatelessWidget {
  final bool mobile;
  final double w;
  const _HeroBody({required this.mobile, required this.w});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        // Fallback scroll only for very small devices
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: mobile ? 28 : (w < 900 ? 60 : 120)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Badge('AI-POWERED PERSONAL FINANCE'),
              SizedBox(height: mobile ? 18 : 26),
              Text(
                'Take Control of\nYour Financial Future',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:     mobile ? 28 : (w < 900 ? 42 : 54),
                  fontWeight:   FontWeight.w900,
                  color:        Colors.white,
                  height:       1.1,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: mobile ? 10 : 14),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [_kAccent, _kAccentSft, Colors.orangeAccent],
                ).createShader(r),
                child: Text(
                  'Analyse  ·  Predict  ·  Grow',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:   mobile ? 14 : 20,
                    fontWeight: FontWeight.w700,
                    color:      Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(height: mobile ? 14 : 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'Eight AI-powered tools — spending analysis, stock prediction, budget planning, and more. Tap any feature below to explore what FinBuild can do for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: mobile ? 13 : 15,
                    color:    _kWhite60,
                    height:   1.7,
                  ),
                ),
              ),
              SizedBox(height: mobile ? 28 : 36),
              Wrap(
                spacing:         14,
                runSpacing:      12,
                alignment:       WrapAlignment.center,
                children: [
                  _PrimaryBtn(
                    label: 'Get Started Free',
                    onTap: () => Navigator.pushNamed(context, '/register'),
                  ),
                  _OutlineBtn(
                    label: 'Sign In',
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature tile strip ────────────────────────────────────────────────────────
class _TileStrip extends StatelessWidget {
  final bool mobile;
  final void Function(int) onSelect;
  const _TileStrip({required this.mobile, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tileH = mobile ? 70.0 : 82.0;

    return Container(
      decoration: BoxDecoration(
        color:  _kSurface,
        border: const Border(top: BorderSide(color: _kBorder)),
        boxShadow: [BoxShadow(color: _kGlow, blurRadius: 28, spreadRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(
                top: mobile ? 10 : 13, bottom: mobile ? 7 : 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 24, height: 1, color: _kBorder),
                const SizedBox(width: 10),
                Text(
                  'TAP A FEATURE TO EXPLORE',
                  style: TextStyle(
                    color:       _kAccentSft.withOpacity(0.65),
                    fontSize:    mobile ? 8 : 10,
                    fontWeight:  FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 24, height: 1, color: _kBorder),
              ],
            ),
          ),
          SizedBox(
            height: tileH,
            child: Row(
              children: List.generate(
                kFeatures.length,
                (i) => Expanded(
                  child: _Tile(
                    index:  i,
                    mobile: mobile,
                    onTap:  () => onSelect(i),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: mobile ? 8 : 10),
        ],
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  final int  index;
  final bool mobile;
  final VoidCallback onTap;
  const _Tile({required this.index, required this.mobile, required this.onTap});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final feat  = kFeatures[widget.index];
    final icon  = feat['icon'] as IconData;
    final title = (feat['title'] as String).split(' ').first;

    return MouseRegion(
      onEnter: (_) => setState(() => _pressed = true),
      onExit:  (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve:    Curves.easeOut,
          margin:   const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _pressed ? _kAccent.withOpacity(0.2) : Colors.transparent,
            border: Border(
              right: const BorderSide(color: _kBorder, width: 1),
              top:   BorderSide(
                color: _pressed ? _kAccentSft : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _pressed ? _kAccent : _kGlow,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size:  widget.mobile ? 15 : 19,
                    color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize:   widget.mobile ? 7 : 9,
                  color:      _pressed ? Colors.white : _kWhite60,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FEATURE DETAIL PAGE
// ─────────────────────────────────────────────────────────────────────────────
class FeatureDetailPage extends StatefulWidget {
  final int initialIndex;
  const FeatureDetailPage({required this.initialIndex});

  @override
  State<FeatureDetailPage> createState() => _FeatureDetailPageState();
}

class _FeatureDetailPageState extends State<FeatureDetailPage> {
  late int            _cur;
  late PageController _pc;

  @override
  void initState() {
    super.initState();
    _cur = widget.initialIndex;
    _pc  = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _pc.dispose(); super.dispose(); }

  void _goTo(int i) {
    if (i < 0 || i >= kFeatures.length) return;
    _pc.animateToPage(i,
        duration: const Duration(milliseconds: 380),
        curve:    Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final w      = mq.size.width;
    final mobile = w < 600;

    return Scaffold(
      backgroundColor: _kBg,
      body: _GradBg(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar
              _DetailBar(
                cur:    _cur,
                mobile: mobile,
                onBack: () => Navigator.pop(context),
              ),

              // ── Pages
              Expanded(
                child: PageView.builder(
                  controller:    _pc,
                  physics:       const BouncingScrollPhysics(),
                  itemCount:     kFeatures.length,
                  onPageChanged: (i) => setState(() => _cur = i),
                  itemBuilder:   (_, i) => _FeaturePage(
                    feat:   kFeatures[i],
                    mobile: mobile,
                    w:      w,
                  ),
                ),
              ),

              // ── Dot row
              _Dots(cur: _cur, total: kFeatures.length),

              // ── Navigation footer
              _NavFooter(
                cur:     _cur,
                mobile:  mobile,
                onPrev:  () => _goTo(_cur - 1),
                onNext:  () => _goTo(_cur + 1),
                onSignUp: () => Navigator.pushNamed(context, '/register'),
                onLogin:  () => Navigator.pushNamed(context, '/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail top bar ────────────────────────────────────────────────────────────
class _DetailBar extends StatelessWidget {
  final int  cur;
  final bool mobile;
  final VoidCallback onBack;
  const _DetailBar(
      {required this.cur, required this.mobile, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: mobile ? 14 : 32, vertical: mobile ? 10 : 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kBorder))),
      child: Row(children: [
        // Back button
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:  _kSurface,
              shape:  BoxShape.circle,
              border: Border.all(color: _kBorder),
            ),
            child: Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: mobile ? 13 : 16),
          ),
        ),
        const SizedBox(width: 12),

        // Logo
        Icon(Icons.account_balance_wallet,
            color: _kAccentSft, size: mobile ? 16 : 20),
        const SizedBox(width: 6),
        Text('FinBuild',
            style: TextStyle(
                color:      Colors.white,
                fontSize:   mobile ? 15 : 18,
                fontWeight: FontWeight.w800)),

        const Spacer(),

        // Counter pill
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: mobile ? 12 : 16, vertical: mobile ? 4 : 6),
          decoration: BoxDecoration(
            color:        _kGlow,
            borderRadius: BorderRadius.circular(30),
            border:       Border.all(color: _kBorder),
          ),
          child: Text(
            '${cur + 1}  /  ${kFeatures.length}',
            style: TextStyle(
                color:      _kAccentSft,
                fontSize:   mobile ? 11 : 13,
                fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }
}

// ── Full-screen feature page ──────────────────────────────────────────────────
class _FeaturePage extends StatelessWidget {
  final Map<String, dynamic> feat;
  final bool   mobile;
  final double w;
  const _FeaturePage(
      {required this.feat, required this.mobile, required this.w});

  @override
  Widget build(BuildContext context) {
    final twoCol = w >= 700;
    final hPad   = mobile ? 24.0 : (w < 900 ? 48.0 : 100.0);

    final iconW = _FeatureIcon(
        icon: feat['icon'] as IconData, mobile: mobile);
    final textW = _FeatureText(feat: feat, mobile: mobile);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 0),
      child: twoCol
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: iconW),
                const SizedBox(width: 52),
                Expanded(flex: 7, child: textW),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconW,
                SizedBox(height: mobile ? 26 : 34),
                textW,
              ],
            ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final bool mobile;
  const _FeatureIcon({required this.icon, required this.mobile});

  @override
  Widget build(BuildContext context) {
    final sz = mobile ? 100.0 : 148.0;
    return Center(
      child: Container(
        width: sz, height: sz,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [Color(0xFF4A0010), Color(0xFF1A0005), _kBg],
            stops:  [0, 0.55, 1],
          ),
          shape:     BoxShape.circle,
          border:    Border.all(color: _kBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
                color:       _kAccent.withOpacity(0.35),
                blurRadius:  50,
                spreadRadius: 10),
          ],
        ),
        child: Icon(icon, color: _kAccentSft,
            size: mobile ? 42 : 64),
      ),
    );
  }
}

class _FeatureText extends StatelessWidget {
  final Map<String, dynamic> feat;
  final bool mobile;
  const _FeatureText({required this.feat, required this.mobile});

  @override
  Widget build(BuildContext context) {
    final pts = feat['points'] as List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize:       MainAxisSize.min,
      children: [
        // Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color:        _kGlow,
            borderRadius: BorderRadius.circular(6),
            border:       Border.all(color: _kBorder),
          ),
          child: Text(
            feat['tag'] as String,
            style: TextStyle(
              color:       _kAccentSft,
              fontSize:    mobile ? 9 : 10,
              fontWeight:  FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: mobile ? 10 : 14),

        // Title
        Text(
          feat['title'] as String,
          style: TextStyle(
            fontSize:   mobile ? 22 : 32,
            fontWeight: FontWeight.w900,
            color:      Colors.white,
            height:     1.1,
          ),
        ),
        SizedBox(height: mobile ? 5 : 7),

        // Subtitle
        Text(
          feat['subtitle'] as String,
          style: TextStyle(
            fontSize:   mobile ? 13 : 16,
            color:      _kAccentSft,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: mobile ? 18 : 24),

        Container(height: 1, color: _kBorder,
            margin: const EdgeInsets.only(bottom: 16)),

        // Bullet points
        ...pts.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7),
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: _kAccentSft, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(p,
                    style: TextStyle(
                        fontSize: mobile ? 13 : 15,
                        color:    _kWhite60,
                        height:   1.55)),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

// ── Dot indicator ─────────────────────────────────────────────────────────────
class _Dots extends StatelessWidget {
  final int cur, total;
  const _Dots({required this.cur, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == cur;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve:    Curves.easeOut,
            margin:   const EdgeInsets.symmetric(horizontal: 3),
            width:    active ? 22 : 7,
            height:   7,
            decoration: BoxDecoration(
              color:        active ? _kAccentSft : _kWhite30,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

// ── Navigation footer ─────────────────────────────────────────────────────────
class _NavFooter extends StatelessWidget {
  final int  cur;
  final bool mobile;
  final VoidCallback onPrev, onNext, onSignUp, onLogin;

  const _NavFooter({
    required this.cur,
    required this.mobile,
    required this.onPrev,
    required this.onNext,
    required this.onSignUp,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = cur == 0;
    final isLast  = cur == kFeatures.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
          mobile ? 18 : 40, 12, mobile ? 18 : 40, mobile ? 16 : 22),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _kBorder))),
      child: isLast
          // ── Final screen CTA ─────────────────────────────────────────
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "You've explored all 8 features!",
                  style: TextStyle(
                    color:    _kWhite60,
                    fontSize: mobile ? 12 : 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSignUp,
                      icon:  const Icon(
                          Icons.rocket_launch_rounded, size: 17),
                      label: Text('Get Started Free',
                          style: TextStyle(
                              fontSize:   mobile ? 13 : 15,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: mobile ? 13 : 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                        elevation:   6,
                        shadowColor: _kAccent.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: onLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _kBorder),
                      padding: EdgeInsets.symmetric(
                          horizontal: mobile ? 22 : 30,
                          vertical:   mobile ? 13 : 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text('Sign In',
                        style: TextStyle(
                            fontSize:   mobile ? 13 : 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            )
          // ── Prev / Next ──────────────────────────────────────────────
          : Row(children: [
              // Prev
              if (!isFirst)
                OutlinedButton.icon(
                  onPressed: onPrev,
                  icon:  const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text('Prev',
                      style:
                          TextStyle(fontSize: mobile ? 13 : 15)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: _kBorder),
                    padding: EdgeInsets.symmetric(
                        horizontal: mobile ? 16 : 24,
                        vertical:   mobile ? 11 : 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                )
              else
                const SizedBox(width: 8),

              const Spacer(),

              // Next feature name hint
              if (!isLast)
                Text(
                  'Next: ${kFeatures[cur + 1]['title']}',
                  style: TextStyle(
                    color:    _kWhite30,
                    fontSize: mobile ? 10 : 12,
                  ),
                ),

              const Spacer(),

              // Next
              ElevatedButton.icon(
                onPressed: onNext,
                icon:  const Icon(
                    Icons.arrow_forward_rounded, size: 16),
                label: Text('Next',
                    style: TextStyle(
                        fontSize:   mobile ? 13 : 15,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: mobile ? 20 : 30,
                      vertical:   mobile ? 11 : 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  elevation:   4,
                  shadowColor: _kAccent.withOpacity(0.4),
                ),
              ),
            ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _GradBg extends StatelessWidget {
  final Widget child;
  const _GradBg({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBg, _kBg2, Color(0xFF1A0005)],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
        ),
        child: child,
      );
}

class _TopNav extends StatelessWidget {
  final bool mobile;
  const _TopNav({required this.mobile});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: mobile ? 16 : 40, vertical: mobile ? 12 : 16),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _kBorder))),
        child: Row(children: [
          // Logo icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kAccent, _kAccentSft],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(color: _kGlow, blurRadius: 12, spreadRadius: 2)
              ],
            ),
            child: Icon(Icons.account_balance_wallet,
                color: Colors.white, size: mobile ? 17 : 21),
          ),
          const SizedBox(width: 10),
          Text('FinBuild',
              style: TextStyle(
                  fontFamily: 'Lobster',
                  fontSize:   mobile ? 20 : 26,
                  fontWeight: FontWeight.w800,
                  color:      Colors.white)),
          
        ]),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color:        _kGlow,
          borderRadius: BorderRadius.circular(30),
          border:       Border.all(color: _kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color:     _kAccentSft,
              shape:     BoxShape.circle,
              boxShadow: [BoxShadow(color: _kAccentSft, blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color:       _kAccentSft,
                  fontSize:    11,
                  fontWeight:  FontWeight.w700,
                  letterSpacing: 1.3)),
        ]),
      );
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool   small;
  final VoidCallback onTap;
  const _PrimaryBtn(
      {required this.label, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
              horizontal: small ? 16 : 32, vertical: small ? 9 : 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
          elevation:   6,
          shadowColor: _kAccent.withOpacity(0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize:   small ? 12 : 15,
                fontWeight: FontWeight.w700)),
      );
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final bool   small;
  final VoidCallback onTap;
  const _OutlineBtn(
      {required this.label, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side:  const BorderSide(color: _kBorder, width: 1.5),
          padding: EdgeInsets.symmetric(
              horizontal: small ? 16 : 32, vertical: small ? 9 : 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize:   small ? 12 : 15,
                fontWeight: FontWeight.w600)),
      );
}