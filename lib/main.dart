import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptoapp/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cryptoapp/splash_screen.dart'; 
import 'package:cryptoapp/utililities/constants.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';


class Crypto {
  final String name;
  final double price;

  Crypto({required this.name, required this.price});

  factory Crypto.fromJson(Map<String, dynamic> json) {
    return Crypto(
      name: json['name'],
      price: json['current_price'].toDouble(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "CryptoApp",
      theme: ThemeData(
        primaryColor: AppColors.primary, 
        hintColor: AppColors.secondary, 
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary, 
          foregroundColor: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight, 
          ),
        ),
      ),
      home: splash_screen(), 
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Crypto> _cryptos = [];

  @override
  void initState() {
    super.initState();
    _fetchCryptos();
  }

  Future<void> _fetchCryptos() async {
    final response = await http.get(Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false'));

    if (response.statusCode == 200) {
      List<dynamic> values = json.decode(response.body);
      setState(() {
        _cryptos = values.map((e) => Crypto.fromJson(e)).toList();
      });
    } else {
      print('Failed to load cryptocurrencies');
    }
  }

 Future<UserModel?> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser; 
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        return UserModel.fromMap(userData.data() as Map<String, dynamic>); // Assuming UserModel has a fromMap constructor
      } catch (e) {
        print("Error getting user data: $e");
        return null;
      }
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<UserModel?>(
          future: getUserData(), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text("Loading...", style: TextStyle(fontFamily: 'Satoshi')),
              );
            }

            if (!snapshot.hasData || snapshot.data?.firstName == null) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text("Welcome Back", style: TextStyle(fontFamily: 'Satoshi')),
              );
            }

            final user = snapshot.data!;
            return Align(
              alignment: Alignment.centerLeft,
              child: Text("Welcome Back ${user.firstName}", style: TextStyle(fontFamily: 'Satoshi')),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Add your settings navigation or functionality here
              print('Settings icon tapped');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _cryptos.length,
        itemBuilder: (context, index) {
          final crypto = _cryptos[index];
          return ListTile(
            title: Text(crypto.name),
            trailing: Text('\$${crypto.price.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }
}
