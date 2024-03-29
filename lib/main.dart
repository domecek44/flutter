import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptoapp/model/user_model.dart';
import 'package:cryptoapp/utililities/constants.dart';
import 'package:cryptoapp/settings_page.dart';
import 'package:cryptoapp/crypto_detail.dart';
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
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Crypto> _cryptos = [];
  Timer? _timer;
  String? _welcomeMessage;

  @override
  void initState() {
    super.initState();
    _initUserData();
    _loadCachedCryptos().then((cachedCryptos) {
      if (cachedCryptos.isNotEmpty) {
        setState(() {
          _cryptos = cachedCryptos;
        });
        _loadFavorites(); 
      } else {
        _fetchCryptos();
      }
    });
    _startRefreshTimer();
  }

  Future<void> _initUserData() async {
    final userModel = await getUserData();
    if (userModel != null) {
      setState(() {
        _welcomeMessage = "Welcome Back ${userModel.firstName}";
      });
    } else {
      setState(() {
        _welcomeMessage = "Welcome Back";
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _timer = Timer.periodic(Duration(hours: 1), (timer) {
      _fetchCryptos();
    });
  }

  Future<void> _fetchCryptos() async {
    final response = await http.get(Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false'));

    if (response.statusCode == 200) {
      List<dynamic> values = json.decode(response.body);
      final cryptos = values.map((e) => Crypto.fromJson(e)).toList();
      await _cacheCryptos(cryptos);
      setState(() {
        _cryptos = cryptos;
      });
      _loadFavorites(); 
    } else {
      print('Failed to load cryptocurrencies');
    }
  }

  Future<void> _cacheCryptos(List<Crypto> cryptos) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(cryptos.map((crypto) => crypto.toJson()).toList());
    await prefs.setString('cachedCryptos', encodedData);
  }

  Future<List<Crypto>> _loadCachedCryptos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('cachedCryptos');
    if (encodedData != null) {
      List<dynamic> decodedData = json.decode(encodedData);
      return decodedData.map((cryptoJson) => Crypto.fromJson(cryptoJson)).toList();
    }
    return [];
  }

  Future<void> _loadFavorites() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> favoriteNames = prefs.getStringList('favorites') ?? [];
  setState(() {
    for (var crypto in _cryptos) {
      crypto.isFavorite = favoriteNames.contains(crypto.name); // This should be sufficient, contains() returns a bool
    }
  });
}


  Future<void> _saveFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteNames = _cryptos.where((crypto) => crypto.isFavorite).map((crypto) => crypto.name).toList();
    await prefs.setStringList('favorites', favoriteNames);
  }

  Future<UserModel?> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        return UserModel.fromMap(userData.data() as Map<String, dynamic>);
      } catch (e) {
        print("Error getting user data: $e");
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: Align(
            alignment: Alignment.centerLeft,
            child: Text(_welcomeMessage ?? "Loading...", style: TextStyle(fontFamily: 'Satoshi')),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.account_box),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(cryptos: _cryptos)));
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchCryptos,
          child: ListView.builder(
            itemCount: _cryptos.length,
            itemBuilder: (context, index) {
              final crypto = _cryptos[index];
              Color textColor = crypto.change24h >= 0 ? Colors.green : Colors.red;

              return ListTile(
                leading: Image.network(crypto.iconUrl, width: 30),
                title: Text(crypto.name),
                subtitle: Text('${crypto.change24h.toStringAsFixed(2)}%', style: TextStyle(fontFamily: 'Satoshi',color: textColor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\$${crypto.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
                    IconButton(
                     icon: Icon(crypto.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                       onPressed: () {
                        setState(() {
                        crypto.isFavorite = !crypto.isFavorite; 
                      });
                        _saveFavorites();
                    },
                   ),
                  ],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CryptoDetailPage(crypto: crypto))
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class Crypto {
  final String name;
  final double price;
  final double change24h;
  final String iconUrl;
  bool isFavorite;

  Crypto({
    required this.name,
    required this.price,
    required this.change24h,
    required this.iconUrl,
    this.isFavorite = false,
  });
  factory Crypto.fromJson(Map<String, dynamic> json) {
  return Crypto(
    name: json['name'],
    price: json['current_price'].toDouble(),
    change24h: json['price_change_percentage_24h'].toDouble(),
    iconUrl: json['image'],
    isFavorite: false, 
  );
}


  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'current_price': price,
      'price_change_percentage_24h': change24h,
      'image': iconUrl,
    };
  }
}

