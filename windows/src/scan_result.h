#pragma once

#include <optional>
#include <string>
#include <vector>

#include <winrt/base.h>
#include <flutter/standard_method_codec.h>

#include <winrt/base.h>
#include <winrt/Windows.Devices.Bluetooth.h>

namespace layrz_ble {
  using namespace winrt;
  using namespace Windows::Devices::Bluetooth;
  
  class BleScanResult {
    public:
      BleScanResult() = default;
      explicit BleScanResult(const std::string& deviceId);

      const std::string& DeviceId() const;
      void setDeviceId(std::string_view deviceId);
      
      const std::string* Name() const;
      void setName(const std::string_view* name);
      void setName(std::string_view name);

      const int64_t Rssi() const;
      void setRssi(int64_t* rssi);
      void setRssi(int64_t rssi);

      const std::vector<uint8_t>* ManufacturerData() const;
      void setManufacturerData(const std::vector<uint8_t>* manufacturerData);
      void setManufacturerData(std::vector<uint8_t> manufacturerData);

      const flutter::EncodableList* ServiceData() const;
      void setServiceData(const flutter::EncodableList* serviceData);
      void setServiceData(flutter::EncodableList serviceData);

      const uint64_t Address() const;
      void setAddress(uint64_t address);

      const std::optional<BluetoothLEDevice> Device() const;
      void setDevice(const std::optional<BluetoothLEDevice> device);

    private:
      std::string deviceId_;
      std::optional<std::string> name_;
      std::optional<int64_t> rssi_;
      std::optional<std::vector<uint8_t>> manufacturerData_;
      std::optional<flutter::EncodableList> serviceData_;
      std::optional<uint64_t> address_;

      std::optional<BluetoothLEDevice> device_;
  };
}