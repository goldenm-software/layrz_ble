#pragma once
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <string>
#include <map>
#include <vector>

class LayrzBlePlugin : public flutter::Plugin {
public:
	static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

	LayrzBlePlugin();

	virtual ~LayrzBlePlugin();

private:
	void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue> &method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

	void CheckCapabilities(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void StartScan(const flutter::MethodCall<flutter::EncodableValue> &method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void StopScan(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void Connect(const flutter::MethodCall<flutter::EncodableValue> &method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void Disconnect(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void DiscoverServices(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void SetMtu(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void WriteCharacteristic(const flutter::MethodCall<flutter::EncodableValue> &method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void ReadCharacteristic(const flutter::MethodCall<flutter::EncodableValue> &method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void StartNotify(const flutter::MethodCall<flutter::EncodableValue> &method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	void StopNotify(const flutter::MethodCall<flutter::EncodableValue> &method_call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

	void Log(const std::string &message);
};
