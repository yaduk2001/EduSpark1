import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math';
import 'package:country_code_picker/country_code_picker.dart';

class StudentRegistrationPage extends StatefulWidget {
  @override
  _StudentRegistrationPageState createState() =>
      _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends State<StudentRegistrationPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordValid = false;
  bool _showPasswordCriteria = false; // To control the password criteria visibility
  late AnimationController _controller;
  late Animation<double> _animation;

  // FocusNode for the password field
  final FocusNode _passwordFocusNode = FocusNode();

  // Password validation regex pattern
  final String passwordPattern =
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%\^&\*]).{8,}$';

  String _countryCode = '+1';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordListener);

    // Animation setup
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Add listener to FocusNode
    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordCriteria = _passwordFocusNode.hasFocus;
      });
    });
    
    _controller.forward();
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordListener);
    _controller.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordFocusNode.dispose(); // Dispose of the FocusNode
    super.dispose();
  }

  void _validatePasswordListener() {
    setState(() {
      _isPasswordValid = _validatePassword(_passwordController.text);
    });
  }

  // Function to generate random Student ID
  Future<String> _generateUniqueStudentID() async {
    String studentID = '';
    bool isUnique = false;

    while (!isUnique) {
      studentID = 'S' + Random().nextInt(999999).toString().padLeft(6, '0');

      // Check Firestore to ensure the Student ID is unique
      QuerySnapshot result = await _firestore
          .collection('students')
          .where('studentID', isEqualTo: studentID)
          .get();

      if (result.docs.isEmpty) {
        isUnique = true;
      }
    }

    return studentID;
  }

  // Function to send email verification
  Future<void> _sendEmailVerification(User user) async {
    await user.sendEmailVerification();
  }

  // Password validation function
  bool _validatePassword(String password) {
    RegExp regExp = RegExp(passwordPattern);
    return regExp.hasMatch(password);
  }

  // Registration function
  Future<void> _registerStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user with Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          // Generate unique Student ID
          String studentID = await _generateUniqueStudentID();

          // Store user data in Firestore (users collection)
          await _firestore.collection('users').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _countryCode + _phoneController.text.trim(),
            'role': 'student',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Store student-specific data in Firestore (students collection)
          await _firestore.collection('students').doc(user.uid).set({
            'studentID': studentID,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _countryCode + _phoneController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Send email verification
          await _sendEmailVerification(user);

          // Show success toast
          Fluttertoast.showToast(
            msg: "Registration successful! Please verify your email.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Redirect to login page after successful registration
          Navigator.of(context).pop(); // Navigate back to login
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An error occurred. Please try again.';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already in use.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        }
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "An unexpected error occurred.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Registration'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _animation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Logo or Header
                      Hero(
                        tag: 'logo',
                        child: Icon(
                          Icons.school,
                          size: 100,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        'Register to Edu Spark',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigoAccent,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),

                      // Full Name
                      _buildInputField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Email
                      _buildInputField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
// Phone Number
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.circular(5),
  ),
  child: Row(
    children: [
      CountryCodePicker(
        onChanged: (countryCode) {
          setState(() {
            _countryCode = countryCode.dialCode!;
          });
        },
        initialSelection: 'US',
        favorite: ['+1', 'US','+91', 'IN'],
        showCountryOnly: false,
        showOnlyCountryWhenClosed: false,
        flagWidth: 20,
        padding: EdgeInsets.zero,
        boxDecoration: BoxDecoration(
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      SizedBox(width: 10),
      Expanded(
        child: _buildInputField(
          controller: _phoneController,
          label: '',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your phone number';
            }
            if (!RegExp(r'^\+?\d{10,15}$')
                .hasMatch(value.trim())) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ),
    ],
  ),
),
                      SizedBox(height: 20),

                      // Password
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        obscureText: true,
                        focusNode: _passwordFocusNode,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!_isPasswordValid) {
                            return 'Password must be at least 8 characters long, contain an uppercase letter, a number, and a special character.';
                          }
                          return null;
                        },
                      ),

                      // Show password criteria when focused
                      if (_showPasswordCriteria)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Password must contain at least: \n- 8 characters\n- 1 uppercase letter\n- 1 number\n- 1 special character',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      SizedBox(height: 30),

                      // Register Button
                      ElevatedButton(
                        onPressed: _registerStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          padding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 30),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Register'),
                      ),
                      SizedBox(height: 20),

                      // Back to Login
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Go back to login
                        },
                        child: Text(
                          'Already have an account? Login',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    FocusNode? focusNode,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}