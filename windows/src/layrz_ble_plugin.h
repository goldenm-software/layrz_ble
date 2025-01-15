#ifndef FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
#define FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <winrt/base.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Devices.Enumeration.h>
#include <winrt/Windows.Devices.Radios.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Bluetooth.Advertisement.h>
#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>

#include <memory>

#include "utils.h"
#include "thread_handler.hpp"


namespace layrz_ble
{

  using namespace winrt;
  using namespace Windows::Devices::Radios;
  class LayrzBlePlugin : public flutter::Plugin
  {
    public:
      // Constructors
      static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

      LayrzBlePlugin(flutter::PluginRegistrarWindows *registrar);
      ~LayrzBlePlugin();

      // Disallow copy and assign.
      LayrzBlePlugin(const LayrzBlePlugin &) = delete;
      LayrzBlePlugin &operator=(const LayrzBlePlugin &) = delete;

      void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );


      Radio bluetoothRadio{nullptr};

      winrt::fire_and_forget GetRadios();

      // Thread handling
      LayrzBlePluginUiThreadHandler uiThreadHandler_;

    private:
      void checkCapabilities(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  }; // class LayrzBlePlugin
} // namespace layrz_ble

#endif // FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
