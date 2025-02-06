import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../Dashboard/StudentDashboardPage.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isOTPRequested = false;
  String? _verificationId;

  Future<void> _sendOTP() async {
    String phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter your phone number.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        // Navigate to dashboard if OTP is auto-retrieved
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentDashboardPage()),
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        Fluttertoast.showToast(
          msg: e.message ?? "Failed to verify phone number.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isOTPRequested = true;
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _verifyOTP() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );

      await _auth.signInWithCredential(credential);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StudentDashboardPage()),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Invalid OTP. Please try again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                Icon(Icons.lock, size: 100, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  _isOTPRequested ? 'Enter OTP' : 'Enter Phone Number',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _isOTPRequested ? _otpController : _phoneController,
                  decoration: InputDecoration(
                    labelText: _isOTPRequested ? 'Enter OTP' : 'Enter Phone Number',
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isOTPRequested ? _verifyOTP : _sendOTP,
                  child: Text(_isOTPRequested ? 'Verify OTP' : 'Send OTP'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.8),
            Colors.deepPurple.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
