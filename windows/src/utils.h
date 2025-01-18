#pragma once

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
  void Log(const std::string &message);
  std::string WStringToString(const std::wstring &wstr);
  std::string HStringToString(const winrt::hstring& hstr);
  std::string formatBluetoothAddress(uint64_t mac_address);
  std::string toLowercase(const std::string &str);
  std::string GuidToString(const winrt::guid &guid);
  winrt::guid StringToGuid(const std::string &str);
  IBuffer VectorToIBuffer(const std::vector<uint8_t> &data);
  std::vector<uint8_t> IBufferToVector(const IBuffer &buffer);
}