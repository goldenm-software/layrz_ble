#pragma once

#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>
#include "flutter_error.h"
#include "layrz_ble_scan_result.h"  

#include <map>
#include <optional>
#include <string>

namespace layrz_ble {

// Native -> Flutter
//
// Generated class from Pigeon that represents Flutter messages that can be called from C++.
class LayrzBleCallbackChannel {
  public:
    LayrzBleCallbackChannel(flutter::BinaryMessenger* binary_messenger);
    LayrzBleCallbackChannel(
      flutter::BinaryMessenger* binary_messenger,
      const std::string& message_channel_suffix);
    static const flutter::StandardMessageCodec& GetCodec();
    void OnAvailabilityChanged(
      int64_t state,
      std::function<void(void)>&& on_success,
      std::function<void(const FlutterError&)>&& on_error);
    void OnPairStateChange(
      const std::string& device_id,
      bool is_paired,
      const std::string* error,
      std::function<void(void)>&& on_success,
      std::function<void(const FlutterError&)>&& on_error);
    void OnScanResult(
      const LayrzBleScanResult& result,
      std::function<void(void)>&& on_success,
      std::function<void(const FlutterError&)>&& on_error);
    void OnValueChanged(
      const std::string& device_id,
      const std::string& characteristic_id,
      const std::vector<uint8_t>& value,
      std::function<void(void)>&& on_success,
      std::function<void(const FlutterError&)>&& on_error);
    void OnConnectionChanged(
      const std::string& device_id,
      bool connected,
      const std::string* error,
      std::function<void(void)>&& on_success,
      std::function<void(const FlutterError&)>&& on_error);

  private:
    flutter::BinaryMessenger* binary_messenger_;
    std::string message_channel_suffix_;
  };

}  // namespace Layrz_ble