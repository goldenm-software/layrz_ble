#pragma once
#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <optional>
#include <string>

namespace layrz_ble {
  class FlutterError {
    public:
      explicit FlutterError(const std::string& code) : code_(code) {}
      explicit FlutterError(const std::string& code, const std::string& message) : code_(code), message_(message) {}
      explicit FlutterError(const std::string& code, const std::string& message, const flutter::EncodableValue& details) : code_(code), message_(message), details_(details) {}

      const std::string& code() const { return code_; }
      const std::string& message() const { return message_; }
      const flutter::EncodableValue& details() const { return details_; }

    private:
      std::string code_;
      std::string message_;
      flutter::EncodableValue details_;
  };

  template<class T> class ErrorOr {
    public:
      ErrorOr(const T& rhs) : v_(rhs) {}
      ErrorOr(const T&& rhs) : v_(std::move(rhs)) {}
      ErrorOr(const FlutterError& rhs) : v_(rhs) {}
      ErrorOr(const FlutterError&& rhs) : v_(std::move(rhs)) {}

      bool has_error() const { return std::holds_alternative<FlutterError>(v_); }
      const T& value() const { return std::get<T>(v_); };
      const FlutterError& error() const { return std::get<FlutterError>(v_); };

    private:
      friend class LayrzBlePlatformChannel;
      friend class LayrzBleCallbackChannel;
      ErrorOr() = default;
      T TakeValue() && { return std::get<T>(std::move(v_)); }

      std::variant<T, FlutterError> v_;
  };

}