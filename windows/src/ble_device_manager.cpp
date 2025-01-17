#include "ble_device_manager.h"
namespace layrz_ble {

class BLEDeviceManager {

  private:
    layrz_ble::BleScanResult device_;

    /// @brief Abre el handle de un dispositivo Bluetooth basado en su dirección
    /// @param address La dirección del dispositivo Bluetooth (BLUETOOTH_ADDRESS)
    /// @return HANDLE El handle del dispositivo Bluetooth si se abre correctamente, NULL en caso contrario
    HANDLE OpenBluetoothDeviceHandle(BLUETOOTH_ADDRESS address) 
    {
      // Convertir la dirección Bluetooth a una cadena en formato estándar
      std::wstringstream addressStream;
      for (int i = 5; i >= 0; --i) {
        addressStream << std::hex << (address.rgBytes[i] & 0xFF);
        if (i > 0)
          addressStream << L":";
      }
      std::wstring bluetoothAddressStr = addressStream.str();
        
      // Crear el nombre del dispositivo en formato compatible con CreateFile
      std::wstring devicePath = L"\\\\?\\BTHLEDevice#";
      devicePath += bluetoothAddressStr;
      devicePath += L"#";
      devicePath += L"{e0cbf06c-cd8b-4647-bb8a-263b43f0f974}"; // GUID genérico para dispositivos BLE

      // Abrir el dispositivo
      HANDLE hDevice = CreateFile(
        devicePath.c_str(),                 // Ruta del dispositivo
        GENERIC_READ | GENERIC_WRITE,       // Acceso de lectura y escritura
        FILE_SHARE_READ | FILE_SHARE_WRITE, // Compartir acceso
        NULL,                               // Seguridad predeterminada
        OPEN_EXISTING,                      // Abre un dispositivo existente
        0,                                  // No se necesitan atributos especiales
        NULL                                // No hay plantillas
      );

      if (hDevice == INVALID_HANDLE_VALUE) {
          Log("Error: No se pudo abrir el dispositivo Bluetooth. Dirección: " + std::wstring(bluetoothAddressStr) + ". Código de error: " + std::to_string(GetLastError()));
          return NULL;
      }
      Log("Dispositivo Bluetooth abierto correctamente. Dirección: " + std::wstring(bluetoothAddressStr));
      return hDevice;
    }

    /// @brief Obtener el handle del dispositivo Bluetooth basado en su DeviceId
    /// @param deviceId El identificador del dispositivo en formato std::string
    /// @return HANDLE El handle del dispositivo Bluetooth si se encuentra, NULL en caso contrario
    HANDLE getBleDeviceHandle() 
    {
      HANDLE hDevice = NULL;

      // Obtener el DeviceId del dispositivo
      const std::string& deviceId = device_.DeviceId();

      // Configurar los parámetros de búsqueda de dispositivos Bluetooth
      BLUETOOTH_DEVICE_SEARCH_PARAMS searchParams = { 0 };
      searchParams.dwSize = sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS);
      searchParams.fReturnAuthenticated = TRUE;
      searchParams.fReturnRemembered = TRUE;
      searchParams.fReturnUnknown = TRUE;
      searchParams.fReturnConnected = TRUE;
      searchParams.fIssueInquiry = TRUE; // Realizar una búsqueda activa
      searchParams.cTimeoutMultiplier = 2;

      // Configurar la estructura de información del dispositivo Bluetooth
      BLUETOOTH_DEVICE_INFO deviceInfo = { 0 };
      deviceInfo.dwSize = sizeof(BLUETOOTH_DEVICE_INFO);

      // Convertir el deviceId a wstring
      std::wstring wDeviceId(deviceId.begin(), deviceId.end());
    
      // Iniciar la búsqueda de dispositivos Bluetooth
      HBLUETOOTH_DEVICE_FIND hFind = BluetoothFindFirstDevice(&searchParams, &deviceInfo);
      if (hFind != NULL) {
        do {
          // Comparar el nombre del dispositivo para encontrar el correcto
          if (wcscmp(deviceInfo.szName, wDeviceId.c_str()) == 0) {
            // Aquí encontramos el dispositivo. Por ahora usamos su dirección.
            hDevice = OpenBluetoothDeviceHandle(deviceInfo.Address);
            break;
          }
          // Reiniciar la estructura deviceInfo antes de la próxima iteración
          ZeroMemory(&deviceInfo, sizeof(BLUETOOTH_DEVICE_INFO));
          deviceInfo.dwSize = sizeof(BLUETOOTH_DEVICE_INFO);

        } while (BluetoothFindNextDevice(hFind, &deviceInfo));
        // Cerrar el handle de búsqueda
        BluetoothFindDeviceClose(hFind);
      } else {
        Log("Error: No se encontraron dispositivos Bluetooth.");
      }

