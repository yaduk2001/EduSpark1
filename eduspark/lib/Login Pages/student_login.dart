import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduspark/Courses/CourseSelectionPage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Dashboard/StudentDashboardPage.dart';
import '../Registration Pages/StudentRegistrationPage.dart';
import 'otp_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:country_code_picker/country_code_picker.dart'; 

class StudentLoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<StudentLoginPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailOrIDController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Background animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _emailOrIDController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent keyboard from resizing the layout
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Animation
          AnimatedBackground(),
          // Foreground content
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : FadeTransition(
                  opacity: _animation,
                  child: Container(
                    padding: const EdgeInsets.all(30.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Logo
                          Hero(
                            tag: 'logo',
                            child: Icon(
                              Icons.school,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 30),
                          Text(
                            'Login to Edu Spark',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30),

                          // Email or Student ID TextField
                          _buildTextField(
                            controller: _emailOrIDController,
                            label: 'Email or Student ID',
                            icon: Icons.person,
                            isEmail: true, // Set to true if expecting email input
                          ),
                          SizedBox(height: 20),

                          // Password TextField
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock,
                            obscureText: true,
                            isEmail: false,
                          ),
                          SizedBox(height: 20),

                          // Login Button (Email/Password)
                          _buildAnimatedButton(
                            text: 'Login',
                            onPressed: _loginWithEmail,
                          ),
                          SizedBox(height: 20),

                          // Google Sign-In Button
                          _buildAnimatedButton(
                            text: 'Sign in with Google',
                            icon: FaIcon(FontAwesomeIcons.google, color: Colors.white),
                            onPressed: _loginWithGoogle,
                            backgroundColor: Colors.redAccent,
                          ),
                          SizedBox(height: 20),

                          // OTP Login Options
                          TextButton(
                            onPressed: () => _showOTPOptions(context),
                            child: Text(
                              'Login with OTP',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Register Button
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => StudentRegistrationPage()),
                            ),
                            child: Text(
                              'Don\'t have an account? Register',
                              style: TextStyle(fontSize: 16, color: Colors.white),
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

  // TextField Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    required bool isEmail,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
      ),
      style: TextStyle(color: Colors.white),
    );
  }

  // Animated Button Builder
  Widget _buildAnimatedButton({
    required String text,
    Widget? icon,
    required Function() onPressed,
    Color backgroundColor = Colors.blueAccent,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeIn,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          backgroundColor: backgroundColor,
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon,
              SizedBox(width: 10),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Email/Password Login Function
  Future<void> _loginWithEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String emailInput = _emailOrIDController.text.trim().toLowerCase();
      String passwordInput = _passwordController.text;

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailInput,
        password: passwordInput,
      );

      User? user = userCredential.user;

      if (user != null) {
        print("Logged in user: ${user.email}");

        bool studentExists = await _checkStudentInDatabase(user.email);

        if (studentExists) {
          if (user.emailVerified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StudentDashboardPage()),
            );
          } else {
            Fluttertoast.showToast(
              msg: "Please verify your email before logging in.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.orange,
              textColor: Colors.white,
            );
            bool resend = await _showResendVerificationDialog();
            if (resend) {
              await user.sendEmailVerification();
              Fluttertoast.showToast(
                msg: "Verification email resent. Please check your inbox.",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.green,
                textColor: Colors.white,
              );
            }
          }
        } else {
          Fluttertoast.showToast(
            msg: "Student data not found. Please register.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An unexpected error occurred.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print("Error during email login: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Google Sign-In Function
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String? email = user.email?.trim().toLowerCase();
        print("Google Sign-In user: $email");

        bool studentExists = await _checkStudentInDatabase(email);

        if (studentExists) {
          if (user.emailVerified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StudentDashboardPage()),
            );
          } else {
            Fluttertoast.showToast(
              msg: "Please verify your email before logging in.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.orange,
              textColor: Colors.white,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: "Student data not found. Please register.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to sign in with Google.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print("Error during Google sign-in: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navigate to OTPOptionsSheet via Modal Bottom Sheet
  void _showOTPOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to adjust height based on content
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return OTPOptionsSheet();
      },
    );
  }

  // Check if Student Exists in Firestore
  Future<bool> _checkStudentInDatabase(String? email) async {
    if (email == null || email.isEmpty) return false;

    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: email)
          .get();

      print("Firestore query for email '$email' returned ${querySnapshot.docs.length} documents.");

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking student in database: $e");
      return false;
    }
  }

  // Resend Verification Email Dialog
  Future<bool> _showResendVerificationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Resend Verification Email"),
              content: Text("Do you want to resend the verification email?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("No"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Yes"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Handle FirebaseAuth Errors
  void _handleAuthError(FirebaseAuthException e) {
    String message = "An error occurred. Please try again.";
    if (e.code == 'user-not-found') {
      message = "No user found for that email.";
    } else if (e.code == 'wrong-password') {
      message = "Incorrect password.";
    } else if (e.code == 'invalid-email') {
      message = "The email address is not valid.";
    } else if (e.code == 'email-already-in-use') {
      message = "The email is already in use by another account.";
    } else if (e.code == 'weak-password') {
      message = "The password is too weak.";
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    print("FirebaseAuthException: ${e.code} - ${e.message}");
  }
}

// Animated Background Widget
class AnimatedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}



