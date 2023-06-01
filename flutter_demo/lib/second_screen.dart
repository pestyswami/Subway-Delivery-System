import 'package:flutter/material.dart';
import 'arrival_time.dart';

class StationInfoPage extends StatelessWidget {
  final List<dynamic> data;
  final String stationName;
  final String email; // Add email field

  const StationInfoPage({
    Key? key,
    required this.data,
    required this.stationName,
    required this.email, // Add email parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 90),
            const Text(
              '가까운 역 중에서',
              style: TextStyle(
                fontSize: 36,
              ),
            ),
            const Text(
              '하나를 선택해주세요',
              style: TextStyle(
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 70),
            Expanded(
              child: ListView.separated(
                itemCount: data.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 30),
                itemBuilder: (context, index) {
                  final station = data[index];
                  final stationName = station['stationName'];
                  final lat = station['lat'];
                  final lng = station['lng'];
                  final distance = station['distance'];

                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArrivalTimePage(
                            selectedStation: stationName,
                            email: email, // Pass email value
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.white,
                      minimumSize: const Size(200, 0),
                    ),
                    child: ListTile(
                      title: Text(
                        stationName,
                        style: const TextStyle(
                          fontSize: 40,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('거리: $distance KM'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
