#include "layrz_ble_plugin.h"

namespace layrz_ble
{
  void LayrzBlePlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar) {
    auto plugin = std::make_unique<LayrzBlePlugin>(registrar);
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(),
      "com.layrz.layrz_ble",
      &flutter::StandardMethodCodec::GetInstance()
    );

    channel->SetMethodCallHandler([plugin_pointer = plugin.get()] (const auto &call, auto result) {
      plugin_pointer->HandleMethodCall(call, std::move(result));
    });

    registrar->AddPlugin(std::move(plugin));
  } // RegisterWithRegistrar

  LayrzBlePlugin::LayrzBlePlugin(flutter::PluginRegistrarWindows *registrar) : uiThreadHandler_(registrar) {
    GetRadios();
  }
  LayrzBlePlugin::~LayrzBlePlugin() {}

  /// @brief Handle incoming method calls from Flutter
  /// @param method_call
  /// @param result
  void LayrzBlePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
  ) {
    Log("Handling method call: " + method_call.method_name());
    if (method_call.method_name ().compare ("checkCapabilities") == 0) checkCapabilities(std::move(result));
    else {
      result->NotImplemented();
    }
  } // HandleMethodCall

  winrt::fire_and_forget LayrzBlePlugin::GetRadios() {
    auto radios = co_await Radio::GetRadiosAsync();
    for (auto radio : radios)
    {
      if (radio.Kind() == RadioKind::Bluetooth)
      {
        Log("Bluetooth radio found");
        bluetoothRadio = radio;
        break;
      }
    }

    if (!bluetoothRadio) {
      Log("No Bluetooth radio found");
    }
  } // GetRadiosAync

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
} // namespace layrz_ble
