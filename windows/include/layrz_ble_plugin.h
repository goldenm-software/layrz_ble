#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <map>
#include <string>
#include <vector>
#include <windows.h>

using namespace std;
using namespace flutter;
class LayrzBlePlugin : public flutter::Plugin
{
public:
  static void
  RegisterWithRegistrar (flutter::PluginRegistrarWindows *registrar);

  LayrzBlePlugin ();

  virtual ~LayrzBlePlugin ();

private:
  void HandleMethodCall (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);

  void CheckCapabilities (
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void StartScan (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void StopScan (
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void Connect (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void Disconnect (
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void DiscoverServices (
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void SetMtu (
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void WriteCharacteristic (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void ReadCharacteristic (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void StartNotify (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);
  void StopNotify (
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result);

  void Log (const std::string &message);
};

void
LayrzBlePlugin::RegisterWithRegistrar (
    flutter::PluginRegistrarWindows *registrar)
{
  auto channel
      = std::make_unique<flutter::MethodChannel<flutter::EncodableValue> > (
          registrar->messenger (), "com.layrz.layrz_ble",
          &flutter::StandardMethodCodec::GetInstance ());

  auto plugin = std::make_unique<LayrzBlePlugin> ();

  channel->SetMethodCallHandler (
      [plugin_pointer = plugin.get ()] (const auto &call, auto result) {
        plugin_pointer->HandleMethodCall (call, std::move (result));
      });

  registrar->AddPlugin (std::move (plugin));
}

LayrzBlePlugin::LayrzBlePlugin () {}
LayrzBlePlugin::~LayrzBlePlugin () {}

void
LayrzBlePlugin::HandleMethodCall (
  const flutter::MethodCall<flutter::EncodableValue> &method_call,
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue> > result)
{
  const auto &method_name = method_call.method_name ();

  if (method_name == "checkCapabilities")
  {
    CheckCapabilities (std::move (result));
  }
  else if (method_name == "startScan")
  {
    StartScan (method_call, std::move (result));
  }
  else if (method_name == "stopScan")
  {
    StopScan (std::move (result));
  }
  else if (method_name == "connect")
  {
    Connect (method_call, std::move (result));
  }
  else if (method_name == "disconnect")
  {
    Disconnect (std::move (result));
  }
  else if (method_name == "discoverServices")
  {
    DiscoverServices (std::move (result));
  }
  else if (method_name == "setMtu")
  {
    SetMtu (std::move (result));
  }
  else if (method_name == "writeCharacteristic")
  {
    WriteCharacteristic (method_call, std::move (result));
  }
  else if (method_name == "readCharacteristic")
  {
    ReadCharacteristic (method_call, std::move (result));
  }
  else if (method_name == "startNotify")
  {
    StartNotify (method_call, std::move (result));
  }
  else if (method_name == "stopNotify")
  {
    StopNotify (method_call, std::move (result));
  }
  else
  {
    result->NotImplemented ();
  }
}

