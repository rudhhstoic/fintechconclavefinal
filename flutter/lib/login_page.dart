import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signup_page.dart';
import 'api_services.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  FocusNode _usernameFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isObscure = true;
  String _message = '';

  @override
  void dispose() {
    // Dispose the focus nodes when the screen is disposed
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/supbg2.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7), // Dark overlay for readability
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // Logo at the top right
          Positioned(
            top: 25,
            right: 25,
            child: Image.asset(
              'assets/logo2.jpg',
              height: 50,
            ),
          ),
          // Centered Credential Box
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Texts
                    Text(
                      "Welcome Back ",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Empowering Your Finances with Smart AI",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 199, 58, 58),
                        fontSize: 26,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    // Email Field
                    Focus(
                      onFocusChange: (hasFocus) {
                        setState(() {});
                      },
                      child: TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        decoration: InputDecoration(
                          labelText: _usernameFocusNode.hasFocus ||
                                  _usernameController.text.isNotEmpty
                              ? ''
                              : 'Email',
                          filled: true,
                          fillColor: Colors.white24,
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (text) {
                          setState(() {}); // Update the UI when text changes
                        },
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Password Field
                    Focus(
                      onFocusChange: (hasFocus) {
                        setState(() {});
                      },
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        focusNode: _passwordFocusNode,
                        decoration: InputDecoration(
                          labelText: _passwordFocusNode.hasFocus ||
                                  _passwordController.text.isNotEmpty
                              ? ''
                              : 'Password',
                          filled: true,
                          fillColor: Colors.white24,
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                        ),
                        onChanged: (text) {
                          setState(() {}); // Update the UI when text changes
                        },
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Remember Me and Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: true,
                              onChanged: (bool? value) {},
                              activeColor: Colors.redAccent,
                            ),
                            Text("Remember me",
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("Forgot Password?",
                              style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Login Button
                    _isLoading
                        ? Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Sign In',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
                          ),
                    SizedBox(height: 15),

                    // Sign-Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don’t have an account? ",
                            style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegisterScreen()),
                            );
                          },
                          child: Text("Sign Up",
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    if (_message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _message,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _message = result['message'];
    });

    if (result['success']) {
      int serialId = result['serial_id'];
      Provider.of<AuthProvider>(context, listen: false).setSerialId(serialId);
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}
