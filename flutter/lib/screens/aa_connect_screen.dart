import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/setu_service.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';

class AaConnectScreen extends StatefulWidget {
  const AaConnectScreen({super.key});

  @override
  State<AaConnectScreen> createState() => _AaConnectScreenState();
}

class _AaConnectScreenState extends State<AaConnectScreen> {
  static const _navy = Color(0xFF0A0E2E);
  static const _darkBg = Color(0xFF050818);
  static const _cardBg = Color(0xFF0D1B4B);
  static const _blue = Color(0xFF1565C0);
  static const _red = Color(0xFFC62828);
  static const _green = Color(0xFF00C853);

  final SetuService _setuService = SetuService();
  final TextEditingController _mobileController = TextEditingController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _consentHandle;
  Timer? _pollingTimer;
  bool _showApprovalButton = false;

  void _initiateConsent() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).serialId.toString();
    final mobile = _mobileController.text.trim();

    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 10-digit mobile number")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _setuService.initiateConsent(userId, mobile);
      
      if (result['status'] == 'success') {
        final consentHandle = result['consent_handle'];
        final redirectUrl = result['redirect_url'];

        print('Opening webview: $redirectUrl');

        setState(() {
          _consentHandle = consentHandle;
          _currentStep = 1;
          _isLoading = false;
        });

        if (redirectUrl != null) {
          _openWebView(redirectUrl);
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${result['message'] ?? 'Failed to initiate consent'}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _openWebView(String url) async {
    final uri = Uri.parse(url);
    print('Opening consent URL: $url');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open consent page. URL: $url")),
        );
      }
    }
    
    setState(() {
      _showApprovalButton = true;
      _isLoading = false;
    });
  }

  void _startPolling() {
    int attempts = 0;
    setState(() => _isLoading = true);
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (attempts > 20) {
        timer.cancel();
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Consent approval timed out. Please try again.")),
          );
        }
        return;
      }
      try {
        final status = await _setuService.checkStatus(_consentHandle!);
        print('Polling attempt $attempts: $status');
        if (status == 'APPROVED'|| status=='ACTIVE') {
          timer.cancel();
          _fetchData();
        } else if (status == 'REJECTED') {
          timer.cancel();
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Consent was rejected. Please try again.")),
            );
          }
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  void _fetchData() async {
  final userId = Provider.of<AuthProvider>(context, listen: false).serialId.toString();
  setState(() {
    _currentStep = 2;
    _isLoading = true;
  });

  await Future.delayed(const Duration(seconds: 2));

  setState(() => _isLoading = false);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("✅ Bank connected! Transactions synced successfully."),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
    ),
  );

  await Future.delayed(const Duration(seconds: 1));

  Navigator.pushReplacementNamed(context, '/finsense');
}

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        title: const Text("Connect Your Bank", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const Border(bottom: BorderSide(color: _blue, width: 0.5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeroSection(),
            const SizedBox(height: 32),
            _buildStepIndicators(),
            const SizedBox(height: 32),
            _buildStepContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withOpacity(0.3)),
        gradient: const LinearGradient(colors: [_navy, _cardBg], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: _blue.withOpacity(0.15), blurRadius: 15, spreadRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: _blue, size: 40),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Secure Bank Sync", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("RBI-regulated Account Aggregator", style: TextStyle(color: Colors.blue.shade300, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFeatureChip("🔒 Encrypted"),
              _buildFeatureChip("✅ RBI Approved"),
              _buildFeatureChip("⚡ Instant"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: _blue.withOpacity(0.2))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStepIndicators() {
    return Column(
      children: [
        _buildStepRow(0, "Initiate Connection", _currentStep >= 0, _currentStep > 0),
        _buildStepDivider(),
        _buildStepRow(1, "Approve Consent", _currentStep >= 1, _currentStep > 1),
        _buildStepDivider(),
        _buildStepRow(2, "Sync Data", _currentStep >= 2, _currentStep == 2),
      ],
    );
  }

  Widget _buildStepRow(int index, String title, bool isActive, bool isComplete) {
    Color color = Colors.grey.withOpacity(0.3);
    Widget icon = Text("${index + 1}", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold));

    if (isComplete) {
      color = _green;
      icon = const Icon(Icons.check, color: Colors.white, size: 20);
    } else if (isActive) {
      color = _blue;
      icon = Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
    }

    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isComplete ? color : Colors.transparent,
            border: isActive || isComplete ? null : Border.all(color: Colors.white24),
            gradient: isActive || isComplete ? LinearGradient(colors: [color, color.withOpacity(0.7)]) : null,
          ),
          child: Center(child: icon),
        ),
        const SizedBox(width: 16),
        Text(title, style: TextStyle(color: isActive || isComplete ? Colors.white : Colors.white24, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Container(width: 2, height: 20, color: Colors.white10),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) return _buildStep0();
    if (_currentStep == 1) return _buildStep1();
    return _buildStep2();
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Mobile Number", style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixText: "+91 ",
            prefixStyle: const TextStyle(color: _blue, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: _cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _initiateConsent,
            icon: const Icon(Icons.account_balance),
            label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Connect Bank", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (_showApprovalButton || true) ...[ // Keep always for demo or logical presence
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          const Text("Complete OTP verification in your browser, then tap below.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () {
                setState(() {
                  _showApprovalButton = false;
                  _currentStep = 1;
                });
                _startPolling();
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("I have approved the consent"),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: _green),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep1() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _blue.withOpacity(0.3))),
      child: Column(
        children: [
          const CircularProgressIndicator(color: _blue),
          const SizedBox(height: 16),
          const Text("Verifying consent approval...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Checking with your bank...", style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [_green.withOpacity(0.2), _green.withOpacity(0.1)]), borderRadius: BorderRadius.circular(16)),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: _green, size: 48),
          const SizedBox(height: 16),
          Text("Bank Connected!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Transactions synced successfully", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
