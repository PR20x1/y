#pragma once

#include "ImGuiDrawView.h"
#include "MenuLoad.h"

#include "../ImGui/imgui.h"
#include "../ImGui/imgui_internal.h"
#include "../ImGui/imgui_impl_metal.h"

#include "../Utilities/Singleton.h"
#include "../Utilities/Settings.h"
#include "../Utilities/Memory.h"
#include "../Utilities/Macros.h"

#include "../Utilities/Fmt.h"

#include <stdio.h>
#include <vector>
#include <map>
#include <unistd.h>
#include <string.h>
#include <vector>
#include <functional>
#include <iostream>
#include <queue>
#include <codecvt>
#include <mutex>
#include <unordered_set>
#include <concepts>
#include <unordered_map>
#include <regex>
#include <array>

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <os/log.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <cmath>
#import <pthread/pthread.h>

static Settings &settings = Settings::GetInstance();

extern MenuInteraction* menuTouchView;
extern UIButton* InvisibleMenuButton;
extern UIButton* VisibleMenuButton;
extern UITextField* hideRecordTextfield;
extern UIView* hideRecordView;

inline ImFont* Font = nullptr;

extern ImFont* IconFont;


template<int32 Len>
struct StringLiteral
{
    char Chars[Len];

    consteval StringLiteral(const char(&String)[Len])
    {
        std::copy_n(String, Len, Chars);
    }

    operator std::string() const
    {
        return static_cast<const char*>(Chars);
    }
};

FORCEINLINE void CrashSafe()
{
    *(volatile int*)0 = 1;
    return;
}

template<typename To>
FORCEINLINE To* Cast(void* Src)
{
    return static_cast<To*>(Src);
}

template<typename To>
FORCEINLINE const To* Cast(const void* Src)
{
    return static_cast<const To*>(Src);
}
