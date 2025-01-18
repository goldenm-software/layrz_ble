#include "utils.h"

#define MAC_ADDRESS_STR_LENGTH (size_t)17


namespace layrz_ble {
  /// @brief Log a message to the console
  /// @param message 
  void Log(const std::string &message) {
    std::cout << "LayrzBlePlugin/Windows: " << message << std::endl;
  } // Log

  /// @brief Convert a wide string to a UTF-8 string
  /// @param wstr 
  /// @return std::string
  std::string WStringToString(const std::wstring& wstr) {
    if (wstr.empty()) {
        return {};
    }
    int sizeNeeded = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string str(sizeNeeded, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &str[0], sizeNeeded, NULL, NULL);
    return str;
  } // WStringToString

  /// @brief Convert an HString to a UTF-8 string
  /// @param hstr
  /// @return std::string
  std::string HStringToString(const winrt::hstring& hstr) {
    std::wstring wstr = hstr.c_str();  // Convert to std::wstring
    if (wstr.empty()) return {};

    int sizeNeeded = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, NULL, 0, NULL, NULL);
    std::string str(sizeNeeded - 1, 0);  // Exclude null terminator
    WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, &str[0], sizeNeeded - 1, NULL, NULL);

    return str;
  } // HStringToString

  /// @brief Format a Bluetooth MAC address
  /// @param mac_address
  /// @return std::string
  std::string formatBluetoothAddress(uint64_t mac_address) {
    uint8_t *mac_ptr = (uint8_t *)&mac_address;
    char mac_str[MAC_ADDRESS_STR_LENGTH + 1] = {0};
    snprintf(mac_str, MAC_ADDRESS_STR_LENGTH + 1, "%02x:%02x:%02x:%02x:%02x:%02x", mac_ptr[5], mac_ptr[4], mac_ptr[3], mac_ptr[2], mac_ptr[1], mac_ptr[0]);
    return std::string(mac_str);
  } // formatBluetoothAddress

  /// @brief Convert a string to lowercase
  /// @param str
  /// @return std::string
  std::string toLowercase(const std::string &str) {
    std::string lower = str;
    std::transform(
      lower.begin(), 
      lower.end(), 
      lower.begin(),
      [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return lower;
  } // toLowercase

  /// @brief Convert a GUID to a string
  /// @param guid
  /// @return std::string
  std::string GuidToString(const winrt::guid &guid) {
    std::ostringstream oss;
    oss << std::hex << std::uppercase << std::setfill('0')
        << std::setw(8) << guid.Data1 << '-'
        << std::setw(4) << guid.Data2 << '-'
        << std::setw(4) << guid.Data3 << '-'
        << std::setw(2) << static_cast<int>(guid.Data4[0])
        << std::setw(2) << static_cast<int>(guid.Data4[1]) << '-';

    for (int i = 2; i < 8; ++i) {
        oss << std::setw(2) << static_cast<int>(guid.Data4[i]);
    }

    return oss.str();
  }

  /// @brief Convert a string to a GUID
  /// @param str
  /// @return winrt::guid
  winrt::guid StringToGuid(const std::string &str) {
    winrt::guid guid;
    std::istringstream iss(str);
    iss >> std::hex >> guid.Data1;
    iss.ignore(1); // Skip '-'
    iss >> std::hex >> guid.Data2;
    iss.ignore(1); // Skip '-'
    iss >> std::hex >> guid.Data3;
    iss.ignore(1); // Skip '-'
    iss >> std::hex >> guid.Data4[0];
    iss >> std::hex >> guid.Data4[1];
    iss.ignore(1); // Skip '-'
    for (int i = 2; i < 8; ++i) {
        iss >> std::hex >> guid.Data4[i];
    }
    return guid;
  }

  /// @brief Convert a vector of bytes to an IBuffer
  /// @param bytes 
  /// @return Windows::Storage::Streams::IBuffer
  IBuffer VectorToIBuffer(const std::vector<uint8_t> &data) {
    auto writer = DataWriter();
    writer.WriteBytes(data);
    return writer.DetachBuffer();
  }

  /// @brief Convert an IBuffer to a vector of bytes
  /// @param buffer
  /// @return std::vector<uint8_t>
  std::vector<uint8_t> IBufferToVector(const IBuffer &buffer) {
    auto reader = DataReader::FromBuffer(buffer);
    std::vector<uint8_t> data(buffer.Length());
    reader.ReadBytes(winrt::array_view<uint8_t>(data));
    return data;
  }
}