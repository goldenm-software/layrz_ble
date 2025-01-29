#pragma once

#include <optional>
#include <string>
#include <vector>

#include <winrt/base.h>
#include <flutter/standard_method_codec.h>

#include <winrt/base.h>
#include <winrt/Windows.Devices.Bluetooth.h>

typedef std::map<uint16_t, std::vector<uint8_t>> AdvPacketType;

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

      const AdvPacketType* ManufacturerData() const;
      void setManufacturerData(const AdvPacketType* manufacturerData);
      void appendManufacturerData(const uint16_t& companyId, const std::vector<uint8_t>& data);

      const AdvPacketType* ServiceData() const;
      void setServiceData(const AdvPacketType* serviceData);
      void appendServiceData(const uint16_t& serviceUuid, const std::vector<uint8_t>& data);

      const uint64_t Address() const;
      void setAddress(uint64_t address);

      const std::optional<BluetoothLEDevice> Device() const;
      void setDevice(const std::optional<BluetoothLEDevice> device);

    private:
      std::string deviceId_;
      std::optional<std::string> name_;
      std::optional<int64_t> rssi_;

      AdvPacketType manufacturerData_;
      AdvPacketType serviceData_;

      std::optional<uint64_t> address_;

      std::optional<BluetoothLEDevice> device_;
  };
}