// class AppUser {
//   final String uid;
//   final String role;
//   final Map<String, dynamic> permissions;

//   AppUser({
//     required this.uid,
//     required this.role,
//     required this.permissions,
//   });

//   bool isAdmin() => role == 'admin';

//   bool can(String key) => permissions[key] == true;

//   factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
//     return AppUser(
//       uid: uid,
//       role: data['role'] ?? '',
//       permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
//     );
//   }
// }