// otp_options_sheet.dart


class OTPOptionsSheet extends StatefulWidget {
  @override
  _OTPOptionsSheetState createState() => _OTPOptionsSheetState();
}

class _OTPOptionsSheetState extends State<OTPOptionsSheet>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Form Keys
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();

  // Variables
  String _selectedCountryCode = '+1'; // Default country code
  bool _isOTPSent = false;
  String _verificationId = '';
  bool _isLoading = false;

  // Animation Controllers
  late AnimationController _separatorColorController;
  late Animation<Color?> _separatorColorAnimation;

  final List<Color> _separatorColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controller for separator line
    _separatorColorController = AnimationController(
      duration: Duration(seconds: _separatorColors.length * 2),
      vsync: this,
    )..repeat();
    _separatorColorAnimation = TweenSequence<Color?>([
      for (int i = 0; i < _separatorColors.length; i++)
        TweenSequenceItem(
          tween: ColorTween(
              begin: _separatorColors[i],
              end: _separatorColors[(i + 1) % _separatorColors.length]),
          weight: 1,
        ),
    ]).animate(_separatorColorController);
  }

  @override
  void dispose() {
    _separatorColorController.dispose();
    _phoneNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Function to request OTP
  Future<void> _requestOTP() async {
    if (_phoneFormKey.currentState?.validate() ?? false) {
      String phoneNumber =
          '$_selectedCountryCode${_phoneNumberController.text.trim()}';

      setState(() {
        _isLoading = true;
      });

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatic verification (Android only)
          await FirebaseAuth.instance.signInWithCredential(credential);
          setState(() {
            _isLoading = false;
          });
          Fluttertoast.showToast(
            msg: "Phone number automatically verified and user signed in",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          Navigator.of(context).pop(); // Close the dialog
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          Fluttertoast.showToast(
            msg: "Verification failed: ${e.message}",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isOTPSent = true;
            _verificationId = verificationId;
            _isLoading = false;
          });
          Fluttertoast.showToast(
            msg: "OTP has been sent to your phone.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-resolution timed out...
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
      );
    } else {
      Fluttertoast.showToast(
        msg: "Please enter a valid phone number.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Function to verify OTP
  Future<void> _verifyOTP() async {
    if (_otpFormKey.currentState?.validate() ?? false) {
      String smsCode = _otpController.text.trim();

      setState(() {
        _isLoading = true;
      });

      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: smsCode,
        );

        // Sign in the user with the credential
        await FirebaseAuth.instance.signInWithCredential(credential);

        setState(() {
          _isLoading = false;
        });

        Fluttertoast.showToast(
          msg: "Phone number verified",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Optionally, navigate to another page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => CourseSelectionPage()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: "Invalid OTP. Please try again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Please enter the OTP.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Widget for Phone Number Input
  Widget _buildPhoneNumberInput() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        children: [
          // Combined Country Code Picker and Phone Number Field
          TextFormField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '123 456 7891',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: CountryCodePicker(
                  onChanged: (countryCode) {
                    setState(() {
                      _selectedCountryCode = countryCode.dialCode ?? '+1';
                    });
                  },
                  initialSelection: 'US',
                  favorite: ['+1', 'US', '+91', 'IN'],
                  showCountryOnly: false,
                  alignLeft: false,
                  textStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              // Add more validation if needed
              return null;
            },
          ),
          SizedBox(height: 20),

          // Request OTP Button
          ElevatedButton(
            onPressed: _requestOTP,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Request OTP',
              style: GoogleFonts.raleway(
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for OTP Input
  Widget _buildOTPInput() {
    return Form(
      key: _otpFormKey,
      child: Column(
        children: [
          // OTP Input Field
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter OTP',
              hintText: '6-digit OTP',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'OTP is required';
              }
              if (value.trim().length != 6) {
                return 'Enter a 6-digit OTP';
              }
              return null;
            },
          ),
          SizedBox(height: 20),

          // Submit Button
          ElevatedButton(
            onPressed: _verifyOTP,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Submit',
              style: GoogleFonts.raleway(
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Animated Separator Line
  Widget _buildAnimatedSeparator() {
    return AnimatedBuilder(
      animation: _separatorColorAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 2,
          color: _separatorColorAnimation.value ?? Colors.transparent,
        );
      },
    );
  }

  // Main Build Method
  @override
  Widget build(BuildContext context) {
    // Determine the height based on screen size for responsiveness
    double screenHeight = MediaQuery.of(context).size.height;
    double panelHeight =
        _isOTPSent ? screenHeight * 0.45 : screenHeight * 0.35;

    return Dialog(
      backgroundColor: Colors.transparent, // Make the background transparent
      insetPadding: EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            height: panelHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95), // Slightly more opaque
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OTP Authentication',
                  style: GoogleFonts.raleway(
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // Phone Number Input or OTP Input
                _isOTPSent ? _buildOTPInput() : _buildPhoneNumberInput(),

                SizedBox(height: 20),

                // Animated Separator Line
                _buildAnimatedSeparator(),

                SizedBox(height: 20),

                // Loading Indicator
                _isLoading
                    ? CircularProgressIndicator()
                    : SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

