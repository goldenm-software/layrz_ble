#include "utils.h"

#define MAC_ADDRESS_STR_LENGTH (size_t)17

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

  std::string formatBluetoothAddress(uint64_t mac_address) {
    uint8_t *mac_ptr = (uint8_t *)&mac_address;
    char mac_str[MAC_ADDRESS_STR_LENGTH + 1] = {0};
    snprintf(mac_str, MAC_ADDRESS_STR_LENGTH + 1, "%02x:%02x:%02x:%02x:%02x:%02x", mac_ptr[5], mac_ptr[4], mac_ptr[3],
              mac_ptr[2], mac_ptr[1], mac_ptr[0]);
    return std::string(mac_str);
  } // formatBluetoothAddress

  std::string toLowercase(const std::string &str) {
    std::string lower = str;
    std::transform(lower.begin(), lower.end(), lower.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return lower;
  } // toLowercase
}