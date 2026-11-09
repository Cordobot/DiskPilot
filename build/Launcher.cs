// DiskPilot.exe - instalador / actualizador / lanzador nativo.
// Lleva DiskPilot.ps1 incrustado. Al abrirse:
//   1. Cierra cualquier versión anterior de DiskPilot que esté abierta (si es la misma versión, la trae al frente).
//   2. Se instala en %LOCALAPPDATA%\Programs\DiskPilot (sustituye la versión anterior), con accesos directos
//      y registro en «Aplicaciones instaladas» de Windows.
//   3. Borra los archivos de versiones anteriores (scripts extraídos y DiskPilot*.exe antiguos en Descargas/Escritorio).
//   4. Ejecuta la aplicación con PowerShell (incluido en Windows) con permisos de administrador.
// Con "--uninstall" desinstala DiskPilot por completo.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("DiskPilot")]
[assembly: AssemblyProduct("DiskPilot")]
[assembly: AssemblyDescription("Analizador de almacenamiento y desinstalador a fondo para Windows")]
[assembly: AssemblyCompany("Cordobot")]
[assembly: AssemblyCopyright("Cordobot")]
[assembly: AssemblyVersion("__VERSION__.0")]
[assembly: AssemblyFileVersion("__VERSION__.0")]
[assembly: AssemblyInformationalVersion("__VERSION__")]

