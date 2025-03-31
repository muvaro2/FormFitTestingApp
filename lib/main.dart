import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

// Global stream controller for sensor data (each update is a List<double> of length 6)
final StreamController<List<double>> sensorDataController = StreamController.broadcast();

// Global variable to store the current repetition data.
// Each element is a list of 6 doubles: [gyroX, gyroY, gyroZ, accelX, accelY, accelZ].
List<List<double>> globalRepetition = [];
const List<List<double>> globalCalibration = [[-0.8569981038570404, -0.5429370146244764, 1.1824060142040254, 8.600462818145752, -5.7364932775497435, -0.2890529714524746], [-0.7674691684735127, -0.7271081763009231, 1.307324035045428, 8.124541061352462, -6.593383026123047, -0.9189972444413564], [-0.7004791699731961, -0.9044760342591847, 1.4137445996969173, 7.305345859283056, -7.355822215936124, -1.8346675912539165], [-0.6439518009813932, -1.0824602448023284, 1.5099648879124568, 6.130867239145132, -7.966295748490552, -2.9157510812465963], [-0.5767621216674644, -1.273974711696307, 1.594218852581122, 4.6227723137690475, -8.242530255439954, -3.7116545874338884], [-0.4302413959008378, -1.4193614293367436, 1.6209986350475212, 2.948362434292451, -8.340548459077493, -4.3288846590580095], [-0.38941836785525086, -1.5205680860922886, 1.6010049315599293, 1.2800543044622128, -8.123140580837545, -4.599874846751874], [-0.38808307089866734, -1.5474339994100426, 1.5389535492811448, -0.5604236225287121, -7.75825349000784, -4.769487692148258], [-0.4068526881245466, -1.5282978730323988, 1.4420585756118482, -2.309119863387866, -7.3479871811010895, -4.733699675706717], [-0.3712462989183572, -1.4363826311551606, 1.2848257935964145, -3.6984847013766946, -6.6350028001345125, -4.252496741368219], [-0.283117241355089, -1.3295920232931773, 1.1197390586901932, -5.038750819059518, -5.948666104903587, -3.867474737534156], [-0.18911408533652624, -1.2174395092022725, 0.9910638249837437, -6.2705852264013044, -5.481818593465365, -3.4059974911885385], [-0.1839103746586121, -1.1213289013275733, 0.9077927415187542, -7.283406989391034, -4.885752573380104, -2.726552379647126], [-0.14357878205676872, -0.9638079226016998, 0.7846614867448807, -7.897192080815633, -4.202693819999696, -2.1264815792441367], [-0.053307000261086625, -0.7479555497566859, 0.636740463360762, -8.262586942085852, -3.7670666908606507, -1.6238354401901745], [-0.051901226118207036, -0.5285323455571556, 0.4887133264770875, -8.697468625582182, -3.308850391094501, -1.3084276295052126], [-0.07372869276561025, -0.3528482903009997, 0.3654618715628598, -8.966909704452906, -3.11444580982893, -0.9882403636781071], [-0.05622192111152859, -0.20434812693259657, 0.2604795943754606, -9.106912918579884, -2.90527935333741, -0.7903355295172869], [0.05274586444810179, -0.003987068797533239, 0.14345465762397414, -9.165951090592603, -2.6358321776756872, -0.7308278681280521], [0.06310316121014647, 0.21815446474804312, -0.06596991956377239, -9.090883969037963, -2.6053651586557045, -0.7323433159158015], [0.07406897810884765, 0.39216529522568766, -0.28585242873583094, -9.068606119889479, -2.8003326431298863, -0.9674197239753528], [0.11916806740829577, 0.5400870942439024, -0.46088137165285065, -8.957425719041092, -3.0550179343957167, -1.3637248243276887], [0.24387893942304145, 0.6594243155075954, -0.5302126199007035, -8.610273229158842, -3.652988909146724, -1.833405254284541], [0.2737428100612492, 0.7622642533901411, -0.6284033314539835, -8.177561822304359, -4.220383958938795, -2.248546179288473], [0.2680782103266281, 0.8610309779644012, -0.7386300478990262, -7.727413668999307, -4.580492991667528, -2.7758215464078466], [0.3031105478031513, 0.9270776718090742, -0.8616191345911759, -7.042730571062137, -5.201637494258393, -3.309700223115775], [0.369945078343153, 0.9642100632190704, -0.9670149226983389, -6.2007208665212, -6.0114883581797285, -3.796452538172403], [0.3898025003190224, 0.9816369377649746, -1.0702652555245618, -5.234598820026104, -6.614695937816914, -4.085855243756221], [0.3686438492666452, 1.0030172147811989, -1.1825974933612042, -4.209887717014704, -6.693178928815402, -4.371777477631202], [0.3662101845137584, 1.0112795698337067, -1.2630417943000793, -2.821599648510797, -7.57739593187968, -4.411251437969698], [0.4017179005994248, 1.0012527717993809, -1.354708786194141, -1.3666008913746246, -8.301681907360372, -4.428493699660668], [0.45501236193455197, 0.9779337576184519, -1.4215358795263828, -0.027960740048915945, -8.456493040231557, -4.299301161674354], [0.36225208539802295, 0.9334647201956845, -1.437814260751773, 1.419681691693573, -8.720918393746402, -3.938554028364328], [0.30029899839025287, 0.9166678850467388, -1.4282534204996549, 2.8055937904004877, -8.591756629943848, -3.6430450870440554], [0.47674272303015763, 0.9144601581952511, -1.4318857266352727, 4.187904313741588, -8.160615817094461, -3.1659667284060746], [0.6241617341072132, 0.8848570890151537, -1.409032327395219, 5.438678731673803, -8.055986419090857, -2.4108301897843676], [0.642217892408371, 0.821250762962378, -1.381360142964583, 6.575881675573496, -7.55537420786344, -1.7568150228032695], [0.60484664722895, 0.667628327776224, -1.262502212096483, 7.55686246554057, -6.837878794547838, -0.9429577448429196], [0.5720862545526753, 0.5483470942920601, -1.16329534023236, 8.169935896457769, -6.1386975428996955, -0.23562095449903148], [0.55332171889022, 0.4835914634168148, -1.1008096754550933, 8.550333213806152, -5.387021374702454, 0.2763710256665945]];

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable debug banner.
      title: 'BLE Sensor App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Sensor App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text("Scan & Connect"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScanPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("View Chart"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChartPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            // New button to navigate to the RepetitionPage.
            ElevatedButton(
              child: const Text("View Repetition"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RepetitionPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ScanPage Implementation ----------------
class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  StreamSubscription<List<ScanResult>>? scanSubscription;
  BluetoothDevice? connectedDevice;
  final List<BluetoothDevice> devicesList = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startScan();
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    // For Android 12+ you might also need:
    // await Permission.bluetoothScan.request();
    // await Permission.bluetoothConnect.request();
  }

  void _startScan() {
    devicesList.clear();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name == "FormFit") {
          if (!devicesList.contains(r.device)) {
            setState(() {
              devicesList.add(r.device);
            });
          }
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await BLEManager.instance.connectToDevice(device);
    setState(() {
      connectedDevice = device;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Connected to ${device.name}")),
    );
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan & Connect")),
      body: ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          BluetoothDevice device = devicesList[index];
          return ListTile(
            title: Text(device.name),
            subtitle: Text(device.id.toString()),
            onTap: () => _connectToDevice(device),
          );
        },
      ),
    );
  }
}

