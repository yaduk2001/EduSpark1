import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAssignmentPage extends StatefulWidget {
  @override
  _AddAssignmentPageState createState() => _AddAssignmentPageState();
}

class _AddAssignmentPageState extends State<AddAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  bool _isLoading = false;
  String _assignmentType = 'mcq'; // Default type
  bool _isForAllStudents = true;
  List<String> _selectedStudents = [];
  bool _acceptSubmissions = true;
  List<Map<String, dynamic>> _mcqQuestions = [];

  // Define assignment types
  final List<Map<String, String>> _assignmentTypes = [
    {'value': 'mcq', 'label': 'Multiple Choice Questions'},
    {'value': 'document', 'label': 'Document Upload'},
    {'value': 'question', 'label': 'Written Answer'},
  ];

  // Add these constants for consistent styling
  final double _borderRadius = 12.0;
  final Color _primaryColor = Color(0xFF1976D2);
  final Color _backgroundColor = Color(0xFFF5F5F5);
  final Color _cardColor = Colors.white;
  final EdgeInsets _contentPadding = EdgeInsets.all(20.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Add Assignment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
      ),
      body: Padding(
        padding: _contentPadding,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                child: Padding(
                  padding: _contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assignment Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Assignment Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_borderRadius),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: Icon(Icons.title, color: _primaryColor),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_borderRadius),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: Icon(Icons.description, color: _primaryColor),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                child: Padding(
                  padding: _contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assignment Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: 20),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: _primaryColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _dueDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(_borderRadius),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: _primaryColor),
                              SizedBox(width: 16),
                              Text(
                                _dueDate == null
                                    ? 'Select Due Date'
                                    : 'Due Date: ${_dueDate!.toString().split(' ')[0]}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Assignment Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_borderRadius),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: Icon(Icons.assignment, color: _primaryColor),
                        ),
                        value: _assignmentType,
                        items: _assignmentTypes.map((type) {
                          return DropdownMenuItem(
                            value: type['value'],
                            child: Text(type['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _assignmentType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (_assignmentType == 'mcq') ...[
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  child: Padding(
                    padding: _contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Multiple Choice Questions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _mcqQuestions.add(_createEmptyQuestion());
                                });
                              },
                              icon: Icon(Icons.add_circle, color: _primaryColor),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        ..._mcqQuestions.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> question = entry.value;
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(_borderRadius),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Question ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _mcqQuestions.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  initialValue: question['question'],
                                  decoration: InputDecoration(
                                    hintText: 'Enter your question',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(_borderRadius),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _mcqQuestions[index]['question'] = value;
                                    });
                                  },
                                ),
                                SizedBox(height: 16),
                                ...List.generate(4, (optionIndex) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Radio<int>(
                                          value: optionIndex,
                                          groupValue: question['correctOption'],
                                          activeColor: _primaryColor,
                                          onChanged: (value) {
                                            setState(() {
                                              _mcqQuestions[index]['correctOption'] = value;
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: question['options'][optionIndex],
                                            decoration: InputDecoration(
                                              hintText: 'Option ${optionIndex + 1}',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(_borderRadius),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                _mcqQuestions[index]['options'][optionIndex] = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
                child: Padding(
                  padding: _contentPadding,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Assign to all students'),
                        subtitle: Text('Toggle to assign to specific students'),
                        value: _isForAllStudents,
                        activeColor: _primaryColor,
                        onChanged: (bool value) {
                          setState(() {
                            _isForAllStudents = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: Text('Accept Submissions'),
                        subtitle: Text('Allow students to submit answers'),
                        value: _acceptSubmissions,
                        activeColor: _primaryColor,
                        onChanged: (bool value) {
                          setState(() {
                            _acceptSubmissions = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAssignment,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Create Assignment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAssignment() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a due date')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection('assignments').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'dueDate': _dueDate,
          'teacherId': user?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'assignmentType': _assignmentType,
          'isForAllStudents': _isForAllStudents,
          'selectedStudents': _selectedStudents,
          'acceptSubmissions': _acceptSubmissions,
          'status': 'active',
          'mcqQuestions': _assignmentType == 'mcq' ? _mcqQuestions : [],
        });

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating assignment: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _createEmptyQuestion() {
    return {
      'question': '',
      'options': ['', '', '', ''],
      'correctOption': 0,
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 