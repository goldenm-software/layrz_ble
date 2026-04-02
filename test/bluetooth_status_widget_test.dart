import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ble/layrz_ble.dart';
import 'package:layrz_ble/src/platform_interface.dart';
import 'dart:typed_data';
import 'dart:async';

// Fake implementation for testing
class FakeBlePlatform extends LayrzBlePlatform {
  bool _isBluetoothEnabled = true;
  bool _openSettingsCalled = false;
  int _getStatusesCallCount = 0;
  final StreamController<bool> _bluetoothStateController = StreamController<bool>.broadcast();

  void setBluetoothEnabled(bool enabled) {
    _isBluetoothEnabled = enabled;
    _bluetoothStateController.add(enabled);
  }

  bool wasOpenSettingsCalled() => _openSettingsCalled;
  int getStatusesCallCount() => _getStatusesCallCount;

  @override
  Future<BleStatus> getStatuses() async {
    _getStatusesCallCount++;
    _bluetoothStateController.add(_isBluetoothEnabled);
    return BleStatus(
      advertising: false,
      scanning: false,
      isEnabled: _isBluetoothEnabled,
    );
  }

  @override
  Future<bool> openBluetoothSettings() async {
    _openSettingsCalled = true;
    // Simular que se abre correctamente
    return true;
  }

  // Implement other required methods (not used in the test but necessary)
  @override
  bool get isAdvertising => false;

  @override
  bool get isScanning => false;

  @override
  Stream<bool> get onBluetoothStateChanged => _bluetoothStateController.stream;

  @override
  Stream<BleDevice> get onScan => Stream.empty();

  @override
  Stream<BleEvent> get onEvent => Stream.empty();

  @override
  Stream<BleCharacteristicNotification> get onNotify => Stream.empty();

  @override
  Stream<BleGattEvent> get onGattUpdate => Stream.empty();

  @override
  Future<bool> checkCapabilities() async => true;

  @override
  Future<bool> checkScanPermissions() async => true;

  @override
  Future<bool> checkAdvertisePermissions() async => true;

  @override
  Future<bool> startScan({String? macAddress, List<String>? servicesUuids}) async => true;

  @override
  Future<bool> stopScan() async => true;

  @override
  Future<bool> connect({required String macAddress}) async => true;

  @override
  Future<bool> disconnect({String? macAddress}) async => true;

  @override
  Future<int?> setMtu({required String macAddress, required int newMtu}) async => null;

  @override
  Future<List<BleService>?> discoverServices({required String macAddress}) async => null;

  @override
  Future<Uint8List?> readCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) async =>
      null;

  @override
  Future<bool> writeCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    required bool withResponse,
  }) async =>
      true;

  @override
  Future<bool> startNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) async =>
      true;

  @override
  Future<bool> stopNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) async =>
      true;

  @override
  Future<bool> startAdvertise({
    List<BleManufacturerData> manufacturerData = const [],
    List<BleServiceData> serviceData = const [],
    bool canConnect = false,
    List<BleService> servicesSpecs = const [],
    bool allowBluetooth5 = true,
    String? name,
  }) async =>
      true;

  @override
  Future<bool> stopAdvertise() async => true;

  @override
  Future<bool> respondReadRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    Uint8List? data,
  }) async =>
      true;

  @override
  Future<bool> respondWriteRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    required bool success,
  }) async =>
      true;

  @override
  Future<bool> sendNotification({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    bool requestConfirmation = false,
  }) async =>
      true;
}

/// Test widget that shows BLE status
class BluetoothStatusWidget extends StatefulWidget {
  final LayrzBlePlatform blePlatform;
  final VoidCallback? onOpenSettings;

  const BluetoothStatusWidget({
    required this.blePlatform,
    this.onOpenSettings,
    super.key,
  });

  @override
  State<BluetoothStatusWidget> createState() => _BluetoothStatusWidgetState();
}

