#include "layrz_ble_plugin.h"

namespace layrz_ble {
  using layrz_ble::ErrorOr;
  using layrz_ble::LayrzBleCallbackChannel;
  using layrz_ble::LayrzBlePlatformChannel;

  std::string LayrzBlePlugin::filteredDeviceId = std::string("");
  std::unique_ptr<BleScanResult> LayrzBlePlugin::connectedDevice = nullptr;
  static std::unique_ptr<LayrzBleCallbackChannel> callbackChannel;

  /// @brief Register the plugin with the registrar
  /// @param registrar
  /// @return void
  void LayrzBlePlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar) {
    auto plugin = std::make_unique<LayrzBlePlugin>(registrar);
    SetUp(registrar->messenger(), plugin.get());
    callbackChannel = std::make_unique<LayrzBleCallbackChannel>(registrar->messenger());
    registrar->AddPlugin(std::move(plugin));
  } // RegisterWithRegistrar

  /// @brief Construct a new LayrzBlePlugin object
  /// @param registrar
  LayrzBlePlugin::LayrzBlePlugin(flutter::PluginRegistrarWindows *registrar) : uiThreadHandler_(registrar) {
    GetRadiosAsync();
  }

  /// @brief Destroy the LayrzBlePlugin object
  LayrzBlePlugin::~LayrzBlePlugin() = default;

  /// @brief Get the Radios available on the system
  /// @return winrt::fire_and_forget
  winrt::fire_and_forget LayrzBlePlugin::GetRadiosAsync() {
    try {
      BluetoothAdapter adapter = co_await BluetoothAdapter::GetDefaultAsync();
      Log("Adapter checks:");
      Log("\tIsLowEnergySupported: %s", BooleanToString(adapter.IsLowEnergySupported()).c_str());
      Log("\tIsClassicSupported: %s", BooleanToString(adapter.IsClassicSupported()).c_str());
      Log("\tIsExtendedAdvertisingSupported: %s", BooleanToString(adapter.IsExtendedAdvertisingSupported()).c_str());

      if (adapter.IsLowEnergySupported()) {
        Log("Valid adapter found!");
        btRadio = co_await adapter.GetRadioAsync();
        if (adapter.IsExtendedAdvertisingSupported()) {
          Log("\tBluetooth 5.X supported!");
        } else {
          Log("\tBluetooth 5.X not supported, falling back to Bluetooth 4.X");
        }
      } else {
        Log("No valid adapter found");
        btRadio = nullptr;
      }
    } catch (...) {
      Log("Failed to get Bluetooth adapter");
      btRadio = nullptr;
    }
  } // GetRadiosAync

  /// @brief Returns the status of the Bluetooth radio and scanners
  /// @param result the callback to return the status
  /// @return void
  /// @note The status is returned as a BtStatus object
  void LayrzBlePlugin::GetStatuses(std::function<void(ErrorOr<BtStatus> reply)> result) {
    bool isScanning = false;
    if (btRadio != nullptr) {
      bool btScannerOn = false;
      if (btScanner != nullptr) {
        Log("Bluetooth classic scanner current status: %s", castBtScannerStatus(btScanner.Status()).c_str());
        btScannerOn = btScanner.Status() == DeviceWatcherStatus::Started || btScanner.Status() == DeviceWatcherStatus::EnumerationCompleted;
      }
      
      bool leScannerOn = false;
      if (leScanner != nullptr) {
        Log("Bluetooth LE scanner current status: %s", castLeScannerStatus(leScanner.Status()).c_str());
        leScannerOn = leScanner.Status() == BluetoothLEAdvertisementWatcherStatus::Started;
      }
      isScanning = btScannerOn && leScannerOn;
    } else {
      isScanning = false;
    }

    result(BtStatus{false, isScanning});
  }

  /// @brief Check the capabilities of the device
  /// @param result the callback to return the capabilities
  /// @return void
  /// @note The capabilities are returned as a boolean
  void LayrzBlePlugin::CheckCapabilities(std::function<void(ErrorOr<bool> reply)> result) {
    result(btRadio != nullptr);
  }

  /// @brief Check the scan permissions of the device
  /// @param result the callback to return the permissions
  /// @return void
  /// @note The permissions are returned as a boolean
  void LayrzBlePlugin::CheckScanPermissions(std::function<void(ErrorOr<bool> reply)> result) {
    result(btRadio != nullptr);
  }

  /// @brief Check the advertise permissions of the device
  /// @param result the callback to return the permissions
  /// @return void
  /// @note Always returns false as the advertise permissions are not available on Windows
  void LayrzBlePlugin::CheckAdvertisePermissions(std::function<void(ErrorOr<bool> reply)> result) {
    result(false);
  }

  /// @brief Starts the Bluetooth classic scanner and LE scanner
  /// @param mac_address the address of the device to scan for
  /// @param services_uuids the list of services to scan for
  /// @param result the callback to return the result of the scan
  /// @return void
  /// @note The result is returned as a boolean
  void LayrzBlePlugin::StartScan(
    const std::string* mac_address,
    const flutter::EncodableList* services_uuids,
    std::function<void(ErrorOr<bool> reply)> result
  ) {
    if (mac_address != nullptr) {
      // Set the filtered device ID to the provided MAC address and uppercase it
      filteredDeviceId = toUppercase(*mac_address);
    } else {
      filteredDeviceId = std::string("");
    }

    if (btRadio && btRadio.State() == RadioState::On) {
      Log("Setting up the device watcher");
      setupWatcher();
      Log("Device watcher set up");
      
      if (btScanner.Status() != DeviceWatcherStatus::Started) {
        Log("Starting Bluetooth(Classic) watcher");
        btScanner.Start();
      } else {
        Log("Bluetooth(Classic) watcher already started");
      }

      if (leScanner.Status() != BluetoothLEAdvertisementWatcherStatus::Started) {
        Log("Starting Bluetooth LE watcher");
        leScanner.Start();
      } else {
        Log("Bluetooth LE watcher already started");
      }

      result(true);
      return;
    }

    result(false);
  }

  /// @brief Stop the Bluetooth classic scanner and LE scanner
  /// @param mac_address the address of the device to stop scanning for
  /// @param result  the callback to return the result of the stop
  /// @return void
  /// @note The result is returned as a boolean
  void LayrzBlePlugin::StopScan(const std::string* mac_address, std::function<void(ErrorOr<bool> reply)> result) {
    if (btScanner != nullptr) {
      Log("Stopping Bluetooth(Classic) watcher");
      btScanner.Stop();
      btScanner = nullptr;
    } else {
      Log("Bluetooth(Classic) watcher is not running");
    }

    if (leScanner != nullptr) {
      Log("Stopping Bluetooth LE watcher");
      leScanner.Stop();
      leScanner = nullptr;
    } else {
      Log("Bluetooth LE watcher is not running");
    }

    result(true);
  }

  /// @brief Connect to a device
  /// @param mac_address the address of the device to connect to
  /// @param result the callback to return the result of the connection
  /// @return void
  /// @note The result is returned as a boolean
  void LayrzBlePlugin::Connect(const std::string& mac_address, std::function<void(ErrorOr<bool> reply)> result) {
    if (connectedDevice != nullptr) {
      Log("Already connected to a device");
      result(false);
      return;
    }
    
    connectAsync(mac_address, result);
  }

  /// @brief Connect to a device asynchronously
  /// @param device the device to connect to
  /// @param result the callback to return the result of the connection
  /// @return void
  /// @note The result is returned as a boolean
  winrt::fire_and_forget LayrzBlePlugin::connectAsync(const std::string& mac_address, std::function<void(ErrorOr<bool> reply)> result) {
    auto it = visibleDevices.find(toLowercase(mac_address));
    if (it == visibleDevices.end()) {
      Log("Device not found");
      result(false);
      return;
    }

    if (btScanner != nullptr) {
      btScanner.Stop();
      btScanner = nullptr;
    }
    if (leScanner != nullptr) {
      leScanner.Stop();
      leScanner = nullptr;
    }

    auto device = it->second;
    Log("Connecting to device: %s", mac_address.c_str());

    try {
      Log("Connecting to device async: %s", device.DeviceId().c_str());
      uint64_t btAddress = device.Address();
      Log("\tBluetooth address: %s", std::to_string(btAddress).c_str());
      auto btDevice = co_await BluetoothLEDevice::FromBluetoothAddressAsync(btAddress);
      if (!btDevice) {
        Log("Failed to connect to device %s", device.DeviceId().c_str());
        result(false);
        co_return;
      }
  
      Log("Connected to device: %s", device.DeviceId().c_str());
  
      servicesAndCharacteristics.clear();
      servicesNotifying.clear();
      device.setDevice(btDevice);
  
      Log("Device found, attempting to get GATT services");
      auto servicesResult = co_await btDevice.GetGattServicesAsync((BluetoothCacheMode::Uncached));
      auto status = servicesResult.Status();
      if (status != GattCommunicationStatus::Success) {
        Log("Failed to get GATT services");
        result(false);
        co_return;
      }
      Log("%d GATT services found", servicesResult.Services().Size());

      for (auto service : servicesResult.Services()) {
        auto serviceUuid = toLowercase(GuidToString(service.Uuid()));
        Log("\tParsing service %s", serviceUuid.c_str());
        servicesAndCharacteristics[serviceUuid] = BleService(service);
  
        auto characteristics = co_await service.GetCharacteristicsAsync(BluetoothCacheMode::Uncached);
        for (auto characteristic : characteristics.Characteristics()) {
          auto characteristicUuid = toLowercase(GuidToString(characteristic.Uuid()));
          Log("\t\tParsing characteristic %s", characteristicUuid.c_str());
          servicesAndCharacteristics[serviceUuid].addCharacteristic(BleCharacteristic(characteristic));
        }
      }
  
      btDevice.ConnectionStatusChanged({this, &LayrzBlePlugin::onConnectionStatusChanged});
      connectedDevice = std::make_unique<BleScanResult>(device);
      result(true);
    } catch (...) {
      Log("Failed to connect to device, general exception");
      result(false);
      co_return;
    }
  } // connectAsync

  /// @brief Disconnect from a device
  /// @param mac_address the address of the device to disconnect from (Not used, Windows only supports single connection)
  /// @param result the callback to return the result of the disconnection
  /// @return void
  /// @note The result is returned as a boolean
  void LayrzBlePlugin::Disconnect(const std::string* mac_address, std::function<void(ErrorOr<bool> reply)> result) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result(false);
      return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result(false);
      return;
    }

    device->Close();

    BtDevice payload = BtDevice(
      toLowercase(HStringToString(device->DeviceId())),
      flutter::EncodableList(),
      flutter::EncodableList()
    );
    
    connectedDevice = nullptr;
    servicesNotifying.clear();
    servicesAndCharacteristics.clear();

    uiThreadHandler_.Post([this, payload]() {
      if (callbackChannel != nullptr) {
        callbackChannel->OnDisconnected(payload, SuccessCallback, ErrorCallback);
      }
    });

    result(true);
  }

  /// @brief Negotiate the MTU size with the device
  /// @param mac_address the address of the device to negotiate the MTU with (Not used, Windows only supports single connection)
  /// @param new_mtu the new MTU size to set (Not used, Windows not support MTU negotiation)
  /// @param result the callback to return the result of the MTU negotiation
  /// @return void
  /// @note The result is returned as an optional int64_t
  void LayrzBlePlugin::SetMtu(
    const std::string& mac_address,
    int64_t new_mtu,
    std::function<void(ErrorOr<std::optional<int64_t>> reply)> result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result(ErrorOr<std::optional<int64_t>>(std::nullopt));
      return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result(ErrorOr<std::optional<int64_t>>(std::nullopt));
      return;
    }

    setMtuAsync(device, result);
    return;
  }

  /// @brief Negotiate the MTU size with the device asynchronously
  /// @param device the device to negotiate the MTU with
  /// @param result the callback to return the result of the MTU negotiation
  /// @return void
  /// @note The result is returned as an optional int64_t
  winrt::fire_and_forget LayrzBlePlugin::setMtuAsync(
    std::optional<BluetoothLEDevice> device,
    std::function<void(ErrorOr<std::optional<int64_t>> reply)> result
  ) {
    auto gatt = co_await GattSession::FromDeviceIdAsync(device->BluetoothDeviceId());
    if (!gatt) {
      Log("Failed to get GATT session");
      result(ErrorOr<std::optional<int64_t>>(std::nullopt));
      co_return;
    }

    auto mtu = gatt.MaxPduSize();
    result(ErrorOr<std::optional<int64_t>>(mtu));
    co_return;
  }

  /// @brief Discover the services and characteristics of the device
  /// @param mac_address the address of the device to discover the services for (Not used, Windows only supports single connection)
  /// @param result the callback to return the result of the discovery
  /// @return void
  /// @note The result is returned as a list of services and characteristics
  void LayrzBlePlugin::DiscoverServices(
    const std::string& mac_address,
    std::function<void(ErrorOr<flutter::EncodableList> reply)> result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result(ErrorOr<flutter::EncodableList>(flutter::EncodableList()));
      return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result(ErrorOr<flutter::EncodableList>(flutter::EncodableList()));
      return;
    }

    flutter::EncodableList output = {};
    for (auto [serviceUuid, service] : servicesAndCharacteristics) {
      flutter::EncodableList characteristicsOutput = {};
      for (auto [characteristicUuid, characteristicItm] : service.Characteristics()) {
        auto characteristic = characteristicItm.Characteristic();
        flutter::EncodableList propertiesList = {};
        auto properties = characteristic.CharacteristicProperties();
        if ((properties & GattCharacteristicProperties::Read) == GattCharacteristicProperties::Read) {
          propertiesList.push_back(flutter::EncodableValue("READ"));
        }
        
        if ((properties & GattCharacteristicProperties::Write) == GattCharacteristicProperties::Write) {
          propertiesList.push_back(flutter::EncodableValue("WRITE"));
        }
        
        if ((properties & GattCharacteristicProperties::Notify) == GattCharacteristicProperties::Notify) {
          propertiesList.push_back(flutter::EncodableValue("NOTIFY"));
        }
        
        if ((properties & GattCharacteristicProperties::Indicate) == GattCharacteristicProperties::Indicate) {
          propertiesList.push_back(flutter::EncodableValue("INDICATE"));
        }

        if ((properties & GattCharacteristicProperties::AuthenticatedSignedWrites) == GattCharacteristicProperties::AuthenticatedSignedWrites) {
          propertiesList.push_back(flutter::EncodableValue("AUTH_SIGN_WRITES"));
        }

        if ((properties & GattCharacteristicProperties::ExtendedProperties) == GattCharacteristicProperties::ExtendedProperties) {
          propertiesList.push_back(flutter::EncodableValue("EXTENDED_PROP"));
        }

        if ((properties & GattCharacteristicProperties::Broadcast) == GattCharacteristicProperties::Broadcast) {
          propertiesList.push_back(flutter::EncodableValue("BROADCAST"));
        }
        
        if ((properties & GattCharacteristicProperties::WriteWithoutResponse) == GattCharacteristicProperties::WriteWithoutResponse) {
          propertiesList.push_back(flutter::EncodableValue("WRITE_WO_RSP"));
        }

        characteristicsOutput.push_back(flutter::CustomEncodableValue(BtCharacteristic(characteristicUuid, propertiesList)));
      }

      output.push_back(flutter::CustomEncodableValue(BtService(serviceUuid, characteristicsOutput)));
    }

    result(ErrorOr<flutter::EncodableList>(output));
    return;
  }

  /// @brief Read a characteristic from the device
  /// @param mac_address the address of the device to read the characteristic from (Not used, Windows only supports single connection)
  /// @param service_uuid the UUID of the service to read the characteristic from
  /// @param characteristic_uuid the UUID of the characteristic to read
  /// @param result the callback to return the result of the read
  /// @return void
  /// @note The result is returned as a vector of bytes
  void LayrzBlePlugin::ReadCharacteristic(
    const std::string& mac_address,
    const std::string& service_uuid,
    const std::string& characteristic_uuid,
    std::function<void(ErrorOr<std::vector<uint8_t>> reply)> result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result(ErrorOr<std::vector<uint8_t>>(std::vector<uint8_t>()));
      return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result(ErrorOr<std::vector<uint8_t>>(std::vector<uint8_t>()));
      return;
    }

    auto serviceSearch = servicesAndCharacteristics.find(toLowercase(service_uuid));
    if (serviceSearch == servicesAndCharacteristics.end()) {
      Log("Service %s not found", service_uuid.c_str());
      result(ErrorOr<std::vector<uint8_t>>(std::vector<uint8_t>()));
      return;
    }
    auto service = serviceSearch->second;

    auto characteristics = service.Characteristics();
    auto characteristicsSearch = characteristics.find(toLowercase(characteristic_uuid));
    if (characteristicsSearch == characteristics.end()) {
      Log("Characteristic %s not found in service %s", characteristic_uuid.c_str(), service_uuid.c_str());
      result(ErrorOr<std::vector<uint8_t>>(std::vector<uint8_t>()));
      return;
    }

    auto characteristic = characteristicsSearch->second.Characteristic();
    auto properties = characteristic.CharacteristicProperties();
    if ((properties & GattCharacteristicProperties::Read) != GattCharacteristicProperties::Read) {
      Log("Characteristic does not support reading");
      result(ErrorOr<std::vector<uint8_t>>(std::vector<uint8_t>()));
      return;
    }

    readCharacteristicAsync(characteristic, result);
    return;
  }

  /// @brief Read a characteristic from the device asynchronously
  /// @param characteristic the characteristic to read
  /// @param result the callback to return the result of the read
  /// @return void
  /// @note The result is returned as a vector of bytes
  winrt::fire_and_forget LayrzBlePlugin::readCharacteristicAsync(
    GattCharacteristic characteristic,
    std::function<void(ErrorOr<std::vector<uint8_t>> reply)> result
  ) {
    try {
      auto data = co_await characteristic.ReadValueAsync(BluetoothCacheMode::Uncached);
      if (data.Status() != GattCommunicationStatus::Success) {
        Log("Failed to read characteristic value");
        result(ErrorOr<std::vector<uint8_t>>(std::vector<uint8_t>()));
        co_return;
      }
  
      auto value = IBufferToVector(data.Value());
      result(ErrorOr<std::vector<uint8_t>>(value));
      co_return;
    } catch (...) {
      Log("Failed to read characteristic value");
      result(ErrorOr<std::vector<uint8_t>>(std::vector<uint8_t>()));
      co_return;
    }
  }

  /// @brief Write a characteristic to the device
  /// @param mac_address the address of the device to write the characteristic to (Not used, Windows only supports single connection)
  /// @param service_uuid the UUID of the service to write the characteristic to
  /// @param characteristic_uuid the UUID of the characteristic to write
  /// @param payload the payload to write to the characteristic
  /// @param with_response whether to wait for a response from the device
  /// @param result the callback to return the result of the write
  /// @return void
  /// @note The result is returned as a boolean
  void LayrzBlePlugin::WriteCharacteristic(
    const std::string& mac_address,
    const std::string& service_uuid,
    const std::string& characteristic_uuid,
    const std::vector<uint8_t>& payload,
    bool with_response,
    std::function<void(ErrorOr<bool> reply)> result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result(false);
      return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result(false);
      return;
    }

    auto serviceSearch = servicesAndCharacteristics.find(toLowercase(service_uuid));
    if (serviceSearch == servicesAndCharacteristics.end()) {
      Log("Service %s not found", service_uuid.c_str());
      result(false);
      return;
    }
    auto service = serviceSearch->second;

    auto characteristics = service.Characteristics();
    auto characteristicsSearch = characteristics.find(toLowercase(characteristic_uuid));
    if (characteristicsSearch == characteristics.end()) {
      Log("Characteristic %s not found in service %s", characteristic_uuid.c_str(), service_uuid.c_str());
      result(false);
      return;
    }

    auto characteristic = characteristicsSearch->second.Characteristic();
    auto properties = characteristic.CharacteristicProperties();
    if ((properties & GattCharacteristicProperties::Write) != GattCharacteristicProperties::Write &&
        (properties & GattCharacteristicProperties::WriteWithoutResponse) != GattCharacteristicProperties::WriteWithoutResponse) {
      Log("Characteristic does not support writing");
      result(false);
      return;
    }

    if (with_response) {
      writeCharacteristicWithResponseAsync(characteristic, payload, result);
    } else {
      writeCharacteristicWithoutResponseAsync(characteristic, payload, result);
    }

    return;
  }

  /// @brief Write a characteristic to the device with response asynchronously
  /// @param characteristic the characteristic to write
  /// @param payload the payload to write to the characteristic
  /// @param result the callback to return the result of the write
  /// @return void
  /// @note The result is returned as a boolean
  winrt::fire_and_forget LayrzBlePlugin::writeCharacteristicWithResponseAsync(
    GattCharacteristic characteristic,
    const std::vector<uint8_t>& payload,
    std::function<void(ErrorOr<bool> reply)> result
  ) {
    try {
      auto status = co_await characteristic.WriteValueAsync(VectorToIBuffer(payload), GattWriteOption::WriteWithResponse);
      if (status != GattCommunicationStatus::Success) {
        Log("Failed to write characteristic value with response");
        result(false);
        co_return;
      }

      result(true);
      co_return;
    } catch (...) {
      Log("Failed to write characteristic value with response");
      result(false);
      co_return;
    }
  }

  /// @brief Write a characteristic to the device without response asynchronously
  /// @param characteristic the characteristic to write
  /// @param payload the payload to write to the characteristic
  /// @param result the callback to return the result of the write
  /// @return void
  /// @note The result is returned as a boolean
  winrt::fire_and_forget LayrzBlePlugin::writeCharacteristicWithoutResponseAsync(
    GattCharacteristic characteristic,
    const std::vector<uint8_t>& payload,
    std::function<void(ErrorOr<bool> reply)> result
  ) {
    try {
      auto status = co_await characteristic.WriteValueAsync(VectorToIBuffer(payload), GattWriteOption::WriteWithoutResponse);
      if (status != GattCommunicationStatus::Success) {
        Log("Failed to write characteristic value without response");
        result(false);
        co_return;
      }

      result(true);
      co_return;
    } catch (...) {
      Log("Failed to write characteristic value without response");
      result(false);
      co_return;
    }
  }

  void LayrzBlePlugin::StartNotify(
    const std::string& mac_address,
    const std::string& service_uuid,
    const std::string& characteristic_uuid,
    std::function<void(ErrorOr<bool> reply)> result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result(false);
      return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result(false);
      return;
    }

    auto serviceSearch = servicesAndCharacteristics.find(toLowercase(service_uuid));
    if (serviceSearch == servicesAndCharacteristics.end()) {
      Log("Service %s not found", service_uuid.c_str());
      result(false);
      return;
    }
    auto service = serviceSearch->second;

    auto characteristics = service.Characteristics();
    auto characteristicsSearch = characteristics.find(toLowercase(characteristic_uuid));
    if (characteristicsSearch == characteristics.end()) {
      Log("Characteristic %s not found in service %s", characteristic_uuid.c_str(), service_uuid.c_str());
      result(false);
      return;
    }
    auto characteristic = characteristicsSearch->second.Characteristic();
    auto properties = characteristic.CharacteristicProperties();
    if ((properties & GattCharacteristicProperties::Notify) != GattCharacteristicProperties::Notify &&
        (properties & GattCharacteristicProperties::Indicate) != GattCharacteristicProperties::Indicate) {
      Log("Characteristic does not support notifications");
      result(false);
      return;
    }

    if (servicesNotifying.find(characteristic_uuid) != servicesNotifying.end()) {
      Log("Already subscribed to characteristic notifications");
      result(true);
      return;
    }

    startNotifyAsync(characteristic, result);
    return;
  }

  /// @brief Start notifications for a characteristic asynchronously
  /// @param characteristic the characteristic to start notifications for
  /// @param result the callback to return the result of the start
  /// @return void
  /// @note The result is returned as a boolean
  winrt::fire_and_forget LayrzBlePlugin::startNotifyAsync(
    GattCharacteristic characteristic,
    std::function<void(ErrorOr<bool> reply)> result
  ) {
    try {
      auto status = co_await characteristic.WriteClientCharacteristicConfigurationDescriptorAsync(GattClientCharacteristicConfigurationDescriptorValue::Notify);
      if (status != GattCommunicationStatus::Success) {
        Log("Failed to start notifications for characteristic");
        result(false);
        co_return;
      }
      
      auto uuid = toLowercase(GuidToString(characteristic.Uuid()));
      servicesNotifying[uuid] = {0};
      characteristic.ValueChanged(servicesNotifying[uuid]);
      auto token  = characteristic.ValueChanged({this, &LayrzBlePlugin::onCharacteristicValueChanged});
      servicesNotifying[uuid] = token;
      Log("Successfully started notifications for characteristic %s", uuid.c_str());
      result(true);
      co_return;
    } catch (...) {
      Log("Failed to start notifications for characteristic");
      result(false);
      co_return;
    }
  }

  /// @brief Stop notifications for a characteristic
  /// @param mac_address the address of the device to stop notifications for (Not used, Windows only supports single connection)
  /// @param service_uuid the UUID of the service to stop notifications for
  /// @param characteristic_uuid the UUID of the characteristic to stop notifications for
  /// @param result the callback to return the result of the stop
  /// @return void
  /// @note The result is returned as a boolean
  void LayrzBlePlugin::StopNotify(
    const std::string& mac_address,
    const std::string& service_uuid,
    const std::string& characteristic_uuid,
    std::function<void(ErrorOr<bool> reply)> result
  ) {
    if (connectedDevice == nullptr) {
      Log("Not connected to a device");
      result(false);
      return;
    }

    auto device = connectedDevice.get()->Device();
    if (!device) {
      Log("Device not found");
      result(false);
      return;
    }

    auto serviceSearch = servicesAndCharacteristics.find(toLowercase(service_uuid));
    if (serviceSearch == servicesAndCharacteristics.end()) {
      Log("Service %s not found", service_uuid.c_str());
      result(false);
      return;
    }
    auto service = serviceSearch->second;

    auto characteristics = service.Characteristics();
    auto characteristicsSearch = characteristics.find(toLowercase(characteristic_uuid));
    if (characteristicsSearch == characteristics.end()) {
      Log("Characteristic %s not found in service %s", characteristic_uuid.c_str(), service_uuid.c_str());
      result(false);
      return;
    }
    auto characteristic = characteristicsSearch->second.Characteristic();
    auto properties = characteristic.CharacteristicProperties();
    if ((properties & GattCharacteristicProperties::Notify) != GattCharacteristicProperties::Notify &&
        (properties & GattCharacteristicProperties::Indicate) != GattCharacteristicProperties::Indicate) {
      Log("Characteristic does not support notifications");
      result(false);
      return;
    }
    
    auto uuid = toLowercase(GuidToString(characteristic.Uuid()));
    if (servicesNotifying.find(uuid) == servicesNotifying.end()) {
      Log("Not subscribed to characteristic notifications");
      result(true);
      return;
    }

    stopNotifyAsync(characteristic, result);
    return;
  }

  /// @brief Stop notifications for a characteristic asynchronously
  /// @param characteristic the characteristic to stop notifications for
  /// @param result the callback to return the result of the stop
  /// @return void
  /// @note The result is returned as a boolean
  winrt::fire_and_forget LayrzBlePlugin::stopNotifyAsync(
    GattCharacteristic characteristic,
    std::function<void(ErrorOr<bool> reply)> result
  ) {
    try {
      auto status = co_await characteristic.WriteClientCharacteristicConfigurationDescriptorAsync(GattClientCharacteristicConfigurationDescriptorValue::None);
      if (status != GattCommunicationStatus::Success) {
        Log("Failed to stop notifications for characteristic");
        result(false);
        co_return;
      }

      auto uuid = toLowercase(GuidToString(characteristic.Uuid()));
      servicesNotifying[uuid] = {0};
      characteristic.ValueChanged(servicesNotifying[uuid]);
      servicesNotifying.erase(uuid);
      Log("Successfully stopped notifications for characteristic %s", uuid.c_str());
      result(true);
      co_return;
    } catch (...) {
      Log("Failed to stop notifications for characteristic");
      result(false);
      co_return;
    }
  }

  /// @brief When the characteristic value changed
  /// @param sender the sender of the event
  /// @param args the arguments of the event
  /// @return void
  void LayrzBlePlugin::onCharacteristicValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args) {
    Log("Received characteristic value changed event");
    auto characteristicUuid = toLowercase(GuidToString(sender.Uuid()));
    Log("\tCharacteristic UUID: %s", characteristicUuid.c_str());
    auto serviceUuid = toLowercase(GuidToString(sender.Service().Uuid()));
    Log("\tService UUID: %s", serviceUuid.c_str());
    auto value = IBufferToVector(args.CharacteristicValue());
    Log("\tData size: %d", value.size());

    BtCharacteristicNotification response(
      connectedDevice->DeviceId(),
      serviceUuid,
      characteristicUuid,
      value
    );

    if (callbackChannel != nullptr) {
      uiThreadHandler_.Post([this, response]() {
        callbackChannel->OnCharacteristicUpdate(response, SuccessCallback, ErrorCallback);
      });
    }
  } // onCharacteristicValueChanged

  /// @brief When the connection status changed
  /// @param device 
  /// @param args 
  void LayrzBlePlugin::onConnectionStatusChanged(BluetoothLEDevice device, IInspectable args) {
    auto status = device.ConnectionStatus();
    auto macAddress = toLowercase(HStringToString(device.DeviceId()));
    BtDevice payload(macAddress, flutter::EncodableList(), flutter::EncodableList());
    if (connectedDevice != nullptr) {
      if (connectedDevice->Name() != nullptr) {
        payload.set_name(*connectedDevice->Name());
      } else {
        payload.set_name("Unknown");
      }
    }

    if (status == BluetoothConnectionStatus::Disconnected) {
      connectedDevice = nullptr;
      servicesNotifying.clear();

      if (callbackChannel != nullptr) {
        uiThreadHandler_.Post([this, payload]() {
          callbackChannel->OnDisconnected(payload, SuccessCallback, ErrorCallback);
        });
      }
      return;
    }

    if (status == BluetoothConnectionStatus::Connected) {
      if (callbackChannel != nullptr) {
        uiThreadHandler_.Post([this, payload]() {
          callbackChannel->OnConnected(payload, SuccessCallback, ErrorCallback);
        });
      }
      return;
    }
  } // onConnectionStatusChanged

  /// @brief Setup the watcher
  /// @return void
  void LayrzBlePlugin::setupWatcher() {
    deviceWatcherDevices.clear();

    if (btScanner == nullptr) {
      btScanner = DeviceInformation::CreateWatcher(Windows::Devices::Bluetooth::BluetoothDevice::GetDeviceSelector());
      // Subscribe to the Added event
      btScanner.Added([this](DeviceWatcher const&, DeviceInformation const& device) {
        std::string deviceId = toUppercase(HStringToString(device.Id()));
        deviceWatcherDevices.insert_or_assign(deviceId, device);
        handleScanResult(device);
      });
      // Subscribe to the Updated event
      btScanner.Updated([this](DeviceWatcher const&, DeviceInformationUpdate const& args) {
        auto deviceId = toUppercase(HStringToString(args.Id()));
        auto it = deviceWatcherDevices.find(deviceId);
        if (it != deviceWatcherDevices.end())  {
          it->second.Update(args);
          handleScanResult(it->second);
        }
      });
      // Subscribe to the Removed event
      btScanner.Removed([this](DeviceWatcher const&, DeviceInformationUpdate const& args) {
        auto deviceId = toUppercase(HStringToString(args.Id()));
        deviceWatcherDevices.erase(deviceId);
      });
    } // if (btScanner == nullptr)

    if (leScanner == nullptr) {
      leScanner = BluetoothLEAdvertisementWatcher();
      leScanner.ScanningMode(BluetoothLEScanningMode::Active);
      // Subscribe to the Received event
      leScanner.Received([this](BluetoothLEAdvertisementWatcher const&, BluetoothLEAdvertisementReceivedEventArgs const& args) {
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
      });
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
    if(result.DeviceId().empty()) {
      Log("Empty Mac Address");
      return;
    }

    if(filteredDeviceId.length() > 0 && toUppercase(result.DeviceId()) != toUppercase(filteredDeviceId)) {
      return;
    }

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
    BtDevice response(
      device.DeviceId(),
      flutter::EncodableList(),
      flutter::EncodableList()
    );

    if (device.Name()) {
      response.set_name(*device.Name());
    } else {
      response.set_name("Unknown");
    }

    response.set_rssi(device.Rssi());
    if (device.TxPower()) {
      response.set_tx_power(device.TxPower());
    }

    if (device.ManufacturerData() != nullptr) {
      auto manufacturerDataList = flutter::EncodableList();
      for (const auto &mfd : *device.ManufacturerData()) {
        int64_t companyId = mfd.first;
        std::vector<uint8_t> data = mfd.second;
        BtManufacturerData mfData(companyId, &data);
        manufacturerDataList.push_back(flutter::CustomEncodableValue(mfData));
      }

      response.set_manufacturer_data(manufacturerDataList);
    }
    
    if (device.ServiceData() != nullptr) {
      auto serviceDataList = flutter::EncodableList();
      for (const auto &serviceData : *device.ServiceData()) {
        int64_t uuid = serviceData.first;
        std::vector<uint8_t> data = serviceData.second;

        BtServiceData sData(uuid, &data);

        serviceDataList.push_back(flutter::CustomEncodableValue(sData));
      }

      response.set_service_data(serviceDataList);
    }
    
    if(callbackChannel != nullptr) {
      uiThreadHandler_.Post([this, response]() {
        callbackChannel->OnScanResult(response, SuccessCallback, ErrorCallback);
      });
    }
  } // handleBleScanResult

  /// @brief Convert the DeviceWatcherStatus to string
  /// @param status 
  /// @return std::string
  std::string LayrzBlePlugin::castBtScannerStatus(DeviceWatcherStatus status) {
    switch (status) {
      case DeviceWatcherStatus::Created:
        return "CREATED";
      case DeviceWatcherStatus::Started:
        return "STARTED";
      case DeviceWatcherStatus::EnumerationCompleted:
        return "ENUMERATION_COMPLETED";
      case DeviceWatcherStatus::Stopping:
        return "STOPPING";
      case DeviceWatcherStatus::Stopped:
        return "STOPPED";
      case DeviceWatcherStatus::Aborted:
        return "ABORTED";
      default:
        return "UNKNOWN";
    }
  } // castBtScannerStatus

  /// @brief Convert the BluetoothLEAdvertisementWatcherStatus to string
  /// @param status
  /// @return std::string
  std::string LayrzBlePlugin::castLeScannerStatus(BluetoothLEAdvertisementWatcherStatus status) {
    switch (status) {
      case BluetoothLEAdvertisementWatcherStatus::Created:
        return "CREATED";
      case BluetoothLEAdvertisementWatcherStatus::Started:
        return "STARTED";
      case BluetoothLEAdvertisementWatcherStatus::Stopping:
        return "STOPPING";
      case BluetoothLEAdvertisementWatcherStatus::Stopped:
        return "STOPPED";
      case BluetoothLEAdvertisementWatcherStatus::Aborted:
        return "ABORTED";
      default:
        return "UNKNOWN";
    }
  } // castLeScannerStatus

  /// @brief Convert the UUID to a standardized format
  /// @param rawUuid
  /// @return std::string
  std::string LayrzBlePlugin::standarizeServiceUuid(std::string rawUuid) {
    return rawUuid.substr(2,2) + rawUuid.substr(0,2);
  } // standarizeServiceUuid

  void LayrzBlePlugin::StartAdvertise(const flutter::EncodableList& manufacturer_data, const flutter::EncodableList& service_data, bool can_connect, const std::string* name, const flutter::EncodableList& services_specs, bool allow_bluetooth5, std::function<void(ErrorOr<bool> reply)> result) {
    result(false);
  }

  void LayrzBlePlugin::StopAdvertise(std::function<void(ErrorOr<bool> reply)> result) {
    result(false);
  }

  void LayrzBlePlugin::RespondReadRequest(int64_t request_id, const std::string& mac_address, int64_t offset, const std::vector<uint8_t>* data, std::function<void(ErrorOr<bool> reply)> result) {
    result(false);
  }

  void LayrzBlePlugin::RespondWriteRequest(int64_t request_id, const std::string& mac_address, int64_t offset, bool success, std::function<void(ErrorOr<bool> reply)> result) {
    result(false);
  }

  void LayrzBlePlugin::SendNotification(const std::string& service_uuid, const std::string& characteristic_uuid, const std::vector<uint8_t>& payload, bool request_confirmation, std::function<void(ErrorOr<bool> reply)> result) {
    result(false);
  }
} // namespace layrz_ble
