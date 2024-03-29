import 'package:flutter/material.dart';
import 'package:cryptoapp/login_screen.dart';

class splash_screen extends StatefulWidget {
  const splash_screen({Key? key}) : super(key: key);

  @override
  State<splash_screen> createState() => _splash_screenState();
}

class _splash_screenState extends State<splash_screen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: <Widget>[
            Image(
              image: AssetImage("assets/logo.png"),
              width: 105,
              height: 105,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(), 
            SizedBox(height: 10), 
            Text(
              "Wait, I'm frogging your data",
              style: TextStyle(
                fontSize: 16, 
                color: Colors.black, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}