class _BluetoothStatusWidgetState extends State<BluetoothStatusWidget> {
  bool? isEnabled;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBluetoothStatus();
  }

  Future<void> _loadBluetoothStatus() async {
    try {
      final status = await widget.blePlatform.getStatuses();
      setState(() {
        isEnabled = status.isEnabled;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _openBluetoothSettings() async {
    widget.onOpenSettings?.call();
    final result = await widget.blePlatform.openBluetoothSettings();
    if (result && mounted) {
      // Refrescar estado después
      await Future.delayed(Duration(milliseconds: 500));
      _loadBluetoothStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Bluetooth Status')),
        body: Center(
          child: CircularProgressIndicator(
            key: Key('loading_spinner'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Status')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Visual status
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isEnabled ?? false ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isEnabled ?? false ? '✅ BLE Enabled' : '❌ BLE Disabled',
                key: Key('status_text'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Settings button
            if (!(isEnabled ?? false))
              ElevatedButton.icon(
                key: Key('open_settings_button'),
                onPressed: _openBluetoothSettings,
                icon: Icon(Icons.bluetooth),
                label: Text('Open Bluetooth Settings'),
              ),

            // Refresh button
            SizedBox(height: 10),
            TextButton(
              key: Key('refresh_button'),
              onPressed: () {
                setState(() => isLoading = true);
                _loadBluetoothStatus();
              },
              child: Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('Bluetooth Status Widget Tests - isEnabled & openBluetoothSettings', () {
    testWidgets('Shows spinner while loading status', (WidgetTester tester) async {
      final fake = FakeBlePlatform();

      await tester.pumpWidget(
        MaterialApp(
          home: BluetoothStatusWidget(blePlatform: fake),
        ),
      );

      // Check that the spinner is visible
      expect(find.byKey(Key('loading_spinner')), findsOneWidget);
      expect(find.byKey(Key('status_text')), findsNothing);

      // Wait for loading
      await tester.pumpAndSettle();

      // Spinner should disappear
      expect(find.byKey(Key('loading_spinner')), findsNothing);
      expect(find.byKey(Key('status_text')), findsOneWidget);
    });

    testWidgets('✅ Shows BLE ENABLED when isEnabled=true', (WidgetTester tester) async {
      final fake = FakeBlePlatform();
      fake.setBluetoothEnabled(true);

      await tester.pumpWidget(
        MaterialApp(
          home: BluetoothStatusWidget(blePlatform: fake),
        ),
      );

      await tester.pumpAndSettle();

      // Check that it shows "BLE Enabled"
      expect(find.text('✅ BLE Enabled'), findsOneWidget);

      // Should not show settings button
      expect(find.byKey(Key('open_settings_button')), findsNothing);

      // Check that getStatuses() was called
      expect(fake.getStatusesCallCount(), 1);
    });

    testWidgets('❌ Shows BLE DISABLED when isEnabled=false', (WidgetTester tester) async {
      final fake = FakeBlePlatform();
      fake.setBluetoothEnabled(false);

      await tester.pumpWidget(
        MaterialApp(
          home: BluetoothStatusWidget(blePlatform: fake),
        ),
      );

      await tester.pumpAndSettle();

      // Check that it shows "BLE Disabled"
      expect(find.text('❌ BLE Disabled'), findsOneWidget);

      // Should show settings button
      expect(find.byKey(Key('open_settings_button')), findsOneWidget);
    });

    testWidgets('🎯 Calls openBluetoothSettings when button is pressed', (WidgetTester tester) async {
      final fake = FakeBlePlatform();
      fake.setBluetoothEnabled(false);

      bool settingsOpenedCallback = false;

      await tester.pumpWidget(
        MaterialApp(
          home: BluetoothStatusWidget(
            blePlatform: fake,
            onOpenSettings: () => settingsOpenedCallback = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that the button exists
      expect(find.byKey(Key('open_settings_button')), findsOneWidget);

      // Tap the button
      await tester.tap(find.byKey(Key('open_settings_button')));
      await tester.pumpAndSettle();

      // Check that openBluetoothSettings was called
      expect(fake.wasOpenSettingsCalled(), true);

      // Check that the callback was called
      expect(settingsOpenedCallback, true);
    });

    testWidgets('Refresh button calls getStatuses again', (WidgetTester tester) async {
      final fake = FakeBlePlatform();
      fake.setBluetoothEnabled(true);

      await tester.pumpWidget(
        MaterialApp(
          home: BluetoothStatusWidget(blePlatform: fake),
        ),
      );

      await tester.pumpAndSettle();

      // Check that it was called once
      expect(fake.getStatusesCallCount(), 1);

      // Tap refresh button
      await tester.tap(find.byKey(Key('refresh_button')));
      await tester.pumpAndSettle();

      // Check that it was called again (2 times total)
      expect(fake.getStatusesCallCount(), 2);
    });

    testWidgets('⭐ Real flow: disabled → open settings → enabled', (WidgetTester tester) async {
      final fake = FakeBlePlatform();

      // Initially disabled
      fake.setBluetoothEnabled(false);

      await tester.pumpWidget(
        MaterialApp(
          home: BluetoothStatusWidget(blePlatform: fake),
        ),
      );

      await tester.pumpAndSettle();

      // Should show disabled with button
      expect(find.text('❌ BLE Disabled'), findsOneWidget);
      expect(find.byKey(Key('open_settings_button')), findsOneWidget);

      // User taps button to open settings
      await tester.tap(find.byKey(Key('open_settings_button')));
      await tester.pumpAndSettle();

      // Check that settings were opened
      expect(fake.wasOpenSettingsCalled(), true);

      // User enables BLE in settings and returns
      // Simulate that now isEnabled=true
      fake.setBluetoothEnabled(true);

      // Refresh status
      await tester.tap(find.byKey(Key('refresh_button')));
      await tester.pumpAndSettle();

      // Now should show enabled without button
      expect(find.text('✅ BLE Enabled'), findsOneWidget);
      expect(find.byKey(Key('open_settings_button')), findsNothing);
    });

    testWidgets('Dynamic change: enabled → disabled → enabled', (WidgetTester tester) async {
      final fake = FakeBlePlatform();
      fake.setBluetoothEnabled(true);

      await tester.pumpWidget(
        MaterialApp(
          home: BluetoothStatusWidget(blePlatform: fake),
        ),
      );

      await tester.pumpAndSettle();

      // Initially enabled
      expect(find.text('✅ BLE Enabled'), findsOneWidget);

      // User disables BLE from settings
      fake.setBluetoothEnabled(false);
      await tester.tap(find.byKey(Key('refresh_button')));
      await tester.pumpAndSettle();

      // Now shows disabled with button
      expect(find.text('❌ BLE Disabled'), findsOneWidget);
      expect(find.byKey(Key('open_settings_button')), findsOneWidget);

      // User enables it again
      fake.setBluetoothEnabled(true);
      await tester.tap(find.byKey(Key('refresh_button')));
      await tester.pumpAndSettle();

      // Shows enabled again
      expect(find.text('✅ BLE Enabled'), findsOneWidget);
      expect(find.byKey(Key('open_settings_button')), findsNothing);
    });

    testWidgets('Multiple refreshes with variable state', (WidgetTester tester) async {
      final fake = FakeBlePlatform();
      fake.setBluetoothEnabled(true);

      await tester.pumpWidget(
        MaterialApp(
          home: BluetoothStatusWidget(blePlatform: fake),
        ),
      );

      await tester.pumpAndSettle();

      // Refresh 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('refresh_button')));
        await tester.pumpAndSettle();
      }

      // Should have called getStatuses 6 times (1 initial + 5 refreshes)
      expect(fake.getStatusesCallCount(), 6);

      // UI should be consistent
      expect(find.text('✅ BLE Enabled'), findsOneWidget);
    });
  });
}
