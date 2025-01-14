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
class LayrzBleCharacteristic {
  public:
    // Constructs an object setting all fields.
    explicit LayrzBleCharacteristic(
      const std::string& uuid,
      const flutter::EncodableList& properties);

    const std::string& uuid() const;
    void set_uuid(std::string_view value_arg);

    const flutter::EncodableList& properties() const;
    void set_properties(const flutter::EncodableList& value_arg);


  private:
    static LayrzBleCharacteristic FromEncodableList(const flutter::EncodableList& list);
    flutter::EncodableList ToEncodableList() const;
    friend class LayrzBlePlatformChannel;
    friend class LayrzBleCallbackChannel;
    friend class PigeonInternalCodecSerializer;
    std::string uuid_;
    flutter::EncodableList properties_;
};
