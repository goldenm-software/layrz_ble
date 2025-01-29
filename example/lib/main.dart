// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

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
  List<BleService> _services = [];

  bool _isScanning = false;
  bool _isLoading = false;
  BleDevice? _selectedDevice;

  String get payload => "<Ac>1;get_msg;;E37A;5367</Ac>";
  String get serviceId => "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  String get readCharacteristic => "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  String get writeCharacteristic => "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

  List<String> get servicesUuids => [serviceId, readCharacteristic, writeCharacteristic];

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
      _devices[device.macAddress] = device;
      setState(() {});
    });

    _ble.onEvent.listen((BleEvent event) {
      switch (event) {
        case BleEvent.connected:
          debugPrint('Connected to device');
          break;
        case BleEvent.disconnected:
          debugPrint('Disconnected from device');
          _selectedDevice = null;
          setState(() {});
          break;
        case BleEvent.scanStopped:
          debugPrint('Scan stopped');
          _isScanning = false;
          setState(() {});
          break;
        default:
          break;
      }
    });

    _ble.onNotify.listen((BleCharacteristicNotification notification) {
      debugPrint('Received notification: $notification');
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
            Row(
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
                    }

                    final result = await plugin.checkCapabilities();

                    setState(() => _isLoading = false);
                    debugPrint('Start scan result: $result');

                    ThemedSnackbarMessenger.of(context).showSnackbar(
                      ThemedSnackbar(
                        message: 'Capabilities: $result',
                        color: Colors.blue,
                        icon: LayrzIcons.solarOutlineBluetoothSquare,
                        maxLines: 5,
                      ),
                    );
                  },
                ),
                if (_selectedDevice != null) ...[
                  const SizedBox(width: 10),
                  ThemedButton(
                    isLoading: _isLoading,
                    labelText: 'Disconnect device',
                    color: Colors.red,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      final result = await plugin.disconnect();

                      if (result == true) {
                        _selectedDevice = null;
                      }

                      _isLoading = false;
                      setState(() {});

                      ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                        message: 'Disconnected from device',
                        color: Colors.red,
                        icon: LayrzIcons.solarOutlineBluetoothSquare,
                      ));
                    },
                  ),
                ] else ...[
                  if (!_isScanning) ...[
                    const SizedBox(width: 10),
                    ThemedButton(
                      isLoading: _isLoading,
                      labelText: 'Start BLE scan',
                      color: Colors.green,
                      onTap: () async {
                        setState(() => _isLoading = true);
                        _devices = {};
                        _isScanning = await plugin.startScan(
                                // macAddress: 'FE:D7:0C:C1:4B:43', // ELA PUCK RHT
                                // macAddress: 'D8:3A:DD:B0:0E:5F', // SIMULATOR
                                ) ??
                            false;
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
              ],
            ),
            const SizedBox(height: 10),
            if (_selectedDevice == null) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _deviceList.length,
                  itemBuilder: (context, index) {
                    final device = _deviceList[index];
                    return InkWell(
                      onTap: () async {
                        debugPrint('Selected device: ${device.macAddress}');
                        setState(() => _isLoading = true);
                        final result = await plugin.connect(
                          macAddress: device.macAddress,
                        );
                        if (result == true) {
                          _selectedDevice = device;
                          _services = [];
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
                                  Text(
                                    "Manufacturer data: ${_castManufaturerData(device.manufacturerData)}",
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 10,
                                  ),
                                  Text(
                                    "Service data: ${_castServiceData(device.serviceData)}",
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 10,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ThemedButton(
                    color: Colors.blue,
                    labelText: 'Discover services',
                    isLoading: _isLoading,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      _services = await plugin.discoverServices() ?? [];
                      setState(() => _isLoading = false);

                      ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                        message: 'Discovered ${_services.length} services',
                        color: Colors.blue,
                        icon: LayrzIcons.solarOutlineBluetoothSquare,
                      ));
                    },
                  ),
                  const SizedBox(width: 10),
                  ThemedButton(
                    color: Colors.orange,
                    labelText: 'Set MTU to 512',
                    isLoading: _isLoading,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      final result = await plugin.setMtu(newMtu: 512);
                      debugPrint('Set MTU result: $result');
                      setState(() => _isLoading = false);

                      if (result != null) {
                        mtu = result;
                        setState(() {});
                      }

                      ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                        message: 'Set MTU to $result after a negotiation',
                        color: Colors.orange,
                        icon: LayrzIcons.solarOutlineBluetoothSquare,
                      ));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ThemedButton(
                    color: Colors.orange,
                    labelText: 'Set notification listener',
                    isLoading: _isLoading,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      final result = await plugin.startNotify(
                        serviceUuid: serviceId,
                        characteristicUuid: readCharacteristic,
                      );
                      debugPrint('Set notification listener result: $result');
                      setState(() => _isLoading = false);

                      ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                        message: 'Notification listener set: $result',
                        color: Colors.orange,
                        icon: LayrzIcons.solarOutlineBluetoothSquare,
                      ));
                    },
                  ),
                  const SizedBox(width: 10),
                  ThemedButton(
                    color: Colors.orange,
                    labelText: 'Set notification listener off',
                    isLoading: _isLoading,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      final result = await plugin.stopNotify(
                        serviceUuid: serviceId,
                        characteristicUuid: readCharacteristic,
                      );
                      debugPrint('Set notification listener result: $result');
                      setState(() => _isLoading = false);

                      ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                        message: 'Notification listener set: $result',
                        color: Colors.orange,
                        icon: LayrzIcons.solarOutlineBluetoothSquare,
                      ));
                    },
                  ),
                  const SizedBox(width: 10),
                  ThemedButton(
                    color: Colors.blue,
                    labelText: 'Send a payload',
                    isLoading: _isLoading,
                    onTap: () async {
                      setState(() => _isLoading = true);

                      debugPrint("Sending header");
                      await plugin.writeCharacteristic(
                        serviceUuid: serviceId,
                        characteristicUuid: writeCharacteristic,
                        payload: Uint8List.fromList("##${payload.length};1".codeUnits),
                        withResponse: true,
                      );

                      debugPrint("Sending payload");
                      await plugin.writeCharacteristic(
                        serviceUuid: serviceId,
                        characteristicUuid: writeCharacteristic,
                        payload: Uint8List.fromList(payload.codeUnits),
                        withResponse: true,
                      );

                      setState(() => _isLoading = false);

                      ThemedSnackbarMessenger.of(context).showSnackbar(ThemedSnackbar(
                        message: 'Payload sent',
                        color: Colors.blue,
                        icon: LayrzIcons.solarOutlineBluetoothSquare,
                      ));

                      final result = await plugin.readCharacteristic(
                        serviceUuid: serviceId,
                        characteristicUuid: readCharacteristic,
                      );

                      debugPrint('Read characteristic result: ${ascii.decode(result?.toList() ?? [])}');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _services.map((service) {
                      return Column(
                        children: [
                          Text(
                            'Service: ${service.uuid}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Characteristics:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              children: (service.characteristics ?? []).map((characteristic) {
                                return Column(
                                  children: [
                                    Text(
                                      'Characteristic: ${characteristic.uuid}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Properties: ${characteristic.properties}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _castUintToString(List<int>? data) {
    if (data == null) return 'Not provided';
    if (data.isEmpty) return 'Empty';
    return data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  String _castManufaturerData(List<BleManufacturerData> data) {
    if (data.isEmpty) return 'Empty';

    List<String> result = [];
    for (final manufacturerData in data) {
      result.add(
        'Company ID: ${manufacturerData.companyId.toRadixString(16).padLeft(4, '0')} - '
        'Data: ${_castUintToString(manufacturerData.data)}',
      );
    }

    return result.join('\n');
  }

  String _castServiceData(List<BleServiceData>? data) {
    if (data == null) return 'Not provided';
    if (data.isEmpty) return 'Empty';
    List<String> result = [];

    for (final serviceData in data) {
      result.add(
        'Service: ${serviceData.uuid.toRadixString(16).padLeft(4, '0')} - '
        'Data: ${_castUintToString(serviceData.data)}',
      );
    }
    return result.join('\n');
  }
}
