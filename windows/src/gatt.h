#pragma once

#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>
#include "utils.h"

namespace layrz_ble {
  using namespace winrt::Windows::Devices::Bluetooth::GenericAttributeProfile;

  class BleCharacteristic {
    public:
      BleCharacteristic() = default;
      explicit BleCharacteristic(const GattCharacteristic& characteristic) : characteristic_(characteristic) {}
      ~BleCharacteristic() {}

      void setCharacteristic(const GattCharacteristic& characteristic) { characteristic_ = characteristic; }
      GattCharacteristic Characteristic() const { return characteristic_; }

    private:
      GattCharacteristic characteristic_{nullptr};
  }; // class BleCharacteristic

  class BleService {
    public:
      BleService() = default;
      explicit BleService(const GattDeviceService& service) : service_(service) {}
      ~BleService() {}

      void setService(const GattDeviceService& service) { service_ = service; }
      GattDeviceService Service() const { return service_; }

      void addCharacteristic(const BleCharacteristic characteristic) {
        characteristics_[toLowercase(GuidToString(characteristic.Characteristic().Uuid()))] = characteristic;
      }
      const std::unordered_map<std::string, BleCharacteristic> Characteristics() const { return characteristics_; }

    private:
      GattDeviceService service_{nullptr};
      std::unordered_map<std::string, BleCharacteristic> characteristics_;
  }; // class BleService
} // namespace layrz_ble