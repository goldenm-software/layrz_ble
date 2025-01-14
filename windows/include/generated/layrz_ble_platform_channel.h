#pragma once

#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>
#include "flutter_error.h"
#include "layrz_scan_filter.h"

#include <map>
#include <optional>
#include <string>

namespace layrz_ble {

  // Flutter -> Native
  //
  // Generated interface from Pigeon that represents a handler of messages from Flutter.
  class LayrzBlePlatformChannel {
    public:
      LayrzBlePlatformChannel(const LayrzBlePlatformChannel&) = delete;
      LayrzBlePlatformChannel& operator=(const LayrzBlePlatformChannel&) = delete;
      virtual ~LayrzBlePlatformChannel() {}
      virtual void GetBluetoothAvailabilityState(std::function<void(ErrorOr<int64_t> reply)> result) = 0;
      virtual void EnableBluetooth(std::function<void(ErrorOr<bool> reply)> result) = 0;
      virtual void DisableBluetooth(std::function<void(ErrorOr<bool> reply)> result) = 0;
      virtual std::optional<FlutterError> StartScan(const LayrzScanFilter* filter) = 0;
      virtual std::optional<FlutterError> StopScan() = 0;
      virtual std::optional<FlutterError> Connect(const std::string& device_id) = 0;
      virtual std::optional<FlutterError> Disconnect(const std::string& device_id) = 0;
      virtual void SetNotifiable(
        const std::string& device_id,
        const std::string& service,
        const std::string& characteristic,
        int64_t ble_input_property,
        std::function<void(std::optional<FlutterError> reply)> result) = 0;
      virtual void DiscoverServices(
        const std::string& device_id,
        std::function<void(ErrorOr<flutter::EncodableList> reply)> result) = 0;
      virtual void ReadValue(
        const std::string& device_id,
        const std::string& service,
        const std::string& characteristic,
        std::function<void(ErrorOr<std::vector<uint8_t>> reply)> result) = 0;
      virtual void RequestMtu(
        const std::string& device_id,
        int64_t expected_mtu,
        std::function<void(ErrorOr<int64_t> reply)> result) = 0;
      virtual void WriteValue(
        const std::string& device_id,
        const std::string& service,
        const std::string& characteristic,
        const std::vector<uint8_t>& value,
        int64_t ble_output_property,
        std::function<void(std::optional<FlutterError> reply)> result) = 0;
      virtual void IsPaired(
        const std::string& device_id,
        std::function<void(ErrorOr<bool> reply)> result) = 0;
      virtual void Pair(
        const std::string& device_id,
        std::function<void(ErrorOr<bool> reply)> result) = 0;
      virtual std::optional<FlutterError> UnPair(const std::string& device_id) = 0;
      virtual void GetSystemDevices(
        const flutter::EncodableList& with_services,
        std::function<void(ErrorOr<flutter::EncodableList> reply)> result) = 0;
      virtual ErrorOr<int64_t> GetConnectionState(const std::string& device_id) = 0;

      // The codec used by LayrzBlePlatformChannel.
      static const flutter::StandardMessageCodec& GetCodec();
      // Sets up an instance of `LayrzBlePlatformChannel` to handle messages through the `binary_messenger`.
      static void SetUp(
        flutter::BinaryMessenger* binary_messenger,
        LayrzBlePlatformChannel* api);
      static void SetUp(
        flutter::BinaryMessenger* binary_messenger,
        LayrzBlePlatformChannel* api,
        const std::string& message_channel_suffix);
      static flutter::EncodableValue WrapError(std::string_view error_message);
      static flutter::EncodableValue WrapError(const FlutterError& error);

    protected:
      LayrzBlePlatformChannel() = default;
  };

}