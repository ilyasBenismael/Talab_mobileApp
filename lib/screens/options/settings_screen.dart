import 'package:flutter/material.dart';
import 'package:ecommerce/services/UserService.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  String _logoutMsg = "";
  bool isAuthenticated = false;
  bool profileExists = false;
//yooo
  @override
  void initState() {
    super.initState();
    checkUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Change Language'),
            onTap: () {},
          ),
          ListTile(
            title: Text('Terms and Conditions'),
            onTap: () {
              Navigator.pushNamed(context, '/terms');
            },
          ),
          ListTile(
            title: Text('Tutorial'),
            onTap: () {
              // Add logic for tutorial
            },
          ),
          if (isAuthenticated && profileExists)
            ListTile(
              title: Text('Edit Profil'),
              onTap: () {
                Navigator.pushNamed(context, '/editProfile');
              },
            ),
          if (isAuthenticated)
            ListTile(
              title: const Text(
                'LogOut',
                style: TextStyle(
                  color: Colors.red, // Text color
                ),
              ),
              onTap: () {
                logout();
              },
            ),
          const SizedBox(height: 50),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SizedBox()
        ],
      ),
    );
  }

  //we set isAuth and profilexists based on response
  //they stay false if user is not auth or if here was an error when checking userAuth
  Future<void> checkUser() async {
    int a = await UserService.checkUserAuth();
    if (a == 1) {
      isAuthenticated = true;
    }
    if (a == 2) {
      isAuthenticated = true;
      profileExists = true;
    }
    setState(() {});
  }

  Future<void> logout() async {
    int? a;
    setState(() {
      _isLoading = true;
    });
    a = await UserService.logout();
    setState(() {
      _isLoading = false;
    });

    if (a == 1) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Logout error'),
        duration: Duration(seconds: 2),
      ));
    }
  }
}
