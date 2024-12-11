import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLogin = true; // Untuk toggle antara login dan register
  String _errorMessage = '';

  Future<void> _submitAuthForm() async {
    try {
      if (_isLogin) {
        // Login user
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Register user
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Parking Finder'),
        backgroundColor: Colors.green, // Sesuaikan dengan warna App secara keseluruhan
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Menambahkan logo atau gambar jika ada
                Image.asset('assets/icons/app_logo.png', height: 100), // Ganti dengan gambar logo aplikasi Anda
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email), // Menambahkan ikon untuk setiap field
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock), // Menambahkan ikon untuk setiap field
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _submitAuthForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Sesuaikan dengan tema aplikasi
                    minimumSize: Size(double.infinity, 50), // Tombol lebih lebar dan konsisten
                  ),
                  child: Text(
                    _isLogin ? 'Login' : 'Register',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin ? 'Don\'t have an account? Register' : 'Already have an account? Login',
                    style: TextStyle(color: Colors.green), // Warna sesuai aplikasi
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}