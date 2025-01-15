#include "layrz_ble_plugin.h"

namespace layrz_ble
{

/// @brief Register the plugin with the Flutter engine
/// @param registrar
void LayrzBlePlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar) {
  init_apartment(apartment_type::single_threaded);

  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
    registrar->messenger(),
    "com.layrz.layrz_ble",
    &flutter::StandardMethodCodec::GetInstance()
  );

  auto plugin = std::make_unique<LayrzBlePlugin>();

  channel->SetMethodCallHandler([plugin_pointer = plugin.get()] (const auto &call, auto result) {
    plugin_pointer->HandleMethodCall(call, std::move(result));
  });

  registrar->AddPlugin(std::move(plugin));
} // RegisterWithRegistrar

LayrzBlePlugin::LayrzBlePlugin() {}
LayrzBlePlugin::~LayrzBlePlugin() {}

/// @brief Handle incoming method calls from Flutter
/// @param method_call
/// @param result
void LayrzBlePlugin::HandleMethodCall(
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
) {
  if (!bluetoothRadio) GetRadios();

  Log("Handling method call: " + method_call.method_name());
  if (method_call.method_name ().compare ("checkCapabilities") == 0) checkCapabilities(std::move(result));
  else {
    result->NotImplemented();
  }
} // HandleMethodCall

void LayrzBlePlugin::GetRadios() {
  try {
    auto radios = Radio::GetRadiosAsync().get();
    for (auto radio : radios)
    {
      if (radio.Kind() == RadioKind::Bluetooth)
      {
        Log("Bluetooth radio found");
        bluetoothRadio = radio;
        return;
      }
    }

    bluetoothRadio = nullptr;
    Log("No Bluetooth radio found");
  } catch (winrt::hresult_error const &ex) {
    bluetoothRadio = nullptr;
    Log("Error getting radios: " + HStringToString(ex.message()));
  }
}

// Private methods
void LayrzBlePlugin::checkCapabilities(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  flutter::EncodableMap response;
  if (!bluetoothRadio) {
    response[flutter::EncodableValue("locationPermission")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("bluetoothPermission")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("bluetoothAdminOrScanPermission")] = flutter::EncodableValue(false);
    response[flutter::EncodableValue("bluetoothConnectPermission")] = flutter::EncodableValue(false);
  } else {
    response[flutter::EncodableValue("locationPermission")] = flutter::EncodableValue(true);
    response[flutter::EncodableValue("bluetoothPermission")] = flutter::EncodableValue(true);
    response[flutter::EncodableValue("bluetoothAdminOrScanPermission")] = flutter::EncodableValue(true);
    response[flutter::EncodableValue("bluetoothConnectPermission")] = flutter::EncodableValue(true);
  }
  result->Success(response);
} // checkCapabilities

/// @brief Check if the device supports BLE
/// @param message
void LayrzBlePlugin::Log(const std::string &message) {
  std::cout << "LayrzBlePlugin/Windows: " << message << std::endl;
} // Log

std::string LayrzBlePlugin::WStringToString(const std::wstring& wstr) {
  if (wstr.empty()) {
      return {};
  }
  int sizeNeeded = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
  std::string str(sizeNeeded, 0);
  WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &str[0], sizeNeeded, NULL, NULL);
  return str;
} // WStringToString

std::string LayrzBlePlugin::HStringToString(const winrt::hstring& hstr) {
    std::wstring wstr = hstr.c_str();  // Convert to std::wstring
    if (wstr.empty()) return {};

    int sizeNeeded = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, NULL, 0, NULL, NULL);
    std::string str(sizeNeeded - 1, 0);  // Exclude null terminator
    WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, &str[0], sizeNeeded - 1, NULL, NULL);

    return str;
} // HStringToString

} // namespace layrz_ble
