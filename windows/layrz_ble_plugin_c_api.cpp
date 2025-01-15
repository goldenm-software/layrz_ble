#include "include/layrz_ble/layrz_ble_plugin_c_api.h"
#include <flutter/plugin_registrar_windows.h>
#include "layrz_ble_plugin.h"

void LayrzBlePluginCApiRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) 
{
  layrz_ble::LayrzBlePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarManager::GetInstance()->GetRegistrar<flutter::PluginRegistrarWindows>(registrar)
  );
}
