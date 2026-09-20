// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ble/layrz_ble.dart';
import 'package:layrz_sdk/layrz_sdk.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui_extensions/layrz_ui_extensions.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final font = OpenSansFont();
  await font.load();
  runApp(MyApp(font: font));
}

class MyApp extends StatelessWidget {
  final LayrzFont font;
  const MyApp({super.key, required this.font});

  @override
  Widget build(BuildContext context) {
    return LayrzApp(
      theme: LayrzThemeData.light(font: font),
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
  final _buttonController = LayrzButtonController();
  bool _isAdvertising = false;
  bool _isBluetoothEnabled = false;
  BleDevice? _selectedDevice;

  String get serviceUuid => '00000000-0000-0000-0000-000000000001';
  String get readCharacteristic => '00000000-0000-0000-0000-000000000002';

  AppThemedAsset get logo => const AppThemedAsset(
    normal: 'https://cdn.layrz.com/resources/layrz/logo/normal.png',
    white: 'https://cdn.layrz.com/resources/layrz/logo/white.png',
  );

  int mtu = 512;
  final plugin = LayrzBle();

  @override
  void initState() {
    super.initState();

    // Sync initial Bluetooth state
    _initializeBluetoothState();

    // Listen to Bluetooth state changes (reactive approach)
    _ble.onBluetoothStateChanged.listen((isEnabled) {
      debugPrint('Bluetooth state changed: $isEnabled');
      setState(() => _isBluetoothEnabled = isEnabled);
    });

    _ble.onScan.listen((BleDevice device) {
      _devices[device.macAddress] = device;
      setState(() {});
    });

    if (LayrzPlatform.isAndroid) {
      _ble.onGattUpdate.listen((BleGattEvent event) {
        if (event is GattWriteRequest) {
          debugPrint('Received GATT write request: ${event.characteristicUuid}');

          debugPrint('\tSending success');
          _ble.respondWriteRequest(
            requestId: event.requestId,
            macAddress: event.macAddress,
            offset: event.offset,
            success: true,
          );
        } else if (event is GattReadRequest) {
          debugPrint('Received GATT read request: ${event.characteristicUuid}');

          _ble.respondReadRequest(
            requestId: event.requestId,
            macAddress: event.macAddress,
            offset: event.offset,
            data: Uint8List.fromList([0x01, 0x02, 0x03, 0x04]),
          );
        } else {
          debugPrint('Received GATT event: $event');
        }
      });
    }

    _ble.onEvent.listen((BleEvent event) {
      if (event is BleDisconnected) {
        debugPrint('Disconnected from device: ${event.macAddress}');
        _selectedDevice = null;
        _services = [];
      }
    });

    _ble.onNotify.listen((BleCharacteristicNotification notification) {
      debugPrint('Received notification: $notification');
    });
  }

  Future<void> _initializeBluetoothState() async {
    try {
      final status = await plugin.getStatuses();
      if (mounted) {
        setState(() => _isBluetoothEnabled = status.isEnabled);
        debugPrint('Initial Bluetooth state: ${status.isEnabled}');
      }
    } catch (e) {
      debugPrint('Error initializing Bluetooth state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayrzLayout(
      logo: context.isDark ? logo.white : logo.normal,
      items: [
        LayrzNavigatorPage(
          id: 'check-capabilities',
          labelText: 'Check capabilities',
          onTap: () async {
            _buttonController.startLoading();
            if (LayrzPlatform.isAndroid) {
              await Permission.location.request();
              await Permission.locationWhenInUse.request();
            }
            if (LayrzPlatform.isIOS || LayrzPlatform.isAndroid) {
              await Permission.bluetooth.request();
            }

            if (LayrzPlatform.isAndroid) {
              await Permission.bluetooth.request();
              await Permission.bluetoothScan.request();
              await Permission.bluetoothConnect.request();
              await Permission.bluetoothAdvertise.request();
            }

            bool result = await plugin.checkCapabilities();
            LayrzSnackbarMessenger.of(context).showSnackbar(
              LayrzSnackbar(
                type: .custom,
                titleText: 'Capabilities',
                descriptionText: '$result',
                color: Colors.blue,
                icon: MdiIcons.bluetooth,
              ),
            );

            await Future.delayed(const Duration(milliseconds: 20));

            result = await plugin.checkScanPermissions();
            LayrzSnackbarMessenger.of(context).showSnackbar(
              LayrzSnackbar(
                type: .custom,
                titleText: 'Scan',
                descriptionText: '$result',
                color: Colors.blue,
                icon: MdiIcons.bluetooth,
              ),
            );

            await Future.delayed(const Duration(milliseconds: 20));

            result = await plugin.checkAdvertisePermissions();
            LayrzSnackbarMessenger.of(context).showSnackbar(
              LayrzSnackbar(
                type: .custom,
                titleText: 'Advertise',
                descriptionText: '$result',
                color: Colors.blue,
                icon: MdiIcons.bluetooth,
              ),
            );

            _buttonController.stopLoading();
          },
        ),
        LayrzNavigatorPage(
          id: 'check_bt_enabled',
          labelText: 'Check BT Enabled',
          onTap: () async {
            _buttonController.startLoading();
            // Refresh status (which will update the reactive stream)
            final status = await plugin.getStatuses();
            debugPrint('Bluetooth state refreshed: ${status.isEnabled}');

            LayrzSnackbarMessenger.of(context).showSnackbar(
              LayrzSnackbar(
                type: .custom,
                titleText: 'Bluetooth',
                descriptionText: status.isEnabled ? "🟢 ON" : "🔴 OFF",
                color: status.isEnabled ? Colors.green : Colors.red,
                icon: MdiIcons.bluetooth,
              ),
            );

            _buttonController.stopLoading();
          },
        ),
        LayrzNavigatorPage(
          id: 'open_bt_settings',
          labelText: 'Open BT Settings',
          onTap: () async {
            _buttonController.startLoading();
            final result = await plugin.openBluetoothSettings();
            debugPrint('openBluetoothSettings result: $result');

            LayrzSnackbarMessenger.of(context).showSnackbar(
              LayrzSnackbar(
                type: .custom,
                titleText: 'Opened Settings',
                descriptionText: '$result',
                color: Colors.orange,
                icon: MdiIcons.bluetooth,
              ),
            );

            _buttonController.stopLoading();
          },
        ),
        if (_selectedDevice != null) ...[
          LayrzNavigatorPage(
            id: 'disconnect_device',
            labelText: 'Disconnect device',
            onTap: () async {
              _buttonController.startLoading();
              final result = await plugin.disconnect();

              if (result == true) {
                _selectedDevice = null;
              }

              _buttonController.stopLoading();
              setState(() {});

              LayrzSnackbarMessenger.of(context).showSnackbar(
                LayrzSnackbar(
                  type: .custom,
                  titleText: 'Disconnected from device',
                  descriptionText: '$result',
                  color: Colors.red,
                  icon: MdiIcons.bluetooth,
                ),
              );
            },
          ),
        ] else ...[
          if (LayrzPlatform.isAndroid) ...[
            if (!_isAdvertising) ...[
              LayrzNavigatorPage(
                id: 'start_ble_advertise',
                labelText: 'Start BLE Advertise',
                onTap: () async {
                  _buttonController.startLoading();
                  _devices = {};
                  _isAdvertising = await plugin.startAdvertise(
                    manufacturerData: [
                      const BleManufacturerData(companyId: 0x1234, data: [0x00, 0x01, 0x02, 0x03]),
                    ],
                    serviceData: [
                      const BleServiceData(uuid: 0x1234, data: [0xff]),
                    ],
                    canConnect: true,
                    allowBluetooth5: true,
                    servicesSpecs: [
                      BleService(
                        uuid: serviceUuid,
                        characteristics: [
                          BleCharacteristic(
                            uuid: readCharacteristic,
                            properties: [BleProperty.read, BleProperty.notify],
                          ),
                          const BleCharacteristic(
                            uuid: '00000000-0000-0000-0000-000000000003',
                            properties: [BleProperty.write],
                          ),
                        ],
                      ),
                    ],
                  );
                  _buttonController.stopLoading();

                  LayrzSnackbarMessenger.of(context).showSnackbar(
                    LayrzSnackbar(
                      type: .custom,
                      titleText: 'Scanning for BLE devices...',
                      descriptionText: 'Scanning for BLE devices...',
                      color: Colors.blue,
                      icon: MdiIcons.bluetooth,
                    ),
                  );
                },
              ),
            ] else ...[
              LayrzNavigatorPage(
                id: 'stop_ble_advertise',
                labelText: 'Stop BLE Advertise',
                onTap: () async {
                  _buttonController.startLoading();
                  final result = await plugin.stopAdvertise();
                  debugPrint('Stop advertise result: $result');
                  if (result == true) {
                    _isAdvertising = false;
                  }

                  _buttonController.stopLoading();
                  setState(() {});

                  LayrzSnackbarMessenger.of(context).showSnackbar(
                    LayrzSnackbar(
                      type: .custom,
                      titleText: 'Advertise stopped',
                      descriptionText: 'Advertise stopped',
                      color: Colors.red,
                      icon: MdiIcons.bluetooth,
                    ),
                  );
                },
              ),
              LayrzNavigatorPage(
                id: 'send_service_update',
                labelText: 'Send Service update',
                onTap: () async {
                  _buttonController.startLoading();
                  final result = await plugin.sendNotification(
                    serviceUuid: serviceUuid,
                    characteristicUuid: readCharacteristic,
                    payload: Uint8List.fromList([0x04, 0x03, 0x02, 0x01, 0x05]),
                    requestConfirmation: false,
                  );
                  debugPrint('Send notification result: $result');
                  _buttonController.stopLoading();
                },
              ),
            ],
          ],
          if (!_isScanning) ...[
            LayrzNavigatorPage(
              id: 'start_ble_scan',
              labelText: 'Start BLE scan',
              onTap: () async {
                _buttonController.startLoading();
                _devices = {};
                _isScanning = await plugin.startScan();
                _buttonController.stopLoading();

                LayrzSnackbarMessenger.of(context).showSnackbar(
                  LayrzSnackbar(
                    type: .custom,
                    titleText: 'Scanning for BLE devices...',
                    descriptionText: 'Scanning for BLE devices...',
                    color: Colors.blue,
                    icon: MdiIcons.bluetooth,
                  ),
                );
              },
            ),
          ] else ...[
            LayrzNavigatorPage(
              id: 'stop_ble_scan',
              labelText: 'Stop BLE scan',
              onTap: () async {
                _buttonController.startLoading();
                final result = await plugin.stopScan();
                debugPrint('Stop scan result: $result');
                if (result == true) {
                  _isScanning = false;
                }

                _buttonController.stopLoading();
                setState(() {});

                LayrzSnackbarMessenger.of(context).showSnackbar(
                  LayrzSnackbar(
                    type: .custom,
                    titleText: 'Scan stopped',
                    descriptionText: 'Scan stopped',
                    color: Colors.red,
                    icon: MdiIcons.bluetooth,
                  ),
                );
              },
            ),
          ],
        ],
      ],
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.bluetooth, color: _isBluetoothEnabled ? Colors.blue : Colors.grey, size: 24),
                const SizedBox(width: 8),
                Text("Layrz BLE Example", style: context.tokens.typography.title),
              ],
            ),
            const SizedBox(height: 10),
            if (_selectedDevice == null) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _deviceList.length,
                  itemBuilder: (context, index) {
                    final device = _deviceList[index];
                    return LayrzTappable(
                      onTap: () async {
                        debugPrint('Selected device: ${device.macAddress}');
                        _buttonController.startLoading();
                        final result = await plugin.connect(macAddress: device.macAddress);
                        if (result == true) {
                          _selectedDevice = device;
                          _services = [];
                        }
                        _buttonController.stopLoading();

                        LayrzSnackbarMessenger.of(context).showSnackbar(
                          LayrzSnackbar(
                            type: .custom,
                            titleText: 'Connected to device',
                            descriptionText: 'Connected to device: ${device.macAddress}',
                            color: Colors.green,
                            icon: MdiIcons.bluetooth,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            LayrzAvatar.icon(icon: MdiIcons.devices, size: 40),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(device.name ?? 'Unknown device', style: context.tokens.typography.body),
                                  Text(
                                    device.macAddress,
                                    style: context.tokens.typography.label,
                                  ),
                                  Text(
                                    'RSSI: ${device.rssi} - TX power: ${device.txPower}',
                                    style: context.tokens.typography.label,
                                  ),
                                  Text(
                                    "Manufacturer data: ${_castManufaturerData(device.manufacturerData)}",
                                    style: context.tokens.typography.label,
                                    maxLines: 10,
                                  ),
                                  Text(
                                    "Service data: ${_castServiceData(device.serviceData)}",
                                    style: context.tokens.typography.label,
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
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _services.map((service) {
                      return Column(
                        children: [
                          Text('Service: ${service.uuid}', style: context.tokens.typography.body),
                          const SizedBox(height: 5),
                          Text('Characteristics:', style: context.tokens.typography.body),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(
                              children: (service.characteristics ?? []).map((characteristic) {
                                return Column(
                                  children: [
                                    Text(
                                      'Characteristic: ${characteristic.uuid}',
                                      style: context.tokens.typography.label,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Properties: ${characteristic.properties}',
                                      style: context.tokens.typography.label,
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
