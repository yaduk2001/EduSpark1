import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CertificatePage extends StatefulWidget {
  final String userID;
  final String courseName;

  CertificatePage({required this.userID, required this.courseName});

  @override
  _CertificatePageState createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  String? userName;
  String? certificateLink;
  File? localFile;

  @override
  void initState() {
    super.initState();
    _fetchCertificateData();
  }

  Future<void> _fetchCertificateData() async {
    try {
      // Fetch user data to get the full name
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .get();

      // Fetch certificate data
      DocumentSnapshot certSnapshot = await FirebaseFirestore.instance
          .collection('certificate')
          .doc(widget.userID)
          .get();

      if (userSnapshot.exists) {
        var userData = userSnapshot.data() as Map<String, dynamic>;
        String fullName = userData['fullName'] ?? 'User';
        
        // Create or update certificate document
        await FirebaseFirestore.instance
            .collection('certificate')
            .doc(widget.userID)
            .set({
          'userName': fullName,
          'courseName': widget.courseName,
          'dateIssued': DateTime.now(),
        }, SetOptions(merge: true));

        setState(() {
          userName = fullName;
          certificateLink = "https://firebasestorage.googleapis.com/v0/b/eduspark-a0562.appspot.com/o/Certificate.pdf?alt=media&token=77e8b507-dcf8-4131-bad1-ab1f086743ee";
        });

        if (certificateLink != null) {
          await _loadPDF(certificateLink!);
        }
      }
    } catch (e) {
      print('Error fetching certificate data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating certificate')),
      );
    }
  }

  Future<void> _loadPDF(String pdfUrl) async {
    try {
      // Download the PDF to a local file and display it
      final response = await http.get(Uri.parse(pdfUrl));
      
      if (response.statusCode != 200) {
        print('PDF download failed with status: ${response.statusCode}');
        throw Exception('Failed to download PDF');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/certificate.pdf');
      await file.writeAsBytes(response.bodyBytes);

      // Verify file exists and has content
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('PDF file is empty or not created');
      }

      print('PDF saved to: ${file.path}');
      print('PDF file size: ${await file.length()} bytes');

      setState(() {
        localFile = file;
      });
    } catch (e) {
      print('Error loading PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading certificate: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Certificate'),
      ),
      body: localFile == null
          ? Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: localFile!.path,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: false,
              onError: (error) {
                print('PDF View Error: $error');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error displaying PDF: $error')),
                  );
                }
              },
              onPageError: (page, error) {
                print('PDF Page $page Error: $error');
              },
            ),
    );
  }
}
