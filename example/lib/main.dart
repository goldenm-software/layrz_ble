// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:layrz_ble/layrz_ble.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_models/layrz_models.dart';
import 'package:layrz_theme/layrz_theme.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: generateLightTheme(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ThemedSnackbarMessenger(
          child: child ?? const SizedBox(),
        );
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _ble = LayrzBle();
  Map<String, BleDevice> _devices = {};
  List<BleDevice> get _deviceList => _devices.values.toList();
  final List<String> _connectedDevices = [];
  final Map<String, Timer> _timers = {};

  bool _isScanning = false;
  bool _isLoading = false;

  String get serviceUuid => '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  String get readCharacteristic => '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  String get writeCharacteristic => '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  AppThemedAsset get logo => const AppThemedAsset(
        normal: 'https://cdn.layrz.com/resources/layrz/logo/normal.png',
        white: 'https://cdn.layrz.com/resources/layrz/logo/white.png',
      );
  AppThemedAsset get favicon => const AppThemedAsset(
        normal: 'https://cdn.layrz.com/resources/layrz/favicon/normal.png',
        white: 'https://cdn.layrz.com/resources/layrz/favicon/white.png',
      );

  int mtu = 512;
  final plugin = LayrzBle();

  @override
  void initState() {
    super.initState();

    _ble.onScan.listen((BleDevice device) {
      // if (device.manufacturerDataMap[0x0f17] == null) return;
      _devices[device.macAddress] = device;
      setState(() {});
    });

    _ble.onNotify.listen((BleCharacteristicNotification notification) {
      debugPrint('Received notification: ${notification.macAddress} - ${notification.value.length}');
    });

    _ble.onEvent.listen((event) {
      if (event is BleConnected) {
        debugPrint('Connected to device: ${event.macAddress}');
        _connectedDevices.add(event.macAddress);
        setState(() {});
        return;
      }

      if (event is BleDisconnected) {
        debugPrint('Disconnected from device: ${event.macAddress}');
        _connectedDevices.remove(event.macAddress);
        setState(() {});
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemedLayout(
      logo: logo,
      favicon: favicon,
      appTitle: 'Layrz BLE Example',
      enableNotifications: false,
      userDynamicAvatar: Avatar(
        type: AvatarType.icon,
        icon: LayrzIconsClasses.solarOutlineUser,
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Text(
              "Layrz BLE Example",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ThemedButton(
                    isLoading: _isLoading,
                    labelText: 'Check capabilities',
                    color: Colors.blue,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      if (ThemedPlatform.isAndroid) {
                        await Permission.location.request();
                        await Permission.locationWhenInUse.request();
                      }
                      if (!ThemedPlatform.isMacOS && !ThemedPlatform.isWeb) {
                        await Permission.bluetooth.request();
                      }

                      if (ThemedPlatform.isAndroid) {
                        await Permission.bluetooth.request();
                        await Permission.bluetoothScan.request();
                        await Permission.bluetoothConnect.request();
                        await Permission.bluetoothAdvertise.request();
                      }

                      bool result = await plugin.checkCapabilities();
                      ThemedSnackbarMessenger.of(context).showSnackbar(
                        ThemedSnackbar(
                          message: 'Capabilities: $result',
                          color: Colors.blue,
                          icon: LayrzIcons.solarOutlineBluetoothSquare,
                          maxLines: 5,
                        ),
                      );

                      await Future.delayed(const Duration(milliseconds: 20));

                      result = await plugin.checkScanPermissions();
                      ThemedSnackbarMessenger.of(context).showSnackbar(
                        ThemedSnackbar(
                          message: 'Scan: $result',
                          color: Colors.blue,
                          icon: LayrzIcons.solarOutlineBluetoothSquare,
                          maxLines: 5,
                        ),
                      );

                      await Future.delayed(const Duration(milliseconds: 20));

                      result = await plugin.checkAdvertisePermissions();
                      ThemedSnackbarMessenger.of(context).showSnackbar(
                        ThemedSnackbar(
                          message: 'Advertise: $result',
                          color: Colors.blue,
                          icon: LayrzIcons.solarOutlineBluetoothSquare,
                          maxLines: 5,
                        ),
                      );

                      setState(() => _isLoading = false);
                    },
                  ),
                  const SizedBox(width: 10),
                  ThemedButton(
                    isLoading: _isLoading,
                    labelText: 'Get statuses',
                    color: Colors.green,
                    onTap: () async {
                      setState(() => _isLoading = true);

                      final output = await plugin.getStatuses();
                      setState(() => _isLoading = false);

                      ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                        message: 'Statuses: $output',
                        color: Colors.blue,
                        icon: LayrzIcons.solarOutlineBluetoothSquare,
                      ));
                    },
                  ),
                  if (!_isScanning) ...[
                    const SizedBox(width: 10),
                    ThemedButton(
                      isLoading: _isLoading,
                      labelText: 'Start BLE scan',
                      color: Colors.green,
                      onTap: () async {
                        setState(() => _isLoading = true);
                        _devices = {};
                        _isScanning = await plugin.startScan() ?? false;
                        setState(() => _isLoading = false);

                        ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                          message: 'Scanning for BLE devices...',
                          color: Colors.blue,
                          icon: LayrzIcons.solarOutlineBluetoothSquare,
                        ));
                      },
                    ),
                  ] else ...[
                    const SizedBox(width: 10),
                    ThemedButton(
                      isLoading: _isLoading,
                      labelText: 'Stop BLE scan',
                      color: Colors.red,
                      onTap: () async {
                        setState(() => _isLoading = true);
                        final result = await plugin.stopScan();
                        debugPrint('Stop scan result: $result');
                        if (result == true) {
                          _isScanning = false;
                        }

                        _isLoading = false;
                        setState(() {});

                        ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                          message: 'Scan stopped',
                          color: Colors.red,
                          icon: LayrzIcons.solarOutlineBluetoothSquare,
                        ));
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _deviceList.length,
                itemBuilder: (context, index) {
                  final device = _deviceList[index];
                  return InkWell(
                    onTap: () async {
                      debugPrint('Selected device: ${device.macAddress}');
                      setState(() => _isLoading = true);
                      if (_connectedDevices.contains(device.macAddress)) {
                        await _ble.stopNotify(
                          macAddress: device.macAddress,
                          serviceUuid: serviceUuid,
                          characteristicUuid: readCharacteristic,
                        );
                        await _ble.disconnect(macAddress: device.macAddress);
                        _connectedDevices.remove(device.macAddress);
                        _timers[device.macAddress]?.cancel();
                        _timers.remove(device.macAddress);
                      } else {
                        await plugin.connect(macAddress: device.macAddress);
                        _connectedDevices.add(device.macAddress);

                        final sub = await _ble.startNotify(
                          macAddress: device.macAddress,
                          serviceUuid: serviceUuid,
                          characteristicUuid: readCharacteristic,
                        );
                        debugPrint('Notification subscription: $sub');
                        if (sub == true) {
                          _timers[device.macAddress] = Timer.periodic(const Duration(seconds: 5), (timer) {
                            _sendPing(device.macAddress);
                          });
                        }
                      }
                      setState(() => _isLoading = false);

                      ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                        message: 'Connected to device: ${device.macAddress}',
                        color: Colors.green,
                        icon: LayrzIcons.solarOutlineBluetoothSquare,
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          ThemedAvatar(
                            icon: LayrzIcons.solarOutlineIPhone,
                            size: 40,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name ?? 'Unknown device',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  device.macAddress,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (_connectedDevices.contains(device.macAddress)) ...[
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ] else ...[
                            const Icon(
                              Icons.circle,
                              color: Colors.red,
                            ),
                          ],
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

  void _sendPing(String macAddress) async {
    String payload = '<Ac>1;ping;;19EE;5DAA</Ac>';

    final result = await plugin.setMtu(macAddress: macAddress, newMtu: 512);
    debugPrint('Set MTU result: $result');

    int chunks = (payload.length / mtu).ceil();
    debugPrint('Payload length: ${payload.length}, chunks: $chunks');

    _ble.writeCharacteristic(
      macAddress: macAddress,
      serviceUuid: serviceUuid,
      characteristicUuid: writeCharacteristic,
      payload: ascii.encode("##${payload.length};$chunks"),
      withResponse: true,
    );

    await Future.delayed(const Duration(milliseconds: 200));

    for (int i = 0; i < chunks; i++) {
      int start = i * mtu;
      int end = (i + 1) * mtu;

      if (end > payload.length) end = payload.length;

      String chunk = payload.substring(start, end);

      debugPrint('Sending chunk: $chunk');
      _ble.writeCharacteristic(
        macAddress: macAddress,
        serviceUuid: serviceUuid,
        characteristicUuid: writeCharacteristic,
        payload: ascii.encode(chunk),
        withResponse: true,
      );
    }
  }
}
