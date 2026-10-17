// ==WindhawkMod==
// @id taskbar-thermals-start
// @name Taskbar Thermals - Start menu compatibility
// @description Keep Taskbar Thermals in the taskbar window band during Start transitions
// @version 1.0.0
// @author Artllex
// @include explorer.exe
// @architecture x86-64
// ==/WindhawkMod==
#include <windows.h>
#include <cwchar>
using GetBandFn = BOOL(WINAPI*)(HWND, DWORD*);
using SetBandFn = BOOL(WINAPI*)(HWND, HWND, DWORD);
GetBandFn getBand;
SetBandFn setBandOriginal;
HWND changedWindow;
DWORD originalBand;
bool IsThermals(HWND hwnd) {
    wchar_t title[80], cls[128];
    if (!GetWindowTextW(hwnd, title, 80) || wcscmp(title, L"Taskbar Thermals")) return false;
    if (!GetClassNameW(hwnd, cls, 128) || wcsncmp(cls, L"WindowsForms10.Window.", 21)) return false;
    DWORD pid; GetWindowThreadProcessId(hwnd, &pid);
    HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!process) return false;
    wchar_t path[32768]; DWORD length = ARRAYSIZE(path);
    bool result = QueryFullProcessImageNameW(process, 0, path, &length) &&
        _wcsicmp(wcsrchr(path, L'\\') ? wcsrchr(path, L'\\') + 1 : path, L"TaskbarThermals.exe") == 0;
    CloseHandle(process); return result;
}
BOOL WINAPI SetBandHook(HWND hwnd, HWND after, DWORD band) {
    BOOL result = setBandOriginal(hwnd, after, band);
    DWORD error = GetLastError();
    if (hwnd == FindWindowW(L"Shell_TrayWnd", nullptr) && result && (band == 1 || band == 6)) {
        // Only the shell's own transition context permits band changes.
        HWND overlay = FindWindowW(nullptr, L"Taskbar Thermals");
        DWORD actual = 0;
        if (overlay && IsThermals(overlay) && getBand(overlay, &actual)) {
            if (changedWindow != overlay) { changedWindow = overlay; originalBand = actual; }
            SetLastError(0);
            BOOL applied = actual == band || setBandOriginal(overlay, HWND_TOP, band);
            DWORD lastError = applied ? 0 : GetLastError();
            DWORD current = 0; getBand(overlay, &current);
            Wh_SetIntValue(L"LastError", lastError);
            Wh_SetIntValue(L"RequestedBand", band);
            Wh_SetIntValue(L"ActualBand", current);
            Wh_Log(L"Taskbar Thermals band %u -> %u result=%d error=%u", actual, band, applied, lastError);
        }
    }
    SetLastError(error); return result;
}
BOOL Wh_ModInit() {
    // Explorer can be injected before it creates Shell_TrayWnd at logon.
    // Install the hook now; the callback identifies the real taskbar later.
    HMODULE user32 = GetModuleHandleW(L"user32.dll");
    getBand = reinterpret_cast<GetBandFn>(GetProcAddress(user32, "GetWindowBand"));
    void* setBand = reinterpret_cast<void*>(GetProcAddress(user32, "SetWindowBand"));
    if (!getBand || !setBand) return FALSE;
    BOOL result = Wh_SetFunctionHook(setBand, reinterpret_cast<void*>(SetBandHook), reinterpret_cast<void**>(&setBandOriginal));
    Wh_SetIntValue(L"HookInstalled", result); return result;
}
void Wh_ModBeforeUninit() {
    // Guaranteed rollback disables this mod and restarts Taskbar Thermals.
    if (changedWindow && IsThermals(changedWindow)) setBandOriginal(changedWindow, HWND_TOP, originalBand);
}
void Wh_ModUninit() {}
