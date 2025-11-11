import 'package:dimple_erp/extra.dart/forgetpassword.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedYear = '2025-26';
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool forcefullyLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA0F9A0), Color(0xFFFFFFFF)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 2,
              color: const Color(0xFFF8F4FC),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/1.jpg', height: 80),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_month),
                            border: OutlineInputBorder(),
                          ),
                          items: ['2025-26', '2024-25', '2023-24']
                              .map((year) => DropdownMenuItem(
                                  value: year, child: Text(year)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedYear = value),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            hintText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Username required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            hintText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Password required' : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: forcefullyLogin,
                              onChanged: (value) =>
                                  setState(() => forcefullyLogin = value!),
                            ),
                            const Text('Forcefully Login?'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Your login logic here
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF03DF04),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('LOGIN',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Customer Support',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('info@dimplepackaging.com'),
                        const Text('(+91) 9815700857'),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordPage()),
                            );
                          },
                          child: const Text('Forgot Password'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
