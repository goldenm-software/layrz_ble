package com.layrz.layrz_ble

class BleService(var uuid: String, var characteristics: List<BleCharacteristic>) {}

class BleCharacteristic(var uuid: String, var properties: List<String>) {}