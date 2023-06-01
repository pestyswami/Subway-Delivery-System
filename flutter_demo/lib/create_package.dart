import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePackagePage extends StatefulWidget {
  final String station;

  const CreatePackagePage({Key? key, required this.station}) : super(key: key);

  @override
  _CreatePackagePageState createState() => _CreatePackagePageState();
}

class _CreatePackagePageState extends State<CreatePackagePage> {
  final _formKey = GlobalKey<FormState>();

  late String _station;
  late String _destination;
  late String _lockerNumber;
  late String _password;

  @override
  void initState() {
    super.initState();
    _station = widget.station;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // HTTP POST 요청 보내기
      final url = Uri.parse('http://127.0.0.1:8000/package-create');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'station': _station,
          'destination': _destination,
          'lockerNumber': _lockerNumber,
          'password': _password,
        }),
      );

      // 응답 결과 확인
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('택배 맡기기 성공'),
              content: const Text('택배 맡기기에 성공하셨습니다.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('확인'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('택배 맡기기 실패'),
              content: const Text('택배 맡기기에 실패하였습니다.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('확인'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '택배를 맡기세요',
          style: TextStyle(
            fontSize: 30,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 120),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '목적지',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '목적지를 입력해주세요';
                  }
                  return null;
                },
                onSaved: (value) {
                  _destination = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '물품보관함 번호',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '물품보관함 번호를 입력해주세요';
                  }
                  return null;
                },
                onSaved: (value) {
                  _lockerNumber = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(170, 70),
                ),
                child: const Text(
                  '택배 맡기기',
                  style: TextStyle(
                    fontSize: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
