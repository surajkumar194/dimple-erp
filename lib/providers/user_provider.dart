// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dimple_erp/models/app_user.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class UserProvider extends ChangeNotifier {
//   AppUser? user;
//   bool loading = true;

//   Future<void> loadUser() async {
//     final uid = FirebaseAuth.instance.currentUser!.uid;
//     final doc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .get();

//     user = AppUser.fromMap(uid, doc.data()!);
//     loading = false;
//     notifyListeners();
//   }
// }
