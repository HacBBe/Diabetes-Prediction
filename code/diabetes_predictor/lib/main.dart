import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:logging/logging.dart';

void main() {
  _setupLogging();
  runApp(MyApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL; // Set logging level
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

final Logger _logger = Logger('DiabetesPredictorApp');

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _logger.info('Building MyApp');
    return MaterialApp(
      title: 'Diabetes Predictor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    _logger.info('Creating MyHomePage state');
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  final TextEditingController _pregnanciesController = TextEditingController();
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _bloodPressureController =
      TextEditingController();
  final TextEditingController _skinThicknessController =
      TextEditingController();
  final TextEditingController _insulinController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _diabetesPedigreeFunctionController =
      TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  Map<String, dynamic>? _healthData;
  String _probability = '';
  String _nonDiabetesProbability = '';

  @override
  void initState() {
    super.initState();
    _logger.info('Initializing MyHomePage state');
    _notificationService.init().then((_) {
      _logger.info('Notification service initialized');
    }).catchError((e) {
      _logger.severe('Failed to initialize notification service: $e');
    });
  }

  Future<void> _predictDiabetes() async {
    _logger.info('Starting diabetes prediction');
    final inputData = {
      'pregnancies': int.tryParse(_pregnanciesController.text) ?? 0,
      'glucose': int.tryParse(_glucoseController.text) ?? 0,
      'blood_pressure': _bloodPressureController.text,
      'skin_thickness': int.tryParse(_skinThicknessController.text) ?? 0,
      'insulin': int.tryParse(_insulinController.text) ?? 0,
      'bmi': double.tryParse(_bmiController.text) ?? 0.0,
      'diabetes_pedigree_function':
          double.tryParse(_diabetesPedigreeFunctionController.text) ?? 0.0,
      'age': int.tryParse(_ageController.text) ?? 0,
      'gender': _genderController.text
    };

    try {
      final result = await _apiService.predictDiabetes(inputData);
      _logger.info('Prediction result: $result');
      setState(() {
        _healthData = result;
        if (result.containsKey('probability')) {
          final probability = result['probability'] as double;
          _probability = (probability * 100).toStringAsFixed(2) + '%';
          _nonDiabetesProbability =
              ((1 - probability) * 100).toStringAsFixed(2) + '%';
        }
      });
      await _notificationService.showNotification();
    } catch (e) {
      _logger.severe('Error predicting diabetes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('Building MyHomePage UI');
    return Scaffold(
      appBar: AppBar(title: Text('Diabetes Predictor')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildTextField(_pregnanciesController, 'Số lần mang thai'),
              _buildTextField(_glucoseController, 'Mức đường huyết'),
              _buildTextField(_bloodPressureController, 'Huyết áp'),
              _buildTextField(_skinThicknessController, 'Độ dày da'),
              _buildTextField(_insulinController, 'Insulin'),
              _buildTextField(_bmiController, 'BMI'),
              _buildTextField(_diabetesPedigreeFunctionController,
                  'Chức năng chỉ số tiểu đường'),
              _buildTextField(_ageController, 'Tuổi'),
              _buildTextField(_genderController, 'Giới tính'),
              ElevatedButton(
                onPressed: _predictDiabetes,
                child: Text('Dự Đoán Tiểu Đường'),
              ),
              if (_healthData != null) ...[
                Text('Khả năng bị tiểu đường: $_probability'),
                Text('Khả năng không bị tiểu đường: $_nonDiabetesProbability'),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HealthChartScreen(
                        healthData: _healthData,
                      ),
                    ),
                  );
                },
                child: Text('Xem Biểu Đồ Sức Khỏe'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HealthHistoryScreen()),
                  );
                },
                child: Text('Xem Lịch Sử Sức Khỏe'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PersonalizedRecommendationsScreen()),
                  );
                },
                child: Text('Gợi Ý Cá Nhân Hóa'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }
}

class ApiService {
  final String apiUrl =
      'https://7477-2001-ee0-4fb6-be30-9d0b-772a-8ecb-66e.ngrok-free.app/predict';

  Future<Map<String, dynamic>> predictDiabetes(
      Map<String, dynamic> inputData) async {
    _logger.info('Sending prediction request to $apiUrl');
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(inputData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Received response: $data');
        return data;
      } else {
        _logger.severe(
            'Failed to load prediction: Status code ${response.statusCode}');
        throw Exception('Failed to load prediction');
      }
    } catch (e) {
      _logger.severe('Failed to connect to the server: $e');
      throw Exception('Failed to connect to the server');
    }
  }
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    _logger.info('Initializing notification service');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      _logger.info('Notification service initialized');
    } catch (e) {
      _logger.severe('Failed to initialize notification service: $e');
    }
  }

  Future<void> showNotification() async {
    _logger.info('Showing notification');
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await _flutterLocalNotificationsPlugin.show(
        0,
        'Nhắc nhở',
        'Đã đến lúc nhập dữ liệu sức khỏe của bạn!',
        platformChannelSpecifics,
      );
      _logger.info('Notification shown successfully');
    } catch (e) {
      _logger.severe('Failed to show notification: $e');
    }
  }
}

