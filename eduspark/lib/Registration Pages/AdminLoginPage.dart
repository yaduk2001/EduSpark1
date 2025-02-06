// AdminLoginPage.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Admin/AdminDashboard.dart';
 // Import your Admin Dashboard page
import 'AdminRegistrationPage.dart'; // Import your Admin Registration page

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  String email = '';
  String password = '';

  // Animation controllers
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize Animation Controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Define Animations
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show a loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Hide the loading indicator
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful!')),
        );

        // Navigate to the Admin Dashboard after successful login
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => AdminDashboardPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.ease;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      } catch (e) {
        // Hide the loading indicator
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${_getFirebaseErrorMessage(e)}')),
        );
      }
    }
  }

  String _getFirebaseErrorMessage(Object e) {
    // Customize error messages based on FirebaseAuthException
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user has been disabled.';
        case 'user-not-found':
          return 'No user found for this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        default:
          return 'An undefined error occurred.';
      }
    }
    return e.toString();
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AdminRegistrationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(0.0, 1.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Animated Gradient Background
      body: AnimatedContainer(
        duration: Duration(seconds: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                FadeTransition(
                  opacity: _logoAnimation,
                  child: ScaleTransition(
                    scale: _logoAnimation,
                    child: Column(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 100,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Admin Login',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                // Animated Form
                FadeTransition(
                  opacity: _formAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(_formAnimation),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email),
                              labelText: 'Email Address',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) => email = value,
                            validator: (value) {
                              if (value == null || value.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          // Password Field
                          TextFormField(
                            obscureText: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock),
                              labelText: 'Password',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) => password = value,
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return 'Password must be at least 8 characters long.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),
                          // Login Button with Animation
                          AnimatedButton(
                            onPressed: _loginAdmin,
                            text: 'Login',
                          ),
                          SizedBox(height: 16),
                          // Navigate to Register
                          GestureDetector(
                            onTap: _navigateToRegister,
                            child: Text(
                              'Don’t have an account? Register Here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Animated Button Widget
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const AnimatedButton({required this.onPressed, required this.text});

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _btnController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _btnController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _btnController.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _btnController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.4),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 4), // changes position of shadow
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
