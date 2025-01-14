#pragma once

#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <optional>
#include <string>

namespace layrz_ble {
  
  class PigeonInternalCodecSerializer : public flutter::StandardCodecSerializer {
    public:
      PigeonInternalCodecSerializer();
      inline static PigeonInternalCodecSerializer& GetInstance() {
        static PigeonInternalCodecSerializer sInstance;
        return sInstance;
      }

      void WriteValue(
        const flutter::EncodableValue& value,
        flutter::ByteStreamWriter* stream) const override;

    protected:
      flutter::EncodableValue ReadValueOfType(
        uint8_t type,
        flutter::ByteStreamReader* stream) const override;
  };

}