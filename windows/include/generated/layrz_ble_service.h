#pragma once

#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <optional>
#include <string>

namespace layrz_ble {  
  
  class LayrzBleService {
    public:
      // Constructs an object setting all non-nullable fields.
      explicit LayrzBleService(const std::string& uuid);

      // Constructs an object setting all fields.
      explicit LayrzBleService(
        const std::string& uuid,
        const flutter::EncodableList* characteristics);

      const std::string& uuid() const;
      void set_uuid(std::string_view value_arg);

      const flutter::EncodableList* characteristics() const;
      void set_characteristics(const flutter::EncodableList* value_arg);
      void set_characteristics(const flutter::EncodableList& value_arg);

    private:
      static LayrzBleService FromEncodableList(const flutter::EncodableList& list);
      flutter::EncodableList ToEncodableList() const;
      friend class LayrzBlePlatformChannel;
      friend class LayrzBleCallbackChannel;
      friend class PigeonInternalCodecSerializer;
      std::string uuid_;
      std::optional<flutter::EncodableList> characteristics_;
  };

}