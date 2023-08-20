import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String donorId;

  const ReportDetailsScreen({Key? key, required this.donorId})
      : super(key: key);

  @override
  _ReportDetailsScreenState createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  String _issue = '';
  String _description = '';
  String _reporter = '';
  bool _isBlocked = false; // Track if the user is blocked

  @override
  void initState() {
    super.initState();
    _fetchReportDetails();
    _checkIfBlocked(); // Check if the user is blocked
  }

  Future<void> _fetchReportDetails() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('reports')
              .where('donorID', isEqualTo: widget.donorId)
              .get();

      final List<Map<String, dynamic>> reports =
          snapshot.docs.map((doc) => doc.data()).toList();

      if (reports.isNotEmpty) {
        final report = reports[0];
        setState(() {
          _issue = report['issue'] ?? '';
          _description = report['description'] ?? '';
        });
        FirebaseFirestore.instance
            .collection('users')
            .doc(report['reporterID'])
            .get()
            .then((doc) {
          setState(() {
            _reporter = doc.data()!['name'];
          });
        });
      }
    } catch (e) {
      print('Error fetching report details: $e');
    }
  }

  Future<void> _checkIfBlocked() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('blocked')
              .where('donorId', isEqualTo: widget.donorId)
              .get();

      setState(() {
        _isBlocked = snapshot.docs.isNotEmpty;
      });
    } catch (e) {
      print('Error checking if donor is blocked: $e');
    }
  }

  // Function to block or unblock the donor
  Future<void> _toggleBlockDonor() async {
    try {
      if (_isBlocked) {
        // User is already blocked, so unblock them
        await FirebaseFirestore.instance
            .collection('blocked')
            .where('donorId', isEqualTo: widget.donorId)
            .get()
            .then((snapshot) {
          snapshot.docs.forEach((doc) {
            doc.reference.delete();
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User unblocked successfully')),
        );
      } else {
        // User is not blocked, so block them
        await FirebaseFirestore.instance.collection('blocked').add({
          'donorId': widget.donorId,
          'blocked': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User blocked successfully')),
        );
      }

      setState(() {
        _isBlocked = !_isBlocked; // Toggle the blocked state
      });

      // Navigate back to the previous screen
      Navigator.of(context).pop();
    } catch (e) {
      print('Error blocking/unblocking donor: $e');
      // Show an error message or perform error handling
    }
  }

  // Function to delete the report
  Future<void> _deleteReport() async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .where('donorID', isEqualTo: widget.donorId)
          .get()
          .then((snapshot) {
        snapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report deleted successfully')),
      );

      Navigator.of(context).pop();

      // Refresh the reported users list
    } catch (e) {
      print('Error deleting report: $e');
      // Show an error message or perform error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: Text(
          'Report Details',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issue:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_issue),
            SizedBox(height: 16.0),
            Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_description),
            SizedBox(height: 16.0),
            Text(
              'Reporter:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_reporter),
            SizedBox(height: 16.0),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _toggleBlockDonor,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: _isBlocked ? Colors.green : Colors.red,
                    side: BorderSide(
                      color: _isBlocked ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    _isBlocked ? 'Unblock' : 'Block',
                    style: TextStyle(
                      color: _isBlocked ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: _deleteReport,
                  child: Text("Delete Report"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
