#pragma once

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
#include "scan_result.h"
#include "thread_handler.hpp"


namespace layrz_ble
{
  using namespace winrt;
  using namespace winrt::Windows::Foundation;
  using namespace winrt::Windows::Foundation::Collections;
  using namespace winrt::Windows::Devices::Radios;
  using namespace winrt::Windows::Devices::Enumeration;
  using namespace winrt::Windows::Devices::Bluetooth;
  using namespace winrt::Windows::Devices::Bluetooth::Advertisement;
  using namespace winrt::Windows::Devices::Bluetooth::GenericAttributeProfile;

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

      static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> methodChannel;
      static std::string filteredDeviceId;

      std::unordered_map<std::string, winrt::event_token> servicesNotifying{};

      Radio btRadio{nullptr};
      DeviceWatcher btScanner{nullptr};
      BluetoothLEAdvertisementWatcher leScanner{nullptr};
      std::unordered_map<std::string, DeviceInformation> deviceWatcherDevices{};
      std::unordered_map<std::string, BleScanResult> visibleDevices{};

      static std::unique_ptr<BleScanResult> connectedDevice;

      winrt::fire_and_forget GetRadios();

      // Thread handling
      LayrzBlePluginUiThreadHandler uiThreadHandler_;

    private:
      void checkCapabilities(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
      void startScan(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );
      void stopScan(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );
      void setupWatcher();
      void handleScanResult(DeviceInformation device);
      void handleBleScanResult(BleScanResult& result);

      //Pancho
      winrt::fire_and_forget connect(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );

      winrt::fire_and_forget disconnect(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );

      winrt::fire_and_forget discoverServices(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );

      winrt::fire_and_forget setMtu(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );

      winrt::fire_and_forget readCharacteristic(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );

      winrt::fire_and_forget writeCharacteristic(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );

      winrt::fire_and_forget startNotify(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );

      winrt::fire_and_forget stopNotify(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
      );

      void onCharacteristicValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args);
      void onConnectionStatusChanged(BluetoothLEDevice device, IInspectable args);
  }; // class LayrzBlePlugin
} // namespace layrz_ble

#endif // FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
