#pragma once
#ifndef FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
#define FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_

#include <VersionHelpers.h>
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <memory>
#include <sstream>

namespace layrz_ble
{

class LayrzBlePlugin : public flutter::Plugin
{
public:
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue> >
      channel;
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > lastResult;
  std::unique_ptr<CBCentralManager> centralManager;
  std::vector<std::unique_ptr<CBPeripheral> > discoveredPeripherals;
  bool isScanning = false;
  std::map<std::string, std::unique_ptr<CBPeripheral> > devices;
  std::unique_ptr<std::string> filteredUuid;
  std::unique_ptr<CBPeripheral> connectedPeripheral;
  std::map<CBUUID, std::vector<std::unique_ptr<CBCharacteristic> > >
      discoveredServices;
  std::unique_ptr<LastOperation> lastOp;

public:
  static void
  RegisterWithRegistrar (flutter::PluginRegistrarWindows *registrar);

  LayrzBlePlugin ();
  virtual ~LayrzBlePlugin ();

  LayrzBlePlugin (const LayrzBlePlugin &) = delete;
  LayrzBlePlugin &operator= (const LayrzBlePlugin &) = delete;
  void HandleMethodCall (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void Logger (const std::string &message);

private:
  /// @brief Check if the current system supports BLE
  /// @param result The result object to send the response to
  void checkCapabilities (
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void startScan (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void stopScan (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);

  void connect (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);

  void disconnect (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);

  void discoverServices (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);

  void setMtu (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);

  void writeCharacteristic (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);

}; // class LayrzBlePlugin

} // namespace layrz_ble

#endif // FLUTTER_PLUGIN_LAYRZ_BLE_PLUGIN_H_
