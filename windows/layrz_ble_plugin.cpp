#include "layrz_ble_plugin.h"

namespace layrz_ble
{

/// @brief Register the plugin with the Flutter engine
/// @param registrar
void
LayrzBlePlugin::RegisterWithRegistrar (
    flutter::PluginRegistrarWindows *registrar)
{
  auto channel
      = std::make_unique<flutter::MethodChannel<flutter::EncodableValue> > (
          registrar->messenger (), "com.layrz.layrz_ble",
          &flutter::StandardMethodCodec::GetInstance ());
  auto plugin = std::make_unique<LayrzBlePlugin> ();

  channel->SetMethodCallHandler (
      [plugin_pointer = plugin.get ()] (const auto &call, auto result) {
        plugin_pointer->HandleMethodCall (call, std::move (result));
      });
  registrar->AddPlugin (std::move (plugin));
} // RegisterWithRegistrar

LayrzBlePlugin::LayrzBlePlugin () {}
LayrzBlePlugin::~LayrzBlePlugin () {}

/// @brief Handle incoming method calls from Flutter
/// @param method_call
/// @param result
void
LayrzBlePlugin::HandleMethodCall (
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result)
{
  Logger ("Handling method call: " + method_call.method_name ());
  if (method_call.method_name ().compare ("checkCapabilities") == 0)
    {
      checkCapabilities (std::move (result));
    }
  else if (method_call.method_name ().compare ("startScan") == 0)
    {
      startScan (method_call, std::move (result));
    }
  else if (method_call.method_name ().compare ("stopScan") == 0)
    {
      stopScan (method_call, std::move (result));
    }
  else if (method_call.method_name ().compare ("connect") == 0)
    {
      connect (method_call, std::move (result));
    }
  else if (method_call.method_name ().compare ("disconnect") == 0)
    {
      disconnect (method_call, std::move (result));
    }
  else if (method_call.method_name ().compare ("discoverServices") == 0)
    {
      discoverServices (method_call, std::move (result));
    }
  else if (method_call.method_name ().compare ("setMtu") == 0)
    {
      setMtu (method_call, std::move (result));
    }
  else if (method_call.method_name ().compare ("writeCharacteristic") == 0)
    {
      writeCharacteristic (method_call, std::move (result));
    }
  else if (method_call.method_name ().compare ("readCharacteristic") == 0)
    {
      readCharacteristic (method_call, std::move (result));
    }
  else if (method_call.method_name ().compare ("startNotify") == 0)
    {
      startNotify (method_call, std::move (result));
    }
  else if (method_call.method_name ().compare ("stopNotify") == 0)
    {
      stopNotify (method_call, std::move (result));
    }
  else
    {
      result->NotImplemented ();
    }
} // HandleMethodCall

// METODOS PRIVADOS
void
LayrzBlePlugin::checkCapabilities (
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result)
{
  // Check if the device supports BLE
  bool locationPermission = true; // Placeholder for actual location permission check
  bool bluetoothPermission = true; // Placeholder for actual Bluetooth permission check
  bool bluetoothAdminOrScanPermission = true; // Placeholder for actual Bluetooth admin or scan permission // check
  bool bluetoothConnectPermission = true; // Placeholder for actual Bluetooth connect permission check

  flutter::EncodableMap response;
  response[flutter::EncodableValue ("locationPermission")] = flutter::EncodableValue (locationPermission);
  response[flutter::EncodableValue ("bluetoothPermission")] = flutter::EncodableValue (bluetoothPermission);
  response[flutter::EncodableValue ("bluetoothAdminOrScanPermission")] = flutter::EncodableValue (bluetoothAdminOrScanPermission);
  response[flutter::EncodableValue ("bluetoothConnectPermission")] = flutter::EncodableValue (bluetoothConnectPermission);

  result->Success (flutter::EncodableValue (response));
  } // checkCapabilities

/// @brief Start scanning for BLE devices
/// @param method_call  // The method call object
/// @param result       // The result object to send the response to
void
LayrzBlePlugin::startScan (
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
  if (isScanning)
    {
      result->Success (flutter::EncodableValue (true));
      return;
    }

  // Placeholder for checking Bluetooth authorization
  bool bluetoothAuthorized = true; // Replace with actual authorization check
  if (!bluetoothAuthorized)
    {
      Logger ("Bluetooth permission denied");
      result->Success (flutter::EncodableValue (false));
      return;
    }

  // Placeholder for checking if Bluetooth is powered on
  bool bluetoothPoweredOn = true; // Replace with actual state check
  if (!bluetoothPoweredOn)
    {
      Logger ("Bluetooth is not turned on");
      result->Success (flutter::EncodableValue (false));
      return;
    }

  const auto *arguments = std::get_if<flutter::EncodableMap> (method_call.arguments ());
  if (arguments)
    {
      auto macAddressIt = arguments->find (flutter::EncodableValue ("macAddress"));
      if (macAddressIt != arguments->end ())
        {
          std::string filteredUuid = std::get<std::string> (macAddressIt->second);          
          std::transform(filteredUuid.begin(), filteredUuid.end(), filteredUuid.begin(), ::tolower);
        }
    }
  // Placeholder for starting BLE scan
  // centralManager.scanForPeripherals(withServices: nil, options: nil);
  isScanning = true;
  result->Success (flutter::EncodableValue (true));
} // startScan

/// @brief Stop scanning for BLE devices
/// @param method_call  // The method call object
/// @param result       // The result object to send the response to
void
LayrzBlePlugin::stopScan (
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
  if (!isScanning)
  {
    result->Success (flutter::EncodableValue (true));
    return;
  }

  // Placeholder for stopping BLE scan
  // centralManager.stopScan();
  isScanning = false;
  result->Success (flutter::EncodableValue (true));
} // stopScan

/// @brief Connect to a BLE device
/// @param method_call 
/// @param result 
void
LayrzBlePlugin::connect (
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
  connectedPeripheral = nullptr;
  const auto *uuid = std::get_if<std::string>(method_call.arguments());
  if (uuid == nullptr)
  {
    Logger ("UUID not defined");
    result->Success (flutter::EncodableValue (false));
    return;
  }

  std::string lowerUuid = *uuid;
  std::transform(lowerUuid.begin(), lowerUuid.end(), lowerUuid.begin(), ::tolower);

  auto deviceIt = devices.find(lowerUuid);
  if (deviceIt != devices.end())
  {
    if (isScanning)
    {
      // Placeholder for stopping BLE scan
      // centralManager.stopScan();
      isScanning = false;
    }

    lastResult = std::move(result);
    // Placeholder for connecting to the device
    // centralManager.connect(deviceIt->second);
  }
  else
  {
    Logger ("Device not found");
    result->Success (flutter::EncodableValue (false));
  }
} // connect

/// @brief Disconnect from the connected BLE device
/// @param method_call
/// @param result
void
LayrzBlePlugin::disconnect (
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
  if (connectedPeripheral != nullptr)
  {
    // Placeholder for canceling the peripheral connection
    // centralManager.cancelPeripheralConnection(connectedPeripheral);
    connectedPeripheral = nullptr;
  }
  result->Success (flutter::EncodableValue (true));
} // disconnect

/// @brief Discover services on the connected BLE device
/// @param method_call
/// @param result
void
LayrzBlePlugin::discoverServices (
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
  if (connectedPeripheral == nullptr)
  {
    result->Success (flutter::EncodableValue (nullptr));
    return;
  }

  lastResult = std::move(result);
  // Placeholder for discovering services on the connected peripheral
  // connectedPeripheral->discoverServices();
} // discoverServices

/// @brief Set the MTU value for the connected BLE device
/// @param method_call 
/// @param result 
void
LayrzBlePlugin::setMtu (
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
  if (connectedPeripheral == nullptr)
  {
    result->Success (flutter::EncodableValue (nullptr));
    return;
  }

  // Placeholder for getting the MTU value
  int mtu = connectedPeripheral->getMaximumWriteValueLength(); // Replace with actual method to get MTU
  result->Success (flutter::EncodableValue (mtu));
} // setMtu

/// @brief Write a value to a characteristic on the connected BLE device
/// @param method_call 
/// @param result 
void
LayrzBlePlugin::writeCharacteristic (
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
{
  const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!arguments)
  {
    Logger("Arguments not defined");
    result->Success(flutter::EncodableValue(false));
    return;
  }

  auto serviceUuidIt = arguments->find(flutter::EncodableValue("serviceUuid"));
  std::string serviceUuid = std::get<std::string>(serviceUuidIt->second);
  if (serviceUuidIt == arguments->end() || serviceUuid.length() == 0)
  {
    Logger("Service UUID not defined");
    result->Success(flutter::EncodableValue(false));
    return;
  }
  std::transform(serviceUuid.begin(), serviceUuid.end(), serviceUuid.begin(), ::tolower);

  auto characteristicUuidIt = arguments->find(flutter::EncodableValue("characteristicUuid"));
  std::string characteristicUuid = std::get<std::string>(characteristicUuidIt->second);
  if (characteristicUuidIt == arguments->end() || characteristicUuid.length() == 0)
  {
    Logger("Characteristic UUID not defined");
    result->Success(flutter::EncodableValue(false));
    return;
  }
  std::transform(characteristicUuid.begin(), characteristicUuid.end(), characteristicUuid.begin(), ::tolower);

  auto payloadIt = arguments->find(flutter::EncodableValue("payload"));
  std::vector<uint8_t> payload = std::get<std::vector<uint8_t>>(payloadIt->second);
  if (payloadIt == arguments->end() || payload.size() == 0)
  {
    Logger("Payload not defined");
    result->Success(flutter::EncodableValue(false));
    return;
  }
  
  auto withResponseIt = arguments->find(flutter::EncodableValue("withResponse"));
  bool withResponse = withResponseIt =  std::get<bool>(withResponseIt->second) : false;

  bool withResponse = withResponseIt != arguments->end() && withResponseIt->second.IsBool() ? std::get<bool>(withResponseIt->second) : false;

  if (connectedPeripheral == nullptr)
  {
    Logger("Device is not connected");
    result->Success(flutter::EncodableValue(false));
    return;
  }

  auto serviceIt = std::find_if(connectedPeripheral->services.begin(), connectedPeripheral->services.end(),
                                [&serviceUuid](const auto &service) { return service.uuid == serviceUuid; });
  if (serviceIt == connectedPeripheral->services.end())
  {
    Logger("Service not found on the device");
    result->Success(flutter::EncodableValue(false));
    return;
  }

  auto characteristicIt = std::find_if(serviceIt->characteristics.begin(), serviceIt->characteristics.end(),
                                       [&characteristicUuid](const auto &characteristic) { return characteristic.uuid == characteristicUuid; });
  if (characteristicIt == serviceIt->characteristics.end())
  {
    Logger("Characteristic not found on the device");
    result->Success(flutter::EncodableValue(false));
    return;
  }

  lastResult = std::move(result);
  connectedPeripheral->writeValue(payload, *characteristicIt, withResponse);
} // writeCharacteristic



/// @brief Check if the device supports BLE
/// @param message
void
LayrzBlePlugin::Logger (const std::string &message)
{
  std::cout << "LayrzBlePlugin/Windows: " << message << std::endl;
} // Logger

} // namespace layrz_ble