      // Comprobar si se encontró el handle del dispositivo
      if (hDevice == NULL) {
          Log("Error: No se pudo encontrar el handle del dispositivo Bluetooth. DeviceId buscado: " + deviceId);
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
        0,
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
      0,
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

  /// @brief Leer el valor de la característica
  /// @param serviceUuid 
  /// @param characteristicUuid 
  /// @return void
  void readCharacteristicValue(const std::string& serviceUuid, const std::string& characteristicUuid) {
    // Implementación para leer el valor de la característica
    Log("Leyendo el valor de la característica con UUID: " + characteristicUuid + " del servicio con UUID: " + serviceUuid);

    GUID serviceGuid;
    if (CLSIDFromString(std::wstring(serviceUuid.begin(), serviceUuid.end()).c_str(), &serviceGuid) != NOERROR) 
    {
      Log("Error: No se pudo convertir el UUID del servicio.");
      return;
    }

    GUID charGuid;
    if (CLSIDFromString(std::wstring(characteristicUuid.begin(), characteristicUuid.end()).c_str(), &charGuid) != NOERROR)
    {
      Log("Error: No se pudo convertir el UUID de la característica.");
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
    if (!pServiceBuffer) {
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

    // Buscar la característica con el UUID especificado
    PBTH_LE_GATT_CHARACTERISTIC pCharacteristic = nullptr;
    for (USHORT i = 0; i < charBufferCount; i++) {
      if (IsEqualGUID(pCharBuffer[i].CharacteristicUuid.Value.LongUuid, charGuid)) {
        pCharacteristic = &pCharBuffer[i];
        break;
      }
    }

    if (!pCharacteristic) {
      Log("Error: No se encontró la característica con el UUID especificado.");
      return;
    }

    // Leer el valor de la característica
    USHORT valueDataSize = 0;
    hr = BluetoothGATTGetCharacteristicValue(
      hDevice,
      pCharacteristic->Descriptors,
      0,
      nullptr,
      &valueDataSize,
      BLUETOOTH_GATT_FLAG_NONE
    );

    if (hr != HRESULT_FROM_WIN32(ERROR_MORE_DATA)) {
      Log("Error: No se pudo obtener el tamaño del valor de la característica.");
      return;
    }

    auto pValueBuffer = std::make_unique<BTH_LE_GATT_CHARACTERISTIC_VALUE[]>(valueDataSize);
    if (!pValueBuffer) {
      Log("Error: No se pudo asignar memoria para el valor de la característica.");
      return;
    }

    hr = BluetoothGATTGetCharacteristicValue(
      hDevice,
      pCharacteristic,
      valueDataSize,
      pValueBuffer.get(),
      nullptr,
      BLUETOOTH_GATT_FLAG_NONE
    );

    if (FAILED(hr)) {
      Log("Error: No se pudo obtener el valor de la característica.");
      return;
    }

    // Registrar el valor leído
    Log("Valor de la característica leído: " + std::to_string(pValueBuffer[0].Data[0]));
  }

  /// @brief Escribir el valor de la característica
  /// @param serviceUuid 
  /// @param characteristicUuid 
  /// @param value 
  void writeCharacteristicValue(const std::string& serviceUuid, const std::string& characteristicUuid, const std::string& value) {
    Log("Escribiendo el valor de la característica con UUID: " + characteristicUuid + " del servicio con UUID: " + serviceUuid);

    GUID serviceGuid;
    if (CLSIDFromString(std::wstring(serviceUuid.begin(), serviceUuid.end()).c_str(), &serviceGuid) != NOERROR) 
    {
      Log("Error: No se pudo convertir el UUID del servicio.");
      return;
    }

    GUID charGuid;
    if (CLSIDFromString(std::wstring(characteristicUuid.begin(), characteristicUuid.end()).c_str(), &charGuid) != NOERROR)
    {
      Log("Error: No se pudo convertir el UUID de la característica.");
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
    if (!pServiceBuffer) {
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

    // Buscar la característica con el UUID especificado
    PBTH_LE_GATT_CHARACTERISTIC pCharacteristic = nullptr;
    for (USHORT i = 0; i < charBufferCount; i++) {
      if (IsEqualGUID(pCharBuffer[i].CharacteristicUuid.Value.LongUuid, charGuid)) {
        pCharacteristic = &pCharBuffer[i];
        break;
      }
    }

    if (!pCharacteristic) {
      Log("Error: No se encontró la característica con el UUID especificado.");
      return;
    }

    // Preparar el valor a escribir
    auto pValueBuffer = std::make_unique<BTH_LE_GATT_CHARACTERISTIC_VALUE>();
    if (!pValueBuffer) {
      Log("Error: No se pudo asignar memoria para el valor de la característica.");
      return;
    }

    pValueBuffer->DataSize = static_cast<ULONG>(value.size());
    memcpy(pValueBuffer->Data, value.data(), value.size());

    // Escribir el valor de la característica
    hr = BluetoothGATTSetCharacteristicValue(
      hDevice,
      pCharacteristic,
      pValueBuffer.get(),
      0,
      BLUETOOTH_GATT_FLAG_NONE
    );

    if (FAILED(hr)) {
      Log("Error: No se pudo escribir el valor de la característica.");
      return;
    }

    Log("Valor de la característica escrito con éxito.");
  }

  /// @brief Iniciar la notificación de la característica
  /// @param serviceUuid 
  /// @param characteristicUuid 
  /// @return void
  void startCharacteristicNotification(const std::string& serviceUuid, const std::string& characteristicUuid) {
    // Implementación para iniciar la notificación de la característica
    Log("Iniciando notificación de la característica con UUID: " + characteristicUuid + " del servicio con UUID: " + serviceUuid);

    GUID serviceGuid;
    if (CLSIDFromString(std::wstring(serviceUuid.begin(), serviceUuid.end()).c_str(), &serviceGuid) != NOERROR) 
    {
      Log("Error: No se pudo convertir el UUID del servicio.");
      return;
    }

    GUID charGuid;
    if (CLSIDFromString(std::wstring(characteristicUuid.begin(), characteristicUuid.end()).c_str(), &charGuid) != NOERROR)
    {
      Log("Error: No se pudo convertir el UUID de la característica.");
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
    if (!pServiceBuffer) {
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

    // Buscar la característica con el UUID especificado
    PBTH_LE_GATT_CHARACTERISTIC pCharacteristic = nullptr;
    for (USHORT i = 0; i < charBufferCount; i++) {
      if (IsEqualGUID(pCharBuffer[i].CharacteristicUuid.Value.LongUuid, charGuid)) {
        pCharacteristic = &pCharBuffer[i];
        break;
      }
    }

    if (!pCharacteristic) {
      Log("Error: No se encontró la característica con el UUID especificado.");
      return;
    }

    // Habilitar la notificación de la característica
    BTH_LE_GATT_DESCRIPTOR_VALUE newValue;
    RtlZeroMemory(&newValue, sizeof(newValue));
    newValue.DescriptorType = ClientCharacteristicConfiguration;
    newValue.ClientCharacteristicConfiguration.IsSubscribeToNotification = TRUE;

    hr = BluetoothGATTSetDescriptorValue(
      hDevice,
      pCharacteristic,
      &newValue,
      BLUETOOTH_GATT_FLAG_NONE
    );

    if (FAILED(hr)) {
      Log("Error: No se pudo habilitar la notificación de la característica.");
      return;
    }

      Log("Notificación de la característica habilitada con éxito.");
  }

  /// @brief Detener la notificación de la característica
  /// @param serviceUuid 
  /// @param characteristicUuid 
  /// @return void
  void stopCharacteristicNotification(const std::string& serviceUuid, const std::string& characteristicUuid) {
    // Implementación para detener la notificación de la característica
    Log("Deteniendo notificación de la característica con UUID: " + characteristicUuid + " del servicio con UUID: " + serviceUuid);

    GUID serviceGuid;
    if (CLSIDFromString(std::wstring(serviceUuid.begin(), serviceUuid.end()).c_str(), &serviceGuid) != NOERROR) 
    {
      Log("Error: No se pudo convertir el UUID del servicio.");
      return;
    }

    GUID charGuid;
    if (CLSIDFromString(std::wstring(characteristicUuid.begin(), characteristicUuid.end()).c_str(), &charGuid) != NOERROR)
    {
      Log("Error: No se pudo convertir el UUID de la característica.");
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
    if (!pServiceBuffer) {
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

    // Buscar la característica con el UUID especificado
    PBTH_LE_GATT_CHARACTERISTIC pCharacteristic = nullptr;
    for (USHORT i = 0; i < charBufferCount; i++) {
      if (IsEqualGUID(pCharBuffer[i].CharacteristicUuid.Value.LongUuid, charGuid)) {
        pCharacteristic = &pCharBuffer[i];
        break;
      }
    }

    if (!pCharacteristic) {
      Log("Error: No se encontró la característica con el UUID especificado.");
      return;
    }

    // Deshabilitar la notificación de la característica
    BTH_LE_GATT_DESCRIPTOR_VALUE newValue;
    RtlZeroMemory(&newValue, sizeof(newValue));
    newValue.DescriptorType = ClientCharacteristicConfiguration;
    newValue.ClientCharacteristicConfiguration.IsSubscribeToNotification = FALSE;

    hr = BluetoothGATTSetDescriptorValue(
      hDevice,
      pCharacteristic,
      &newValue,
      BLUETOOTH_GATT_FLAG_NONE
    );

    if (FAILED(hr)) {
      Log("Error: No se pudo deshabilitar la notificación de la característica.");
      return;
    }

    Log("Notificación de la característica deshabilitada con éxito.");
  }

}; // class BLEDeviceManager
} // namespace layrz_ble