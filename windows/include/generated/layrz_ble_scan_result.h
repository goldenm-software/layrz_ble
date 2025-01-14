#pragma once

#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <optional>
#include <string>

namespace layrz_ble {

  class LayrzBleScanResult {
    public:
      // Constructs an object setting all non-nullable fields.
      explicit LayrzBleScanResult(const std::string& device_id);

      // Constructs an object setting all fields.
      explicit LayrzBleScanResult(
        const std::string& device_id,
        const std::string* name,
        const bool* is_paired,
        const int64_t* rssi,
        const flutter::EncodableList* manufacturer_data_list,
        const flutter::EncodableList* services);

      const std::string& device_id() const;
      void set_device_id(std::string_view value_arg);

      const std::string* name() const;
      void set_name(const std::string_view* value_arg);
      void set_name(std::string_view value_arg);

      const bool* is_paired() const;
      void set_is_paired(const bool* value_arg);
      void set_is_paired(bool value_arg);

      const int64_t* rssi() const;
      void set_rssi(const int64_t* value_arg);
      void set_rssi(int64_t value_arg);

      const flutter::EncodableList* manufacturer_data_list() const;
      void set_manufacturer_data_list(const flutter::EncodableList* value_arg);
      void set_manufacturer_data_list(const flutter::EncodableList& value_arg);

      const flutter::EncodableList* services() const;
      void set_services(const flutter::EncodableList* value_arg);
      void set_services(const flutter::EncodableList& value_arg);

    private:
      static LayrzBleScanResult FromEncodableList(const flutter::EncodableList& list);
      flutter::EncodableList ToEncodableList() const;
      friend class LayrzBlePlatformChannel;
      friend class LayrzBleCallbackChannel;
      friend class PigeonInternalCodecSerializer;
      std::string device_id_;
      std::optional<std::string> name_;
      std::optional<bool> is_paired_;
      std::optional<int64_t> rssi_;
      std::optional<flutter::EncodableList> manufacturer_data_list_;
      std::optional<flutter::EncodableList> services_;
  };

}