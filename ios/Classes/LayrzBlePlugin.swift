import Flutter
import UIKit
import CoreBluetooth

public class LayrzBlePlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {
    static var channel: FlutterMethodChannel?
    var lastResult: FlutterResult?
    var centralManager: CBCentralManager!
    var discoveredPeripherals: [CBPeripheral] = []
    var isScanning: Bool = false
    var devices: [String: CBPeripheral] = [:]
    var filteredUuid: String?
    var connectedPeripheral: CBPeripheral?
    var servicesAndCharacteristics: [String: BleService?] = [:]
    var lastOp: LastOperation?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "com.layrz.layrz_ble", binaryMessenger: registrar.messenger())
        let instance = LayrzBlePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel!)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        log("Handling method call: \(call.method)")
        switch call.method {
        case "checkCapabilities":
            checkCapabilities(result: result)
        case "startScan":
            startScan(call: call, result: result)
        case "stopScan":
            stopScan(call: call, result: result)
        case "connect":
            connect(call: call, result: result)
        case "disconnect":
            disconnect(call: call, result: result)
        case "discoverServices":
            discoverServices(call: call, result: result)
        case "setMtu":
            setMtu(call: call, result: result)
        case "writeCharacteristic":
            writeCharacteristic(call: call, result: result)
        case "readCharacteristic":
            readCharacteristic(call: call, result: result)
        case "startNotify":
            startNotify(call: call, result: result)
        case "stopNotify":
            stopNotify(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func checkCapabilities(result: @escaping FlutterResult) {
        let auth = CBCentralManager.authorization
        
        return result([
            "locationPermission": auth == .allowedAlways,
            "bluetoothPermission": auth == .allowedAlways,
            "bluetoothAdminOrScanPermission": auth == .allowedAlways,
            "bluetoothConnectPermission": auth == .allowedAlways
        ])
    }
    
    private func startScan(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (isScanning) {
            return result(true)
        }
        
        let auth = CBCentralManager.authorization
        if (auth != .allowedAlways) {
            log("Bluetooth permission denied - \(auth)")
            return result(false)
        }
        if (centralManager.state != .poweredOn) {
            log("Bluetooth is not turned on - \(centralManager.state)")
            return result(false)
        }
        
        let args = call.arguments as? [String: Any] ?? [:]
        filteredUuid = (args["macAddress"] as? String)?.lowercased()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        isScanning = true
        return result(true)
    }
    
    private func stopScan(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (!isScanning) {
            return result(true)
        }
        
        centralManager.stopScan()
        isScanning = false
        return result(true)
    }
    
    private func connect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        connectedPeripheral = nil
        let uuid = (call.arguments as? String)?.uppercased()
        if (uuid == nil) {
            log("UUID not defined")
            return result(false)
        }
        
        if let device = devices[uuid!] {
            if (isScanning) {
                centralManager.stopScan()
                isScanning = false
            }
            
            lastResult = result
            
            centralManager.connect(device)
        } else {
            log("Device not found")
            return result(false)
        }
    }
    
    private func disconnect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (connectedPeripheral != nil) {
            centralManager.cancelPeripheralConnection(connectedPeripheral!)
        }
        
        servicesAndCharacteristics.removeAll()
        return result(true)
    }
    
    private func discoverServices(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (connectedPeripheral == nil) {
            return result(nil)
        }
        
        var output: [[String: Any]] = []
        for (_, service) in servicesAndCharacteristics {
            if service == nil { continue }
            output.append(service!.toDictionary())
        }
        return result(output)
    }
    
    private func setMtu(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if connectedPeripheral == nil {
            return result(nil)
        }
        
        let mtu = connectedPeripheral!.maximumWriteValueLength(for: .withResponse)
        return result(mtu)
    }
    
    private func writeCharacteristic(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let serviceUuid = (args["serviceUuid"] as? String)?.uppercased()
        if serviceUuid == nil {
            log("Service UUID not defined")
            return result(false)
        }
        
        guard let service = servicesAndCharacteristics.first(where: { $0.value != nil && $0.value!.uuidString == serviceUuid })?.value else {
            log("Service not found")
            return result(false)
        }
        
        let characteristicUuid = (args["characteristicUuid"] as? String)?.uppercased()
        if characteristicUuid == nil {
            log("Characteristic UUID not defined")
            return result(false)
        }
        
        guard let characteristic = service.characteristics.first(where: { $0.uuidString == characteristicUuid }) else {
            log("Characteristic not found")
            return result(false)
        }
        
        let payload = args["payload"] as? FlutterStandardTypedData
        if payload == nil {
            log("Payload not defined")
            return result(false)
        }
        
        let withResponse = args["withResponse"] as? Bool ?? false
        
        if connectedPeripheral == nil {
            log("Device is not connected")
            return result(false)
        }
        
        lastResult = result
        connectedPeripheral!.writeValue(payload!.data, for: characteristic.characteristic, type: withResponse ? .withResponse : .withoutResponse)
    }
    
    private func readCharacteristic(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let serviceUuid = (args["serviceUuid"] as? String)?.uppercased()
        if serviceUuid == nil {
            log("Service UUID not defined")
            return result(nil)
        }
        
        guard let service = servicesAndCharacteristics.first(where: { $0.value != nil && $0.value!.uuidString == serviceUuid })?.value else {
            log("Service not found")
            return result(nil)
        }
        
        let characteristicUuid = (args["characteristicUuid"] as? String)?.uppercased()
        if characteristicUuid == nil {
            log("Characteristic UUID not defined")
            return result(nil)
        }
        
        guard let characteristic = service.characteristics.first(where: { $0.uuidString == characteristicUuid }) else {
            log("Characteristic not found")
            return result(nil)
        }
        
        if connectedPeripheral == nil {
            log("Device is not connected")
            return result(nil)
        }
        
        if characteristic.characteristic.isNotifying {
            log("Characteristic is notifying, cannot read it.")
            return result(nil)
        }
        
        lastResult = result
        connectedPeripheral!.readValue(for: characteristic.characteristic)
    }
    
    private func startNotify(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let serviceUuid = (args["serviceUuid"] as? String)?.uppercased()
        if serviceUuid == nil {
            log("Service UUID not defined")
            return result(nil)
        }
        
        guard let service = servicesAndCharacteristics.first(where: { $0.value != nil && $0.value!.uuidString == serviceUuid })?.value else {
            log("Service not found")
            return result(false)
        }
        
        let characteristicUuid = (args["characteristicUuid"] as? String)?.uppercased()
        if characteristicUuid == nil {
            log("Characteristic UUID not defined")
            return result(nil)
        }
        
        guard let characteristic = service.characteristics.first(where: { $0.uuidString == characteristicUuid }) else {
            log("Characteristic not found")
            return result(false)
        }
        
        if connectedPeripheral == nil {
            log("Device is not connected")
            return result(false)
        }
        
        connectedPeripheral!.setNotifyValue(true, for: characteristic.characteristic)
        log("Notify started")
        return result(true)
    }
    
    private func stopNotify(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let serviceUuid = (args["serviceUuid"] as? String)?.uppercased()
        if serviceUuid == nil {
            log("Service UUID not defined")
            return result(nil)
        }
        
        guard let service = servicesAndCharacteristics.first(where: { $0.value != nil && $0.value!.uuidString == serviceUuid })?.value else {
            log("Service not found")
            return result(false)
        }
        
        let characteristicUuid = (args["characteristicUuid"] as? String)?.uppercased()
        if characteristicUuid == nil {
            log("Characteristic UUID not defined")
            return result(nil)
        }
        
        guard let characteristic = service.characteristics.first(where: { $0.uuidString == characteristicUuid }) else {
            log("Characteristic not found")
            return result(false)
        }
        
        if connectedPeripheral == nil {
            log("Device is not connected")
            return result(false)
        }
        
        connectedPeripheral!.setNotifyValue(false, for: characteristic.characteristic)
        return result(true)
    }
    
    // Peripheral delegate
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            log("Error updating notification state: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            log("Notification started")
        } else {
            log("Notification stopped")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            log("Error writing value: \(error.localizedDescription)")
            lastResult?(false)
            lastResult = nil
            return
        }
        
        log("Payload sent successfully")
        lastResult?(true)
        lastResult = nil
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            log("Error reading value: \(error.localizedDescription)")
            lastResult?(nil)
            lastResult = nil
            return
        }
        
        if characteristic.isNotifying {
            let notification: [String: Any?] = [
                "serviceUuid": characteristic.service?.uuid.uuidString.uppercased(),
                "characteristicUuid": characteristic.uuid.uuidString.uppercased(),
                "value": characteristic.value
            ]
            
            LayrzBlePlugin.channel!.invokeMethod("onNotify", arguments: notification)
        } else {
            lastResult?(characteristic.value)
            lastResult = nil
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString.uppercased()
        log("Discovering services of \(uuid)")
        if let error = error {
            log("Error discovering services: \(error.localizedDescription)")
            lastResult?(nil)
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            servicesAndCharacteristics.updateValue(nil, forKey: service.uuid.uuidString.uppercased())
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error = error {
            log("Error discovering services - \(error.localizedDescription)")
            return
        }
        
        let serviceUuid = service.uuid.uuidString.uppercased()
        
        guard let characteristics = service.characteristics else { return }
        
        var characteristicsParsed: [BleCharacteristic] = []
        for characteristic in characteristics {
            var propertiesList: [String] = []
            let properties = characteristic.properties
            if properties.contains(.read) { propertiesList.append("READ") }
            if properties.contains(.write) { propertiesList.append("WRITE") }
            if properties.contains(.writeWithoutResponse) { propertiesList.append("WRITE_WO_RSP") }
            if properties.contains(.notify) { propertiesList.append("NOTIFY") }
            if properties.contains(.indicate) { propertiesList.append("INDICATE") }
            if properties.contains(.authenticatedSignedWrites) { propertiesList.append("AUTH_SIGN_WRITES") }
            if properties.contains(.broadcast) { propertiesList.append("BROADCAST") }
            if properties.contains(.extendedProperties) { propertiesList.append("EXTENDED_PROP") }
            
            characteristicsParsed.append(BleCharacteristic(
                uuid: characteristic.uuid,
                properties: propertiesList,
                characteristic: characteristic
            ))
        }
        
        servicesAndCharacteristics.updateValue(
            BleService(
                uuid: service.uuid,
                characteristics: characteristicsParsed,
                service: service
            ),
            forKey: serviceUuid
        )
        
        log("Checking if all services are discovered")
        for (uuid, service) in servicesAndCharacteristics {
            if (service?.characteristics.isEmpty ?? true) {
                log("Service \(uuid) has not been discovered")
                return
            }
        }
        
        lastResult?(true)
    }
    
    // Central manager delegate
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString.uppercased()
        log("Failed to connect to \(uuid) - \(error?.localizedDescription ?? "")")
        connectedPeripheral = nil
        LayrzBlePlugin.channel?.invokeMethod("onEvent", arguments: "DISCONNECTED")
        lastResult?(false)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString.uppercased()
        log("Disconnected from \(uuid) - \(error?.localizedDescription ?? "")")
        connectedPeripheral = nil
        LayrzBlePlugin.channel?.invokeMethod("onEvent", arguments: "DISCONNECTED")
        lastResult?(false)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name
        let uuid = peripheral.identifier.uuidString.uppercased()
        
        if (devices[uuid] != nil) {
            return
        }
        
        if (filteredUuid != nil && uuid != filteredUuid) {
            return
        }
        
        var manufacturerData: [[String: Any]] = []
        if let rawManufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            // Extract company ID (first 2 bytes) and manufacturer data
            if rawManufacturerData.count >= 2 {
                let companyId = Int(rawManufacturerData.prefix(2).withUnsafeBytes { $0.load(as: UInt16.self) })
                let data = rawManufacturerData.dropFirst(2)

                manufacturerData.append([
                    "companyId": companyId,
                    "data": data
                ])
            }
        }
        
        var serviceData: [[String: Any]] = []
        if let raw = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            for (serviceUuid, data) in raw {
                serviceData.append([
                    "uuid": standarizeServiceUuid(serviceUuid),
                    "data": data
                ])
            }
        }
        
        var txPower: Int? = nil
        if let rawPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
            txPower = rawPower.intValue
        }
        
        devices.updateValue(peripheral, forKey: uuid)
        LayrzBlePlugin.channel!.invokeMethod("onScan", arguments: [
            "name": name ?? "Unknown",
            "macAddress": uuid,
            "rssi": RSSI,
            "manufacturerData": manufacturerData,
            "serviceData": serviceData,
            "txPower": txPower
        ])
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if (isScanning) {
            centralManager.stopScan()
            isScanning = false
            LayrzBlePlugin.channel?.invokeMethod("onEvent", arguments: "SCAN_STOPPED")
        }
        
        peripheral.delegate = self
        connectedPeripheral = peripheral
        LayrzBlePlugin.channel?.invokeMethod("onEvent", arguments: "CONNECTED")
        peripheral.discoverServices(nil)
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            log("Bluetooth is turned on")
        case .poweredOff:
            if (isScanning) {
                LayrzBlePlugin.channel?.invokeMethod("onEvent", arguments: "SCAN_STOPPED")
                isScanning = false
            }
            log("Bluetooth is turned off")
        case .unsupported:
            log("Bluetooth is unsupported")
        case .unauthorized:
            log("Bluetooth is unauthorized")
        default:
            log("Unknown Bluetooth state \(central.state)")
        }
    }
    
    private func log(_ message: String) {
        NSLog("LayrzBlePlugin/iOS: \(message)")
    }
    
    private func standarizeServiceUuid(_ uuid: CBUUID) -> Int {
        return Int(uuid.data.withUnsafeBytes { $0.load(as: UInt16.self) }.littleEndian)
    }
}
