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
  const flutter::EncodableList* BleScanResult::ServiceData() const {
    return serviceData_ ? &(*serviceData_) : nullptr;
  }

  /// @brief Set the ServiceData object
  /// @param serviceData
  /// @return void  
  void BleScanResult::setServiceData(const flutter::EncodableList* serviceData) {
    serviceData_ = serviceData ? std::optional<flutter::EncodableList>(*serviceData) : std::nullopt;
  }

  /// @brief Set the ServiceData object
  /// @param serviceData
  /// @return void
  void BleScanResult::setServiceData(flutter::EncodableList serviceData) {
    serviceData_ = std::optional<flutter::EncodableList>(serviceData);
  }
  
  /// @brief Get the Address object
  /// @return const uint64_t
  const uint64_t BleScanResult::Address() const {
    return address_ ? *address_ : 0;
  }

  /// @brief Set the Address object
  /// @param address
  /// @return void
  void BleScanResult::setAddress(uint64_t address) {
    address_ = address;
  }

  /// @brief Get the Device object
  /// @return const std::optional<BluetoothLEDevice>
  const std::optional<BluetoothLEDevice> BleScanResult::Device() const {
    return device_;
  }

  /// @brief Set the Device object
  /// @param device
  /// @return void
  void BleScanResult::setDevice(const std::optional<BluetoothLEDevice> device) {
    device_ = device;
  }
}