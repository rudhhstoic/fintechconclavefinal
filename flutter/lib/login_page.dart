import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signup_page.dart';
import 'api_services.dart';
import 'auth_provider.dart';
import 'email_validator_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  FocusNode _usernameFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isObscure = true;
  bool _rememberMe = false;
  String _message = '';
  bool _isValidatingEmail = false;
  bool _isEmailValid = false;
  String _emailValidationMessage = '';
  Timer? _emailValidationTimer;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _emailValidationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;
    
    // Responsive calculations
    final bool isSmallDevice = size.height < 600;
    final bool isMobile = size.width < 600;
    final bool isTablet = size.width >= 600 && size.width < 900;
    
    // Adaptive sizing
    final double horizontalPadding = isMobile ? 24.0 : (isTablet ? 48.0 : size.width * 0.15);
    final double maxFormWidth = isMobile ? double.infinity : (isTablet ? 500.0 : 450.0);
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF000831),
              Color(0xFF000000),
              Color(0x4DFF5252),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: ClampingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: false,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                ),
              ),
              
              // Main Content
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      // Flexible spacer for top
                      if (!isKeyboardOpen && !isSmallDevice) 
                        Flexible(flex: 1, child: SizedBox()),
                      
                      // Logo/Brand Section
                      if (!isKeyboardOpen)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Container(
                                width: isSmallDevice ? 60 : 80,
                                height: isSmallDevice ? 60 : 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Colors.redAccent, Colors.orangeAccent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: isSmallDevice ? 30 : 40,
                                ),
                              ),
                              SizedBox(height: isSmallDevice ? 16 : 24),
                              Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: isSmallDevice ? 24 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Empowering Your Finances with AI",
                                style: TextStyle(
                                  fontSize: isSmallDevice ? 14 : 16,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      
                      SizedBox(height: isKeyboardOpen ? 20 : (isSmallDevice ? 24 : 40)),
                      
                      // Form Container
                      Container(
                        constraints: BoxConstraints(maxWidth: maxFormWidth),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 20 : 32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email Field
                                  _buildTextField(
                                    controller: _usernameController,
                                    focusNode: _usernameFocusNode,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                    onChanged: _validateEmail,
                                    suffixIcon: _isValidatingEmail
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                                          ),
                                        )
                                      : _usernameController.text.isNotEmpty
                                          ? Icon(
                                              _isEmailValid ? Icons.check_circle : Icons.error,
                                              color: _isEmailValid ? Colors.green : Colors.red,
                                            )
                                          : null,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                                    },
                                  ),

                                  if (_emailValidationMessage.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Text(
                                        _emailValidationMessage,
                                        style: TextStyle(
                                          color: _isEmailValid ? Colors.green : Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),

                                  SizedBox(height: 16),
                                  
                                  // Password Field
                                  _buildTextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscureText: _isObscure,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isObscure = !_isObscure;
                                        });
                                      },
                                    ),
                                    onFieldSubmitted: (_) => _handleLogin(),
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Remember Me & Forgot Password
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    _rememberMe = value ?? false;
                                                  });
                                                },
                                                activeColor: Colors.redAccent,
                                                side: BorderSide(color: Colors.white54),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                "Remember me",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: isSmallDevice ? 12 : 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Handle forgot password
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: isSmallDevice ? 12 : 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 24),
                                  
                                  // Login Button
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    height: isMobile ? 48 : 56,
                                    child: _isLoading
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.redAccent,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                              elevation: 5,
                                              shadowColor: Colors.redAccent.withOpacity(0.5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: isSmallDevice ? 16 : 18,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                  ),
                                  
                                  // Error Message
                                  if (_message.isNotEmpty)
                                    Container(
                                      margin: EdgeInsets.only(top: 16),
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        _message,
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: isSmallDevice ? 12 : 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Sign Up Link
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isSmallDevice ? 13 : 15,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallDevice ? 13 : 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom spacer
                      if (!isKeyboardOpen)
                        Flexible(flex: 1, child: SizedBox(height: 20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    void Function(String)? onChanged,
  }) {
    final isSmallDevice = MediaQuery.of(context).size.height < 600;
    
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Colors.white,
        fontSize: isSmallDevice ? 14 : 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white70,
          fontSize: isSmallDevice ? 13 : 15,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white54,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSmallDevice ? 12 : 16,
        ),
        errorStyle: TextStyle(
          fontSize: isSmallDevice ? 11 : 12,
        ),
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      _login();
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    // Check if email is valid before proceeding
    if (!_isEmailValid) {
      setState(() {
        _isLoading = false;
        _message = 'Please enter a valid email address';
      });
      return;
    }

    try {
      final result = await _apiService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _message = result['message'] ?? '';
      });

      if (result['success'] == true) {
        int serialId = result['serial_id'] ?? 0;
        String name = result['name'] ?? '';
        
        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).setSerialId(serialId, name);
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _validateEmail(String email) async {
    // Cancel any previous validation timer
    _emailValidationTimer?.cancel();

    // Clear previous validation state
    setState(() {
      _isValidatingEmail = false;
      _isEmailValid = false;
      _emailValidationMessage = '';
    });

    // Basic email format check first
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() {
        _emailValidationMessage = 'Please enter a valid email format';
      });
      return;
    }

    // Start timer to validate after user stops typing (1 second delay)
    _emailValidationTimer = Timer(Duration(seconds: 3), () async {
      setState(() {
        _isValidatingEmail = true;
      });

      final result = await EmailValidatorService.validateEmail(email);

      setState(() {
        _isValidatingEmail = false;
        _isEmailValid = result['isValid'];
        _emailValidationMessage = result['message'];
      });
    });
  }
}
