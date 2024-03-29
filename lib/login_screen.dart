import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cryptoapp/utililities/constants.dart'; 
import 'package:cryptoapp/signup_screen.dart'; 
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Widget _emailField() {
    return TextFormField(
      autofocus: false,
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value!.isEmpty) {
          return "Please Enter your email id.";
        }
        if (!RegExp("^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]").hasMatch(value)) {
          return "Please Enter a valid Email";
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.mail),
        contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
        hintText: "Email",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      autofocus: false,
      controller: passwordController,
      obscureText: true,
      validator: (value) {
        if (value!.isEmpty) {
          return "Password is required for login";
        }
        if (value.length < 6) {
          return "Password must be at least 6 characters long";
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.key),
        contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
        hintText: "Password",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _loginButton() {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(30),
      color: AppColors.primary,
      child: MaterialButton(
        onPressed: signIn,
        minWidth: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
        child: const Text(
          "Login",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _signUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          "Don't have an Account? ",
          style: TextStyle(fontSize: 14, color: AppColors.primary),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const registration_screen()));
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                  height: 200,
                  child: Image(
                  image: AssetImage("assets/logo.png"), // Ensure the path to the asset is correct
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                     ),
                     ),
                  const SizedBox(height: 45),
                  _emailField(),
                  const SizedBox(height: 25),
                  _passwordField(),
                  const SizedBox(height: 35),
                  _loginButton(),
                  const SizedBox(height: 15),
                  _signUpPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void signIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        Fluttertoast.showToast(msg: "Login Successful");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  HomeScreen()));
      } on FirebaseAuthException {
        Fluttertoast.showToast(msg: "Incorrect login");
      }
    }
  }
}
