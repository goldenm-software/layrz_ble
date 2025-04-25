#if os(iOS)
    import Flutter
#elseif os(macOS)
    import FlutterMacOS
#endif
import CoreBluetooth

public class LayrzBlePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        var messenger: FlutterBinaryMessenger
        #if os(iOS)
            messenger = registrar.messenger()
        #else
            messenger = registrar.messenger
        #endif
        let callback = LayrzBleCallbackChannel(binaryMessenger: messenger)
        let api = LayrzBleDarwin(callbackChannel: callback)
        LayrzBlePlatformChannelSetup.setUp(binaryMessenger: messenger, api: api)
    }
        
}

private class LayrzBleDarwin: NSObject, LayrzBlePlatformChannel, CBCentralManagerDelegate, CBPeripheralDelegate {
    var callbackChannel: LayrzBleCallbackChannel
    
    var isAdvertising: Bool = false
    var centralManager: CBCentralManager!

    var filterMac: String?
    var connectedPeripherals: [String: CBPeripheral] = [:]
    var servicesAndCharacteristics: [String: [BleService]] = [:]
    var connectCallback: ((Result<Bool, any Error>) -> Void)?
    var writeCallback: ((Result<Bool, any Error>) -> Void)?
    var readCallback: ((Result<FlutterStandardTypedData, any Error>) -> Void)?
    
    var discoveredPeripherals: [CBPeripheral] = []
    var devices: [String: CBPeripheral] = [:]
    var filteredUuid: String?

    init(callbackChannel: LayrzBleCallbackChannel) {
        self.callbackChannel = callbackChannel
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func isTurnedOn() -> Bool {
        log("Status: \(centralManager.state)")
        return centralManager.state == .poweredOn
    }
    
    func getStatuses(completion: @escaping (Result<BtStatus, any Error>) -> Void) {
        completion(.success(BtStatus(advertising: isAdvertising, scanning: centralManager.isScanning)))
    }

    func checkCapabilities(completion: @escaping (Result<Bool, any Error>) -> Void) {
        if (!validateScanPermissions()) {
            completion(.success(false))
            return
        }
        
        if (!isTurnedOn()) {
            completion(.success(false))
            return
        }
        
        completion(.success(true))
    }
    
    func validateScanPermissions() -> Bool {
        let auth = CBCentralManager.authorization
        return auth == .allowedAlways
    }
    
    func checkScanPermissions(completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(validateScanPermissions()))
    }
    
    func validateAdvertisePermissions() -> Bool {
        let auth = CBPeripheralManager.authorization
        return auth == .allowedAlways
    }
    
