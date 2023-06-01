import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_fastapi_pods/second_screen.dart';

class FirstScreen extends StatefulWidget {
  final String email; // Add email field
  var items;

  FirstScreen({Key? key, required this.email, required this.items})
      : super(key: key);

  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  String stationName = '';

  List<dynamic> stationList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '원하는 목적지를 입력해주세요',
                style: TextStyle(
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                '목적지와 가까운 택배를 매칭합니다',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 200),
              SizedBox(
                width: 300,
                height: 50,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      stationName = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: '주소를 입력하세요',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final Uri uri =
                      Uri.parse('http://127.0.0.1:8000/stations/$stationName');
                  final Map<String, dynamic> queryParams = {
                    'email': widget.email,
                  };
                  final response =
                      await http.get(uri.replace(queryParameters: queryParams));
                  if (response.statusCode == 200) {
                    final jsonResponse = jsonDecode(response.body);
                    setState(() {
                      stationList = jsonResponse;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StationInfoPage(
                          data: stationList,
                          stationName: stationName,
                          email: widget.email, // Pass the email value
                        ),
                      ),
                    );
                  } else {
                    throw Exception('Failed to load station information');
                  }
                },
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
