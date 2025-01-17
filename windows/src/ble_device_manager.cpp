#include <string>
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

    /// @brief Obtener el handle del dispositivo Bluetooth
    /// @return HANDLE
    HANDLE getBleDeviceHandle() 
    {
      HANDLE hDevice = NULL;
      BLUETOOTH_DEVICE_SEARCH_PARAMS searchParams = { 0 };
      searchParams.dwSize = sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS);
      searchParams.fReturnAuthenticated = TRUE;
      searchParams.fReturnRemembered = TRUE;
      searchParams.fReturnUnknown = TRUE;
      searchParams.fReturnConnected = TRUE;
      searchParams.fIssueInquiry = TRUE;
      searchParams.cTimeoutMultiplier = 2;

      BLUETOOTH_DEVICE_INFO deviceInfo = { 0 };
      deviceInfo.dwSize = sizeof(BLUETOOTH_DEVICE_INFO);
      std::string deviceID = device_.DeviceId();
      std::wstring wDeviceID(deviceID.begin(), deviceID.end());
      wcsncpy_s(deviceInfo.szName, wDeviceID.c_str(), wDeviceID.size());

      HBLUETOOTH_DEVICE_FIND hFind = BluetoothFindFirstDevice(&searchParams, &deviceInfo);
      if (hFind != NULL) {
      do {
          if (wcscmp(deviceInfo.szName, wDeviceID.c_str()) == 0) {
            hDevice = deviceInfo.hRadio;
            break;
          }
      } while (BluetoothFindNextDevice(hFind, &deviceInfo));
      BluetoothFindDeviceClose(hFind);
      }

      if (hDevice == NULL) {
        Log("Error: No se pudo encontrar el handle del dispositivo Bluetooth.");
      }

      return hDevice;
    }

  public:
    /// @brief Verificar si el dispositivo está conectado
    /// @return bool
    bool IsConnected() 
    {
      // Verificar si el dispositivo está conectado usando la API de Bluetooth de Windows
      SOCKET sock = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
      if (sock == INVALID_SOCKET) {
        Log("Error: No se pudo crear el socket Bluetooth.");
        return false;
      }

      SOCKADDR_BTH addr = { 0 };
      addr.addressFamily = AF_BTH;
      addr.serviceClassId = RFCOMM_PROTOCOL_UUID;
      addr.port = BT_PORT_ANY;

      std::string deviceID = device_.DeviceId();
      int result = WSAStringToAddressA((LPSTR)deviceID.c_str(), AF_BTH, NULL, (LPSOCKADDR)&addr, (LPINT)sizeof(addr));
      if (result != 0) {
        Log("Error: No se pudo convertir el ID del dispositivo a la dirección Bluetooth.");
        closesocket(sock);
        return false;
      }

      result = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
      closesocket(sock);
      return (result == 0);
    }

    /// @brief Constructor de la clase BLEDeviceManager
    /// @param device 
    BLEDeviceManager(const layrz_ble::BleScanResult& device) : device_(device) 
    {
      device_ = device;
    }
    /// @brief Destructor de la clase BLEDeviceManager
    ~BLEDeviceManager() {
    }

    /// @brief Conectar al dispositivo
    /// @return bool
    bool connectToDevice() 
    {
      // Implementación para conectar al dispositivo usando deviceID
      std::string deviceID = device_.DeviceId();
      if (!deviceID.empty()) {
        SOCKET sock = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
        if (sock < 0) {
          Log("Error: No se pudo crear el socket Bluetooth.");
          return false;
        } // Crear un socket Bluetooth
        SOCKADDR_BTH addr = { 0 };
        addr.addressFamily = AF_BTH;
        addr.serviceClassId = RFCOMM_PROTOCOL_UUID;
        addr.port = BT_PORT_ANY;
        // Convert deviceID to Bluetooth address
        int result = WSAStringToAddressA((LPSTR)deviceID.c_str(), AF_BTH, NULL, (LPSOCKADDR)&addr, (LPINT)sizeof(addr));
        if (result != 0) {
          Log("Error: No se pudo convertir el ID del dispositivo a la dirección Bluetooth.");
          closesocket(sock);
          return false;
        } // Convertir el ID del dispositivo a la dirección Bluetooth

        if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
          Log("Error: No se pudo conectar al dispositivo Bluetooth.");
          return false;
        }

        Log("Conectado al dispositivo Bluetooth con éxito.");
        Log("Conectando al dispositivo con ID: " + deviceID);
        return true;
      } 
      else
      {
        Log("Error: El ID del dispositivo está vacío.");
        return false;
      }
    }

    /// @brief Desconectar del dispositivo
    /// @return bool
    bool disconnectFromDevice() 
    {
      // Implementación para desconectar del dispositivo
      SOCKET sock = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
      if (sock == INVALID_SOCKET) {
        Log("Error: No se pudo crear el socket Bluetooth.");
        return false;
      }

      SOCKADDR_BTH addr = { 0 };
      addr.addressFamily = AF_BTH;
      addr.serviceClassId = RFCOMM_PROTOCOL_UUID;
      addr.port = BT_PORT_ANY;

      std::string deviceID = device_.DeviceId();
      int addrSize = sizeof(addr);
      int result = WSAStringToAddressA((LPSTR)deviceID.c_str(), AF_BTH, NULL, (LPSOCKADDR)&addr, &addrSize);
      if (result != 0) {
        Log("Error: No se pudo convertir el ID del dispositivo a la dirección Bluetooth.");
        closesocket(sock);
        return false;
      }

      result = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
      if (result == 0) 
      {
        result = shutdown(sock, SD_BOTH);
        if (result == 0)
            Log("Desconectado del dispositivo Bluetooth con éxito.");
        else
            Log("Error: No se pudo desconectar del dispositivo Bluetooth.");
      } else
        Log("Error: No se pudo conectar al dispositivo Bluetooth para desconectar.");

      closesocket(sock);
      return (result == 0);
    }
    
    /// @brief  Descubrir servicios del dispositivo
    /// @return void
    void discoverDeviceServices() 
    {
      HANDLE hDevice = getBleDeviceHandle();
      USHORT serviceBufferCount = 0;

      // Obtener el número de servicios
      HRESULT hr = BluetoothGATTGetServices(
        hDevice,
        0,
        nullptr,
        &serviceBufferCount,
        BLUETOOTH_GATT_FLAG_NONE
      );

      if (hr != HRESULT_FROM_WIN32(ERROR_MORE_DATA)) 
      {
        Log("Error: No se pudo obtener el número de servicios.");
        return;
      }

      // Asignar memoria para los servicios
      auto pServiceBuffer = std::make_unique<BTH_LE_GATT_SERVICE[]>(serviceBufferCount);
      if (!pServiceBuffer) 
      {
          Log("Error: No se pudo asignar memoria para los servicios.");
          return;
      }

      // Obtener los servicios
      hr = BluetoothGATTGetServices(
          hDevice,
          serviceBufferCount,
          pServiceBuffer.get(),
          &serviceBufferCount,
          BLUETOOTH_GATT_FLAG_NONE
      );

      if (FAILED(hr)) 
      {
          Log("Error: No se pudieron obtener los servicios.");
          return;
      }

      // Registrar los servicios encontrados
      for (USHORT i = 0; i < serviceBufferCount; i++) 
          Log("Servicio encontrado: " + std::to_string(pServiceBuffer[i].ServiceUuid.Value.LongUuid.Data1));

      Log("Descubrimiento de servicios completado.");
  }

    void setDeviceMtu(int mtu) 
    {
      // Implementación para establecer el MTU del dispositivo
      UNREFERENCED_PARAMETER(mtu); // El parámetro MTU no se usa en esta implementación
      // En Windows, no hay una API directa para establecer el MTU de un dispositivo Bluetooth.
      // El MTU generalmente se negocia automáticamente durante el proceso de conexión.
      Log("Advertencia: Establecer el MTU directamente no es compatible en Windows. El MTU se negocia automáticamente.");
    }

    /// @brief Descubrir características del servicio
    /// @param serviceUuid 
    /// @return void
    void discoverServiceCharacteristics(const std::string& serviceUuid) 
    {
      // Implementación para descubrir características del servicio
      Log("Descubriendo características del servicio con UUID: " + serviceUuid);

      GUID serviceGuid;
      if (CLSIDFromString(std::wstring(serviceUuid.begin(), serviceUuid.end()).c_str(), &serviceGuid) != NOERROR) 
      {
          Log("Error: No se pudo convertir el UUID del servicio.");
          return;
      }

      HANDLE hDevice = getBleDeviceHandle();
      USHORT serviceBufferCount = 0;

      // Obtener el número de servicios
      HRESULT hr = BluetoothGATTGetServices(
        hDevice,
        0,
        nullptr,
        &serviceBufferCount,
        BLUETOOTH_GATT_FLAG_NONE
      );

      if (hr != HRESULT_FROM_WIN32(ERROR_MORE_DATA)) 
      {
        Log("Error: No se pudo obtener el número de servicios.");
        return;
      }

      // Asignar memoria para los servicios
      auto pServiceBuffer = std::make_unique<BTH_LE_GATT_SERVICE[]>(serviceBufferCount);
      if (!pServiceBuffer) 
      {
        Log("Error: No se pudo asignar memoria para los servicios.");
        return;
      }

      // Obtener los servicios
      hr = BluetoothGATTGetServices(
        hDevice,
        serviceBufferCount,
        pServiceBuffer.get(),
        &serviceBufferCount,
        BLUETOOTH_GATT_FLAG_NONE
      );

      if (FAILED(hr)) {
        Log("Error: No se pudieron obtener los servicios.");
        return;
      }

      // Buscar el servicio con el UUID especificado
      PBTH_LE_GATT_SERVICE pService = nullptr;
      for (USHORT i = 0; i < serviceBufferCount; i++) {
        if (IsEqualGUID(pServiceBuffer[i].ServiceUuid.Value.LongUuid, serviceGuid)) {
          pService = &pServiceBuffer[i];
          break;
        }
      }

      if (!pService) {
        Log("Error: No se encontró el servicio con el UUID especificado.");
        return;
      }

      // Obtener las características del servicio
      USHORT charBufferCount = 0;

      // Obtener el número de características
      hr = BluetoothGATTGetCharacteristics(
        hDevice,
        pService,
        0,
        nullptr,
        &charBufferCount,
        BLUETOOTH_GATT_FLAG_NONE
      );

      if (hr != HRESULT_FROM_WIN32(ERROR_MORE_DATA)) {
          Log("Error: No se pudo obtener el número de características.");
          return;
      }

      // Asignar memoria para las características
      auto pCharBuffer = std::make_unique<BTH_LE_GATT_CHARACTERISTIC[]>(charBufferCount);
      if (!pCharBuffer) {
        Log("Error: No se pudo asignar memoria para las características.");
        return;
      }

      // Obtener las características
      hr = BluetoothGATTGetCharacteristics(
        hDevice,
        pService,
        charBufferCount,
        pCharBuffer.get(),
        &charBufferCount,
        BLUETOOTH_GATT_FLAG_NONE
      );

      if (FAILED(hr)) {
        Log("Error: No se pudieron obtener las características.");
        return;
      }

      // Registrar las características encontradas
      for (USHORT i = 0; i < charBufferCount; i++)
        Log("Característica encontrada: " + std::to_string(pCharBuffer[i].CharacteristicUuid.Value.LongUuid.Data1));

      Log("Descubrimiento de características completado.");
    }

    void readCharacteristicValue(const std::string& serviceUuid, const std::string& characteristicUuid) {
        // Implementación para leer el valor de la característica
    }

        void writeCharacteristicValue(const std::string& serviceUuid, const std::string& characteristicUuid, const std::string& value) {
            // Implementación para escribir el valor de la característica
        }

        void startCharacteristicNotification(const std::string& serviceUuid, const std::string& characteristicUuid) {
            // Implementación para iniciar la notificación de la característica
        }

        void stopCharacteristicNotification(const std::string& serviceUuid, const std::string& characteristicUuid) {
            // Implementación para detener la notificación de la característica
        }

};
} // namespace layrz_ble