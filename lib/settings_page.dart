import 'package:cryptoapp/main.dart';
import 'package:flutter/material.dart';
import 'package:cryptoapp/utililities/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptoapp/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptoapp/login_screen.dart';
import 'package:cryptoapp/crypto_detail.dart'; 

class SettingsPage extends StatefulWidget {
  final List<Crypto> cryptos;

  SettingsPage({required this.cryptos});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  UserModel? _currentUser;
  List<Crypto> _favoriteCryptos = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadFavoriteCryptos();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      UserModel userModel = UserModel.fromMap(userData.data() as Map<String, dynamic>);
      setState(() {
        _currentUser = userModel;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginScreen()), (Route<dynamic> route) => false);
  }

  Future<void> _loadFavoriteCryptos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteNames = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favoriteCryptos = widget.cryptos.where((crypto) => favoriteNames.contains(crypto.name)).toList();
    });
  }

  void _navigateToCryptoDetail(Crypto crypto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CryptoDetailPage(crypto: crypto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your profile'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text('Your Watch List', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
                ..._favoriteCryptos.map((crypto) {
                  return Card(
                    elevation: 4.0,
                    margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    child: ListTile(
                      onTap: () => _navigateToCryptoDetail(crypto),
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(crypto.iconUrl),
                      ),
                      title: Text(crypto.name, style: TextStyle(fontSize: 18)),
                      trailing: Text('\$${crypto.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'User Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(),
                  Text('First Name: ${_currentUser?.firstName ?? "Loading..."}'),
                  Text('Last Name: ${_currentUser?.lastName ?? ""}'),
                  Text('Email: ${_currentUser?.email ?? ""}'),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.exit_to_app),
                      label: Text('Logout'),
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}