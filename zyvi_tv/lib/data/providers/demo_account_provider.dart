import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DemoAccountService {
  static const String demoEmail = 'demo@zyvi.tv';
  static const String demoPassword = 'demo1234';

  static Future<void> login(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: demoEmail,
        password: demoPassword,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in as demo user'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: demoEmail,
            password: demoPassword,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demo account created and logged in'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (createError) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Demo login failed: $createError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
