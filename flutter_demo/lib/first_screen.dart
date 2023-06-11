import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_fastapi_pods/second_screen.dart';
import 'package:geolocator/geolocator.dart';

class FirstScreen extends StatefulWidget {
  final String email; // 이메일 필드 추가
  var items;

  FirstScreen({Key? key, required this.email, required this.items})
      : super(key: key);

  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  String currentLocation = ''; // 현재 위치를 나타내는 변수

  List<dynamic> stationList = [];

  @override
  void initState() {
    super.initState();
    getCurrentLocationAndFetchData(); // 현재 위치를 가져와 데이터를 호출하는 함수 실행
  }

  Future<void> getCurrentLocationAndFetchData() async {
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentLocation =
          '${position.latitude},${position.longitude}'; // 현재 위치 좌표를 문자열로 저장
    });

    fetchStationData(); // 위치 정보를 얻은 후 API 호출
  }

  Future<void> fetchStationData() async {
    final Uri uri = Uri.parse(
        'http://127.0.0.1:8000/stations/$currentLocation'); // 현재 위치를 이용해 URI 생성
    final Map<String, dynamic> queryParams = {
      'email': widget.email,
    };
    final response = await http.get(uri.replace(queryParameters: queryParams));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      setState(() {
        stationList = jsonResponse;
      });
      navigateToStationInfoPage(); // API 응답이 정상일 경우 StationInfoPage로 이동
    } else {
      throw Exception('Failed to load station information');
    }
  }

  void navigateToStationInfoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationInfoPage(
          data: stationList,
          stationName: currentLocation,
          email: widget.email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '적절한 택배 매칭을 위해',
                style: TextStyle(
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                '위치 정보를 허용해주세요',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
