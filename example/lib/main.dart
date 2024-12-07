import 'package:flutter/material.dart';
import 'package:layrz_ble/layrz_ble.dart';
import 'package:layrz_ble/layrz_ble_web.dart';
import 'package:layrz_models/layrz_models.dart';
import 'package:layrz_theme/layrz_theme.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _ble = LayrzBle();
  final web = LayrzBleWeb()
    ..onEvent.listen((e) {
      // pass
    });
  AppThemedAsset get logo => const AppThemedAsset(
        normal: 'https://cdn.layrz.com/resources/layrz/logo/normal.png',
        white: 'https://cdn.layrz.com/resources/layrz/logo/white.png',
      );
  AppThemedAsset get favicon => const AppThemedAsset(
        normal: 'https://cdn.layrz.com/resources/layrz/favicon/normal.png',
        white: 'https://cdn.layrz.com/resources/layrz/favicon/white.png',
      );
  final plugin = LayrzBle();

  @override
  void initState() {
    super.initState();

    _ble.onScan.listen((BleDevice device) {
      debugPrint('Device found: ${device.macAddress} - ${device.name}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: generateLightTheme(),
      home: ThemedLayout(
        logo: logo,
        favicon: favicon,
        appTitle: 'Layrz BLE Example',
        body: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(
                "Layrz BLE Example",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ThemedButton(
                labelText: 'Check capabilities',
                onTap: () async {
                  await Permission.location.request();
                  await Permission.bluetooth.request();
                  await Permission.bluetoothScan.request();
                  await Permission.bluetoothConnect.request();

                  final result = await plugin.checkCapabilities();
                  debugPrint('Start scan result: $result');
                },
              ),
              const SizedBox(height: 10),
              ThemedButton(
                labelText: 'Start BLE scan',
                onTap: () async {
                  final result = await plugin.startScan();
                  debugPrint('Start scan result: $result');
                },
              ),
              const SizedBox(height: 10),
              ThemedButton(
                labelText: 'Stop BLE scan',
                onTap: () async {
                  final result = await plugin.stopScan();
                  debugPrint('Stop scan result: $result');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