    func checkAdvertisePermissions(completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(validateAdvertisePermissions()))
    }
    
    func startScan(macAddress: String?, servicesUuids: [String]?, completion: @escaping (Result<Bool, any Error>) -> Void) {
        if (centralManager.isScanning) {
            log("Already scanning")
            completion(.success(true))
            return
        }
        
        if (!validateScanPermissions()) {
            log("Scan permissions not granted")
            completion(.success(false))
            return
        }
        
        if (!isTurnedOn()) {
            log("Bluetooth not turned on")
            completion(.success(false))
            return
        }
        
        filterMac = macAddress
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        log("Started scanning")
        completion(.success(true))
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name
        let uuid = peripheral.identifier.uuidString.uppercased()
        if (filteredUuid != nil && uuid != filteredUuid) { return }
        
        var manufacturerData: [BtManufacturerData] = []
        if let rawManufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            // Extract company ID (first 2 bytes) and manufacturer data
            if rawManufacturerData.count >= 2 {
                let companyId = Int64(rawManufacturerData.prefix(2).withUnsafeBytes { $0.load(as: UInt16.self) })
                let data = rawManufacturerData.dropFirst(2)

                manufacturerData.append(BtManufacturerData(
                    companyId: companyId,
                    data: FlutterStandardTypedData(bytes: data)
                ))
            }
        }
        
        var serviceData: [BtServiceData] = []
        if let raw = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            for (serviceUuid, data) in raw {
                serviceData.append(BtServiceData(
                    uuid: standarizeServiceUuid(serviceUuid),
                    data: FlutterStandardTypedData(bytes: data)
                ))
            }
        }
        
        var txPower: Int64? = nil
        if let rawPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
            txPower = rawPower.int64Value
        }
        
        devices.updateValue(peripheral, forKey: uuid)
        
        callbackChannel.onScanResult(device: BtDevice(
            macAddress: uuid,
            name: name,
            rssi: RSSI.int64Value,
            txPower: txPower,
            manufacturerData: manufacturerData,
            serviceData: serviceData,
        )) { _ in }
    }
    
    func stopScan(macAddress: String?, completion: @escaping (Result<Bool, any Error>) -> Void) {
        if (!centralManager.isScanning) {
            log("Not scanning")
            completion(.success(true))
            return
        }
        
        centralManager.stopScan()
        log("Stopped scanning")
        completion(.success(true))
    }
    
    func connect(macAddress: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        if (connectedPeripherals[macAddress.uppercased()] != nil) {
            log("Already connected to \(macAddress)")
            completion(.success(true))
            return
        }
        
        if (devices[macAddress] == nil) {
            log("Device not found")
            completion(.success(false))
            return
        }
        
        let peripheral = devices[macAddress.uppercased()]!
        if (peripheral.state == .connected) {
            log("Already connected")
            completion(.success(true))
            return
        }
        
        centralManager.connect(peripheral)
        connectCallback = completion
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let uuid = peripheral.identifier.uuidString.uppercased()
        log("Connected to \(uuid)")
        peripheral.delegate = self
        connectedPeripherals[uuid] = peripheral
        
        callbackChannel.onConnected(device: BtDevice(
            macAddress: uuid,
            name: peripheral.name,
            manufacturerData: [],
            serviceData: [],
        )) { _ in }
        
        peripheral.discoverServices(nil)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString.uppercased()
        if let error = error {
            log("Error discovering services for \(uuid): \(error.localizedDescription)")
            connectCallback?(.success(false))
            connectCallback = nil
            centralManager.cancelPeripheralConnection(peripheral)
            callbackChannel.onDisconnected(device: BtDevice(
                macAddress: uuid,
                name: peripheral.name,
                manufacturerData: [],
                serviceData: [],
            )) { _ in }
            connectedPeripherals.removeValue(forKey: uuid)
            servicesAndCharacteristics.removeValue(forKey: uuid)
            return
        }
        
        guard let services = peripheral.services else {
            log("No services found for \(uuid)")
            connectCallback?(.success(true))
            connectCallback = nil
            return
        }
        
        for service in services {
            if servicesAndCharacteristics[uuid] == nil {
                servicesAndCharacteristics[uuid] = []
            }
            
            servicesAndCharacteristics[uuid]!.append(BleService(
                uuid: service.uuid,
                characteristics: [],
                service: service
            ))
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString.uppercased()
        if let error = error {
            // Find the service in servicesAndCharacteristics, and update the discovered to true
            if let index = servicesAndCharacteristics[uuid]?.firstIndex(where: { $0.uuid == service.uuid }) {
                servicesAndCharacteristics[uuid]![index].discovered = true
            }
            log("Error discovering characteristics for service \(service.uuid): \(error.localizedDescription)")
            return
        }
        
        let serviceUuid = service.uuid.uuidString.uppercased()
        guard let characteristics = service.characteristics else {
            log("No characteristics found for service \(serviceUuid)")
            // Find the service in servicesAndCharacteristics, and update the discovered to true
            if let index = servicesAndCharacteristics[uuid]?.firstIndex(where: { $0.uuid == service.uuid }) {
                servicesAndCharacteristics[uuid]![index].discovered = true
            }
            return
        }
        
        var characteristicsList: [BleCharacteristic] = []
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
            
            characteristicsList.append(BleCharacteristic(
                uuid: characteristic.uuid,
                properties: propertiesList,
                characteristic: characteristic
            ))
        }
        
        
        if let index = servicesAndCharacteristics[uuid]?.firstIndex(where: { $0.uuid == service.uuid }) {
            servicesAndCharacteristics[uuid]![index].characteristics = characteristicsList
            servicesAndCharacteristics[uuid]![index].discovered = true
        } else {
            log("Service \(serviceUuid) not found in servicesAndCharacteristics")
        }
        
        let toValidate = servicesAndCharacteristics[uuid] ?? []
        for service in toValidate {
            if !service.discovered {
                log("Service \(service.uuid) has not discovered all characteristics yet")
                return
            }
        }
        
        log("All services and characteristics discovered for \(uuid)")
        connectCallback?(.success(true))
        connectCallback = nil
    }
    
    func disconnect(macAddress: String?, completion: @escaping (Result<Bool, any Error>) -> Void) {
        if (macAddress == nil) {
            for (_, peripheral) in connectedPeripherals {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            
            connectedPeripherals.removeAll()
            servicesAndCharacteristics.removeAll()
        } else {
            if let peripheral = connectedPeripherals[macAddress!.uppercased()] {
                centralManager.cancelPeripheralConnection(peripheral)
                connectedPeripherals.removeValue(forKey: macAddress!.uppercased())
                servicesAndCharacteristics.removeValue(forKey: macAddress!.uppercased())
            } else {
                log("Device not found")
            }
        }
        
        completion(.success(true))
    }
    
    func setMtu(macAddress: String, newMtu: Int64, completion: @escaping (Result<Int64?, any Error>) -> Void) {
        let peripheral = connectedPeripherals[macAddress.uppercased()]
        if peripheral == nil {
            log("Device not found")
            completion(.success(nil))
            return
        }
        
        let mtu = peripheral!.maximumWriteValueLength(for: .withResponse)
        log("MTU for \(macAddress): \(mtu)")
        completion(.success(Int64(mtu)))
    }
    
    func discoverServices(macAddress: String, completion: @escaping (Result<[BtService], any Error>) -> Void) {
        let services = servicesAndCharacteristics[macAddress.uppercased()]
        if services == nil {
            log("Device not found")
            completion(.success([]))
        }
        
        var servicesList: [BtService] = []
        for service in services ?? [] {
            servicesList.append(service.toPigeon())
        }
        
        completion(.success(servicesList))
    }
    
    func readCharacteristic(
        macAddress: String,
        serviceUuid: String,
        characteristicUuid: String,
        completion: @escaping (Result<FlutterStandardTypedData, any Error>) -> Void
    ) {
        let peripheral = connectedPeripherals[macAddress.uppercased()]
        if peripheral == nil {
            log("Device not found")
            completion(.success(FlutterStandardTypedData(bytes: Data())))
            return
        }
        
        let services = servicesAndCharacteristics[macAddress.uppercased()]
        if services == nil {
            log("Device not found")
            completion(.success(FlutterStandardTypedData(bytes: Data())))
            return
        }
        
        guard let service = services!.first(where: { $0.uuidString == serviceUuid.uppercased() }) else {
            log("Service not found")
            completion(.success(FlutterStandardTypedData(bytes: Data())))
            return
        }
        
        guard let characteristic = service.characteristics.first(where: { $0.uuidString == characteristicUuid.uppercased() }) else {
            log("Characteristic not found")
            completion(.success(FlutterStandardTypedData(bytes: Data())))
            return
        }
        
        if !characteristic.characteristic.properties.contains(.read) {
            log("Characteristic does not support read")
            completion(.success(FlutterStandardTypedData(bytes: Data())))
            return
        }
        
        if characteristic.characteristic.isNotifying {
            log("Characteristic is notifying, cannot read it")
            completion(.success(FlutterStandardTypedData(bytes: Data())))
            return
        }
        
        readCallback = completion
        peripheral!.readValue(for: characteristic.characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            log("Error reading value for characteristic \(characteristic.uuid): \(error.localizedDescription)")
            readCallback?(.success(FlutterStandardTypedData(bytes: Data())))
            readCallback = nil
            return
        }
        
        if characteristic.isNotifying {
            log("Received notification for characteristic \(characteristic.uuid)")
            guard let serviceUuid = characteristic.service?.uuid.uuidString.uppercased() else {
                log("Service UUID not found")
                return
            }
            
            let characteristicUuid = characteristic.uuid.uuidString.uppercased()
            
            callbackChannel.onCharacteristicUpdate(
                notification: BtCharacteristicNotification(
                    macAddress: peripheral.identifier.uuidString.uppercased(),
                    serviceUuid: serviceUuid,
                    characteristicUuid: characteristicUuid,
                    value: FlutterStandardTypedData(bytes: characteristic.value ?? Data())
                )
            ) { _ in }
            return
        }
        
        let uuid = peripheral.identifier.uuidString.uppercased()
        log("Read value for characteristic \(characteristic.uuid) on device \(uuid)")
        if let data = characteristic.value {
            readCallback?(.success(FlutterStandardTypedData(bytes: data)))
        } else {
            readCallback?(.success(FlutterStandardTypedData(bytes: Data())))
        }
        readCallback = nil
    }
    
    func writeCharacteristic(
        macAddress: String,
        serviceUuid: String,
        characteristicUuid: String,
        payload: FlutterStandardTypedData,
        withResponse: Bool,
        completion: @escaping (Result<Bool, any Error>) -> Void
    ) {
        let peripheral = connectedPeripherals[macAddress.uppercased()]
        if peripheral == nil {
            log("Device not found")
            completion(.success(false))
            return
        }
        
        let services = servicesAndCharacteristics[macAddress.uppercased()]
        if services == nil {
            log("Device not found")
            completion(.success(false))
            return
        }
        
        guard let service = services!.first(where: { $0.uuidString == serviceUuid.uppercased() }) else {
            log("Service not found")
            completion(.success(false))
            return
        }
        
        guard let characteristic = service.characteristics.first(where: { $0.uuidString == characteristicUuid.uppercased() }) else {
            log("Characteristic not found")
            completion(.success(false))
            return
        }
        
        if !characteristic.characteristic.properties.contains(.write) && !characteristic.characteristic.properties.contains(.writeWithoutResponse) {
            log("Characteristic does not support write")
            completion(.success(false))
            return
        }
        
        writeCallback = completion
        peripheral!.writeValue(
            payload.data,
            for: characteristic.characteristic,
            type: withResponse ? .withResponse : .withoutResponse
        )
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            log("Error writing value for characteristic \(characteristic.uuid): \(error.localizedDescription)")
            writeCallback?(.success(false))
            writeCallback = nil
            return
        }
        
        let uuid = peripheral.identifier.uuidString.uppercased()
        log("Wrote value for characteristic \(characteristic.uuid) on device \(uuid)")
        writeCallback?(.success(true))
        writeCallback = nil
    }
    
    func startNotify(macAddress: String, serviceUuid: String, characteristicUuid: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        let peripheral = connectedPeripherals[macAddress.uppercased()]
        if peripheral == nil {
            log("Device not found")
            completion(.success(false))
            return
        }
        
        let services = servicesAndCharacteristics[macAddress.uppercased()]
        if services == nil {
            log("Device not found")
            completion(.success(false))
            return
        }
        
        guard let service = services!.first(where: { $0.uuidString == serviceUuid.uppercased() }) else {
            log("Service not found")
            completion(.success(false))
            return
        }
        
        guard let characteristic = service.characteristics.first(where: { $0.uuidString == characteristicUuid.uppercased() }) else {
            log("Characteristic not found")
            completion(.success(false))
            return
        }
        
        if !characteristic.characteristic.properties.contains(.notify) && !characteristic.characteristic.properties.contains(.indicate) {
            log("Characteristic does not support notify or indicate")
            completion(.success(false))
            return
        }
        
        peripheral!.setNotifyValue(true, for: characteristic.characteristic)
        log("Started notifying for characteristic \(characteristicUuid) on service \(serviceUuid)")
        completion(.success(true))
    }
    
    func stopNotify(macAddress: String, serviceUuid: String, characteristicUuid: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        let peripheral = connectedPeripherals[macAddress.uppercased()]
        if peripheral == nil {
            log("Device not found")
            completion(.success(false))
            return
        }
        
        let services = servicesAndCharacteristics[macAddress.uppercased()]
        if services == nil {
            log("Device not found")
            completion(.success(false))
            return
        }
        
        guard let service = services!.first(where: { $0.uuidString == serviceUuid.uppercased() }) else {
            log("Service not found")
            completion(.success(false))
            return
        }
        
        guard let characteristic = service.characteristics.first(where: { $0.uuidString == characteristicUuid.uppercased() }) else {
            log("Characteristic not found")
            completion(.success(false))
            return
        }
        
        if !characteristic.characteristic.properties.contains(.notify) && !characteristic.characteristic.properties.contains(.indicate) {
            log("Characteristic does not support notify or indicate")
            completion(.success(false))
            return
        }
        
        peripheral!.setNotifyValue(false, for: characteristic.characteristic)
        log("Stopped notifying for characteristic \(characteristicUuid) on service \(serviceUuid)")
        completion(.success(true))
    }
    
    func startAdvertise(
        manufacturerData: [BtManufacturerData],
        serviceData: [BtServiceData],
        canConnect: Bool,
        name: String?,
        servicesSpecs: [BtService],
        allowBluetooth5: Bool,
        completion: @escaping (Result<Bool, any Error>) -> Void
    ) {
        completion(.success(false))
    }
    
    func stopAdvertise(completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(false))
    }
    
    func respondReadRequest(
        requestId: Int64,
        macAddress: String,
        offset: Int64,
        data: FlutterStandardTypedData?,
        completion: @escaping (Result<Bool, any Error>) -> Void
    ) {
        completion(.success(false))
    }
    
    func respondWriteRequest(
        requestId: Int64,
        macAddress: String,
        offset: Int64,
        success: Bool,
        completion: @escaping (Result<Bool, any Error>) -> Void
    ) {
        completion(.success(false))
    }
    
    func sendNotification(
        serviceUuid: String,
        characteristicUuid: String,
        payload: FlutterStandardTypedData,
        requestConfirmation: Bool,
        completion: @escaping (Result<Bool, any Error>) -> Void
    ) {
        completion(.success(false))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString.uppercased()
        log("Disconnected from \(uuid)")
        
        connectedPeripherals[uuid] = nil
        if let error = error {
            log("Error disconnecting from \(uuid): \(error.localizedDescription)")
        }
        
        connectCallback?(.success(false))
        connectCallback = nil
        callbackChannel.onDisconnected(device: BtDevice(
            macAddress: uuid,
            name: peripheral.name,
            manufacturerData: [],
            serviceData: [],
        )) { _ in }
        
        connectedPeripherals.removeValue(forKey: uuid)
        servicesAndCharacteristics.removeValue(forKey: uuid)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        let uuid = peripheral.identifier.uuidString.uppercased()
        log("Failed to connect to \(uuid): \(error?.localizedDescription ?? "Unknown error")")
        connectCallback?(.success(false))
        connectCallback = nil
        callbackChannel.onDisconnected(device: BtDevice(
            macAddress: uuid,
            name: peripheral.name,
            manufacturerData: [],
            serviceData: [],
        )) { _ in }
        connectedPeripherals.removeValue(forKey: uuid)
        servicesAndCharacteristics.removeValue(forKey: uuid)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            log("Bluetooth powered on")
            callbackChannel.onBluetoothOn() { _ in }
        case .poweredOff:
            log("Bluetooth powered off")
            callbackChannel.onBluetoothOff() { _ in }
        case .resetting:
            log("Bluetooth resetting")
        case .unauthorized:
            log("Bluetooth unauthorized")
        case .unsupported:
            log("Bluetooth unsupported")
        case .unknown:
            log("Bluetooth unknown")
        @unknown default:
            log("Bluetooth unknown state")
        }
    }
    
    private func log(_ message: String) {
        NSLog("LayrzBlePlugin/darwin: \(message)")
    }
    
    private func standarizeServiceUuid(_ uuid: CBUUID) -> Int64 {
        return Int64(uuid.data.withUnsafeBytes { $0.load(as: UInt16.self) }.littleEndian)
    }
}
