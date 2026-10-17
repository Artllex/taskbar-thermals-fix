namespace TaskbarThermals;

internal static class FullscreenPolicy
{
    private static readonly HashSet<string> SystemHosts = new(StringComparer.OrdinalIgnoreCase)
    {
        "explorer.exe", "StartMenuExperienceHost.exe", "SearchHost.exe",
        "SearchApp.exe", "ShellExperienceHost.exe", "ScreenClippingHost.exe",
    };

    public static bool IsSystemOverlay(string processPath, string windowsDirectory)
    {
        if (string.IsNullOrWhiteSpace(processPath) || string.IsNullOrWhiteSpace(windowsDirectory)) return false;
        string root = windowsDirectory.TrimEnd('\\', '/') + Path.DirectorySeparatorChar;
        if (processPath.StartsWith(root, StringComparison.OrdinalIgnoreCase))
            return SystemHosts.Contains(Path.GetFileName(processPath));
        // The modern Snipping Tool is a Microsoft Store system package.
        string apps = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "WindowsApps") + Path.DirectorySeparatorChar;
        if (!processPath.StartsWith(apps, StringComparison.OrdinalIgnoreCase)) return false;
        string[] parts = processPath[apps.Length..].Split(Path.DirectorySeparatorChar);
        return parts.Length >= 2 && parts[0].StartsWith("Microsoft.ScreenSketch_", StringComparison.OrdinalIgnoreCase)
            && parts[0].EndsWith("__8wekyb3d8bbwe", StringComparison.OrdinalIgnoreCase)
            && (parts[^1].Equals("SnippingTool.exe", StringComparison.OrdinalIgnoreCase)
                || parts[^1].Equals("ScreenClippingHost.exe", StringComparison.OrdinalIgnoreCase));
    }
}
