#pragma once

#ifndef __LAYRZ_BLE_PLUGIN_UTILS_H__
#define __LAYRZ_BLE_PLUGIN_UTILS_H__

#include <iostream>
#include <codecvt>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <string>
#include <cctype>

#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.Streams.h>

namespace layrz_ble {
  using namespace winrt;
  using namespace Windows::Storage::Streams;

  // Utilities
  /// @brief Log a message to the console
  /// @param message
  /// @return void
  void Log(const char* format, ...);

  /// @brief Convert a wide string to a UTF-8 string
  /// @param wstr 
  /// @return std::string
  std::string WStringToString(const std::wstring &wstr);

  /// @brief Convert an HString to a UTF-8 string
  /// @param hstr
  /// @return std::string
  std::string HStringToString(const winrt::hstring& hstr);

  /// @brief Format a Bluetooth MAC address
  /// @param mac_address
  /// @return std::string
  std::string formatBluetoothAddress(uint64_t mac_address);

  /// @brief Convert a string to lowercase
  /// @param str
  /// @return std::string
  std::string toLowercase(const std::string &str);

  /// @brief Convert a string to uppercase
  /// @param str
  /// @return std::string
  std::string toUppercase(const std::string &str);

  /// @brief Convert a GUID to a string
  /// @param guid
  /// @return std::string
  std::string GuidToString(const winrt::guid &guid);

  /// @brief Convert a string to a GUID
  /// @param str
  /// @return winrt::guid
  winrt::guid StringToGuid(const std::string &str);

  /// @brief Convert a vector of bytes to an IBuffer
  /// @param data
  /// @return Windows::Storage::Streams::IBuffer
  IBuffer VectorToIBuffer(const std::vector<uint8_t> &data);

  /// @brief Convert an IBuffer to a vector of bytes
  /// @param buffer
  /// @return std::vector<uint8_t>
  std::vector<uint8_t> IBufferToVector(const IBuffer &buffer);

  /// @brief Convert a boolean to a string
  /// @param value
  /// @return std::string
  std::string BooleanToString(bool value);
}

#endif // __LAYRZ_BLE_PLUGIN_UTILS_H__