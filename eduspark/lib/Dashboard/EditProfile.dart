import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Field controllers
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _favoriteSubjectController = TextEditingController();

  String? _disabilityStatus = 'No';
  bool _isDisabilitySelected = false;
  String? _disabilityType;

  // Animation controller
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDisabilityFields() {
    setState(() {
      _isDisabilitySelected = _disabilityStatus == 'Yes';
      if (_isDisabilitySelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Simulate saving data to the database or server
      Fluttertoast.showToast(
        msg: "Profile updated successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      // Here you would typically send data to your backend
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _departmentController,
                  label: 'Department',
                  hint: 'Enter your department',
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your department';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _dobController,
                  label: 'Date of Birth',
                  hint: 'Select your date of birth',
                  isDate: true,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please select your date of birth';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'Enter your address',
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _favoriteSubjectController,
                  label: 'Favorite Subject',
                  hint: 'Enter your favorite subject',
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your favorite subject';
                    }
                    return null;
                  },
                ),
                _buildDisabilityDropdown(),
                _buildDisabilityFields(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: Text('Save Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isDate = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
        validator: validator,
        onTap: isDate
            ? () async {
                FocusScope.of(context).requestFocus(FocusNode()); // Close keyboard
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  controller.text = "${pickedDate.toLocal()}".split(' ')[0]; // Format date
                }
              }
            : null,
      ),
    );
  }

  Widget _buildDisabilityDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _disabilityStatus,
        decoration: InputDecoration(
          labelText: 'Do you have a disability?',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
        items: [
          DropdownMenuItem(value: 'No', child: Text('No')),
          DropdownMenuItem(value: 'Yes', child: Text('Yes')),
        ],
        onChanged: (value) {
          setState(() {
            _disabilityStatus = value;
            _toggleDisabilityFields();
          });
        },
      ),
    );
  }

  Widget _buildDisabilityFields() {
    return SizeTransition(
      sizeFactor: _animation,
      child: Column(
        children: [
          Text(
            'If yes, please specify:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: const Text('Hearing'),
            leading: Radio<String>(
              value: 'Hearing',
              groupValue: _disabilityType,
              onChanged: (value) {
                setState(() {
                  _disabilityType = value;
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Vocal'),
            leading: Radio<String>(
              value: 'Vocal',
              groupValue: _disabilityType,
              onChanged: (value) {
                setState(() {
                  _disabilityType = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
