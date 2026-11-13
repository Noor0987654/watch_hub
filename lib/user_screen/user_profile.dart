import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color kBgBlack = Color(0xFF000000);
  static const Color kSurface = Color(0xFF1A1A1A);
  static const Color kGold = Color(0xFFD4AF37);

  bool isEditing = false;
  bool isSaving = false;

  // Controllers ko late nahi, bina late declare karo
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    
    // initState mein controllers ko initialize karo
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose karo
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(String uid) async {
    setState(() => isSaving = true);
    try {
      await _firestore.collection('Users').doc(uid).update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
      });
      if (mounted) {
        setState(() {
          isEditing = false;
          isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: kBgBlack,
        body: Center(
          child: Text("No user logged in", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBgBlack,
      appBar: AppBar(
        backgroundColor: kBgBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kGold),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('Users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kGold));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Profile not found", style: TextStyle(color: Colors.white)),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['name'] ?? 'No Name';
          final String email = data['email'] ?? '';
          final String phone = data['phone'] ?? '';
          final String address = data['address'] ?? '';

          //  Sync controllers when not editing
          if (!isEditing) {
            nameController.text = name;
            emailController.text = email;
            phoneController.text = phone;
            addressController.text = address;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ---- Info Card ----
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kGold.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // Name - Editable
                      isEditing
                          ? _editField(Icons.person, "Full Name", nameController)
                          : _infoRow(Icons.person, "Full Name", name),
                      const Divider(color: Colors.white12, height: 24),

                      //  Email - Editable
                      isEditing
                          ? _editField(Icons.email, "Email", emailController)
                          : _infoRow(Icons.email, "Email", email),
                      const Divider(color: Colors.white12, height: 24),

                      //  Phone - Editable
                      isEditing
                          ? _editField(Icons.phone, "Phone", phoneController)
                          : _infoRow(Icons.phone, "Phone", phone.isEmpty ? "Not added" : phone),
                      const Divider(color: Colors.white12, height: 24),

                      //  Address - Editable
                      isEditing
                          ? _editField(Icons.location_on, "Address", addressController)
                          : _infoRow(Icons.location_on, "Address", address.isEmpty ? "Not added" : address),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Edit / Save Button ----
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isSaving
                        ? null
                        : () {
                            if (isEditing) {
                              _saveChanges(currentUser.uid);
                            } else {
                              setState(() => isEditing = true);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            isEditing ? "Save Changes" : "Edit Profile",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // ---- Cancel (only while editing) ----
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isEditing = false;
                        // Reset to original values
                        nameController.text = name;
                        emailController.text = email;
                        phoneController.text = phone;
                        addressController.text = address;
                      });
                    },
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),

                const SizedBox(height: 12),

                // ---- Logout Button ----
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- Read-only info row ----
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kGold, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Editable field ----
  Widget _editField(IconData icon, String label, TextEditingController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kGold, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: "Enter $label",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              Container(height: 1, color: kGold.withOpacity(0.3)),
            ],
          ),
        ),
      ],
    );
  }
}