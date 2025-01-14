#pragma once

#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <optional>
#include <string>

namespace layrz_ble {

  // Generated class from Pigeon that represents data sent in messages.
  class LayrzManufacturerData {
    public:
      // Constructs an object setting all fields.
      explicit LayrzManufacturerData(
        int64_t company_identifier,
        const std::vector<uint8_t>& data);

      int64_t company_identifier() const;
      void set_company_identifier(int64_t value_arg);

      const std::vector<uint8_t>& data() const;
      void set_data(const std::vector<uint8_t>& value_arg);


    private:
      static LayrzManufacturerData FromEncodableList(const flutter::EncodableList& list);
      flutter::EncodableList ToEncodableList() const;
      friend class LayrzBlePlatformChannel;
      friend class LayrzBleCallbackChannel;
      friend class PigeonInternalCodecSerializer;
      int64_t company_identifier_;
      std::vector<uint8_t> data_;
  };

}