// ---------------- ChartPage Implementation ----------------
class ChartPage extends StatefulWidget {
  const ChartPage({Key? key}) : super(key: key);

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<ChartData> chartData = [];
  int xValue = 0;
  StreamSubscription? sensorSubscription;

  bool isPlotting = true;
  bool isRecording = false;
  // Local list for recording during the session.
  List<List<double>> currentRepetition = [];

  @override
  void initState() {
    super.initState();
    sensorSubscription = sensorDataController.stream.listen((data) {
      // Append full sensor data (6 values) when recording.
      if (isRecording) {
        currentRepetition.add(List<double>.from(data));
      }
      // Plot accelerometer values (indices 3, 4, 5) if plotting is enabled.
      if (isPlotting) {
        setState(() {
          chartData.add(ChartData(xValue, data[3], data[4], data[5]));
          if (chartData.length > 50) {
            chartData.removeAt(0);
          }
          xValue++;
        });
      }
    });
  }

  @override
  void dispose() {
    sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sensor Data Chart"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text("Plotting")),
          ),
          Switch(
            value: isPlotting,
            onChanged: (value) {
              setState(() {
                isPlotting = value;
                if (isPlotting) {
                  sensorSubscription?.resume();
                } else {
                  sensorSubscription?.pause();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Recording button placed in the body above the chart.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isRecording) {
                    // When stopping recording, store current data into the global variable.
                    globalRepetition = List<List<double>>.from(currentRepetition);
                  } else {
                    // When starting a new recording, clear the local repetition data.
                    currentRepetition.clear();
                  }
                  isRecording = !isRecording;
                });
              },
              child: Text(isRecording ? "Stop Recording" : "Start Recording"),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SfCartesianChart(
                primaryXAxis: NumericAxis(),
                primaryYAxis: NumericAxis(),
                legend: Legend(isVisible: true),
                series: <ChartSeries>[
                  LineSeries<ChartData, int>(
                    name: 'Acc X',
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.accX,
                    color: Colors.red,
                  ),
                  LineSeries<ChartData, int>(
                    name: 'Acc Y',
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.accY,
                    color: Colors.green,
                  ),
                  LineSeries<ChartData, int>(
                    name: 'Acc Z',
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.accZ,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- RepetitionPage Implementation ----------------
class RepetitionPage extends StatefulWidget {
  const RepetitionPage({Key? key}) : super(key: key);

  @override
  _RepetitionPageState createState() => _RepetitionPageState();
}

class _RepetitionPageState extends State<RepetitionPage> {
  bool showCalibration = false;
  List<double> repetitionError = List.filled(6, 0.0); // Indexes 0-2: Gyro XYZ, 3-5: Accel XYZ
  double accuracyScore = 0.0;

  Future<void> _exportCSV() async {
    // Request storage permission.
    await Permission.storage.request();
    // Create header row.
    List<List<dynamic>> rows = [];
    rows.add(['Gyro X', 'Gyro Y', 'Gyro Z', 'Acc X', 'Acc Y', 'Acc Z']);
    // Append each sample.
    for (List<double> sample in globalRepetition) {
      rows.add(sample);
    }
    // Convert rows to CSV string.
    String csvData = const ListToCsvConverter().convert(rows);
    // [CHANGE] Save CSV to the "Repetitions" folder within the Download directory.
    final path = "/storage/emulated/0/Download/Repetitions/global_repetition.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    print('CSV file saved to: $path');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV file saved to: $path')),
    );
  }

  // [CHANGE] Function to normalize and resample globalRepetition.
  // Resamples the time series to 'targetLength' samples using linear interpolation.
  List<List<double>> normalizeAndResampleRepetition(List<List<double>> rep, int targetLength) {
    List<List<double>> newRep = [];
    int n = rep.length;
    if (n == 0) return newRep;

    // Trim start and end where acceleration X > 9.0
    int startIndex = 0;
    int endIndex = n - 1;

    // Find first valid sample (accX <= 9.0)
    while (startIndex < n && rep[startIndex][3] > 9.0) {
      startIndex++;
    }

    // Find last valid sample (accX <= 9.0)
    while (endIndex >= 0 && rep[endIndex][3] > 9.0) {
      endIndex--;
    }

    if (startIndex > endIndex) return newRep; // No valid data
    List<List<double>> trimmedRep = rep.sublist(startIndex, endIndex + 1);
    int trimmedLength = trimmedRep.length;

    // Original normalization logic with trimmed data
    for (int i = 0; i < targetLength; i++) {
      double t = i * (trimmedLength - 1) / (targetLength - 1);
      int index = t.floor();
      int nextIndex = (index + 1 < trimmedLength) ? index + 1 : index;
      double frac = t - index;
      List<double> sample = [];

      for (int j = 0; j < 6; j++) {
        double v1 = trimmedRep[index][j];
        double v2 = trimmedRep[nextIndex][j];
        double value = v1 + (v2 - v1) * frac;
        sample.add(value);
      }
      newRep.add(sample);
    }

    return newRep;
  }

  // [CHANGE] New function to trigger normalization & resampling.
  Future<void> _normalizeAndResample() async {
    // Choose target length based on experimental value (e.g., 40 samples).
    const int targetLength = 40;
    List<List<double>> newRep = normalizeAndResampleRepetition(globalRepetition, targetLength);
    setState(() {
      globalRepetition = newRep;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Repetition normalized to $targetLength samples')),
    );
  }

  void _calculateAccuracy() {
    if (globalRepetition.isEmpty || globalCalibration.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No repetition or calibration data!')),
      );
      return;
    }

    if (globalRepetition.length != globalCalibration.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data lengths must match! Normalize first.')),
      );
      return;
    }

    List<double> errorSums = List.filled(6, 0.0);

    for (int i = 0; i < globalRepetition.length; i++) {
      List<double> repSample = globalRepetition[i];
      List<double> calSample = globalCalibration[i];

      for (int j = 0; j < 6; j++) {
        double diff = repSample[j] - calSample[j];
        errorSums[j] += diff * diff; // Sum of squared errors
      }
    }

    // Calculate total error (sum all axes)
    double totalError = errorSums.reduce((a, b) => a + b);

    // Convert error to score (0-100) using exponential decay scaling
    // Adjust the 1000 divisor to change sensitivity (higher = more forgiving)
    accuracyScore = 100 * exp(-totalError / 1000);
    accuracyScore = accuracyScore.clamp(0.0, 100.0); // Ensure within bounds

    setState(() {
      repetitionError = errorSums;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Process globalRepetition and globalCalibration to create chart data
    List<ChartData> accData = [];
    List<ChartData> gyroData = [];
    List<ChartData> accCalibrationData = []; // NEW: Calibration acc data
    List<ChartData> gyroCalibrationData = []; // NEW: Calibration gyro data

    for (int i = 0; i < globalRepetition.length; i++) {
      List<double> sample = globalRepetition[i];
      accData.add(ChartData(i, sample[3], sample[4], sample[5]));
      gyroData.add(ChartData(i, sample[0], sample[1], sample[2]));
    }

    // NEW: Process calibration data if needed
    if (showCalibration) {
      for (int i = 0; i < globalCalibration.length; i++) {
        List<double> sample = globalCalibration[i];
        accCalibrationData.add(ChartData(i, sample[3], sample[4], sample[5]));
        gyroCalibrationData.add(ChartData(i, sample[0], sample[1], sample[2]));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Repetition Data")),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportCSV,
        child: const Icon(Icons.save),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: _normalizeAndResample,
                    child: const Text("Normalize & Resample"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () => setState(() => showCalibration = !showCalibration),
                    child: const Text("Show/Hide Calibration"),
                  ),
                ),
                // NEW: Accuracy calculation row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _calculateAccuracy,
                        child: const Text("Calculate Accuracy"),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score: ${accuracyScore.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SfCartesianChart(
                title: ChartTitle(text: "Accelerometer Data"),
                primaryXAxis: NumericAxis(),
                primaryYAxis: NumericAxis(),
                legend: Legend(isVisible: true),
                series: <ChartSeries>[
                  // Original repetition series
                  LineSeries<ChartData, int>(
                    name: 'Acc X',
                    dataSource: accData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.accX,
                    color: Colors.red,
                  ),
                  LineSeries<ChartData, int>(
                    name: 'Acc Y',
                    dataSource: accData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.accY,
                    color: Colors.green,
                  ),
                  LineSeries<ChartData, int>(
                    name: 'Acc Z',
                    dataSource: accData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.accZ,
                    color: Colors.blue,
                  ),
                  // NEW: Calibration series
                  if (showCalibration)
                    LineSeries<ChartData, int>(
                      name: 'Calib Acc X',
                      dataSource: accCalibrationData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.accX,
                      color: Colors.red[800]!, // Darker red
                      dashArray: [5,5], // Dashed line
                    ),
                  if (showCalibration)
                    LineSeries<ChartData, int>(
                      name: 'Calib Acc Y',
                      dataSource: accCalibrationData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.accY,
                      color: Colors.green[800]!, // Darker green
                      dashArray: [5,5],
                    ),
                  if (showCalibration)
                    LineSeries<ChartData, int>(
                      name: 'Calib Acc Z',
                      dataSource: accCalibrationData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.accZ,
                      color: Colors.blue[800]!, // Darker blue
                      dashArray: [5,5],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SfCartesianChart(
                title: ChartTitle(text: "Gyroscope Data"),
                primaryXAxis: NumericAxis(),
                primaryYAxis: NumericAxis(),
                legend: Legend(isVisible: true),
                series: <ChartSeries>[
                  // Original gyro series
                  LineSeries<ChartData, int>(
                    name: 'Gyro X',
                    dataSource: gyroData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.accX,
                    color: Colors.orange,
                  ),
                  LineSeries<ChartData, int>(
                    name: 'Gyro Y',
                    dataSource: gyroData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.accY,
                    color: Colors.purple,
                  ),
                  LineSeries<ChartData, int>(
                    name: 'Gyro Z',
                    dataSource: gyroData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.accZ,
                    color: Colors.teal,
                  ),
                  // NEW: Calibration gyro series
                  if (showCalibration)
                    LineSeries<ChartData, int>(
                      name: 'Calib Gyro X',
                      dataSource: gyroCalibrationData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.accX,
                      color: Colors.orange[800]!,
                      dashArray: [5,5],
                    ),
                  if (showCalibration)
                    LineSeries<ChartData, int>(
                      name: 'Calib Gyro Y',
                      dataSource: gyroCalibrationData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.accY,
                      color: Colors.purple[800]!,
                      dashArray: [5,5],
                    ),
                  if (showCalibration)
                    LineSeries<ChartData, int>(
                      name: 'Calib Gyro Z',
                      dataSource: gyroCalibrationData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.accZ,
                      color: Colors.teal[800]!,
                      dashArray: [5,5],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Data Model ----------------
// Used for both ChartPage and RepetitionPage.
class ChartData {
  final int x;
  final double accX;
  final double accY;
  final double accZ;
  ChartData(this.x, this.accX, this.accY, this.accZ);
}

// ---------------- BLEManager ----------------
class BLEManager {
  static final BLEManager _instance = BLEManager._internal();
  static BLEManager get instance => _instance;
  BLEManager._internal();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? sensorCharacteristic;

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() ==
          "12345678-1234-5678-1234-56789abcdef0") {
        for (var c in service.characteristics) {
          if (c.uuid.toString().toLowerCase() ==
              "12345678-1234-5678-1234-56789abcdef1") {
            sensorCharacteristic = c;
            await sensorCharacteristic!.setNotifyValue(true);
            sensorCharacteristic!.value.listen((value) {
              if (value.length >= 24) {
                ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));
                List<double> sensorValues = [];
                for (int i = 0; i < 6; i++) {
                  sensorValues.add(byteData.getFloat32(i * 4, Endian.little));
                }
                sensorDataController.add(sensorValues);
              }
            });
          }
        }
      }
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
    }
  }
}