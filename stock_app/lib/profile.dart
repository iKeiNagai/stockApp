import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;

  List<Map<String, dynamic>> _savedArticles = [];
  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
    _loadSavedArticles();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _firstNameController.text = userDoc['firstName'] ?? '';
          _lastNameController.text = userDoc['lastName'] ?? '';
        });
      }
    }
  }

  Future<void> _loadSavedArticles() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('savedArticles')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _savedArticles = snapshot.docs.map((doc) => doc.data()).toList();
      });
    }
  }


  Future<void> _updateUserData(String field, String newValue) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          field: newValue,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showEditDialog(String field, TextEditingController controller) {
    TextEditingController _tempController = TextEditingController(text: controller.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${field == 'firstName' ? 'First Name' : 'Last Name'}'),
          content: TextField(
            controller: _tempController,
            decoration: InputDecoration(
              labelText: field == 'firstName' ? 'First Name' : 'Last Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  controller.text = _tempController.text;
                });
                _updateUserData(field, _tempController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.of(context).pop(); 
  }

  void _copyToClipboard(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    enabled: false,
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _showEditDialog('firstName', _firstNameController),
                  child: const Text('Edit'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    enabled: false,
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _showEditDialog('lastName', _lastNameController),
                  child: const Text('Edit'),
                ),
              ],
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              enabled: false,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            const Text('Saved Articles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: _savedArticles.isEmpty
                  ? const Center(child: Text('No saved articles'))
                  : ListView.builder(
                      itemCount: _savedArticles.length,
                      itemBuilder: (context, index) {
                        final article = _savedArticles[index];
                        final url = article['url'] ?? 'No URL';
                        return ListTile(
                          title: Text(article['title'] ?? 'No Title'),
                          subtitle: Text(article['pubDate'] ?? 'Unknown Date'),
                          trailing: IconButton(
                            onPressed: () => _copyToClipboard(url), 
                            icon: Icon(Icons.copy))
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}