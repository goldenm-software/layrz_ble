#pragma once

#include <windows.h>

#include <flutter/plugin_registrar_windows.h>

#include <algorithm>
#include <functional>
#include <optional>
#include <mutex>

class LayrzBlePluginUiThreadHandler
{
public:

    /// @brief Construct a new LayrzBlePluginUiThreadHandler
    /// @param registrar 
    explicit LayrzBlePluginUiThreadHandler(flutter::PluginRegistrarWindows *registrar)
      : registrar_(registrar)
    {
      windowProcId_ = registrar_->RegisterTopLevelWindowProcDelegate(
        [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam)
        {
            return HandleWindowMessage(hwnd, message, wparam, lparam);
        });
    }

    /// @brief Destroy the LayrzBlePluginUiThreadHandler
    ~LayrzBlePluginUiThreadHandler()
    {
      registrar_->UnregisterTopLevelWindowProcDelegate(windowProcId_);
    }

    /// @brief Copy constructor    
    LayrzBlePluginUiThreadHandler(const LayrzBlePluginUiThreadHandler &) = delete;
    /// @brief Copy assignment operator
    LayrzBlePluginUiThreadHandler &operator=(const LayrzBlePluginUiThreadHandler &) = delete;

    /// @brief Move constructor
    void Post(std::function<void()> &&func)
    {
      std::lock_guard<std::mutex> lock(mutex_);
      queuedFuncs_.emplace_back(std::move(func));
      Notify();
    }

private:

    static const UINT kWmCallQueuedFunctions = WM_APP + 0x1d7;

    /// @brief Notify the UI thread to process queued functions    
    void Notify()
    {
        if (hwnd_ != 0)
        {
            PostMessage(hwnd_, kWmCallQueuedFunctions, 0, reinterpret_cast<LPARAM>(this));
        }
    }

    /// @brief Handle a window message
    /// @param hwnd
    /// @param message
    /// @param wparam
    /// @param lparam
    /// @return std::optional<LRESULT>
    std::optional<LRESULT> HandleWindowMessage(
        HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam)
    {
        if (hwnd_ == 0)
        {
          hwnd_ = hwnd;
          Notify(); // Make sure queued functions are processed
        }
        if (message == kWmCallQueuedFunctions && lparam == reinterpret_cast<LPARAM>(this))
        {
          std::list<std::function<void()>> queuedFuncs;
          {
            std::lock_guard<std::mutex> lock(mutex_);
            std::swap(queuedFuncs_, queuedFuncs);
          }
          for (auto &func : queuedFuncs)
          {
            func();
          }
        }
        return std::nullopt;
    }

    flutter::PluginRegistrarWindows *registrar_;
    int windowProcId_ = 0;
    HWND hwnd_ = 0;
    std::list<std::function<void()>> queuedFuncs_;
    std::mutex mutex_;
};