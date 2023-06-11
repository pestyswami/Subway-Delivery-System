import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'waiting.dart';
import 'dart:convert';

class PackageDataPage extends StatefulWidget {
  final Map<String, dynamic> packageData;
  final String email;

  const PackageDataPage({
    Key? key,
    required this.packageData,
    required this.email,
  }) : super(key: key);

  @override
  _PackageDataPageState createState() => _PackageDataPageState();
}

class _PackageDataPageState extends State<PackageDataPage> {
  bool _showPassword = false;
  bool _deliveryCompleted = false;
  String _errorMessage = '';

  Future<void> _completeDelivery() async {
    setState(() {
      _deliveryCompleted = true;
    });

    try {
      const url = 'http://127.0.0.1:8000/accept-package';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'location': widget.packageData['location'],
          'lockerNumber': widget.packageData['lockerNumber'],
          'password': widget.packageData['password'],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'];

        if (message == 'Package already exists.') {
          // 이미 수락된 택배인 경우
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('이미 수락된 택배입니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // 이전 페이지로 돌아가기
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        } else {
          // 패키지 수락 성공
          // TODO: 원하는 동작 수행
        }
      } else {
        setState(() {
          _errorMessage = '오류가 발생했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다.';
      });
    }
  }

  Future<void> _deletePackage() async {
    try {
      const url = 'http://127.0.0.1:8000/delete-package';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'location': widget.packageData['location'],
          'lockerNumber': widget.packageData['lockerNumber'],
          'password': widget.packageData['password'],
        }),
      );

      if (response.statusCode == 200) {
        // 패키지 삭제 성공
        _navigateToFirstScreen();
      } else {
        setState(() {
          _errorMessage = '패키지 삭제에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다.';
      });
    }
  }

  void _rejectPackageData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WaitingPage(email: widget.email)),
    );
  }

  void _navigateToFirstScreen() {
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.packageData['location'],
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 100),
              const Text(
                '보관함 번호',
                style: TextStyle(fontSize: 24),
              ),
              Text(
                widget.packageData['lockerNumber'],
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '비밀번호',
                style: TextStyle(fontSize: 24),
              ),
              Text(
                _showPassword ? widget.packageData['password'] : '****',
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              if (!_deliveryCompleted)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showPassword = true;
                      _completeDelivery();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 80),
                  ),
                  child: const Text(
                    '수락',
                    style: TextStyle(fontSize: 30),
                  ),
                ),
              const SizedBox(height: 40),
              if (!_deliveryCompleted)
                ElevatedButton(
                  onPressed: _rejectPackageData,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 80),
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    '거절',
                    style: TextStyle(fontSize: 30),
                  ),
                ),
              if (_deliveryCompleted)
                ElevatedButton(
                  onPressed: _deletePackage, // Delete the package
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 80),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    '배달 완료!',
                    style: TextStyle(fontSize: 30),
                  ),
                ),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
