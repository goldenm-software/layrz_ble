#pragma once

#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <optional>
#include <string>

namespace layrz_ble {

  // Scan Filters
  //
  // Generated class from Pigeon that represents data sent in messages.
  class LayrzScanFilter {
    public:
      // Constructs an object setting all fields.
      explicit LayrzScanFilter(
        const flutter::EncodableList& with_services,
        const flutter::EncodableList& with_name_prefix,
        const flutter::EncodableList& with_manufacturer_data);

      const flutter::EncodableList& with_services() const;
      void set_with_services(const flutter::EncodableList& value_arg);

      const flutter::EncodableList& with_name_prefix() const;
      void set_with_name_prefix(const flutter::EncodableList& value_arg);

      const flutter::EncodableList& with_manufacturer_data() const;
      void set_with_manufacturer_data(const flutter::EncodableList& value_arg);

    private:
      static LayrzScanFilter FromEncodableList(const flutter::EncodableList& list);
      flutter::EncodableList ToEncodableList() const;
      friend class LayrzBlePlatformChannel;
      friend class LayrzBleCallbackChannel;
      friend class PigeonInternalCodecSerializer;
      flutter::EncodableList with_services_;
      flutter::EncodableList with_name_prefix_;
      flutter::EncodableList with_manufacturer_data_;
  };
}