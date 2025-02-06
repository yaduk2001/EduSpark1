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
    // Fetch certificate data from Firestore
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('certificate')
        .doc(widget.userID)
        .get();

    if (snapshot.exists) {
      var certificateData = snapshot.data() as Map<String, dynamic>;
      setState(() {
        certificateLink = "https://firebasestorage.googleapis.com/v0/b/eduspark-a0562.appspot.com/o/Certificate.pdf?alt=media&token=77e8b507-dcf8-4131-bad1-ab1f086743ee"; // Example PDF link
        userName = certificateData['userName'] ?? 'User';
      });
      await _loadPDF(certificateLink!);  // Load the PDF directly for viewing
    }
  }

  Future<void> _loadPDF(String pdfUrl) async {
    // Download the PDF to a local file and display it
    final response = await http.get(Uri.parse(pdfUrl));
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/certificate.pdf');
    await file.writeAsBytes(response.bodyBytes);

    setState(() {
      localFile = file;
    });
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading PDF')),
                );
              },
            ),
    );
  }
}
