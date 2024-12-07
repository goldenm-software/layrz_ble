#ifndef FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
#define FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace layrz_ble {

class LayrzBlePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LayrzBlePlugin();

  virtual ~LayrzBlePlugin();

  // Disallow copy and assign.
  LayrzBlePlugin(const LayrzBlePlugin&) = delete;
  LayrzBlePlugin& operator=(const LayrzBlePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace layrz_ble

#endif  // FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
