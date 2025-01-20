//
//  Entities.swift
//  Pods
//
//  Created by Layrz Mobile on 20/01/25.
//

import CoreBluetooth

class BleService {
    let uuid: CBUUID
    let characteristics: [BleCharacteristic]
    let service: CBService
    
    public var uuidString: String { uuid.uuidString.uppercased() }

    public func toDictionary() -> [String: Any] {
        return [
            "uuid": uuidString,
            "characteristics": characteristics.map { $0.toDictionary() }
        ]
    }
    
    // Define the constructor
    public init(uuid: CBUUID, characteristics: [BleCharacteristic], service: CBService) {
        self.uuid = uuid
        self.characteristics = characteristics
        self.service = service
    }
}

class BleCharacteristic {
    let uuid: CBUUID
    let properties: [String]
    let characteristic: CBCharacteristic
    
    public var uuidString: String { uuid.uuidString.uppercased() }
    
    public func toDictionary() -> [String: Any] {
        return [
            "uuid": uuidString,
            "properties": properties
        ]
    }
    
    // Define the constructor
    public init(uuid: CBUUID, properties: [String], characteristic: CBCharacteristic) {
        self.uuid = uuid
        self.properties = properties
        self.characteristic = characteristic
    }
}
