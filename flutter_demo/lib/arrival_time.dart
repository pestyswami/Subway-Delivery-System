import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'waiting.dart';

class ArrivalTimePage extends StatefulWidget {
  final String selectedStation;
  final String email;

  const ArrivalTimePage({
    Key? key,
    required this.selectedStation,
    required this.email,
  }) : super(key: key);

  @override
  _ArrivalTimePageState createState() => _ArrivalTimePageState();
}

class _ArrivalTimePageState extends State<ArrivalTimePage> {
  late String selectedTime = '오후 06:00';

  void _showTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                '도착 예정 시간 선택',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(0, 1, 1, 18, 0),
                  onDateTimeChanged: (DateTime? dateTime) {
                    if (dateTime != null) {
                      final hour = dateTime.hour;
                      final minute = dateTime.minute;
                      final period = hour < 12 ? '오전' : '오후';
                      final hourText = hour % 12 == 0
                          ? '12'
                          : (hour % 12).toString().padLeft(2, '0');
                      final minuteText = minute.toString().padLeft(2, '0');
                      setState(() {
                        selectedTime = '$period $hourText:$minuteText';
                      });
                    }
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('선택완료'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendDataToServer() async {
    final String selectedStation = widget.selectedStation;
    final String arrivalTime = selectedTime;

    // arrivalTime 값을 fastAPI 서버와 소통 가능한 형식으로 변환
    final List<String> timeParts = arrivalTime.split(' ');
    final String period = timeParts[0];
    final String time = timeParts[1];
    final List<String> timeComponents = time.split(':');
    final int hour = int.parse(timeComponents[0]);
    final int minute = int.parse(timeComponents[1]);
    final int convertedHour = period == '오후' ? hour + 12 : hour;
    final String convertedTime = '$convertedHour:${timeComponents[1]}';

    final String email = widget.email;

    final Map<String, dynamic> requestData = {
      'email': email,
      'selectedStation': selectedStation,
      'selectedTime': convertedTime,
    };

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/arrival-time'),
      body: jsonEncode(requestData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('API 호출 성공');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingPage(email: email),
        ),
      );
    } else {
      print('API 호출 실패');
      // TODO: 에러 처리 로직 작성
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${widget.selectedStation}에',
                style: const TextStyle(
                  fontSize: 36,
                ),
              ),
              const Text(
                '언제 도착예정이신가요?',
                style: TextStyle(
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '시간을 선택해주세요',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              ElevatedButton(
                onPressed: () => _showTimePicker(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white,
                  minimumSize: const Size(200, 0),
                ),
                child: Text(
                  selectedTime,
                  style: const TextStyle(color: Colors.black, fontSize: 24),
                ),
              ),
              const SizedBox(height: 300),
              ElevatedButton(
                onPressed: _sendDataToServer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size(200, 0),
                ),
                child: const Text(
                  '택배 찾으러 가기',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
