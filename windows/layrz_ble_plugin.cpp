#include "layrz_ble_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace layrz_ble {

// static
void LayrzBlePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.layrz.layrz_ble",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<LayrzBlePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

LayrzBlePlugin::LayrzBlePlugin() {}

LayrzBlePlugin::~LayrzBlePlugin() {}

void LayrzBlePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("checkCapabilities") == 0) {
    Log("Hola Pancho, esto está corriendo desde C++");
    result->NotImplemented();
  } else {
    result->NotImplemented();
  }
}

void LayrzBlePlugin::Log(
    const std::string &message) {
  std::cout << "LayrzBlePlugin/Windows: " << message << std::endl;
}

}  // namespace layrz_ble
