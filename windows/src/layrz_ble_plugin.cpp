#include "layrz_ble_plugin.h"
namespace layrz_ble {
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>LayrzBlePlugin::methodChannel = nullptr;
  std::string LayrzBlePlugin::filteredDeviceId = std::string("");
  std::unique_ptr<BleScanResult> LayrzBlePlugin::connectedDevice = nullptr;

  /// @brief Register the plugin with the registrar
  /// @param registrar
  /// @return void
  void LayrzBlePlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar) {
    auto plugin = std::make_unique<LayrzBlePlugin>(registrar);
    methodChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(registrar->messenger(), "com.layrz.layrz_ble", &flutter::StandardMethodCodec::GetInstance());

    methodChannel->SetMethodCallHandler([plugin_pointer = plugin.get()](const auto &call, auto result) 
      {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      }
    );

    registrar->AddPlugin(std::move(plugin));
  } // RegisterWithRegistrar

  /// @brief Construct a new LayrzBlePlugin object
  /// @param registrar
  LayrzBlePlugin::LayrzBlePlugin(flutter::PluginRegistrarWindows *registrar) : uiThreadHandler_(registrar) {
    GetRadios();
  }

  /// @brief Destroy the LayrzBlePlugin object
  LayrzBlePlugin::~LayrzBlePlugin() {}

  /// @brief Handle the method call
  /// @param method_call
  /// @param result
  /// @return void
  void LayrzBlePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
  ) {
    Log("Handling method call: " + method_call.method_name());
    auto method = method_call.method_name();

    if (method.compare("checkCapabilities") == 0)
      checkCapabilities(std::move(result));
    else if (method.compare("startScan") == 0)
      startScan(method_call, std::move(result));
    else if (method.compare("stopScan") == 0)
      stopScan(method_call, std::move(result));
    else if (method.compare("connect") == 0)
      connect(method_call, std::move(result));
    else if (method.compare("disconnect") == 0)
      disconnect(method_call, std::move(result));
    else if (method.compare("discoverServices") == 0)
      discoverServices(method_call, std::move(result));
    else if (method.compare("setMtu") == 0)
      setMtu(method_call, std::move(result));
    else if (method.compare("readCharacteristic") == 0)
      readCharacteristic(method_call, std::move(result));
    else if (method.compare("writeCharacteristic") == 0)
      writeCharacteristic(method_call, std::move(result));
    else if (method.compare("startNotify") == 0)
      startNotify(method_call, std::move(result));
    else if (method.compare("stopNotify") == 0)
      stopNotify(method_call, std::move(result));
    else
      result->NotImplemented();
  } // HandleMethodCall

  /// @brief Get the Radios object
  /// @return winrt::fire_and_forget
  winrt::fire_and_forget LayrzBlePlugin::GetRadios() {
    auto radios = co_await Radio::GetRadiosAsync();
    for(auto radio : radios)
      if(radio.Kind() == RadioKind::Bluetooth)
      {
        Log("Bluetooth radio found");
        btRadio = radio;
        break;
      }

    if(!btRadio)
      Log("No Bluetooth radio found");
  } // GetRadiosAync

  // ===============
  // Private methods
  // ===============

  /// @brief Check the capabilities of the device
  /// @param result
  /// @return void
  void LayrzBlePlugin::checkCapabilities(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    flutter::EncodableMap response;
    bool hasPermissions =(btRadio != nullptr);

    response[flutter::EncodableValue("locationPermission")]              = flutter::EncodableValue(hasPermissions);
    response[flutter::EncodableValue("bluetoothPermission")]             = flutter::EncodableValue(hasPermissions);
    response[flutter::EncodableValue("bluetoothAdminOrScanPermission")]  = flutter::EncodableValue(hasPermissions);
    response[flutter::EncodableValue("bluetoothConnectPermission")]      = flutter::EncodableValue(hasPermissions);

    result->Success(response);
  } // checkCapabilities

  /// @brief Start the scan
  /// @param method_call
  /// @param result
  /// @return void
  void LayrzBlePlugin::startScan(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result
  ) {
    filteredDeviceId = std::string("");

    // Get macAddress from arguments
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto macAddressFind = arguments.find(flutter::EncodableValue("macAddress"));
    if(macAddressFind != arguments.end())
    {
      try {
        Log("Filtering by macAddress");
        auto macAddress = std::get<std::string>(macAddressFind->second);
        Log("Casting");
        filteredDeviceId = toLowercase(macAddress);
        Log("Filtered by macAddress: " + filteredDeviceId);
      } catch (...) {
        Log("Error filtering by macAddress");
        filteredDeviceId = std::string("");
      }
    }

    // Check if the radio is on
    if(btRadio && btRadio.State() == RadioState::On)
    {
      Log("Setting up the device watcher");
      setupWatcher();
      Log("Device watcher set up");
      // Start the scan
      if(btScanner.Status() != DeviceWatcherStatus::Started)
      {
        Log("Starting Bluetooth(Classic) watcher");
        btScanner.Start();
      }
      else
        Log("Bluetooth(Classic) watcher already started");
      // Start the scan
      if(leScanner.Status() != BluetoothLEAdvertisementWatcherStatus::Started)
      {
        Log("Starting Bluetooth LE watcher");
        leScanner.Start();
      }
      else
        Log("Bluetooth LE watcher already started");
      result->Success(true);
    }
    else
    {
      Log("Bluetooth radio is off");
      result->Success(false);
    }
  } // startScan

  /// @brief Stop the scan
  /// @param method_call
  /// @param result
  /// @return void
  void LayrzBlePlugin::stopScan(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result
  ) {
    // Stop the scan
    if(btScanner != nullptr)
    {
      Log("Stopping Bluetooth(Classic) watcher");
      btScanner.Stop();
      btScanner = nullptr;
    }
    else
      Log("Bluetooth(Classic) watcher is not running");
    // Stopping the scan
    if(leScanner != nullptr)
    {
      Log("Stopping Bluetooth LE watcher");
      leScanner.Stop();
      leScanner = nullptr;
    }
    else
      Log("Bluetooth LE watcher is not running");
    result->Success(true);
  } // stopScan

  /// @brief Setup the watcher
  /// @return void
  void LayrzBlePlugin::setupWatcher() {
    deviceWatcherDevices.clear();

    if (btScanner == nullptr) 
    {
      btScanner = DeviceInformation::CreateWatcher(Windows::Devices::Bluetooth::BluetoothDevice::GetDeviceSelector());
      // Subscribe to the Added event
      btScanner.Added([this](DeviceWatcher const&, DeviceInformation const& device) 
        {
          std::string deviceId = toLowercase(HStringToString(device.Id()));
          deviceWatcherDevices.insert_or_assign(deviceId, device);
          handleScanResult(device);
        }
      );
      // Subscribe to the Updated event
      btScanner.Updated([this](DeviceWatcher const&, DeviceInformationUpdate const& args) 
        {
          auto deviceId = toLowercase(HStringToString(args.Id()));
          auto it = deviceWatcherDevices.find(deviceId);
          if (it != deviceWatcherDevices.end()) 
          {
            it->second.Update(args);
            handleScanResult(it->second);
          }
        }
      );
      // Subscribe to the Removed event
      btScanner.Removed([this](DeviceWatcher const&, DeviceInformationUpdate const& args)
        {
          auto deviceId = toLowercase(HStringToString(args.Id()));
          deviceWatcherDevices.erase(deviceId);
        }
      );
    } // if (btScanner == nullptr)

    if (leScanner == nullptr) 
    {
      leScanner = BluetoothLEAdvertisementWatcher();
      leScanner.ScanningMode(BluetoothLEScanningMode::Active);
      // Subscribe to the Received event
      leScanner.Received([this](BluetoothLEAdvertisementWatcher const&, BluetoothLEAdvertisementReceivedEventArgs const& args)
        {
          auto macAddress = toLowercase(formatBluetoothAddress(args.BluetoothAddress()));

          BleScanResult deviceInfo(macAddress);
          deviceInfo.setAddress(args.BluetoothAddress());

          if (args.Advertisement() != nullptr)
          {
            auto manufacturerItems = args.Advertisement().ManufacturerData();
            for (const auto &item : manufacturerItems) 
            {
              // Append the Company ID to manufacturerData
              // Extract additional data from the IBuffer
              auto dataBuffer = item.Data();
              if (dataBuffer && dataBuffer.Length() > 0) 
              {
                std::vector<uint8_t> manufacturerData;
                auto reader = winrt::Windows::Storage::Streams::DataReader::FromBuffer(dataBuffer);
                std::vector<uint8_t> additionalData(dataBuffer.Length());
                reader.ReadBytes(winrt::array_view<uint8_t>(additionalData));
                // Append the additional data to manufacturerData
                manufacturerData.insert(manufacturerData.end(), additionalData.begin(), additionalData.end());

                deviceInfo.appendManufacturerData(
                  item.CompanyId(),
                  manufacturerData
                );
              } // if (dataBuffer && dataBuffer.Length() > 0)
            } // for (const auto &item : manufacturerItems)

            flutter::EncodableList serviceData = flutter::EncodableList();
            auto serviceItems = args.Advertisement().DataSections();
            for (const auto& section : serviceItems) 
            {
              auto dataType = section.DataType();
              if (
                  dataType == BluetoothLEAdvertisementDataTypes::ServiceData16BitUuids() ||
                  dataType == BluetoothLEAdvertisementDataTypes::ServiceData32BitUuids() ||
                  dataType == BluetoothLEAdvertisementDataTypes::ServiceData128BitUuids() ) 
              {
                auto dataBuffer = section.Data();
                if (dataBuffer && dataBuffer.Length() > 0) 
                {
                  auto reader = winrt::Windows::Storage::Streams::DataReader::FromBuffer(dataBuffer);
                  std::vector<uint8_t> additionalData(dataBuffer.Length());
                  reader.ReadBytes(winrt::array_view<uint8_t>(additionalData));

                  // Separate UUID from additional data
                  size_t uuidLength = 0;

                  if (dataType == BluetoothLEAdvertisementDataTypes::ServiceData16BitUuids())  { // 16-bit UUID
                    uuidLength = 2;
                  } else if (dataType == BluetoothLEAdvertisementDataTypes::ServiceData32BitUuids())  { // 32-bit UUID
                    uuidLength = 4;
                  } else if (dataType == BluetoothLEAdvertisementDataTypes::ServiceData128BitUuids())  { // 128-bit UUID
                    uuidLength = 16;
                  }

                  std::vector<uint8_t> uuidBytes(additionalData.begin(), additionalData.begin() + uuidLength);
                  uint16_t uuid = (uuidBytes[1] << 8) | uuidBytes[0];
                  std::vector<uint8_t> valueBytes(additionalData.begin() + uuidLength, additionalData.end());


                  deviceInfo.appendServiceData(uuid, valueBytes);
                } // if (dataBuffer && dataBuffer.Length() > 0)
              } // if (dataType == BluetoothLEAdvertisementDataTypes::ServiceData16BitUuids() || ...)
            } // for (const auto& section : serviceItems)

            auto name = HStringToString(args.Advertisement().LocalName());
            if (!name.empty()) 
              deviceInfo.setName(name);
            else
            {
              auto it = deviceWatcherDevices.find(macAddress);
              if (it != deviceWatcherDevices.end()) 
                deviceInfo.setName(HStringToString(it->second.Name()));
            } // if (!name.empty())
          } // if (args.Advertisement() != nullptr)

          auto rssi = args.RawSignalStrengthInDBm();
          if (rssi)
            deviceInfo.setRssi(rssi);

          // Get the txPower
          if (args.TransmitPowerLevelInDBm()) {
            auto txPower = args.TransmitPowerLevelInDBm().Value();
            deviceInfo.setTxPower(static_cast<int16_t>(txPower));
          }

          handleBleScanResult(deviceInfo);
        }
      );
    } // if (leScanner == nullptr)
  } // setupWatcher

  /// @brief Handle the scan result
  /// @param device 
  /// @return void
  void LayrzBlePlugin::handleScanResult(DeviceInformation device) {
    auto properties = device.Properties();

    auto bluetoothAddressPropertyValue = properties.Lookup(L"System.Devices.Aep.DeviceAddress").as<IPropertyValue>();
    std::string macAddress = toLowercase(HStringToString(bluetoothAddressPropertyValue.GetString()));

    auto result = BleScanResult(macAddress);
    if(!device.Name().empty())
      result.setName(HStringToString(device.Name()));

    if(properties.HasKey(L"System.Devices.Aep.SignalStrength"))
    {
      auto signalStrength = properties.Lookup(L"System.Devices.Aep.SignalStrength").as<IPropertyValue>();
      result.setRssi(signalStrength.GetInt64());
    }

    handleBleScanResult(result);
  } // handleScanResult

  /// @brief Handle the BLE scan result
  /// @param result
  /// @return void
  void LayrzBlePlugin::handleBleScanResult(BleScanResult &result) {
    if(result.DeviceId().empty())
    {
      Log("Empty Mac Address");
      return;
    }

    if(filteredDeviceId.length() > 0 && result.DeviceId() != filteredDeviceId)
      return;

    // Check if the result.deviceId is inside of visibleDevices
    auto it = visibleDevices.find(result.DeviceId());

    if(it != visibleDevices.end()) {
      // Update the existing device
      // Check if the name is not empty to update it
      auto &device = it->second;
      if(result.Name()) {
        device.setName(*result.Name());
      }

      if(result.Rssi()) {
        device.setRssi(result.Rssi());
      }

      if (!result.ServiceData()->empty()) {
        for (const auto &serviceData : *result.ServiceData()) {
          device.appendServiceData(serviceData.first, serviceData.second);
        }
      }

      if (!result.ManufacturerData()->empty()) {
        for (const auto &mfd : *result.ManufacturerData()) {
          device.appendManufacturerData(mfd.first, mfd.second);
        }
      }

      visibleDevices.insert_or_assign(result.DeviceId(), device);
    } else {
      visibleDevices.insert_or_assign(result.DeviceId(), result);
    }

    const auto &device = visibleDevices[result.DeviceId()];
    flutter::EncodableMap response;

    response[flutter::EncodableValue("macAddress")]       = flutter::EncodableValue(device.DeviceId());
    response[flutter::EncodableValue("name")]             = flutter::EncodableValue(device.Name() ? *device.Name() : "Unknown");
    response[flutter::EncodableValue("rssi")]             = flutter::EncodableValue(device.Rssi());
    if (device.TxPower()) {
      response[flutter::EncodableValue("txPower")]        = flutter::EncodableValue(device.TxPower());
    }

    if (device.ManufacturerData() != nullptr) {
      flutter::EncodableList manufacturerDataList;
      for (const auto &mfd : *device.ManufacturerData()) {
        flutter::EncodableMap mfdMap = flutter::EncodableMap();
        mfdMap[flutter::EncodableValue("companyId")] = flutter::EncodableValue(mfd.first);
        mfdMap[flutter::EncodableValue("data")] = flutter::EncodableValue(mfd.second);
        
        manufacturerDataList.push_back(mfdMap);
      }

      response[flutter::EncodableValue("manufacturerData")] = flutter::EncodableValue(manufacturerDataList);
    }
    
    if (device.ServiceData() != nullptr) {
      flutter::EncodableList serviceDataList;
      for (const auto &serviceData : *device.ServiceData()) {
        flutter::EncodableMap serviceDataMap = flutter::EncodableMap();
        serviceDataMap[flutter::EncodableValue("uuid")] = flutter::EncodableValue(serviceData.first);
        serviceDataMap[flutter::EncodableValue("data")] = flutter::EncodableValue(serviceData.second);
        
        serviceDataList.push_back(serviceDataMap);
      }

      response[flutter::EncodableValue("serviceData")] = flutter::EncodableValue(serviceDataList);
    }
    
    if(methodChannel != nullptr) {
      uiThreadHandler_.Post([this, response]() {
        methodChannel->InvokeMethod(
          "onScan",
          std::make_unique<flutter::EncodableValue>(response)
        );
      });
    }
  } // handleBleScanResult

  /// @brief Connect to the device
  /// @param method_call
  /// @param result
  /// @return void
  winrt::fire_and_forget LayrzBlePlugin::connect(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result
  ) {
    if (connectedDevice != nullptr) 
    {
      Log("Already connected to a device");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto macAddress = std::get<std::string>(*method_call.arguments());
    Log("MacAddress casted to " + macAddress);
    auto it = visibleDevices.find(toLowercase(macAddress));
    if (it == visibleDevices.end()) {
      Log("Device not found");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    if(btScanner != nullptr){
      Log("Stopping Bluetooth(Classic) watcher");
      btScanner.Stop();
      btScanner = nullptr;
    }

    // Stopping the scan
    if(leScanner != nullptr){
      Log("Stopping Bluetooth LE watcher");
      leScanner.Stop();
      leScanner = nullptr;

      if (methodChannel != nullptr) {
        methodChannel->InvokeMethod(
          "onEvent",
          std::make_unique<flutter::EncodableValue>("SCAN_STOPPED")
        );
      }
    }

    Log("Device found, attempting to get");
    auto device = it->second;

    auto connDevice = co_await BluetoothLEDevice::FromBluetoothAddressAsync(device.Address());
    if (!connDevice) {
      Log("Failed to connect to the device");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    servicesAndCharacteristics.clear();
    servicesNotifying.clear();
    device.setDevice(connDevice);

    Log("Device found, attempting to get GATT services");
    auto servicesResult = co_await connDevice.GetGattServicesAsync((BluetoothCacheMode::Uncached));
    auto status = servicesResult.Status();
    if (status != GattCommunicationStatus::Success) {
      Log("Failed to get GATT services");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    for (auto service : servicesResult.Services()) {
      auto serviceUuid = toLowercase(GuidToString(service.Uuid()));
      servicesAndCharacteristics[serviceUuid] = BleService(service);

      auto characteristics = co_await service.GetCharacteristicsAsync(BluetoothCacheMode::Uncached);
      for (auto characteristic : characteristics.Characteristics()) {
        auto characteristicUuid = toLowercase(GuidToString(characteristic.Uuid()));
        servicesAndCharacteristics[serviceUuid].addCharacteristic(BleCharacteristic(characteristic));
      }
    }

    connDevice.ConnectionStatusChanged({this, &LayrzBlePlugin::onConnectionStatusChanged});

    Log("GATT Services discovered");
    connectedDevice = std::make_unique<BleScanResult>(device);
    result->Success(flutter::EncodableValue(true));

    if (methodChannel != nullptr) {
      uiThreadHandler_.Post([this]() {
        methodChannel->InvokeMethod(
          "onEvent",
          std::make_unique<flutter::EncodableValue>("CONNECTED")
        ); 
      });
    }
    co_return;
  } // connect

  /// @brief Disconnect from the device
  /// @param method_call 
  /// @param result 
  /// @return void
  winrt::fire_and_forget LayrzBlePlugin::disconnect(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result
  ) {
    if (connectedDevice == nullptr) 
    {
      Log("Not connected to a device");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    
    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    device->Close();
    connectedDevice = nullptr;
    servicesNotifying.clear();
    servicesAndCharacteristics.clear();

    result->Success(flutter::EncodableValue(true));
    if (methodChannel != nullptr) {
      methodChannel->InvokeMethod(
        "onEvent",
        std::make_unique<flutter::EncodableValue>("DISCONNECTED")
      ); 
    }
    co_return;
  } // disconnect

  /// @brief Discover services and characteristics of the device
  /// @param method_call
  /// @param result
  /// @return void
  winrt::fire_and_forget LayrzBlePlugin::discoverServices(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
  ) {
    if (connectedDevice == nullptr)
    {
      Log("Not connected to a device");
      result->Success(flutter::EncodableValue());
      co_return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result->Success(flutter::EncodableValue());
      co_return;
    }

    auto gatt = co_await GattSession::FromDeviceIdAsync(device->BluetoothDeviceId());
    if (!gatt) {
      Log("Failed to get GATT session");
      result->Success(flutter::EncodableValue());
      co_return;
    }


    flutter::EncodableList output = {};
    for (auto [serviceUuid, service] : servicesAndCharacteristics) {

      flutter::EncodableList characteristicsOutput = {};
      for (auto [characteristicUuid, characteristicItm] : service.Characteristics()) {
        auto characteristic = characteristicItm.Characteristic();
        flutter::EncodableMap characteristicObj = {};
        flutter::EncodableList propertiesList = {};

        std::vector<std::string> propertiesToStore = {};

        auto properties = characteristic.CharacteristicProperties();
        if ((properties & GattCharacteristicProperties::Read) == GattCharacteristicProperties::Read) {
          propertiesList.push_back(flutter::EncodableValue("READ"));
          propertiesToStore.push_back("READ");
        }
        
        if ((properties & GattCharacteristicProperties::Write) == GattCharacteristicProperties::Write) {
          propertiesList.push_back(flutter::EncodableValue("WRITE"));
          propertiesToStore.push_back("WRITE");
        }
        
        if ((properties & GattCharacteristicProperties::Notify) == GattCharacteristicProperties::Notify) {
          propertiesList.push_back(flutter::EncodableValue("NOTIFY"));
          propertiesToStore.push_back("NOTIFY");
        }
        
        if ((properties & GattCharacteristicProperties::Indicate) == GattCharacteristicProperties::Indicate) {
          propertiesList.push_back(flutter::EncodableValue("INDICATE"));
          propertiesToStore.push_back("INDICATE");
        }

        if ((properties & GattCharacteristicProperties::AuthenticatedSignedWrites) == GattCharacteristicProperties::AuthenticatedSignedWrites) {
          propertiesList.push_back(flutter::EncodableValue("AUTH_SIGN_WRITES"));
          propertiesToStore.push_back("AUTH_SIGN_WRITES");
        }

        if ((properties & GattCharacteristicProperties::ExtendedProperties) == GattCharacteristicProperties::ExtendedProperties) {
          propertiesList.push_back(flutter::EncodableValue("EXTENDED_PROP"));
          propertiesToStore.push_back("EXTENDED_PROP");
        }

        if ((properties & GattCharacteristicProperties::Broadcast) == GattCharacteristicProperties::Broadcast) {
          propertiesList.push_back(flutter::EncodableValue("BROADCAST"));
          propertiesToStore.push_back("BROADCAST");
        }
        
        if ((properties & GattCharacteristicProperties::WriteWithoutResponse) == GattCharacteristicProperties::WriteWithoutResponse) {
          propertiesList.push_back(flutter::EncodableValue("WRITE_WO_RSP"));
          propertiesToStore.push_back("WRITE_WO_RSP");
        }

        characteristicObj[flutter::EncodableValue("uuid")] = flutter::EncodableValue(characteristicUuid);
        characteristicObj[flutter::EncodableValue("properties")] = propertiesList;

        characteristicsOutput.push_back(characteristicObj);
      }

      flutter::EncodableMap serviceMap = {};
      serviceMap[flutter::EncodableValue("uuid")] = flutter::EncodableValue(serviceUuid);
      serviceMap[flutter::EncodableValue("characteristics")] = characteristicsOutput;
      output.push_back(serviceMap);
    }

    result->Success(output);
  } // discoverServices

  /// @brief Set the MTU (Only return the current MTU, do not negotiate)
  /// @param method_call
  /// @param result
  /// @return void
  winrt::fire_and_forget LayrzBlePlugin::setMtu(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
  ) {
    if (connectedDevice == nullptr)
    {
      Log("Not connected to a device");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto gatt = co_await GattSession::FromDeviceIdAsync(device->BluetoothDeviceId());
    if (!gatt) {
      Log("Failed to get GATT session");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto mtu = gatt.MaxPduSize();
    result->Success(flutter::EncodableValue(mtu));
    co_return;
  } // setMtu
  
  /// @brief Read the characteristic
  /// @param method_call
  /// @param result 
  /// @return void
  winrt::fire_and_forget LayrzBlePlugin::readCharacteristic(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result->Success(flutter::EncodableValue());
      co_return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result->Success(flutter::EncodableValue());
      co_return;
    }

    // Log("Casting arguments");
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    // Log("Getting service UUID");
    auto rawServiceUuid = arguments.find(flutter::EncodableValue("serviceUuid"));
    if (rawServiceUuid == arguments.end()) {
      Log("Service UUID not provided");
      result->Success(flutter::EncodableValue());
      co_return;
    }
    // Log("Casting service UUID");
    auto serviceUuid = toLowercase(std::get<std::string>(rawServiceUuid->second));

    // Log("Casting characteristic UUID");
    auto rawCharacteristicUuid = arguments.find(flutter::EncodableValue("characteristicUuid"));
    if (rawCharacteristicUuid == arguments.end()) {
      Log("Characteristic UUID not provided");
      result->Success(flutter::EncodableValue());
      co_return;
    }
    // Log("Casting characteristic UUID");
    auto characteristicUuid = toLowercase(std::get<std::string>(rawCharacteristicUuid->second));

    if (servicesNotifying.find(characteristicUuid) != servicesNotifying.end()) {
      Log("This characteristic " + characteristicUuid + " is notifying, so we can't read it");
      result->Success(flutter::EncodableValue());
      co_return;
    }

    // Log("Getting service from GATT " + serviceUuid);
    auto serviceSearch = servicesAndCharacteristics.find(serviceUuid);
    if (serviceSearch == servicesAndCharacteristics.end()) {
      Log("Service " + serviceUuid + " not found");
      result->Success(flutter::EncodableValue());
      co_return;
    }

    auto service = serviceSearch->second;

    auto characteristics = service.Characteristics();
    // Log("Getting characteristic from service " + serviceUuid);
    auto characteristicSearch = characteristics.find(characteristicUuid);
    if (characteristicSearch == characteristics.end()) {
      Log("Characteristic " + characteristicUuid + " not found in service " + serviceUuid);
      result->Success(flutter::EncodableValue());
      co_return;
    }

    auto characteristic = characteristicSearch->second.Characteristic();

    auto properties = characteristic.CharacteristicProperties();
    if ((properties & GattCharacteristicProperties::Read) != GattCharacteristicProperties::Read) {
      Log("Characteristic does not support writing");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto data = co_await characteristic.ReadValueAsync();
    if (data.Status() != GattCommunicationStatus::Success) {
      Log("Failed to read characteristic value");
      result->Success(flutter::EncodableValue());
      co_return;
    }

    auto value = IBufferToVector(data.Value());
    result->Success(flutter::EncodableValue(value));
  } // readCharacteristic

  /// @brief Write to the characteristic
  /// @param method_call 
  /// @param result 
  /// @return 
  winrt::fire_and_forget LayrzBlePlugin::writeCharacteristic(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    // Log("Casting arguments");
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    // Log("Getting service UUID");
    auto rawServiceUuid = arguments.find(flutter::EncodableValue("serviceUuid"));
    if (rawServiceUuid == arguments.end()) {
      Log("Service UUID not provided");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    // Log("Casting service UUID");
    auto serviceUuid = toLowercase(std::get<std::string>(rawServiceUuid->second));

    // Log("Casting characteristic UUID");
    auto rawCharacteristicUuid = arguments.find(flutter::EncodableValue("characteristicUuid"));
    if (rawCharacteristicUuid == arguments.end()) {
      Log("Characteristic UUID not provided");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    // Log("Casting characteristic UUID");
    auto characteristicUuid = toLowercase(std::get<std::string>(rawCharacteristicUuid->second));

    // Log("Getting payload");
    auto rawPayload = arguments.find(flutter::EncodableValue("payload"));
    if (rawPayload == arguments.end()) {
      Log("Payload not provided");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    auto payload = std::get<std::vector<uint8_t>>(rawPayload->second);

    // Log("Getting withResponse");
    auto rawWithResponse = arguments.find(flutter::EncodableValue("withResponse"));
    bool withResponse = false;
    if (rawWithResponse != arguments.end()) {
      withResponse = std::get<bool>(rawWithResponse->second);
    }

    Log("With response: " + std::to_string(withResponse));

    // Log("Getting service from GATT " + serviceUuid);
    auto serviceSearch = servicesAndCharacteristics.find(serviceUuid);
    if (serviceSearch == servicesAndCharacteristics.end()) {
      Log("Service " + serviceUuid + " not found");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto service = serviceSearch->second;
    auto characteristics = service.Characteristics();

    auto characteristicsSearch = characteristics.find(characteristicUuid);
    if (characteristicsSearch == characteristics.end()) {
      Log("Characteristic " + characteristicUuid + " not found in service " + serviceUuid);
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto characteristic = characteristicsSearch->second.Characteristic();
    auto properties = characteristic.CharacteristicProperties();
    if ((properties & GattCharacteristicProperties::Write) != GattCharacteristicProperties::Write) {
      Log("Characteristic does not support writing");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    // Log("Writing to characteristic " + characteristicUuid + " from service " + serviceUuid);
    auto writeType = withResponse ? GattWriteOption::WriteWithResponse : GattWriteOption::WriteWithoutResponse;
    auto status = co_await characteristic.WriteValueAsync(VectorToIBuffer(payload), writeType);
    if (status != GattCommunicationStatus::Success) {
      Log("Failed to write characteristic value");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    Log("Successfully wrote to characteristic " + characteristicUuid + " from service " + serviceUuid);
    result->Success(flutter::EncodableValue(true));
    co_return;

  } // writeCharacteristic

  /// @brief Start notifications for the characteristic
  /// @param method_call 
  /// @param result 
  /// @return 
  winrt::fire_and_forget LayrzBlePlugin::startNotify(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    // Log("Casting arguments");
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    // Log("Getting service UUID");
    auto rawServiceUuid = arguments.find(flutter::EncodableValue("serviceUuid"));
    if (rawServiceUuid == arguments.end()) {
      Log("Service UUID not provided");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    // Log("Casting service UUID");
    auto serviceUuid = toLowercase(std::get<std::string>(rawServiceUuid->second));

    // Log("Casting characteristic UUID");
    auto rawCharacteristicUuid = arguments.find(flutter::EncodableValue("characteristicUuid"));
    if (rawCharacteristicUuid == arguments.end()) {
      Log("Characteristic UUID not provided");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    // Log("Casting characteristic UUID");
    auto characteristicUuid = toLowercase(std::get<std::string>(rawCharacteristicUuid->second));

    if (servicesNotifying.find(characteristicUuid) != servicesNotifying.end()) {
      Log("Already subscribed to characteristic notifications");
      result->Success(flutter::EncodableValue(true));
      co_return;
    }

    auto serviceSearch = servicesAndCharacteristics.find(serviceUuid);
    if (serviceSearch == servicesAndCharacteristics.end()) {
      Log("Service " + serviceUuid + " not found");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    auto service = serviceSearch->second;
    auto characteristics = service.Characteristics();

    auto characteristicsSearch = characteristics.find(characteristicUuid);
    if (characteristicsSearch == characteristics.end()) {
      Log("Characteristic " + characteristicUuid + " not found in service " + serviceUuid);
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto characteristic = characteristicsSearch->second.Characteristic();

    auto properties = characteristic.CharacteristicProperties();
    if ((properties & GattCharacteristicProperties::Notify) != GattCharacteristicProperties::Notify) {
      // Log("Characteristic does not support notifications");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    // Log("Subscribing to characteristic " + characteristicUuid + " from service " + serviceUuid);
    auto descriptor = GattClientCharacteristicConfigurationDescriptorValue::Notify;

    try {
      auto status = co_await characteristic.WriteClientCharacteristicConfigurationDescriptorAsync(descriptor);
      if (status != GattCommunicationStatus::Success) {
        // Log("Failed to subscribe to characteristic notifications");
        result->Success(flutter::EncodableValue(false));
        co_return;
      }

      servicesNotifying[characteristicUuid] = {0};
      characteristic.ValueChanged(servicesNotifying[characteristicUuid]);
      auto token = characteristic.ValueChanged({this, &LayrzBlePlugin::onCharacteristicValueChanged});
      servicesNotifying[characteristicUuid] = token;
      Log("Successfully subscribed to characteristic " + characteristicUuid + " from service " + serviceUuid);
    } catch (...) {
      Log("Failed to subscribe to characteristic notifications");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    result->Success(flutter::EncodableValue(true));
    co_return;
  } // startNotify

  /// @brief Stop notifications for the characteristic
  /// @param method_call 
  /// @param result 
  /// @return 
  winrt::fire_and_forget LayrzBlePlugin::stopNotify(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    // Log("Casting arguments");
    auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
    // Log("Getting service UUID");
    auto rawServiceUuid = arguments.find(flutter::EncodableValue("serviceUuid"));
    if (rawServiceUuid == arguments.end()) {
      Log("Service UUID not provided");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    // Log("Casting service UUID");
    auto serviceUuid = toLowercase(std::get<std::string>(rawServiceUuid->second));

    // Log("Casting characteristic UUID");
    auto rawCharacteristicUuid = arguments.find(flutter::EncodableValue("characteristicUuid"));
    if (rawCharacteristicUuid == arguments.end()) {
      Log("Characteristic UUID not provided");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    // Log("Casting characteristic UUID");
    auto characteristicUuid = toLowercase(std::get<std::string>(rawCharacteristicUuid->second));

    if (servicesNotifying.find(characteristicUuid) == servicesNotifying.end()) {
      Log("Already not subscribed to characteristic notifications");
      result->Success(flutter::EncodableValue(true));
      co_return;
    }

    auto serviceSearch = servicesAndCharacteristics.find(serviceUuid);
    if (serviceSearch == servicesAndCharacteristics.end()) {
      Log("Service " + serviceUuid + " not found");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }
    auto service = serviceSearch->second;

    auto characteristics = service.Characteristics();

    auto characteristicsSearch = characteristics.find(characteristicUuid);
    if (characteristicsSearch == characteristics.end()) {
      Log("Characteristic " + characteristicUuid + " not found in service " + serviceUuid);
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    auto characteristic = characteristicsSearch->second.Characteristic();

    auto properties = characteristic.CharacteristicProperties();
    if ((properties & GattCharacteristicProperties::Notify) != GattCharacteristicProperties::Notify) {
      // Log("Characteristic does not support notifications");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    // Log("Subscribing to characteristic " + characteristicUuid + " from service " + serviceUuid);
    auto descriptor = GattClientCharacteristicConfigurationDescriptorValue::None;

    try {
      auto status = co_await characteristic.WriteClientCharacteristicConfigurationDescriptorAsync(descriptor);
      if (status != GattCommunicationStatus::Success) {
        // Log("Failed to subscribe to characteristic notifications");
        result->Success(flutter::EncodableValue(false));
        co_return;
      }

      servicesNotifying[characteristicUuid] = {0};
      characteristic.ValueChanged(servicesNotifying[characteristicUuid]);
      servicesNotifying.erase(characteristicUuid);
      Log("Successfully unsubscribed to characteristic " + characteristicUuid + " from service " + serviceUuid);
    } catch (...) {
      Log("Failed to unsubscribe to characteristic notifications");
      result->Success(flutter::EncodableValue(false));
      co_return;
    }

    result->Success(flutter::EncodableValue(true));
    co_return;
  } // stopNotify

  /// @brief When the characteristic value changed
  /// @param sender 
  /// @param args 
  void LayrzBlePlugin::onCharacteristicValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args) {
    Log("Received characteristic value changed event");
    auto characteristicUuid = toLowercase(GuidToString(sender.Uuid()));
    Log("Characteristic UUID: " + characteristicUuid);
    auto serviceUuid = toLowercase(GuidToString(sender.Service().Uuid()));
    Log("Service UUID: " + serviceUuid);
    auto value = IBufferToVector(args.CharacteristicValue());
    Log("Data size: " + std::to_string(value.size()));

    flutter::EncodableMap response = {};
    response[flutter::EncodableValue("serviceUuid")] = flutter::EncodableValue(serviceUuid);
    response[flutter::EncodableValue("characteristicUuid")] = flutter::EncodableValue(characteristicUuid);
    response[flutter::EncodableValue("value")] = flutter::EncodableValue(value);

    if (methodChannel != nullptr) {
      uiThreadHandler_.Post([this, response]() {
        methodChannel->InvokeMethod(
          "onNotify",
          std::make_unique<flutter::EncodableValue>(response)
        );
      });
    }
  } // onCharacteristicValueChanged

  /// @brief When the connection status changed
  /// @param device 
  /// @param args 
  void LayrzBlePlugin::onConnectionStatusChanged(BluetoothLEDevice device, IInspectable args) {
    auto status = device.ConnectionStatus();
    if (status == BluetoothConnectionStatus::Disconnected) {
      connectedDevice = nullptr;
      servicesNotifying.clear();

      if (methodChannel != nullptr) {
        uiThreadHandler_.Post([this]() {
          methodChannel->InvokeMethod(
            "onEvent",
            std::make_unique<flutter::EncodableValue>("DISCONNECTED")
          );
        });
      }
    } else if (status == BluetoothConnectionStatus::Connected) {
      if (methodChannel != nullptr) {
        uiThreadHandler_.Post([this]() {
          methodChannel->InvokeMethod(
            "onEvent",
            std::make_unique<flutter::EncodableValue>("CONNECTED")
          );
        });
      }
    }
  } // onConnectionStatusChanged

  std::string LayrzBlePlugin::standarizeServiceUuid(std::string rawUuid) {
    return rawUuid.substr(2,2) + rawUuid.substr(0,2);
  }
} // namespace layrz_ble
