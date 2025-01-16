#include "layrz_ble_plugin.h"
namespace layrz_ble
{
  
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>LayrzBlePlugin::methodChannel = nullptr;
std::string LayrzBlePlugin::filteredDeviceId = std::string("");

/// @brief Register the plugin with the registrar
/// @param registrar
/// @return void
void LayrzBlePlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar)
{
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
LayrzBlePlugin::LayrzBlePlugin(flutter::PluginRegistrarWindows *registrar) : uiThreadHandler_(registrar)
{
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
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{

  Log("Handling method call: " + method_call.method_name());
  auto method = method_call.method_name();

  if(method.compare("checkCapabilities") == 0)
    checkCapabilities(std::move(result));
  else if(method.compare("startScan") == 0)
    startScan(method_call, std::move(result));
  else if(method.compare("stopScan") == 0)
    stopScan(method_call, std::move(result));
  else
    result->NotImplemented();
} // HandleMethodCall

/// @brief Get the Radios object
/// @return winrt::fire_and_forget
winrt::fire_and_forget LayrzBlePlugin::GetRadios()
{
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
void LayrzBlePlugin::checkCapabilities(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
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
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result)
{
  filteredDeviceId = std::string("");

  // Get macAddress from arguments
  auto arguments = std::get<flutter::EncodableMap>(*method_call.arguments());
  if(arguments.find(flutter::EncodableValue("macAddress")) != arguments.end())
  {
    auto macAddress = std::get<std::string>(arguments[flutter::EncodableValue("macAddress")]);
    filteredDeviceId = toLowercase(macAddress);
    Log("Applied filter for device with macAddress: " + filteredDeviceId);
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
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result)
{
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
void LayrzBlePlugin::setupWatcher() 
{
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

        if (args.Advertisement() != nullptr)
        {
          std::vector<uint8_t> manufacturerData;
          auto manufacturerItems = args.Advertisement().ManufacturerData();
          for (const auto &item : manufacturerItems) 
          {
            uint16_t companyId = item.CompanyId();
            const uint8_t* companyIdBytes = reinterpret_cast<const uint8_t*>(&companyId);
            // Append the Company ID to manufacturerData
            manufacturerData.push_back(companyIdBytes[0]); // Low byte
            manufacturerData.push_back(companyIdBytes[1]); // High byte
            // Extract additional data from the IBuffer
            auto dataBuffer = item.Data();
            if (dataBuffer && dataBuffer.Length() > 0) 
            {
              auto reader = winrt::Windows::Storage::Streams::DataReader::FromBuffer(dataBuffer);
              std::vector<uint8_t> additionalData(dataBuffer.Length());
              reader.ReadBytes(winrt::array_view<uint8_t>(additionalData));
              // Append the additional data to manufacturerData
              manufacturerData.insert(manufacturerData.end(), additionalData.begin(), additionalData.end());
            } // if (dataBuffer && dataBuffer.Length() > 0)
          } // for (const auto &item : manufacturerItems)

          deviceInfo.setManufacturerData(manufacturerData);

          std::vector<uint8_t> serviceData;
          std::vector<std::vector<uint8_t>> servicesIdentifiers;
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
                std::vector<uint8_t> uuidBytes;
                size_t uuidLength = 0;

                if (dataType == BluetoothLEAdvertisementDataTypes::ServiceData16BitUuids()) 
                  uuidLength = 2; // 16-bit UUID
                else if (dataType == BluetoothLEAdvertisementDataTypes::ServiceData32BitUuids()) 
                  uuidLength = 4; // 32-bit UUID
                else if (dataType == BluetoothLEAdvertisementDataTypes::ServiceData128BitUuids()) 
                  uuidLength = 16; // 128-bit UUID

                if (additionalData.size() >= uuidLength) 
                {
                  // Extract UUID
                  uuidBytes.assign(additionalData.begin(), additionalData.begin() + uuidLength);
                  servicesIdentifiers.push_back(uuidBytes);
                  // Append only remaining data (excluding UUID) to serviceData
                  serviceData.insert(serviceData.end(), additionalData.begin() + uuidLength, additionalData.end());
                } // if (additionalData.size() >= uuidLength)
              } // if (dataBuffer && dataBuffer.Length() > 0)
            } // if (dataType == BluetoothLEAdvertisementDataTypes::ServiceData16BitUuids() || ...)
          } // for (const auto& section : serviceItems)

          deviceInfo.setServiceData(serviceData);
          deviceInfo.setServicesIdentifiers(servicesIdentifiers);

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
        handleBleScanResult(deviceInfo);
      }
    );
  } // if (leScanner == nullptr)
} // setupWatcher

/// @brief Handle the scan result
/// @param device 
/// @return void
void LayrzBlePlugin::handleScanResult(DeviceInformation device)
{
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
void LayrzBlePlugin::handleBleScanResult(BleScanResult &result)
{
  if(result.DeviceId().empty())
  {
    Log("Empty Mac Address");
    return;
  }

  if(filteredDeviceId.length() > 0 && result.DeviceId() != filteredDeviceId)
    return;

  // Check if the result.deviceId is inside of visibleDevices
  auto it = visibleDevices.find(result.DeviceId());

  if(it != visibleDevices.end())
  {
    // Update the existing device
    // Check if the name is not empty to update it
    auto &device = it->second;
    if(result.Name())
      device.setName(*result.Name());
    if(result.Rssi())
      device.setRssi(result.Rssi());
    if(!result.ManufacturerData()->empty())
      device.setManufacturerData(*result.ManufacturerData());
    if(!result.ServiceData()->empty())
      device.setServiceData(*result.ServiceData());
  }
  else
    // Add the new device
    visibleDevices.insert_or_assign(result.DeviceId(), result);

  const auto &device = visibleDevices[result.DeviceId()];
  flutter::EncodableMap response;

  response[flutter::EncodableValue("macAddress")]       = flutter::EncodableValue(device.DeviceId());
  response[flutter::EncodableValue("name")]             = flutter::EncodableValue(device.Name() ? *device.Name() : "Unknown");
  response[flutter::EncodableValue("rssi")]             = flutter::EncodableValue(device.Rssi());
  response[flutter::EncodableValue("manufacturerData")] = flutter::EncodableValue(*device.ManufacturerData());
  response[flutter::EncodableValue("serviceData")]      = flutter::EncodableValue(*device.ServiceData());

  flutter::EncodableList servicesIdentifiers = flutter::EncodableList();
  for(const auto &serviceIdentifier : *device.ServicesIdentifiers())
    servicesIdentifiers.push_back(flutter::EncodableValue(serviceIdentifier));

  response[flutter::EncodableValue("servicesIdentifiers")] = servicesIdentifiers;

  if(methodChannel != nullptr)
    methodChannel->InvokeMethod("onScan", std::make_unique<flutter::EncodableValue>(response));
} // handleBleScanResult

} // namespace layrz_ble
