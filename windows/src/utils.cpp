#include "utils.h"

namespace layrz_ble {
  void Log(const std::string &message) {
    std::cout << "LayrzBlePlugin/Windows: " << message << std::endl;
  } // Log

  std::string WStringToString(const std::wstring& wstr) {
    if (wstr.empty()) {
        return {};
    }
    int sizeNeeded = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string str(sizeNeeded, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &str[0], sizeNeeded, NULL, NULL);
    return str;
  } // WStringToString

  std::string HStringToString(const winrt::hstring& hstr) {
      std::wstring wstr = hstr.c_str();  // Convert to std::wstring
      if (wstr.empty()) return {};

      int sizeNeeded = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, NULL, 0, NULL, NULL);
      std::string str(sizeNeeded - 1, 0);  // Exclude null terminator
      WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, &str[0], sizeNeeded - 1, NULL, NULL);

      return str;
  } // HStringToString
}