static class Program
{
    const string AppVersion = "__VERSION__";
    const string UninstallKey = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\DiskPilot";

    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int cmd);

    static string LocalApp { get { return Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData); } }
    static string DataDir { get { return Path.Combine(LocalApp, "DiskPilot"); } }
    static string InstallDir { get { return Path.Combine(LocalApp, @"Programs\DiskPilot"); } }
    static string InstallExe { get { return Path.Combine(InstallDir, "DiskPilot.exe"); } }
    static string SelfPath { get { return Assembly.GetExecutingAssembly().Location; } }
    static string StartMenuLnk { get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "DiskPilot.lnk"); } }
    static string DesktopLnk { get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "DiskPilot.lnk"); } }

    [STAThread]
    static int Main(string[] args)
    {
        try
        {
            foreach (var a in args)
                if (a.Equals("--uninstall", StringComparison.OrdinalIgnoreCase)) return Uninstall();

            // 1) Cerrar versiones anteriores abiertas (o traer al frente si ya corre esta misma versión)
            if (HandleRunningInstances()) return 0;

            // 2) Instalar / actualizar
            bool firstInstall = !File.Exists(InstallExe);
            Install(firstInstall);

            // 3) Borrar restos de versiones anteriores
            CleanupOldVersions();

            // 4) Lanzar la aplicación
            Launch(args);
            return 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show("No se pudo iniciar DiskPilot:\n\n" + ex.Message, "DiskPilot", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }

    // ------------------------------------------------------------------
    //  Instancias en ejecución
    // ------------------------------------------------------------------
    class Running { public int Pid; public string Cmd; public string Title; }

    // Busca ventanas de DiskPilot abiertas: por línea de comandos (requiere admin) o por título de ventana
    static List<Running> FindRunning()
    {
        var cmds = new Dictionary<int, string>();
        try
        {
            using (var s = new ManagementObjectSearcher("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name = 'powershell.exe'"))
                foreach (ManagementObject o in s.Get())
                    cmds[Convert.ToInt32(o["ProcessId"])] = Convert.ToString(o["CommandLine"]) ?? "";
        }
        catch { }
        var l = new List<Running>();
        foreach (var p in Process.GetProcessesByName("powershell"))
        {
            try
            {
                string cmd; if (!cmds.TryGetValue(p.Id, out cmd)) cmd = "";
                string title = "";
                try { title = p.MainWindowTitle ?? ""; } catch { }
                bool byCmd = cmd.IndexOf("DiskPilot", StringComparison.OrdinalIgnoreCase) >= 0 && cmd.IndexOf(".ps1", StringComparison.OrdinalIgnoreCase) >= 0;
                bool byTitle = title.StartsWith("DiskPilot", StringComparison.Ordinal);
                if (byCmd || byTitle) { var r = new Running(); r.Pid = p.Id; r.Cmd = cmd; r.Title = title; l.Add(r); }
            }
            catch { }
        }
        return l;
    }

    // Devuelve true si ya está abierta esta misma versión (se trae al frente y no se hace nada más)
    static bool HandleRunningInstances()
    {
        string mine = "DiskPilot-" + AppVersion + ".ps1";
        foreach (var r in FindRunning())
        {
            try
            {
                var p = Process.GetProcessById(r.Pid);
                if (r.Cmd.IndexOf(mine, StringComparison.OrdinalIgnoreCase) >= 0 || r.Title.StartsWith("DiskPilot v" + AppVersion + " ", StringComparison.Ordinal))
                {
                    IntPtr h = p.MainWindowHandle;
                    if (h != IntPtr.Zero) { ShowWindow(h, 9); SetForegroundWindow(h); return true; }
                    continue;
                }
                // Versión anterior: cerrar (primero con amabilidad, luego a la fuerza)
                if (!p.HasExited)
                {
                    p.CloseMainWindow();
                    if (!p.WaitForExit(3000)) { p.Kill(); p.WaitForExit(5000); }
                }
            }
            catch { }
        }
        return false;
    }

    static void KillAll()
    {
        foreach (var r in FindRunning())
        {
            try
            {
                var p = Process.GetProcessById(r.Pid);
                p.CloseMainWindow();
                if (!p.WaitForExit(3000)) { p.Kill(); p.WaitForExit(5000); }
            }
            catch { }
        }
    }

    // ------------------------------------------------------------------
    //  Instalación
    // ------------------------------------------------------------------
    static void Install(bool firstInstall)
    {
        Directory.CreateDirectory(InstallDir);
        if (!string.Equals(Path.GetFullPath(SelfPath), Path.GetFullPath(InstallExe), StringComparison.OrdinalIgnoreCase))
        {
            for (int i = 0; i < 10; i++)
            {
                try { File.Copy(SelfPath, InstallExe, true); break; }
                catch { Thread.Sleep(500); }
            }
        }

        try { CreateShortcut(StartMenuLnk); } catch { }
        if (firstInstall) { try { CreateShortcut(DesktopLnk); } catch { } }

        try
        {
            using (var k = Registry.CurrentUser.CreateSubKey(UninstallKey))
            {
                k.SetValue("DisplayName", "DiskPilot");
                k.SetValue("DisplayVersion", AppVersion);
                k.SetValue("Publisher", "Cordobot");
                k.SetValue("InstallLocation", InstallDir);
                k.SetValue("DisplayIcon", InstallExe + ",0");
                k.SetValue("UninstallString", "\"" + InstallExe + "\" --uninstall");
                k.SetValue("URLInfoAbout", "https://github.com/Cordobot/DiskPilot");
                k.SetValue("InstallDate", DateTime.Now.ToString("yyyyMMdd"));
                k.SetValue("NoModify", 1, RegistryValueKind.DWord);
                k.SetValue("NoRepair", 1, RegistryValueKind.DWord);
                k.SetValue("EstimatedSize", (int)Math.Max(1, new FileInfo(InstallExe).Length / 1024), RegistryValueKind.DWord);
            }
        }
        catch { }
    }

    static void CreateShortcut(string lnkPath)
    {
        Type t = Type.GetTypeFromProgID("WScript.Shell");
        object sh = Activator.CreateInstance(t);
        try
        {
            object lnk = t.InvokeMember("CreateShortcut", BindingFlags.InvokeMethod, null, sh, new object[] { lnkPath });
            Type lt = lnk.GetType();
            lt.InvokeMember("TargetPath", BindingFlags.SetProperty, null, lnk, new object[] { InstallExe });
            lt.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, lnk, new object[] { InstallDir });
            lt.InvokeMember("IconLocation", BindingFlags.SetProperty, null, lnk, new object[] { InstallExe + ",0" });
            lt.InvokeMember("Description", BindingFlags.SetProperty, null, lnk, new object[] { "DiskPilot - almacenamiento y desinstalación a fondo" });
            lt.InvokeMember("Save", BindingFlags.InvokeMethod, null, lnk, null);
            Marshal.FinalReleaseComObject(lnk);
        }
        finally { Marshal.FinalReleaseComObject(sh); }
    }

    // ------------------------------------------------------------------
    //  Limpieza de versiones anteriores
    // ------------------------------------------------------------------
    static void CleanupOldVersions()
    {
        // Scripts extraídos de otras versiones
        try
        {
            if (Directory.Exists(DataDir))
                foreach (var f in Directory.GetFiles(DataDir, "DiskPilot-*.ps1"))
                    if (!Path.GetFileName(f).Equals("DiskPilot-" + AppVersion + ".ps1", StringComparison.OrdinalIgnoreCase))
                        TryDelete(f);
        }
        catch { }

        // DiskPilot*.exe antiguos descargados (solo si son nuestros y de una versión menor)
        Version cur = new Version(AppVersion);
        var dirs = new List<string>();
        try { dirs.Add(Path.GetDirectoryName(SelfPath)); } catch { }
        dirs.Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Downloads"));
        dirs.Add(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory));
        var done = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var d in dirs)
        {
            if (string.IsNullOrEmpty(d) || !done.Add(d) || !Directory.Exists(d)) continue;
            string[] files; try { files = Directory.GetFiles(d, "DiskPilot*.exe"); } catch { continue; }
            foreach (var f in files)
            {
                try
                {
                    if (string.Equals(Path.GetFullPath(f), Path.GetFullPath(SelfPath), StringComparison.OrdinalIgnoreCase)) continue;
                    if (string.Equals(Path.GetFullPath(f), Path.GetFullPath(InstallExe), StringComparison.OrdinalIgnoreCase)) continue;
                    var vi = FileVersionInfo.GetVersionInfo(f);
                    if (vi.ProductName != "DiskPilot" || vi.CompanyName != "Cordobot") continue;
                    Version v; if (!Version.TryParse(vi.FileVersion, out v)) continue;
                    if (v < cur) TryDelete(f);
                }
                catch { }
            }
        }
    }

    static void TryDelete(string f)
    {
        for (int i = 0; i < 5; i++)
        {
            try { File.SetAttributes(f, FileAttributes.Normal); File.Delete(f); return; }
            catch { Thread.Sleep(400); }
        }
    }

    // ------------------------------------------------------------------
    //  Ejecución
    // ------------------------------------------------------------------
    static void Launch(string[] args)
    {
        Directory.CreateDirectory(DataDir);
        string script = Path.Combine(DataDir, "DiskPilot-" + AppVersion + ".ps1");
        byte[] data;
        using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("DiskPilot.ps1"))
        {
            data = new byte[s.Length];
            int read = 0;
            while (read < data.Length) read += s.Read(data, read, data.Length - read);
        }
        bool same = File.Exists(script) && new FileInfo(script).Length == data.Length;
        if (!same) File.WriteAllBytes(script, data);

        string ps = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe");
        var psi = new ProcessStartInfo(ps,
            "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File \"" + script + "\" " + string.Join(" ", args));
        psi.UseShellExecute = false;
        psi.CreateNoWindow = true;
        Process.Start(psi);
    }

    // ------------------------------------------------------------------
    //  Desinstalación de DiskPilot
    // ------------------------------------------------------------------
    static int Uninstall()
    {
        if (MessageBox.Show("¿Desinstalar DiskPilot de este equipo?\n\nSe cerrará la aplicación y se borrarán sus archivos y accesos directos.",
                "Desinstalar DiskPilot", MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes) return 0;
        KillAll();
        TryDelete(StartMenuLnk);
        TryDelete(DesktopLnk);
        try { Registry.CurrentUser.DeleteSubKeyTree(UninstallKey, false); } catch { }
        try { if (Directory.Exists(DataDir)) Directory.Delete(DataDir, true); } catch { }
        // El propio .exe no puede borrarse mientras se ejecuta: se borra la carpeta unos segundos después
        try
        {
            var psi = new ProcessStartInfo("cmd.exe", "/c ping 127.0.0.1 -n 3 > nul & rmdir /s /q \"" + InstallDir + "\"");
            psi.CreateNoWindow = true; psi.UseShellExecute = false;
            Process.Start(psi);
        }
        catch { }
        MessageBox.Show("DiskPilot se ha desinstalado.", "DiskPilot", MessageBoxButtons.OK, MessageBoxIcon.Information);
        return 0;
    }
}
