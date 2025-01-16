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

namespace layrz_ble {
  // Utilities
  void Log(const std::string &message);
  std::string WStringToString(const std::wstring &wstr);
  std::string HStringToString(const winrt::hstring& hstr);
  std::string formatBluetoothAddress(uint64_t mac_address);
  std::string toLowercase(const std::string &str);
}