String getHealthRecommendation(Map<String, dynamic> healthData) {
  _logger.info('Generating health recommendation');

  final glucose = healthData['glucose'];
  final bloodPressure = healthData['blood_pressure'];
  final skinThickness = healthData['skin_thickness'];
  final insulin = healthData['insulin'];
  final bmi = healthData['bmi'];
  final age = healthData['age'];
  final diabetesPedigreeFunction = healthData['diabetes_pedigree_function'];

  String recommendation = 'Dựa trên dữ liệu của bạn:\n';

  if (glucose != null && glucose > 100) {
    recommendation += 'Mức glucose của bạn cao hơn mức bình thường.\n';
  }

  if (bloodPressure != null && bloodPressure > 120) {
    recommendation += 'Huyết áp của bạn cao hơn mức bình thường.\n';
  }

  if (skinThickness != null && skinThickness > 20) {
    recommendation += 'Độ dày da của bạn cao hơn mức bình thường.\n';
  }

  if (insulin != null && insulin > 20) {
    recommendation += 'Mức insulin của bạn cao hơn mức bình thường.\n';
  }

  if (bmi != null && bmi > 25) {
    recommendation += 'Chỉ số BMI của bạn cao hơn mức bình thường.\n';
  }

  if (age != null && age > 50) {
    recommendation += 'Bạn có độ tuổi cao hơn mức bình thường.\n';
  }

  if (diabetesPedigreeFunction != null && diabetesPedigreeFunction > 0.5) {
    recommendation +=
        'Chỉ số di truyền tiểu đường của bạn cao hơn mức bình thường.\n';
  }

  return recommendation;
}

class HealthChartScreen extends StatelessWidget {
  final Map<String, dynamic>? healthData;

  HealthChartScreen({this.healthData});

  @override
  Widget build(BuildContext context) {
    if (healthData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Biểu Đồ Sức Khỏe')),
        body: Center(
          child: Text('Không có dữ liệu để hiển thị.'),
        ),
      );
    }

    final data = [
      LinearSales('Glucose', healthData!['glucose']?.toDouble() ?? 0, 100),
      LinearSales('BMI', healthData!['bmi']?.toDouble() ?? 0, 25),
      LinearSales('Insulin', healthData!['insulin']?.toDouble() ?? 0, 20),
      LinearSales(
          'Skin Thickness', healthData!['skin_thickness']?.toDouble() ?? 0, 20),
      LinearSales('Age', healthData!['age']?.toDouble() ?? 0, 50),
      LinearSales('Blood Pressure',
          _parseBloodPressure(healthData!['blood_pressure']), 120),
    ];

    final series = [
      charts.Series<LinearSales, String>(
        id: 'HealthData',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearSales sales, _) => sales.label,
        measureFn: (LinearSales sales, _) => sales.value,
        data: data,
        labelAccessorFn: (LinearSales sales, _) => '${sales.value}',
      ),
      charts.Series<LinearSales, String>(
        id: 'Thresholds',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (LinearSales sales, _) => sales.label,
        measureFn: (LinearSales sales, _) => sales.threshold,
        data: data,
        labelAccessorFn: (LinearSales sales, _) => '${sales.threshold}',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Biểu Đồ Sức Khỏe')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: charts.BarChart(
                series,
                animate: true,
                barRendererDecorator: charts.BarLabelDecorator<String>(),
                domainAxis: charts.OrdinalAxisSpec(
                  renderSpec: charts.SmallTickRendererSpec(
                    labelStyle: charts.TextStyleSpec(
                        fontSize: 12, color: charts.MaterialPalette.black),
                    lineStyle: charts.LineStyleSpec(
                        color: charts.MaterialPalette.black),
                  ),
                ),
                primaryMeasureAxis: charts.NumericAxisSpec(
                  renderSpec: charts.GridlineRendererSpec(
                    labelStyle: charts.TextStyleSpec(
                        fontSize: 12, color: charts.MaterialPalette.black),
                    lineStyle: charts.LineStyleSpec(
                        color: charts.MaterialPalette.black),
                  ),
                ),
                behaviors: [
                  charts.ChartTitle('Các Chỉ Số Sức Khỏe',
                      behaviorPosition: charts.BehaviorPosition.top,
                      titleOutsideJustification:
                          charts.OutsideJustification.middle,
                      titleStyleSpec: charts.TextStyleSpec(
                          fontSize: 14, color: charts.MaterialPalette.black)),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Ngưỡng bình thường hoặc mức tối ưu'),
            Text('Glucose: < 100 mg/dL'),
            Text('BMI: 18.5 - 24.9'),
            Text('Insulin: < 20 µU/mL'),
            Text('Skin Thickness: < 20 mm'),
            Text('Age: 50 tuổi hoặc thấp hơn'),
            Text('Blood Pressure: < 120/80 mmHg'),
          ],
        ),
      ),
    );
  }

  double _parseBloodPressure(String? bloodPressure) {
    if (bloodPressure != null) {
      final parts = bloodPressure.split('/');
      if (parts.length == 2) {
        final systolic = int.tryParse(parts[0]);
        final diastolic = int.tryParse(parts[1]);
        if (systolic != null && diastolic != null) {
          return (systolic + diastolic) / 2.0; // Trung bình huyết áp
        }
      }
    }
    return 0.0;
  }
}

class LinearSales {
  final String label;
  final double value;
  final double threshold;

  LinearSales(this.label, this.value, this.threshold);
}

class HealthHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lịch Sử Sức Khỏe')),
      body: Center(
        child: Text('Danh sách lịch sử sức khỏe'),
      ),
    );
  }
}

class PersonalizedRecommendationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gợi Ý Cá Nhân Hóa')),
      body: Center(
        child: Text('Danh sách gợi ý cá nhân hóa'),
      ),
    );
  }
}
