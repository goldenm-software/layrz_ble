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

#include "generated/layrz_ble.g.h"
#include "gatt.h"
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

  class LayrzBlePlugin : public flutter::Plugin, public LayrzBlePlatformChannel
  {
    public:
      // Constructors
      static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

      LayrzBlePlugin(flutter::PluginRegistrarWindows *registrar);
      ~LayrzBlePlugin();

      // Disallow copy and assign.
      LayrzBlePlugin(const LayrzBlePlugin &) = delete;
      LayrzBlePlugin &operator=(const LayrzBlePlugin &) = delete;

      static std::string filteredDeviceId;

      std::unordered_map<std::string, BleService> servicesAndCharacteristics{};
      std::unordered_map<std::string, winrt::event_token> servicesNotifying{};

      Radio btRadio{nullptr};
      DeviceWatcher btScanner{nullptr};
      BluetoothLEAdvertisementWatcher leScanner{nullptr};
      std::unordered_map<std::string, DeviceInformation> deviceWatcherDevices{};
      std::unordered_map<std::string, BleScanResult> visibleDevices{};

      static std::unique_ptr<BleScanResult> connectedDevice;

      winrt::fire_and_forget GetRadiosAsync();

      // Thread handling
      LayrzBlePluginUiThreadHandler uiThreadHandler_;

      void GetStatuses(std::function<void(ErrorOr<BtStatus> reply)> result);
      void CheckCapabilities(std::function<void(ErrorOr<bool> reply)> result);
      void CheckScanPermissions(std::function<void(ErrorOr<bool> reply)> result);
      void CheckAdvertisePermissions(std::function<void(ErrorOr<bool> reply)> result);

      void StartScan(const std::string* mac_address, const flutter::EncodableList* services_uuids, std::function<void(ErrorOr<bool> reply)> result);
      void StopScan(const std::string* mac_address, std::function<void(ErrorOr<bool> reply)> result);
      void Connect(const std::string& mac_address, std::function<void(ErrorOr<bool> reply)> result);
      void Disconnect(const std::string* mac_address, std::function<void(ErrorOr<bool> reply)> result);
      void SetMtu(const std::string& mac_address, int64_t new_mtu, std::function<void(ErrorOr<std::optional<int64_t>> reply)> result);
      void DiscoverServices(const std::string& mac_address, std::function<void(ErrorOr<flutter::EncodableList> reply)> result);
      void ReadCharacteristic(const std::string& mac_address, const std::string& service_uuid, const std::string& characteristic_uuid, std::function<void(ErrorOr<std::vector<uint8_t>> reply)> result);
      void WriteCharacteristic(const std::string& mac_address, const std::string& service_uuid, const std::string& characteristic_uuid, const std::vector<uint8_t>& payload, bool with_response, std::function<void(ErrorOr<bool> reply)> result);
      void StartNotify(const std::string& mac_address, const std::string& service_uuid, const std::string& characteristic_uuid, std::function<void(ErrorOr<bool> reply)> result);
      void StopNotify(const std::string& mac_address, const std::string& service_uuid, const std::string& characteristic_uuid, std::function<void(ErrorOr<bool> reply)> result);
      void StartAdvertise(const flutter::EncodableList& manufacturer_data, const flutter::EncodableList& service_data, bool can_connect, const std::string* name, const flutter::EncodableList& services_specs, bool allow_bluetooth5, std::function<void(ErrorOr<bool> reply)> result);
      void StopAdvertise(std::function<void(ErrorOr<bool> reply)> result);
      void RespondReadRequest(int64_t request_id, const std::string& mac_address, int64_t offset, const std::vector<uint8_t>* data, std::function<void(ErrorOr<bool> reply)> result);
      void RespondWriteRequest(int64_t request_id, const std::string& mac_address, int64_t offset, bool success, std::function<void(ErrorOr<bool> reply)> result);
      void SendNotification(const std::string& service_uuid, const std::string& characteristic_uuid, const std::vector<uint8_t>& payload, bool request_confirmation, std::function<void(ErrorOr<bool> reply)> result);

    private:
      winrt::fire_and_forget connectAsync(const std::string& mac_address, std::function<void(ErrorOr<bool> reply)> result);
      winrt::fire_and_forget setMtuAsync(std::optional<BluetoothLEDevice> device, std::function<void(ErrorOr<std::optional<int64_t>> reply)> result);
      winrt::fire_and_forget readCharacteristicAsync(GattCharacteristic characteristic, std::function<void(ErrorOr<std::vector<uint8_t>> reply)> result);
      winrt::fire_and_forget writeCharacteristicWithResponseAsync(GattCharacteristic characteristic, const std::vector<uint8_t>& payload, std::function<void(ErrorOr<bool> reply)> result);
      winrt::fire_and_forget writeCharacteristicWithoutResponseAsync(GattCharacteristic characteristic, const std::vector<uint8_t>& payload, std::function<void(ErrorOr<bool> reply)> result);
      winrt::fire_and_forget startNotifyAsync(GattCharacteristic characteristic, std::function<void(ErrorOr<bool> reply)> result);
      winrt::fire_and_forget stopNotifyAsync(GattCharacteristic characteristic, std::function<void(ErrorOr<bool> reply)> result);
      
      void onCharacteristicValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args);
      void onConnectionStatusChanged(BluetoothLEDevice device, IInspectable args);
      void setupWatcher();
      void handleScanResult(DeviceInformation device);
      void handleBleScanResult(BleScanResult &result);
      std::string castBtScannerStatus(DeviceWatcherStatus status);
      std::string castLeScannerStatus(BluetoothLEAdvertisementWatcherStatus status);
      std::string standarizeServiceUuid(std::string uuid);

      static void SuccessCallback() {}
      static void ErrorCallback(const FlutterError &error)
      {
          // Ignore ChannelConnection Error, This might occur because of HotReload
          if (error.code() != "channel-error")
          {
              std::cout << "ErrorCode: " << error.code() << " Message: " << error.message() << std::endl;
          }
      }
  }; // class LayrzBlePlugin
} // namespace layrz_ble

#endif // FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
