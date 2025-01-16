#include "scan_result.h"

namespace layrz_ble {
  BleScanResult::BleScanResult(const std::string& deviceId) : deviceId_(deviceId) {}

  const std::string& BleScanResult::DeviceId() const {
    return deviceId_;
  }

  void BleScanResult::setDeviceId(const std::string_view deviceId) {
    deviceId_ = deviceId;
  }

  const std::string* BleScanResult::Name() const {
      return name_ ? &(*name_) : nullptr;
  }

  void BleScanResult::setName(const std::string_view* name) {
    name_ = name ? std::optional<std::string>(*name) : std::nullopt;
  }

  void BleScanResult::setName(std::string_view name) {
    name_ = std::optional<std::string>(name);
  }

  const int64_t BleScanResult::Rssi() const {
    return rssi_ ? *rssi_ : 0;
  }

  void BleScanResult::setRssi(int64_t* rssi) {
    rssi_ = rssi ? std::optional<int64_t>(*rssi) : std::nullopt;
  }

  void BleScanResult::setRssi(int64_t rssi) {
    rssi_ = std::optional<int64_t>(rssi);
  }

  const std::vector<uint8_t>* BleScanResult::ManufacturerData() const {
    return manufacturerData_ ? &(*manufacturerData_) : nullptr;
  }

  void BleScanResult::setManufacturerData(const std::vector<uint8_t>* manufacturerData) {
    manufacturerData_ = manufacturerData ? std::optional<std::vector<uint8_t>>(*manufacturerData) : std::nullopt;
  }

  void BleScanResult::setManufacturerData(std::vector<uint8_t> manufacturerData) {
    manufacturerData_ = std::optional<std::vector<uint8_t>>(manufacturerData);
  }

  const std::vector<uint8_t>* BleScanResult::ServiceData() const {
    return serviceData_ ? &(*serviceData_) : nullptr;
  }

  void BleScanResult::setServiceData(const std::vector<uint8_t>* serviceData) {
    serviceData_ = serviceData ? std::optional<std::vector<uint8_t>>(*serviceData) : std::nullopt;
  }

  void BleScanResult::setServiceData(std::vector<uint8_t> serviceData) {
    serviceData_ = std::optional<std::vector<uint8_t>>(serviceData);
  }

  const std::vector<std::vector<uint8_t>>* BleScanResult::ServicesIdentifiers() const {
    return servicesIdentifiers_ ? &(*servicesIdentifiers_) : nullptr;
  }

  void BleScanResult::setServicesIdentifiers(const std::vector<std::vector<uint8_t>>* servicesIdentifiers) {
    servicesIdentifiers_ = servicesIdentifiers ? std::optional<std::vector<std::vector<uint8_t>>>(*servicesIdentifiers) : std::nullopt;
  }

  void BleScanResult::setServicesIdentifiers(std::vector<std::vector<uint8_t>> servicesIdentifiers) {
    servicesIdentifiers_ = std::optional<std::vector<std::vector<uint8_t>>>(servicesIdentifiers);
  }
}