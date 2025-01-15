#pragma once
#ifndef FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
#define FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <iostream>
#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Devices.Radios.h>

#include <algorithm>
#include <memory>
#include <sstream>
#include <codecvt>


using namespace winrt;
using namespace Windows::Devices::Radios;

namespace layrz_ble
{

class LayrzBlePlugin : public flutter::Plugin
{
  public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    LayrzBlePlugin();
    virtual ~LayrzBlePlugin();

    LayrzBlePlugin(const LayrzBlePlugin &) = delete;
    LayrzBlePlugin &operator= (const LayrzBlePlugin &) = delete;

    void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
    );
    static void Log(const std::string &message);

    static std::string LayrzBlePlugin::WStringToString(const std::wstring &wstr);
    static std::string LayrzBlePlugin::HStringToString(const winrt::hstring& hstr);

    Radio bluetoothRadio{nullptr};

    void GetRadios();

private:
  void checkCapabilities(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
}; // class LayrzBlePlugin

} // namespace layrz_ble

#endif // FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
