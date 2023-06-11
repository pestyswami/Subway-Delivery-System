import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_fastapi_pods/first_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.indigo,
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.doHyeonTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const MyHomePage(title: '지하철 택배 배송'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState(title);
}

class _MyHomePageState extends State<MyHomePage> {
  final String title;

  var myEmailController = TextEditingController();
  var myPasswordController = TextEditingController();

  _MyHomePageState(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.25,
              child: const Icon(
                Icons.subway,
                size: 200,
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        '지하철역의 택배를',
                        style: TextStyle(
                          fontSize: 40,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '배송하세요',
                        style: TextStyle(fontSize: 40),
                      ),
                      const SizedBox(
                        height: 300,
                      ),
                      TextFormField(
                        controller: myEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: myPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.password),
                        ),
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: () {
                          login(myEmailController.text); // Pass the email value
                        },
                        icon: const Icon(
                          Icons.login,
                          size: 16,
                        ),
                        label: const Text(
                          '로그인',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          signup();
                        },
                        icon: const Icon(
                          Icons.person_add,
                          size: 16,
                        ),
                        label: const Text(
                          '회원가입',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Login with HTTP POST to FastAPI
  Future<void> login(String email) async {
    // Add email parameter
    if (myEmailController.text.isEmpty || myPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email/password')));
    } else {
      final response = await http.post(Uri.parse('http://127.0.0.1:8000/login'),
          body: json.encode({
            'email': myEmailController.text,
            'password': myPasswordController.text,
          }),
          headers: {
            'Content-Type': 'application/json',
          });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('로그인 성공')));
        var items = json.decode(response.body);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FirstScreen(
                    email: email, items: items))); // Pass the email value
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Login failed (invalid email/password)')));
      }
    }
  }

  // Signup with HTTP POST to FastAPI
  Future<void> signup() async {
    if (myEmailController.text.isEmpty || myPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email/password')));
    } else {
      final response =
          await http.post(Uri.parse('http://127.0.0.1:8000/signup'),
              body: json.encode({
                'email': myEmailController.text,
                'password': myPasswordController.text,
              }),
              headers: {
            'Content-Type': 'application/json',
          });
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('회원가입 성공')));
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('User already exists. Please login instead.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Signup failed. Please try again later.')));
      }
    }
  }
}
