#include "scan_result.h"

namespace layrz_ble {

  /// @brief Construct a new BleScanResult object
  /// @param deviceId 
  /// @return
  BleScanResult::BleScanResult(const std::string& deviceId) : deviceId_(deviceId) {}

  /// @brief Get the DeviceId object
  /// @return const std::string&
  const std::string& BleScanResult::DeviceId() const {
    return deviceId_;
  }

  /// @brief Set the DeviceId object
  /// @param deviceId
  /// @return void
  void BleScanResult::setDeviceId(const std::string_view deviceId) {
    deviceId_ = deviceId;
  }

  /// @brief Get the Name object
  /// @return const std::string*
  const std::string* BleScanResult::Name() const {
      return name_ ? &(*name_) : nullptr;
  }

  /// @brief Set the Name object
  /// @param name
  /// @return void 
  void BleScanResult::setName(const std::string_view* name) {
    name_ = name ? std::optional<std::string>(*name) : std::nullopt;
  }

  /// @brief Set the Name object
  /// @param name
  /// @return void
  void BleScanResult::setName(std::string_view name) {
    name_ = std::optional<std::string>(name);
  }

  /// @brief Get the Rssi object
  /// @return const int64_t  
  const int64_t BleScanResult::Rssi() const {
    return rssi_ ? *rssi_ : 0;
  }

  /// @brief Set the Rssi object
  /// @param rssi
  /// @return void
  void BleScanResult::setRssi(int64_t* rssi) {
    rssi_ = rssi ? std::optional<int64_t>(*rssi) : std::nullopt;
  }

  /// @brief Set the Rssi object
  /// @param rssi
  /// @return void
  void BleScanResult::setRssi(int64_t rssi) {
    rssi_ = std::optional<int64_t>(rssi);
  }

  /// @brief Get the ManufacturerData object
  /// @return const std::vector<uint8_t>*
  const std::vector<uint8_t>* BleScanResult::ManufacturerData() const {
    return manufacturerData_ ? &(*manufacturerData_) : nullptr;
  }

  /// @brief Set the ManufacturerData object
  /// @param manufacturerData
  /// @return void
  void BleScanResult::setManufacturerData(const std::vector<uint8_t>* manufacturerData) {
    manufacturerData_ = manufacturerData ? std::optional<std::vector<uint8_t>>(*manufacturerData) : std::nullopt;
  }

  /// @brief Set the ManufacturerData object
  /// @param manufacturerData
  /// @return void
  void BleScanResult::setManufacturerData(std::vector<uint8_t> manufacturerData) {
    manufacturerData_ = std::optional<std::vector<uint8_t>>(manufacturerData);
  }

  /// @brief Get the ServiceData object
  /// @return const std::vector<uint8_t>*  
  const std::vector<uint8_t>* BleScanResult::ServiceData() const {
    return serviceData_ ? &(*serviceData_) : nullptr;
  }

  /// @brief Set the ServiceData object
  /// @param serviceData
  /// @return void  
  void BleScanResult::setServiceData(const std::vector<uint8_t>* serviceData) {
    serviceData_ = serviceData ? std::optional<std::vector<uint8_t>>(*serviceData) : std::nullopt;
  }

  /// @brief Set the ServiceData object
  /// @param serviceData
  /// @return void
  void BleScanResult::setServiceData(std::vector<uint8_t> serviceData) {
    serviceData_ = std::optional<std::vector<uint8_t>>(serviceData);
  }

  /// @brief Get the ServicesIdentifiers object
  /// @return const std::vector<std::vector<uint8_t>>*  
  const std::vector<std::vector<uint8_t>>* BleScanResult::ServicesIdentifiers() const {
    return servicesIdentifiers_ ? &(*servicesIdentifiers_) : nullptr;
  }

  /// @brief Set the ServicesIdentifiers object
  /// @param servicesIdentifiers
  /// @return void
  void BleScanResult::setServicesIdentifiers(const std::vector<std::vector<uint8_t>>* servicesIdentifiers) {
    servicesIdentifiers_ = servicesIdentifiers ? std::optional<std::vector<std::vector<uint8_t>>>(*servicesIdentifiers) : std::nullopt;
  }

  /// @brief Set the ServicesIdentifiers object
  /// @param servicesIdentifiers
  /// @return void
  void BleScanResult::setServicesIdentifiers(std::vector<std::vector<uint8_t>> servicesIdentifiers) {
    servicesIdentifiers_ = std::optional<std::vector<std::vector<uint8_t>>>(servicesIdentifiers);
  }
  
}