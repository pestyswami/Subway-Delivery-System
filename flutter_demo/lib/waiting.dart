import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_fastapi_pods/package_data.dart';

class WaitingPage extends StatefulWidget {
  final String email;

  const WaitingPage({Key? key, required this.email}) : super(key: key);

  @override
  _WaitingPageState createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  bool isAccepted = false;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    // 2초마다 check-package API 호출
    timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkPackageStatus();
    });
  }

  void _checkPackageStatus() async {
    final Uri url =
        Uri.parse('http://127.0.0.1:8000/check-package?email=${widget.email}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      if (responseData != null && responseData['accepted'] != null) {
        final result = responseData['accepted'] as bool;
        setState(() {
          isAccepted = result;
        });
        if (isAccepted) {
          timer.cancel(); // 타이머를 취소하여 API 호출 중지
          final packageData =
              jsonDecode(responseData['package']) as Map<String, dynamic>;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PackageDataPage(
                  packageData: packageData, email: widget.email),
            ),
          );
        }
      } else {
        print('API 응답 형식이 잘못되었습니다.');
        // TODO: 에러 처리 로직 작성
      }
    } else {
      print('API 호출 실패');
      // TODO: 에러 처리 로직 작성
    }
  }

  @override
  void dispose() {
    timer.cancel(); // 페이지가 dispose 될 때 타이머를 취소합니다.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAccepted)
              const Text(
                '매칭되었습니다',
                style: TextStyle(
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              )
            else
              Column(
                children: const [
                  Text(
                    '적절한 택배를 찾고 있습니다...',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
