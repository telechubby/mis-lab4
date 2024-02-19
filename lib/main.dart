// ignore_for_file: unrelated_type_equality_checks, deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Import this for latitude and longitude handling

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class Exam {
  late String name;
  late DateTime date;
  late TimeOfDay time;
  late Key key;

  Exam(this.name, this.date, this.time) {
    key = Key(name);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 3',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _examList = <Exam>[];
  final _events = <DateTime, List<Exam>>{};
  LatLng? _pickedLocation;

  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _addExam() {
    final name = _textEditingController.text.trim();
    if (name.isNotEmpty) {
      final exam = Exam(name, _selectedDate, _selectedTime);
      setState(() {
        _examList.add(exam);
        _events.update(_selectedDate, (value) => value..add(exam),
            ifAbsent: () => [exam]);
        _textEditingController.clear();
      });
      _scheduleNotification(exam);
    }
  }

  Future<void> _scheduleNotification(Exam exam) async {
    final scheduledDate = tz.TZDateTime.from(
        DateTime(exam.date.year, exam.date.month, exam.date.day, exam.time.hour,
            exam.time.minute),
        tz.local);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'Exam is now',
      exam.name,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Exam Reminder',
      'Your exam ${exam.name} is scheduled now!',
      tz.TZDateTime.from(exam.date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          '',
          'Exam is now',
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  List<Exam> _getEventsByDay(day) {
    List<Exam>? list = [];
    for (var exam in _examList) {
      if (exam.date == list) list.add(exam);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('201039\'s Exam Scheduler'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDate,
            firstDay: DateTime(2015),
            lastDay: DateTime(2050),
            eventLoader: _getEventsByDay,
            calendarFormat: CalendarFormat.month,
            onFormatChanged: (format) {},
            onPageChanged: (focusedDay) {
              setState(() {
                _selectedDate = focusedDay;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _examList.length,
              itemBuilder: (context, index) {
                final exam = _examList[index];
                if (exam.date == _selectedDate) {
                  return Card(
                    child: ListTile(
                      title: Text(exam.name),
                      subtitle: Text('${exam.date} ${exam.time}'),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Go to exam'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2050),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                        Text(_selectedDate != null
                            ? _selectedDate.toString().split(' ')[0]
                            : 'Select Date'),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                _selectedTime = pickedTime;
                              });
                            }
                          },
                          child: const Text('Select Time'),
                        ),
                        Text(_selectedTime != null
                            ? _selectedTime.format(context)
                            : 'Select Time'),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.all(15),
                      width: 300,
                      height: 300,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(42.0041, 21.4088),
                          initialZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(42.00431, 21.4088),
                                width: 30,
                                height: 30,
                                child: Image.network('https://cdn-icons-png.freepik.com/512/929/929426.png'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _addExam();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
