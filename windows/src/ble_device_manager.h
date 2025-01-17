#pragma once

#include <windows.h>
#include <iostream>
#include <string>
#include <sstream>

#include <winsock2.h>
#include <ws2bth.h>
#include <bthsdpdef.h> // Include this header for HBLUETOOTH_SERVICE_FIND
#include <bluetoothleapis.h> // Include this header for PBTH_LE_GATT_SERVICE
#include <bluetoothapis.h> // Include this header for HBLUETOOTH_SERVICE_FIND
#include <bthdef.h> // Include this header for BLUETOOTH_SERVICE_INFO

#include "layrz_ble_plugin.h" // Asegúrate de incluir el archivo de encabezado correcto para layrz_ble::BleScanResult

namespace layrz_ble {

  class BLEDeviceManager {

    private:
      layrz_ble::BleScanResult device_;

      HANDLE OpenBluetoothDeviceHandle(BLUETOOTH_ADDRESS address);
      HANDLE getBleDeviceHandle();

    public:
      bool IsConnected();
      BLEDeviceManager(const layrz_ble::BleScanResult& device) : device_(device);
      ~BLEDeviceManager();
      bool connectToDevice();
      bool disconnectFromDevice();   
      void discoverDeviceServices();
      void setDeviceMtu(int mtu);
      void discoverServiceCharacteristics(const std::string& serviceUuid); 
      void readCharacteristicValue(const std::string& serviceUuid, const std::string& characteristicUuid);
      void writeCharacteristicValue(const std::string& serviceUuid, const std::string& characteristicUuid, const std::string& value);
      void startCharacteristicNotification(const std::string& serviceUuid, const std::string& characteristicUuid);
      void stopCharacteristicNotification(const std::string& serviceUuid, const std::string& characteristicUuid);

  }
}