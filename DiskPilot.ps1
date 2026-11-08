# =====================================================================
#  DiskPilot v1.1.0 - Analizador de disco y desinstalador a fondo para Windows
#  Requiere: Windows 10/11 con PowerShell 5.1 (incluido en Windows)
# =====================================================================
param(
    [switch]$NoElevate,
    [switch]$SelfTest,
    [string]$Screenshot
)
$ErrorActionPreference = 'Continue'
$AppVersion = '1.1.0'

# ---------- Elevación a administrador ----------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$IsAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin -and -not $NoElevate -and -not $SelfTest -and -not $Screenshot) {
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    } catch { }
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# =====================================================================
#  Motor (C#)
# =====================================================================
$cs = @'
using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Win32;

namespace DiskPilot
{
    public static class Fmt
    {
        public static string Size(long b)
        {
            if (b < 0) return "?";
            string[] u = { "B", "KB", "MB", "GB", "TB" };
            double v = b; int i = 0;
            while (v >= 1024 && i < u.Length - 1) { v /= 1024; i++; }
            return (i == 0 ? v.ToString("0") : v.ToString(v >= 100 ? "0" : "0.0")) + " " + u[i];
        }
    }

    public class Bindable : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;
        protected void N(string p) { var h = PropertyChanged; if (h != null) h(this, new PropertyChangedEventArgs(p)); }
    }

    public static class Native
    {
        [DllImport("dwmapi.dll")] static extern int DwmSetWindowAttribute(IntPtr h, int a, ref int v, int s);
        public static void DarkTitle(IntPtr h) { try { int v = 1; DwmSetWindowAttribute(h, 20, ref v, 4); } catch { } }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool MoveFileEx(string a, string b, int flags);

        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        public static extern int SHEmptyRecycleBin(IntPtr h, string root, uint flags);

        [StructLayout(LayoutKind.Sequential)]
        public struct SHQUERYRBINFO { public int cbSize; public long i64Size; public long i64NumItems; }
        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        public static extern int SHQueryRecycleBin(string root, ref SHQUERYRBINFO info);

        public static long RecycleBinSize()
        {
            try
            {
                var i = new SHQUERYRBINFO(); i.cbSize = Marshal.SizeOf(typeof(SHQUERYRBINFO));
                return SHQueryRecycleBin(null, ref i) == 0 ? i.i64Size : 0;
            }
            catch { return 0; }
        }
    }

    // ------------------------------------------------------------------
    //  Protección: rutas que NUNCA se borran
    // ------------------------------------------------------------------
    public static class Safety
    {
        static readonly List<string> Roots = new List<string>();
        static readonly string WinDir;
        static Safety()
        {
            WinDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows).TrimEnd('\\');
            Environment.SpecialFolder[] sf = {
                Environment.SpecialFolder.Windows, Environment.SpecialFolder.ProgramFiles, Environment.SpecialFolder.ProgramFilesX86,
                Environment.SpecialFolder.CommonProgramFiles, Environment.SpecialFolder.CommonProgramFilesX86,
                Environment.SpecialFolder.CommonApplicationData, Environment.SpecialFolder.UserProfile,
                Environment.SpecialFolder.ApplicationData, Environment.SpecialFolder.LocalApplicationData,
                Environment.SpecialFolder.Desktop, Environment.SpecialFolder.MyDocuments, Environment.SpecialFolder.MyPictures,
                Environment.SpecialFolder.MyMusic, Environment.SpecialFolder.MyVideos, Environment.SpecialFolder.System,
                Environment.SpecialFolder.SystemX86, Environment.SpecialFolder.CommonDesktopDirectory,
                Environment.SpecialFolder.CommonDocuments, Environment.SpecialFolder.StartMenu, Environment.SpecialFolder.CommonStartMenu,
                Environment.SpecialFolder.Programs, Environment.SpecialFolder.CommonPrograms, Environment.SpecialFolder.Startup,
                Environment.SpecialFolder.CommonStartup, Environment.SpecialFolder.Fonts };
            foreach (var f in sf) Add(Environment.GetFolderPath(f));
            string up = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            Add(Path.Combine(up, "Downloads"));
            Add(Path.Combine(up, "AppData\\LocalLow"));
            Add(Path.Combine(up, "OneDrive"));
            Add(Environment.GetEnvironmentVariable("OneDrive"));
            Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs"));
            Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "WindowsApps"));
            Add(Path.GetTempPath());
        }
        static void Add(string p)
        {
            if (string.IsNullOrEmpty(p)) return;
            try { Roots.Add(Path.GetFullPath(p).TrimEnd('\\')); } catch { }
        }
        public static bool IsProtected(string p)
        {
            if (string.IsNullOrWhiteSpace(p)) return true;
            string f;
            try { f = Path.GetFullPath(p.Trim()).TrimEnd('\\'); } catch { return true; }
            if (f.Length <= 3) return true;
            if (f.Equals(WinDir, StringComparison.OrdinalIgnoreCase) || f.StartsWith(WinDir + "\\", StringComparison.OrdinalIgnoreCase)) return true;
            foreach (var r in Roots)
                if (r.Equals(f, StringComparison.OrdinalIgnoreCase) || r.StartsWith(f + "\\", StringComparison.OrdinalIgnoreCase)) return true;
            string parent = Path.GetDirectoryName(f);
            if (parent != null && parent.TrimEnd('\\').Length <= 2)
            {
                string n = Path.GetFileName(f).ToLowerInvariant();
                if (n == "system volume information" || n == "recovery" || n == "boot" || n == "efi" ||
                    n == "$recycle.bin" || n == "users" || n == "programdata" || n == "pagefile.sys" ||
                    n == "swapfile.sys" || n == "hiberfil.sys" || n == "bootmgr") return true;
            }
            return false;
        }
    }

    // ------------------------------------------------------------------
    //  Unidades
    // ------------------------------------------------------------------
    public class DriveCard
    {
        public string Root { get; set; }
        public string Name { get; set; }
        public string Label { get; set; }
        public long Total { get; set; }
        public long Free { get; set; }
        public long Used { get { return Total - Free; } }
        public double UsedPct { get { return Total > 0 ? Used * 100.0 / Total : 0; } }
        public string UsedText { get { return Fmt.Size(Used) + " de " + Fmt.Size(Total); } }
        public string FreeText { get { return Fmt.Size(Free) + " libres  ·  " + UsedPct.ToString("0") + "% ocupado"; } }

        public static List<DriveCard> GetAll()
        {
            var l = new List<DriveCard>();
            foreach (var d in DriveInfo.GetDrives())
            {
                try
                {
                    if (!d.IsReady || (d.DriveType != DriveType.Fixed && d.DriveType != DriveType.Removable)) continue;
                    var c = new DriveCard();
                    c.Root = d.RootDirectory.FullName; c.Name = d.Name.TrimEnd('\\');
                    c.Label = string.IsNullOrEmpty(d.VolumeLabel) ? "Disco local" : d.VolumeLabel;
                    c.Total = d.TotalSize; c.Free = d.TotalFreeSpace;
                    l.Add(c);
                }
                catch { }
            }
            return l;
        }
    }

    // ------------------------------------------------------------------
    //  Escáner de carpetas (rápido, Win32 FindFirstFileEx)
    // ------------------------------------------------------------------
    public class DirNode
    {
        public string Name; public string Path; public long Size; public long Files;
        public long SmallSize; public int SmallCount; public bool Denied; public DirNode Parent;
        public List<DirNode> Dirs = new List<DirNode>();
        public List<KeyValuePair<string, long>> BigFiles = new List<KeyValuePair<string, long>>();
    }

    public class DiskItem
    {
        public string Name { get; set; }
        public string FullPath { get; set; }
        public long Size { get; set; }
        public string SizeText { get; set; }
        public double Percent { get; set; }
        public string PercentText { get; set; }
        public string Icon { get; set; }
        public string Kind { get; set; }
        public string Detail { get; set; }
        public DirNode Node { get; set; }
        public DirNode Owner { get; set; }
    }

    public static class Scanner
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct WIN32_FIND_DATA
        {
            public uint dwFileAttributes;
            public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime, ftLastAccessTime, ftLastWriteTime;
            public uint nFileSizeHigh, nFileSizeLow, dwReserved0, dwReserved1;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string cFileName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)] public string cAlternateFileName;
        }
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern IntPtr FindFirstFileExW(string name, int level, out WIN32_FIND_DATA data, int op, IntPtr filter, int flags);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        static extern bool FindNextFileW(IntPtr h, out WIN32_FIND_DATA data);
        [DllImport("kernel32.dll")]
        static extern bool FindClose(IntPtr h);
        static readonly IntPtr INVALID = new IntPtr(-1);

        public const long BigFile = 20L << 20;
        public const long HugeFile = 200L << 20;
        public static long FilesScanned, BytesScanned;
        public static string Current = "";
        public static volatile bool Cancel;
        static ConcurrentBag<KeyValuePair<string, long>> huge = new ConcurrentBag<KeyValuePair<string, long>>();

        public static Task<DirNode> ScanAsync(string root)
        {
            Cancel = false; FilesScanned = 0; BytesScanned = 0;
            huge = new ConcurrentBag<KeyValuePair<string, long>>();
            return Task.Factory.StartNew(() =>
            {
                var n = new DirNode(); n.Path = root; n.Name = root;
                Build(n, 0);
                return n;
            }, TaskCreationOptions.LongRunning);
        }

        static void Build(DirNode node, int depth)
        {
            if (Cancel) return;
            string b = node.Path.TrimEnd('\\');
            WIN32_FIND_DATA fd;
            IntPtr h = FindFirstFileExW(@"\\?\" + b + @"\*", 1, out fd, 0, IntPtr.Zero, 2);
            if (h == INVALID) { node.Denied = true; return; }
            long files = 0, bytes = 0;
            try
            {
                do
                {
                    string n = fd.cFileName;
                    if (n == "." || n == "..") continue;
                    if ((fd.dwFileAttributes & 0x10) != 0)
                    {
                        if ((fd.dwFileAttributes & 0x400) != 0) continue; // junction / symlink
                        var c = new DirNode(); c.Name = n; c.Path = b + "\\" + n; c.Parent = node;
                        node.Dirs.Add(c);
                    }
                    else
                    {
                        long s = ((long)fd.nFileSizeHigh << 32) | fd.nFileSizeLow;
                        files++; bytes += s;
                        if (s >= BigFile) node.BigFiles.Add(new KeyValuePair<string, long>(n, s));
                        else { node.SmallSize += s; node.SmallCount++; }
                        if (s >= HugeFile) huge.Add(new KeyValuePair<string, long>(b + "\\" + n, s));
                    }
                } while (FindNextFileW(h, out fd));
            }
            finally { FindClose(h); }
            Interlocked.Add(ref FilesScanned, files);
            Interlocked.Add(ref BytesScanned, bytes);
            Current = b;
            node.Size = bytes; node.Files = files;
            if (depth < 2 && node.Dirs.Count > 1)
                Parallel.ForEach(node.Dirs, new ParallelOptions { MaxDegreeOfParallelism = 6 }, c => Build(c, depth + 1));
            else
                foreach (var c in node.Dirs) Build(c, depth + 1);
            foreach (var c in node.Dirs) { node.Size += c.Size; node.Files += c.Files; }
        }

        public static long DirSize(string path)
        {
            long total = 0;
            var st = new Stack<string>(); st.Push(path.TrimEnd('\\'));
            while (st.Count > 0)
            {
                string b = st.Pop();
                WIN32_FIND_DATA fd;
                IntPtr h = FindFirstFileExW(@"\\?\" + b + @"\*", 1, out fd, 0, IntPtr.Zero, 2);
                if (h == INVALID) continue;
                try
                {
                    do
                    {
                        string n = fd.cFileName;
                        if (n == "." || n == "..") continue;
                        if ((fd.dwFileAttributes & 0x10) != 0)
                        {
                            if ((fd.dwFileAttributes & 0x400) == 0) st.Push(b + "\\" + n);
                        }
                        else total += ((long)fd.nFileSizeHigh << 32) | fd.nFileSizeLow;
                    } while (FindNextFileW(h, out fd));
                }
                finally { FindClose(h); }
            }
            return total;
        }

        static string Ext(string n)
        {
            string e = System.IO.Path.GetExtension(n);
            return string.IsNullOrEmpty(e) ? "" : e.TrimStart('.').ToUpperInvariant();
        }

        static DiskItem Mk(string name, string full, long size, double total, string kind, string icon, string detail, DirNode node, DirNode owner)
        {
            var d = new DiskItem();
            d.Name = name; d.FullPath = full; d.Size = size; d.SizeText = Fmt.Size(size);
            d.Percent = total > 0 ? size * 100.0 / total : 0;
            d.PercentText = d.Percent < 0.1 ? "<0.1%" : d.Percent.ToString("0.0") + "%";
            d.Kind = kind; d.Icon = icon; d.Detail = detail; d.Node = node; d.Owner = owner;
            return d;
        }

        public static List<DiskItem> GetItems(DirNode n)
        {
            var l = new List<DiskItem>();
            double t = n.Size > 0 ? n.Size : 1;
            string pfx = n.Path.TrimEnd('\\') + "\\";
            foreach (var d in n.Dirs)
                l.Add(Mk(d.Name, d.Path, d.Size, t, "dir", "\uE8B7",
                    d.Denied ? "Acceso denegado" : d.Files.ToString("N0") + " archivos  ·  " + d.Dirs.Count.ToString("N0") + " carpetas", d, n));
            foreach (var f in n.BigFiles)
                l.Add(Mk(f.Key, pfx + f.Key, f.Value, t, "file", "\uE8A5", "Archivo " + Ext(f.Key), null, n));
            if (n.SmallCount > 0)
                l.Add(Mk(n.SmallCount.ToString("N0") + " archivos pequeños", n.Path, n.SmallSize, t, "small", "\uE7C3",
                    "Archivos menores de 20 MB sueltos en esta carpeta", null, n));
            l.Sort((a, b) => b.Size.CompareTo(a.Size));
            return l;
        }

        public static List<DiskItem> TopFiles(int max)
        {
            var all = new List<KeyValuePair<string, long>>(huge);
            all.Sort((a, b) => b.Value.CompareTo(a.Value));
            var l = new List<DiskItem>();
            double top = all.Count > 0 ? all[0].Value : 1;
            for (int i = 0; i < all.Count && i < max; i++)
                l.Add(Mk(System.IO.Path.GetFileName(all[i].Key), all[i].Key, all[i].Value, top, "file", "\uE8A5",
                    System.IO.Path.GetDirectoryName(all[i].Key), null, null));
            return l;
        }

        public static void Remove(DiskItem it)
        {
            DirNode owner = it.Owner; if (owner == null) return;
            long s = it.Size;
            if (it.Kind == "dir") owner.Dirs.Remove(it.Node);
            else if (it.Kind == "file") owner.BigFiles.RemoveAll(x => x.Key == it.Name);
            else return;
            for (var p = owner; p != null; p = p.Parent) p.Size -= s;
        }
    }

    // ------------------------------------------------------------------
    //  Programas instalados
    // ------------------------------------------------------------------
    public class ProgramInfo : Bindable
    {
        public string Name { get; set; }
        public string Publisher { get; set; }
        public string Version { get; set; }
        public string InstallDateText { get; set; }
        public DateTime InstallDate { get; set; }
        public string InstallDir { get; set; }
        public string UninstallString, QuietUninstallString, ProductCode, Hive, View, KeyPath;
        public bool IsMsi;
        public long Estimated;
        public string Initial { get { return string.IsNullOrEmpty(Name) ? "?" : Name.Substring(0, 1).ToUpperInvariant(); } }
        public string SubLine
        {
            get
            {
                var parts = new List<string>();
                if (!string.IsNullOrEmpty(Publisher)) parts.Add(Publisher);
                if (!string.IsNullOrEmpty(Version)) parts.Add("v" + Version);
                parts.Add(string.IsNullOrEmpty(InstallDir) ? "Ubicación desconocida" : InstallDir);
                return string.Join("   ·   ", parts);
            }
        }
        long size = -1;
        public long Size { get { return size; } set { size = value; N("Size"); N("SizeText"); } }
        public string SizeText { get { return size < 0 ? "calculando…" : (size == 0 ? "—" : Fmt.Size(size)); } }
        double pct;
        public double Percent { get { return pct; } set { pct = value; N("Percent"); } }
    }

    public static class Programs
    {
        public static int Sized;
        const string Sub = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall";

        public static List<ProgramInfo> Load()
        {
            var list = new List<ProgramInfo>();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            Read(RegistryHive.LocalMachine, RegistryView.Registry64, "HKLM", "64", list, seen);
            Read(RegistryHive.LocalMachine, RegistryView.Registry32, "HKLM", "32", list, seen);
            Read(RegistryHive.CurrentUser, RegistryView.Registry64, "HKCU", "64", list, seen);
            return list;
        }

        static string S(RegistryKey k, string n)
        {
            object v = k.GetValue(n);
            if (v == null) return null;
            string s = v.ToString().Trim();
            return s.Length == 0 ? null : s;
        }
        static int I(RegistryKey k, string n)
        {
            object v = k.GetValue(n);
            if (v is int) return (int)v;
            int r; if (v != null && int.TryParse(v.ToString(), out r)) return r;
            return 0;
        }

        static void Read(RegistryHive hive, RegistryView view, string hn, string vn, List<ProgramInfo> list, HashSet<string> seen)
        {
            try
            {
                using (var b = RegistryKey.OpenBaseKey(hive, view))
                using (var k = b.OpenSubKey(Sub))
                {
                    if (k == null) return;
                    foreach (string n in k.GetSubKeyNames())
                    {
                        try
                        {
                            using (var s = k.OpenSubKey(n))
                            {
                                if (s == null) continue;
                                string dn = S(s, "DisplayName");
                                if (dn == null) continue;
                                if (I(s, "SystemComponent") == 1) continue;
                                if (S(s, "ParentKeyName") != null) continue;
                                string rt = S(s, "ReleaseType");
                                if (rt != null && (rt.Contains("Update") || rt.Contains("Hotfix"))) continue;
                                string us = S(s, "UninstallString"), qus = S(s, "QuietUninstallString");
                                if (us == null && qus == null) continue;
                                string ver = S(s, "DisplayVersion") ?? "";
                                if (!seen.Add(dn + "|" + ver)) continue;

                                var p = new ProgramInfo();
                                p.Name = dn; p.Version = ver; p.Publisher = S(s, "Publisher") ?? "";
                                p.UninstallString = us; p.QuietUninstallString = qus;
                                p.Hive = hn; p.View = vn; p.KeyPath = Sub + "\\" + n;
                                p.IsMsi = I(s, "WindowsInstaller") == 1 || (us != null && us.IndexOf("msiexec", StringComparison.OrdinalIgnoreCase) >= 0);
                                if (n.StartsWith("{") && n.EndsWith("}")) p.ProductCode = n;
                                else if (us != null) { var m = Regex.Match(us, @"\{[0-9A-Fa-f\-]{36}\}"); if (m.Success) p.ProductCode = m.Value; }
                                p.Estimated = (long)I(s, "EstimatedSize") * 1024;
                                string date = S(s, "InstallDate");
                                DateTime dt;
                                if (date != null && date.Length == 8 && DateTime.TryParseExact(date, "yyyyMMdd", null, System.Globalization.DateTimeStyles.None, out dt))
                                { p.InstallDate = dt; p.InstallDateText = dt.ToString("dd/MM/yyyy"); }
                                else p.InstallDateText = "";
                                p.InstallDir = ResolveDir(S(s, "InstallLocation"), S(s, "DisplayIcon"), us);
                                list.Add(p);
                            }
                        }
                        catch { }
                    }
                }
            }
            catch { }
        }

        public static string ExePath(string cmd)
        {
            if (string.IsNullOrWhiteSpace(cmd)) return null;
            cmd = cmd.Trim();
            if (cmd.StartsWith("\"")) { int e = cmd.IndexOf('"', 1); return e > 1 ? cmd.Substring(1, e - 1) : null; }
            int i = cmd.IndexOf(".exe", StringComparison.OrdinalIgnoreCase);
            if (i > 0) return cmd.Substring(0, i + 4);
            int c = cmd.LastIndexOf(',');
            if (c > 0) cmd = cmd.Substring(0, c);
            return cmd;
        }

        public static string ArgsOf(string cmd)
        {
            if (string.IsNullOrWhiteSpace(cmd)) return "";
            cmd = cmd.Trim();
            if (cmd.StartsWith("\"")) { int e = cmd.IndexOf('"', 1); return e > 0 && e + 1 < cmd.Length ? cmd.Substring(e + 1).Trim() : ""; }
            int i = cmd.IndexOf(".exe", StringComparison.OrdinalIgnoreCase);
            if (i > 0 && i + 4 < cmd.Length) return cmd.Substring(i + 4).Trim();
            return "";
        }

        static string NormDir(string d)
        {
            if (string.IsNullOrWhiteSpace(d)) return null;
            d = d.Trim().Trim('"').Replace('/', '\\').TrimEnd('\\');
            return d.Length < 3 ? null : d;
        }

        static bool Good(string d)
        {
            if (d == null) return false;
            try
            {
                if (!Directory.Exists(d)) return false;
                if (Safety.IsProtected(d)) return false;
                string l = d.ToLowerInvariant();
                if (l.Contains("\\package cache") || l.Contains("installshield installation information") ||
                    l.Contains("\\windows\\installer") || l.Contains("\\{")) return false;
                return true;
            }
            catch { return false; }
        }

        static string Dir(string exe)
        {
            try { return NormDir(Path.GetDirectoryName(exe)); } catch { return null; }
        }

        public static string ResolveDir(string loc, string icon, string us)
        {
            string d = NormDir(loc);
            if (Good(d)) return d;
            string e = ExePath(icon);
            if (e != null) { d = Dir(e); if (Good(d)) return d; }
            e = ExePath(us);
            if (e != null && e.IndexOf("msiexec", StringComparison.OrdinalIgnoreCase) < 0) { d = Dir(e); if (Good(d)) return d; }
            return null;
        }

        public static Task SizeAsync(List<ProgramInfo> list)
        {
            Sized = 0;
            return Task.Factory.StartNew(() =>
            {
                Parallel.ForEach(list, new ParallelOptions { MaxDegreeOfParallelism = 4 }, p =>
                {
                    long s = 0;
                    if (!string.IsNullOrEmpty(p.InstallDir)) { try { s = Scanner.DirSize(p.InstallDir); } catch { } }
                    if (s == 0) s = p.Estimated;
                    p.Size = s;
                    Interlocked.Increment(ref Sized);
                });
            }, TaskCreationOptions.LongRunning);
        }

        public static bool StillInstalled(ProgramInfo p)
        {
            try
            {
                var hive = p.Hive == "HKCU" ? RegistryHive.CurrentUser : RegistryHive.LocalMachine;
                var view = p.View == "32" ? RegistryView.Registry32 : RegistryView.Registry64;
                using (var b = RegistryKey.OpenBaseKey(hive, view))
                using (var k = b.OpenSubKey(p.KeyPath))
                    return k != null;
            }
            catch { return true; }
        }
    }

    // ------------------------------------------------------------------
    //  Búsqueda de restos (carpetas, accesos directos, servicios, registro)
    // ------------------------------------------------------------------
    public class Leftover : Bindable
    {
        bool c;
        public bool Checked { get { return c; } set { c = value; N("Checked"); } }
        public string Path { get; set; }
        public string Kind { get; set; }
        public string SizeText { get; set; }
        public string Warning { get; set; }
        public string Icon { get; set; }
        public long SizeBytes;
        public bool IsReg, IsService;
        public string RegHive, RegView, RegSub, Service;
    }

    public static class Leftovers
    {
        static readonly string[] Black = { "microsoft", "windows", "common", "commonfiles", "packages", "programs", "temp", "google",
            "nvidia", "nvidiacorporation", "intel", "amd", "adobe", "apple", "oracle", "java", "mozilla", "system", "users", "default",
            "public", "cache", "data", "app", "apps", "update", "updater", "installer", "setup", "tools", "driver", "drivers",
            "software", "classes", "policies", "wow6432node", "clients", "local", "roaming", "programdata", "programfiles" };

        public static string Norm(string s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            s = s.ToLowerInvariant();
            s = Regex.Replace(s, @"\(.*?\)|\[.*?\]", " ");
            s = Regex.Replace(s, @"\b(x64|x86|64-bit|32-bit|64bit|32bit|amd64|win64|win32)\b", " ");
            s = Regex.Replace(s, @"\b(v|version)?\s?\d+([.\-_]\d+)*\b", " ");
            s = Regex.Replace(s, @"[^a-z0-9]", "");
            return s;
        }
        public static string NormPub(string s)
        {
            s = (s ?? "").ToLowerInvariant();
            s = Regex.Replace(s, @"\b(inc|ltd|llc|corp|corporation|gmbh|co|limited|software|technologies|s\.a|s\.l)\b\.?", " ");
            return Norm(s);
        }
        static bool IsBlack(string n) { return Array.IndexOf(Black, n) >= 0; }

        static void AddV(List<string> v, string s) { if (s.Length >= 3 && !IsBlack(s) && !v.Contains(s)) v.Add(s); }

        static bool Match(string fn, List<string> vars)
        {
            if (fn.Length < 3 || IsBlack(fn)) return false;
            foreach (var v in vars)
            {
                if (fn == v) return true;
                if (fn.Length >= 5 && v.Length >= 5 && (v.StartsWith(fn) || fn.StartsWith(v)) &&
                    Math.Min(fn.Length, v.Length) * 10 >= Math.Max(fn.Length, v.Length) * 6) return true;
            }
            return false;
        }

        static string[] Dirs(string p) { try { return Directory.GetDirectories(p); } catch { return new string[0]; } }
        static string[] Files(string p, string pat) { try { return Directory.GetFiles(p, pat); } catch { return new string[0]; } }

        public static Task<List<Leftover>> FindAsync(ProgramInfo p, List<ProgramInfo> all)
        {
            return Task.Factory.StartNew(() => Find(p, all));
        }

        static int SharedWith(string dir, ProgramInfo p, List<ProgramInfo> all)
        {
            int n = 0; string me = dir.TrimEnd('\\');
            foreach (var o in all)
            {
                if (o == p || string.IsNullOrEmpty(o.InstallDir)) continue;
                string od = o.InstallDir.TrimEnd('\\');
                if (od.Equals(me, StringComparison.OrdinalIgnoreCase) || od.StartsWith(me + "\\", StringComparison.OrdinalIgnoreCase)) n++;
            }
            return n;
        }

        static void AddPath(List<Leftover> res, HashSet<string> seen, string path, string kind, string icon, ProgramInfo p, List<ProgramInfo> all, string installDir)
        {
            path = path.TrimEnd('\\');
            if (seen.Contains(path) || Safety.IsProtected(path)) return;
            if (installDir != null && path.StartsWith(installDir + "\\", StringComparison.OrdinalIgnoreCase)) return;
            seen.Add(path);
            bool isDir = Directory.Exists(path);
            long size = 0;
            try { size = isDir ? Scanner.DirSize(path) : new FileInfo(path).Length; } catch { }
            int shared = isDir ? SharedWith(path, p, all) : 0;
            var l = new Leftover();
            l.Path = path; l.Kind = kind; l.Icon = icon; l.SizeBytes = size; l.SizeText = Fmt.Size(size);
            l.Checked = shared == 0;
            l.Warning = shared > 0 ? "Contiene " + shared + " programa(s) más instalados — desmarcada por seguridad" : "";
            res.Add(l);
        }

        static void AddReg(List<Leftover> res, HashSet<string> seen, string hive, string view, string sub, string kind, bool chk)
        {
            if (string.IsNullOrEmpty(sub) || sub.Split('\\').Length < 2) return;
            try
            {
                var h = hive == "HKCU" ? RegistryHive.CurrentUser : RegistryHive.LocalMachine;
                var v = view == "32" ? RegistryView.Registry32 : RegistryView.Registry64;
                using (var b = RegistryKey.OpenBaseKey(h, v))
                using (var k = b.OpenSubKey(sub))
                {
                    if (k == null) return;
                }
                string disp = hive + "\\" + (view == "32" && hive == "HKLM" ? sub.Replace("SOFTWARE\\", "SOFTWARE\\WOW6432Node\\") : sub);
                if (!seen.Add(disp)) return;
                var l = new Leftover();
                l.Path = disp; l.Kind = kind; l.Icon = "\uE8F1"; l.SizeText = ""; l.Checked = chk; l.Warning = "";
                l.IsReg = true; l.RegHive = hive; l.RegView = view; l.RegSub = sub;
                res.Add(l);
            }
            catch { }
        }

        static List<Leftover> Find(ProgramInfo p, List<ProgramInfo> all)
        {
            var res = new List<Leftover>();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            string inst = string.IsNullOrEmpty(p.InstallDir) ? null : p.InstallDir.TrimEnd('\\');

            // 1) Carpeta de instalación
            if (inst != null && Directory.Exists(inst) && !Safety.IsProtected(inst))
            {
                int shared = SharedWith(inst, p, all);
                var l = new Leftover();
                l.Path = inst; l.Kind = "Carpeta de instalación"; l.Icon = "\uE8B7";
                l.SizeBytes = p.Size >= 0 ? p.Size : Scanner.DirSize(inst);
                l.SizeText = Fmt.Size(l.SizeBytes);
                l.Checked = shared == 0;
                l.Warning = shared > 0 ? "Contiene " + shared + " programa(s) más instalados — desmarcada por seguridad" : "";
                res.Add(l); seen.Add(inst);
            }

            // 2) Variantes de nombre
            var vars = new List<string>();
            string nn = Norm(p.Name);
            AddV(vars, nn);
            if (inst != null) AddV(vars, Norm(Path.GetFileName(inst)));
            string pub = NormPub(p.Publisher);
            if (pub.Length >= 3 && nn.StartsWith(pub) && nn.Length - pub.Length >= 3) AddV(vars, nn.Substring(pub.Length));

            if (vars.Count > 0)
            {
                string up = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
                string la = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                string ra = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                string pd = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
                string[] roots = {
                    Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                    Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonProgramFiles),
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonProgramFilesX86),
                    Path.Combine(la, "Programs"), la, ra, Path.Combine(up, "AppData\\LocalLow"), pd,
                    Environment.GetFolderPath(Environment.SpecialFolder.Programs),
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonPrograms) };
                foreach (var root in roots)
                {
                    if (string.IsNullOrEmpty(root) || !Directory.Exists(root)) continue;
                    foreach (var d in Dirs(root))
                    {
                        string name = Path.GetFileName(d);
                        if (Match(Norm(name), vars)) { AddPath(res, seen, d, "Datos residuales", "\uE8B7", p, all, inst); continue; }
                        if (pub.Length >= 3 && NormPub(name) == pub)
                            foreach (var d2 in Dirs(d))
                                if (Match(Norm(Path.GetFileName(d2)), vars)) AddPath(res, seen, d2, "Datos residuales", "\uE8B7", p, all, inst);
                    }
                }
                // Accesos directos
                string[] lnkDirs = {
                    Environment.GetFolderPath(Environment.SpecialFolder.Desktop),
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonDesktopDirectory),
                    Environment.GetFolderPath(Environment.SpecialFolder.Programs),
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonPrograms) };
                foreach (var ld in lnkDirs)
                {
                    if (string.IsNullOrEmpty(ld)) continue;
                    foreach (var f in Files(ld, "*.lnk"))
                        if (Match(Norm(Path.GetFileNameWithoutExtension(f)), vars)) AddPath(res, seen, f, "Acceso directo", "\uE71B", p, all, inst);
                }
            }

            // 3) Servicios que apuntan a la carpeta del programa
            if (inst != null)
            {
                try
                {
                    using (var b = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64))
                    using (var svcs = b.OpenSubKey(@"SYSTEM\CurrentControlSet\Services"))
                    {
                        if (svcs != null)
                            foreach (var sn in svcs.GetSubKeyNames())
                            {
                                try
                                {
                                    using (var s = svcs.OpenSubKey(sn))
                                    {
                                        object ip = s == null ? null : s.GetValue("ImagePath");
                                        if (ip == null) continue;
                                        string ips = Environment.ExpandEnvironmentVariables(ip.ToString());
                                        if (ips.IndexOf(inst + "\\", StringComparison.OrdinalIgnoreCase) >= 0)
                                        {
                                            var l = new Leftover();
                                            l.Path = "Servicio de Windows: " + sn; l.Kind = "Servicio (se detendrá y eliminará)"; l.Icon = "\uE912";
                                            l.SizeText = ""; l.Warning = ""; l.Checked = true; l.IsService = true; l.Service = sn;
                                            res.Add(l);
                                        }
                                    }
                                }
                                catch { }
                            }
                    }
                }
                catch { }
            }

            // 4) Registro
            AddReg(res, seen, p.Hive, p.View, p.KeyPath, "Registro (entrada de desinstalación)", true);
            string rawName = Regex.Replace(p.Name, @"\s*\(.*?\)", "");
            rawName = Regex.Replace(rawName, @"\s+v?\d+(\.\d+)+.*$", "").Trim();
            string rawPub = (p.Publisher ?? "").Trim();
            var subs = new List<string>();
            if (rawName.Length > 0 && rawPub.Length > 0) subs.Add("SOFTWARE\\" + rawPub + "\\" + rawName);
            string nrn = Norm(rawName);
            if (rawName.Length > 0 && nrn.Length >= 4 && !IsBlack(nrn)) subs.Add("SOFTWARE\\" + rawName);
            foreach (var sub in subs)
            {
                AddReg(res, seen, "HKCU", "64", sub, "Registro (configuración)", true);
                AddReg(res, seen, "HKLM", "64", sub, "Registro (configuración)", true);
                AddReg(res, seen, "HKLM", "32", sub, "Registro (configuración)", true);
            }
            return res;
        }
    }

    // ------------------------------------------------------------------
    //  Desinstalador agresivo
    // ------------------------------------------------------------------
    public class UninstallJob
    {
        public string Name, Exe, Args;
        public List<Leftover> Items = new List<Leftover>();
    }

    public static class Uninstaller
    {
        public static ConcurrentQueue<string> Log = new ConcurrentQueue<string>();
        public static long Freed;
        public static int PendingReboot;
        static void L(string s) { Log.Enqueue(DateTime.Now.ToString("HH:mm:ss") + "   " + s); }

        public static bool BuildCommand(ProgramInfo p, bool silent, out string exe, out string args)
        {
            exe = null; args = null;
            if (p.IsMsi && !string.IsNullOrEmpty(p.ProductCode))
            {
                exe = "msiexec.exe";
                args = "/x " + p.ProductCode + (silent ? " /qn /norestart" : " /norestart");
                return true;
            }
            bool fromQuiet = silent && !string.IsNullOrEmpty(p.QuietUninstallString);
            string cmd = fromQuiet ? p.QuietUninstallString : p.UninstallString;
            if (string.IsNullOrEmpty(cmd)) return false;
            exe = Programs.ExePath(cmd); args = Programs.ArgsOf(cmd);
            if (exe == null) return false;
            string fn = Path.GetFileName(exe).ToLowerInvariant();
            if (fn == "msiexec.exe")
            {
                args = Regex.Replace(args, @"/I(?=\{|\s)", "/X", RegexOptions.IgnoreCase);
                if (silent && args.IndexOf("/q", StringComparison.OrdinalIgnoreCase) < 0) args += " /qn /norestart";
            }
            else if (silent && !fromQuiet)
            {
                if (Regex.IsMatch(fn, @"^unins\d+\.exe$")) args += " /VERYSILENT /SUPPRESSMSGBOXES /NORESTART";
                else if (fn == "update.exe" && args.IndexOf("--uninstall", StringComparison.OrdinalIgnoreCase) >= 0) args += " -s";
                else if (fn.StartsWith("uninst") && args.IndexOf("/S", StringComparison.Ordinal) < 0) args += " /S";
            }
            args = args.Trim();
            return true;
        }

        public static Task RunAsync(UninstallJob j)
        {
            Freed = 0; PendingReboot = 0;
            string dummy; while (Log.TryDequeue(out dummy)) { }
            return Task.Factory.StartNew(() => Run(j), TaskCreationOptions.LongRunning);
        }

        static void Run(UninstallJob j)
        {
            L("Iniciando desinstalación a fondo de: " + j.Name);

            // 1) Desinstalador oficial
            if (j.Exe != null)
            {
                bool exists = j.Exe.IndexOf('\\') < 0 || File.Exists(j.Exe);
                if (!exists) L("El desinstalador oficial ya no existe (" + j.Exe + "). Se forzará el borrado.");
                else
                {
                    L("Ejecutando desinstalador: " + j.Exe + " " + j.Args);
                    try
                    {
                        var psi = new ProcessStartInfo(j.Exe, j.Args ?? "");
                        psi.UseShellExecute = true;
                        try { string wd = Path.GetDirectoryName(j.Exe); if (!string.IsNullOrEmpty(wd)) psi.WorkingDirectory = wd; } catch { }
                        var pr = Process.Start(psi);
                        if (pr != null)
                        {
                            if (!pr.WaitForExit(20 * 60 * 1000)) L("El desinstalador tardó más de 20 min; se continúa con el borrado.");
                            else L("El desinstalador terminó (código " + pr.ExitCode + ").");
                        }
                        WaitHelpers();
                    }
                    catch (Exception ex) { L("No se pudo ejecutar el desinstalador: " + ex.Message); }
                }
            }
            else L("Se omite el desinstalador oficial: borrado directo.");

            // 2) Servicios
            foreach (var it in j.Items)
            {
                if (!it.IsService) continue;
                L("Deteniendo y eliminando servicio " + it.Service);
                RunHidden("sc.exe", "stop \"" + it.Service + "\"", 30000);
                Thread.Sleep(1500);
                RunHidden("sc.exe", "delete \"" + it.Service + "\"", 30000);
            }

            // 3) Cerrar procesos que se ejecutan desde esas carpetas
            var dirs = new List<string>();
            foreach (var it in j.Items) if (!it.IsReg && !it.IsService && Directory.Exists(it.Path)) dirs.Add(it.Path.TrimEnd('\\'));
            KillUnder(dirs);

            // 4) Borrar archivos y carpetas
            foreach (var it in j.Items)
            {
                if (it.IsReg || it.IsService) continue;
                if (Safety.IsProtected(it.Path)) { L("Ruta protegida del sistema, omitida: " + it.Path); continue; }
                if (!Directory.Exists(it.Path) && !File.Exists(it.Path)) { L("Ya no existe: " + it.Path); Freed += 0; continue; }
                long before = it.SizeBytes;
                ForceDelete(it.Path);
                if (!Directory.Exists(it.Path) && !File.Exists(it.Path)) { Freed += before; L("Eliminado: " + it.Path + "  (" + Fmt.Size(before) + ")"); }
                else
                {
                    long left = 0; try { left = Directory.Exists(it.Path) ? Scanner.DirSize(it.Path) : 0; } catch { }
                    Freed += Math.Max(0, before - left);
                    L("Parcialmente eliminado (archivos bloqueados se borrarán al reiniciar): " + it.Path);
                }
            }

            // 5) Registro
            foreach (var it in j.Items)
            {
                if (!it.IsReg) continue;
                try
                {
                    var hive = it.RegHive == "HKCU" ? RegistryHive.CurrentUser : RegistryHive.LocalMachine;
                    var view = it.RegView == "32" ? RegistryView.Registry32 : RegistryView.Registry64;
                    using (var b = RegistryKey.OpenBaseKey(hive, view)) b.DeleteSubKeyTree(it.RegSub, false);
                    L("Registro eliminado: " + it.Path);
                }
                catch (Exception ex) { L("No se pudo borrar " + it.Path + ": " + ex.Message); }
            }

            L("────────────────────────────────────────");
            L("COMPLETADO. Espacio liberado: " + Fmt.Size(Freed));
            if (PendingReboot > 0) L(PendingReboot + " elemento(s) bloqueados se eliminarán al reiniciar Windows.");
        }

        static void WaitHelpers()
        {
            // Muchos desinstaladores (NSIS, Inno) se copian a %TEMP% y siguen corriendo
            string[] pref = { "au_", "un_a", "un_", "_iu", "unins", "uninst" };
            var until = DateTime.Now.AddMinutes(10);
            Thread.Sleep(1500);
            while (DateTime.Now < until)
            {
                bool any = false;
                foreach (var pr in Process.GetProcesses())
                {
                    string n = pr.ProcessName.ToLowerInvariant();
                    foreach (var x in pref) if (n.StartsWith(x)) { any = true; break; }
                    if (any) break;
                }
                if (!any) return;
                Thread.Sleep(1000);
            }
        }

        static void KillUnder(List<string> dirs)
        {
            if (dirs.Count == 0) return;
            int me = Process.GetCurrentProcess().Id;
            foreach (var pr in Process.GetProcesses())
            {
                try
                {
                    if (pr.Id == me || pr.Id <= 4) continue;
                    string f = pr.MainModule.FileName;
                    foreach (var d in dirs)
                        if (f.StartsWith(d + "\\", StringComparison.OrdinalIgnoreCase))
                        {
                            L("Cerrando proceso: " + pr.ProcessName + " (PID " + pr.Id + ")");
                            pr.Kill(); pr.WaitForExit(5000);
                            break;
                        }
                }
                catch { }
            }
        }

        public static string RunHidden(string exe, string args, int timeoutMs)
        {
            try
            {
                var psi = new ProcessStartInfo(exe, args);
                psi.UseShellExecute = false; psi.CreateNoWindow = true;
                psi.RedirectStandardOutput = true; psi.RedirectStandardError = true; psi.RedirectStandardInput = true;
                using (var p = Process.Start(psi))
                {
                    p.StandardInput.Close();
                    var o = p.StandardOutput.ReadToEndAsync();
                    p.StandardError.ReadToEndAsync();
                    p.WaitForExit(timeoutMs);
                    return o.IsCompleted ? o.Result : "";
                }
            }
            catch { return ""; }
        }

        static void DeleteFile(string f)
        {
            try { File.SetAttributes(f, FileAttributes.Normal); File.Delete(f); } catch { }
        }

        public static void DeleteTree(string path)
        {
            try
            {
                if (Directory.Exists(path))
                {
                    var di = new DirectoryInfo(path);
                    if ((di.Attributes & FileAttributes.ReparsePoint) != 0) { try { Directory.Delete(path, false); } catch { } return; }
                    foreach (var f in Files(path)) DeleteFile(f);
                    foreach (var d in Subdirs(path)) DeleteTree(d);
                    try { di.Attributes = FileAttributes.Normal; Directory.Delete(path, false); } catch { }
                }
                else if (File.Exists(path)) DeleteFile(path);
            }
            catch { }
        }
        static string[] Files(string p) { try { return Directory.GetFiles(p); } catch { return new string[0]; } }
        static string[] Subdirs(string p) { try { return Directory.GetDirectories(p); } catch { return new string[0]; } }

        static void ScheduleTree(string p)
        {
            try
            {
                if (Directory.Exists(p))
                {
                    foreach (var f in Files(p)) if (Native.MoveFileEx(f, null, 4)) PendingReboot++;
                    foreach (var d in Subdirs(p)) ScheduleTree(d);
                    Native.MoveFileEx(p, null, 4);
                }
                else if (File.Exists(p)) { if (Native.MoveFileEx(p, null, 4)) PendingReboot++; }
            }
            catch { }
        }

        public static void ForceDelete(string path)
        {
            DeleteTree(path);
            if (!Directory.Exists(path) && !File.Exists(path)) return;
            // Tomar propiedad y dar control total a Administradores (SID universal, funciona en Windows en español)
            RunHidden("takeown.exe", "/f \"" + path + "\" /r /a", 600000);
            RunHidden("icacls.exe", "\"" + path + "\" /grant *S-1-5-32-544:F /t /c /q", 600000);
            DeleteTree(path);
            if (Directory.Exists(path) || File.Exists(path)) ScheduleTree(path);
        }
    }

    // ------------------------------------------------------------------
    //  Limpieza rápida
    // ------------------------------------------------------------------
    public class CleanItem : Bindable
    {
        bool c = true;
        public bool Checked { get { return c; } set { c = value; N("Checked"); } }
        public string Name { get; set; }
        public string Desc { get; set; }
        public string Path { get; set; }
        public string Icon { get; set; }
        public string Kind;
        long s = -1;
        public long Size { get { return s; } set { s = value; N("Size"); N("SizeText"); } }
        public string SizeText { get { return s < 0 ? "midiendo…" : Fmt.Size(s); } }
    }

    public static class Cleaner
    {
        static void Add(List<CleanItem> l, string name, string desc, string kind, string path, string icon, bool chk)
        {
            if (kind == "contents" || kind == "whole") { if (!Directory.Exists(path)) return; }
            else if (kind == "file" || kind == "hiber") { if (!File.Exists(path)) return; }
            var c = new CleanItem(); c.Name = name; c.Desc = desc; c.Kind = kind; c.Path = path; c.Icon = icon; c.Checked = chk;
            l.Add(c);
        }

        public static List<CleanItem> Targets()
        {
            var l = new List<CleanItem>();
            string win = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
            string sys = Path.GetPathRoot(win);
            string la = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string pd = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
            Add(l, "Archivos temporales del usuario", "Restos que dejan las aplicaciones en %TEMP%", "contents", Path.GetTempPath().TrimEnd('\\'), "\uE74C", true);
            Add(l, "Temporales de Windows", win + "\\Temp", "contents", win + "\\Temp", "\uE74C", true);
            Add(l, "Papelera de reciclaje", "Vacía la papelera de todas las unidades", "recycle", "", "\uE74D", true);
            Add(l, "Descargas de Windows Update", "Instaladores de actualizaciones ya aplicadas", "contents", win + "\\SoftwareDistribution\\Download", "\uE895", true);
            Add(l, "Caché de Optimización de distribución", "Copias de actualizaciones compartidas en red", "contents",
                win + @"\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache", "\uE895", true);
            Add(l, "Informes de errores de Windows", "Volcados y reportes de fallos (WER)", "contents", pd + @"\Microsoft\Windows\WER", "\uE7BA", true);
            Add(l, "Minivolcados de memoria", win + "\\Minidump", "contents", win + "\\Minidump", "\uE7BA", true);
            Add(l, "Volcado completo de memoria", win + "\\MEMORY.DMP", "file", win + "\\MEMORY.DMP", "\uE7BA", true);
            Add(l, "Caché de Google Chrome", "Se vuelve a generar al navegar", "contents", la + @"\Google\Chrome\User Data\Default\Cache", "\uE774", true);
            Add(l, "Caché de Microsoft Edge", "Se vuelve a generar al navegar", "contents", la + @"\Microsoft\Edge\User Data\Default\Cache", "\uE774", true);
            Add(l, "Caché de miniaturas de iconos", "Explorer la regenera automáticamente", "contents", la + @"\Microsoft\Windows\Explorer", "\uE91B", false);
            Add(l, "Windows.old (Windows anterior)", "Impide volver a la versión anterior de Windows. Suele ocupar 15-30 GB", "whole", sys + "Windows.old", "\uE7F8", false);
            Add(l, "Archivo de hibernación (hiberfil.sys)", "Desactiva la hibernación (powercfg /h off). Libera tanto como tu RAM", "hiber", sys + "hiberfil.sys", "\uE708", false);
            return l;
        }

        static long Measure(CleanItem c)
        {
            try
            {
                switch (c.Kind)
                {
                    case "contents": case "whole": return Scanner.DirSize(c.Path);
                    case "file": case "hiber": return File.Exists(c.Path) ? new FileInfo(c.Path).Length : 0;
                    case "recycle": return Native.RecycleBinSize();
                }
            }
            catch { }
            return 0;
        }

        public static Task MeasureAsync(List<CleanItem> items)
        {
            return Task.Factory.StartNew(() =>
            {
                Parallel.ForEach(items, new ParallelOptions { MaxDegreeOfParallelism = 4 }, c => { c.Size = Measure(c); });
            }, TaskCreationOptions.LongRunning);
        }

        public static Task<long> CleanAsync(List<CleanItem> items)
        {
            return Task.Factory.StartNew(() =>
            {
                long freed = 0;
                foreach (var c in items)
                {
                    if (!c.Checked) continue;
                    long before = Measure(c);
                    try
                    {
                        switch (c.Kind)
                        {
                            case "contents":
                                foreach (var f in SafeFiles(c.Path)) { try { File.SetAttributes(f, FileAttributes.Normal); File.Delete(f); } catch { } }
                                foreach (var d in SafeDirs(c.Path)) Uninstaller.DeleteTree(d);
                                break;
                            case "whole": Uninstaller.ForceDelete(c.Path); break;
                            case "file": try { File.SetAttributes(c.Path, FileAttributes.Normal); File.Delete(c.Path); } catch { } break;
                            case "recycle": Native.SHEmptyRecycleBin(IntPtr.Zero, null, 0x7); break;
                            case "hiber": Uninstaller.RunHidden("powercfg.exe", "/h off", 60000); break;
                        }
                    }
                    catch { }
                    long after = Measure(c);
                    c.Size = after;
                    freed += Math.Max(0, before - after);
                }
                return freed;
            }, TaskCreationOptions.LongRunning);
        }

        static string[] SafeFiles(string p) { try { return Directory.GetFiles(p); } catch { return new string[0]; } }
        static string[] SafeDirs(string p) { try { return Directory.GetDirectories(p); } catch { return new string[0]; } }

        public static Task<bool> DeletePathAsync(string path)
        {
            return Task.Factory.StartNew(() =>
            {
                if (Safety.IsProtected(path)) return false;
                Uninstaller.ForceDelete(path);
                return !Directory.Exists(path) && !File.Exists(path);
            }, TaskCreationOptions.LongRunning);
        }
    }
}
'@

if (-not ('DiskPilot.Scanner' -as [type])) {
    Add-Type -TypeDefinition $cs -Language CSharp
}

# =====================================================================
#  Interfaz (XAML)
# =====================================================================
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="DiskPilot — Almacenamiento y desinstalación a fondo" Width="1320" Height="840" MinWidth="1080" MinHeight="660"
        WindowStartupLocation="CenterScreen" Background="#0E1016" FontFamily="Segoe UI" Foreground="#E8EAF0"
        TextOptions.TextFormattingMode="Display" UseLayoutRounding="True">
  <Window.Resources>
    <SolidColorBrush x:Key="Card" Color="#171B24"/>
    <SolidColorBrush x:Key="Line" Color="#252B39"/>
    <SolidColorBrush x:Key="Sub" Color="#8B92A6"/>
    <LinearGradientBrush x:Key="Accent" StartPoint="0,0" EndPoint="1,1">
      <GradientStop Color="#7C5CFF" Offset="0"/>
      <GradientStop Color="#00C2FF" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="DangerGrad" StartPoint="0,0" EndPoint="1,1">
      <GradientStop Color="#FF3D6E" Offset="0"/>
      <GradientStop Color="#FF7A3D" Offset="1"/>
    </LinearGradientBrush>

    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Foreground" Value="#E8EAF0"/>
      <Setter Property="Background" Value="#202533"/>
      <Setter Property="BorderBrush" Value="#2C3344"/>
      <Setter Property="Padding" Value="16,9"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="1" CornerRadius="9" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Opacity" Value="0.82"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bd" Property="Opacity" Value="0.65"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="bd" Property="Opacity" Value="0.35"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="BtnPrimary" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="{StaticResource Accent}"/>
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="Foreground" Value="White"/>
    </Style>
    <Style x:Key="BtnDanger" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="{StaticResource DangerGrad}"/>
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="Foreground" Value="White"/>
    </Style>
    <Style x:Key="BtnSmall" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Padding" Value="12,6"/>
      <Setter Property="FontSize" Value="12"/>
    </Style>

    <Style x:Key="Nav" TargetType="RadioButton">
      <Setter Property="Foreground" Value="#8B92A6"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Margin" Value="0,3"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="bd" CornerRadius="10" Padding="14,11" Background="Transparent">
              <Grid>
                <Border x:Name="bar" Width="3" Height="18" CornerRadius="2" Background="{StaticResource Accent}"
                        HorizontalAlignment="Left" Margin="-14,0,0,0" Visibility="Collapsed"/>
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="{TemplateBinding Tag}" FontFamily="Segoe MDL2 Assets" FontSize="16" Margin="0,0,14,0"
                             VerticalAlignment="Center" Foreground="{TemplateBinding Foreground}"/>
                  <ContentPresenter VerticalAlignment="Center"/>
                </StackPanel>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="#1A1F2B"/></Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#212839"/>
                <Setter TargetName="bar" Property="Visibility" Value="Visible"/>
                <Setter Property="Foreground" Value="White"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SortBtn" TargetType="RadioButton">
      <Setter Property="Foreground" Value="#8B92A6"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="bd" CornerRadius="7" Padding="12,6" Background="Transparent">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#2A3246"/>
                <Setter Property="Foreground" Value="White"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ProgressBar">
      <Setter Property="Height" Value="7"/>
      <Setter Property="Foreground" Value="{StaticResource Accent}"/>
      <Setter Property="Background" Value="#242A38"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ProgressBar">
            <Grid>
              <Border Background="{TemplateBinding Background}" CornerRadius="4"/>
              <Border x:Name="PART_Track"/>
              <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}" CornerRadius="4"/>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="10"/>
      <Setter Property="MinWidth" Value="10"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track x:Name="PART_Track" IsDirectionReversed="True">
              <Track.Thumb>
                <Thumb>
                  <Thumb.Template>
                    <ControlTemplate TargetType="Thumb">
                      <Border Background="#333A4D" CornerRadius="4" Margin="2"/>
                    </ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Row" TargetType="ListBoxItem">
      <Setter Property="Foreground" Value="#E8EAF0"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListBoxItem">
            <Border x:Name="bd" Background="Transparent" BorderBrush="Transparent" BorderThickness="1" CornerRadius="10" Padding="12,9" Margin="0,1">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="#1C2130"/></Trigger>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#232B40"/>
                <Setter TargetName="bd" Property="BorderBrush" Value="#6A55E8"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="List" TargetType="ListBox">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Foreground" Value="#E8EAF0"/>
      <Setter Property="ItemContainerStyle" Value="{StaticResource Row}"/>
      <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Disabled"/>
      <Setter Property="VirtualizingStackPanel.IsVirtualizing" Value="True"/>
      <Setter Property="VirtualizingStackPanel.VirtualizationMode" Value="Recycling"/>
    </Style>

    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E8EAF0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <StackPanel Orientation="Horizontal" Background="Transparent">
              <Border x:Name="box" Width="18" Height="18" CornerRadius="5" BorderThickness="1.5" BorderBrush="#4A5268" Background="#1A1F2B" VerticalAlignment="Center">
                <TextBlock x:Name="chk" Text="&#xE73E;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="White"
                           HorizontalAlignment="Center" VerticalAlignment="Center" Visibility="Collapsed"/>
              </Border>
              <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="box" Property="Background" Value="{StaticResource Accent}"/>
                <Setter TargetName="box" Property="BorderBrush" Value="Transparent"/>
                <Setter TargetName="chk" Property="Visibility" Value="Visible"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Search" TargetType="TextBox">
      <Setter Property="Foreground" Value="#E8EAF0"/>
      <Setter Property="CaretBrush" Value="#E8EAF0"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border Background="#171B24" BorderBrush="#2A3142" BorderThickness="1" CornerRadius="9" Padding="10,7">
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                <TextBlock Text="&#xE721;" FontFamily="Segoe MDL2 Assets" Foreground="#8B92A6" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock x:Name="ph" Grid.Column="1" Text="Buscar programa o editor…" Foreground="#5D6478" VerticalAlignment="Center" Visibility="Collapsed"/>
                <ScrollViewer x:Name="PART_ContentHost" Grid.Column="1" VerticalAlignment="Center"/>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="Text" Value=""><Setter TargetName="ph" Property="Visibility" Value="Visible"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="H1" TargetType="TextBlock">
      <Setter Property="FontSize" Value="26"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Foreground" Value="White"/>
    </Style>
    <Style x:Key="Hint" TargetType="TextBlock">
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Foreground" Value="#8B92A6"/>
      <Setter Property="TextWrapping" Value="Wrap"/>
    </Style>
    <Style x:Key="CardBorder" TargetType="Border">
      <Setter Property="Background" Value="#151922"/>
      <Setter Property="BorderBrush" Value="#232938"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="16"/>
      <Setter Property="Padding" Value="20"/>
    </Style>

    <Style x:Key="Glyph" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="Segoe MDL2 Assets"/>
    </Style>
  </Window.Resources>

  <Grid>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="236"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <Border Grid.ColumnSpan="2" Background="#0E1016"/>
    <!-- ================= SIDEBAR ================= -->
    <Border Background="#12151C" BorderBrush="#1E2330" BorderThickness="0,0,1,0">
      <Grid Margin="16,22,16,18">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Orientation="Horizontal" Margin="6,0,0,30">
          <Border Width="40" Height="40" CornerRadius="12" Background="{StaticResource Accent}">
            <TextBlock Text="&#xEDA2;" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
            <TextBlock Text="DiskPilot" FontSize="19" FontWeight="Bold" Foreground="White"/>
            <TextBlock x:Name="VersionText" Text="Control de almacenamiento" FontSize="11" Foreground="#8B92A6"/>
          </StackPanel>
        </StackPanel>
        <StackPanel Grid.Row="1">
          <RadioButton x:Name="NavHome" Style="{StaticResource Nav}" Tag="&#xE80F;" Content="Resumen" IsChecked="True" GroupName="nav"/>
          <RadioButton x:Name="NavProgs" Style="{StaticResource Nav}" Tag="&#xE71D;" Content="Programas" GroupName="nav"/>
          <RadioButton x:Name="NavFolders" Style="{StaticResource Nav}" Tag="&#xE8B7;" Content="Explorar disco" GroupName="nav"/>
          <RadioButton x:Name="NavClean" Style="{StaticResource Nav}" Tag="&#xEA99;" Content="Limpieza rápida" GroupName="nav"/>
        </StackPanel>
        <Border Grid.Row="2" CornerRadius="12" Background="#171B24" BorderBrush="#232938" BorderThickness="1" Padding="12,10">
          <StackPanel Orientation="Horizontal">
            <TextBlock x:Name="AdminGlyph" Text="&#xEA18;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="#2ED39A" VerticalAlignment="Center"/>
            <StackPanel Margin="10,0,0,0">
              <TextBlock x:Name="AdminText" Text="Administrador" FontWeight="SemiBold" FontSize="12.5"/>
              <TextBlock x:Name="AdminSub" Text="Permisos completos activos" FontSize="11" Foreground="#8B92A6"/>
            </StackPanel>
          </StackPanel>
        </Border>
      </Grid>
    </Border>

    <!-- ================= CONTENIDO ================= -->
    <Grid Grid.Column="1" Margin="34,26,34,0">
      <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="38"/></Grid.RowDefinitions>

      <!-- ===== RESUMEN ===== -->
      <Grid x:Name="PageHome">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
        <StackPanel>
          <TextBlock Text="Resumen del almacenamiento" Style="{StaticResource H1}"/>
          <TextBlock Text="Elige una unidad y pulsa «Analizar» para descubrir qué carpetas y archivos ocupan más espacio." Style="{StaticResource Hint}" Margin="0,6,0,20"/>
        </StackPanel>
        <ItemsControl x:Name="DrivesList" Grid.Row="1">
          <ItemsControl.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
          <ItemsControl.ItemTemplate>
            <DataTemplate>
              <Border Style="{StaticResource CardBorder}" Width="340" Margin="0,0,16,16">
                <StackPanel>
                  <Grid>
                    <StackPanel Orientation="Horizontal">
                      <Border Width="44" Height="44" CornerRadius="12" Background="#221F3D">
                        <TextBlock Text="&#xEDA2;" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#9C86FF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                      </Border>
                      <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
                        <TextBlock Text="{Binding Name}" FontSize="18" FontWeight="Bold"/>
                        <TextBlock Text="{Binding Label}" FontSize="12" Foreground="#8B92A6"/>
                      </StackPanel>
                    </StackPanel>
                    <Button Style="{StaticResource BtnPrimary}" Tag="{Binding Root}" HorizontalAlignment="Right" VerticalAlignment="Center" Padding="14,8">
                      <StackPanel Orientation="Horizontal">
                        <TextBlock Text="&#xE721;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0" IsHitTestVisible="False"/>
                        <TextBlock Text="Analizar" IsHitTestVisible="False"/>
                      </StackPanel>
                    </Button>
                  </Grid>
                  <TextBlock Text="{Binding UsedText}" FontSize="22" FontWeight="SemiBold" Margin="0,18,0,10"/>
                  <ProgressBar Value="{Binding UsedPct, Mode=OneWay}" Maximum="100" Height="10"/>
                  <TextBlock Text="{Binding FreeText}" FontSize="12" Foreground="#8B92A6" Margin="0,8,0,0"/>
                </StackPanel>
              </Border>
            </DataTemplate>
          </ItemsControl.ItemTemplate>
        </ItemsControl>
        <Grid Grid.Row="2" Margin="0,4,0,12">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border Style="{StaticResource CardBorder}">
            <Grid>
              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
              <Grid Margin="0,0,0,10">
                <StackPanel>
                  <TextBlock Text="Programas que más ocupan" FontSize="16" FontWeight="Bold"/>
                  <TextBlock x:Name="HomeProgHint" Text="Calculando tamaños reales…" FontSize="12" Foreground="#8B92A6" Margin="0,3,0,0"/>
                </StackPanel>
                <Button x:Name="BtnGoProgs" Style="{StaticResource BtnSmall}" Content="Ver todos" HorizontalAlignment="Right" VerticalAlignment="Top"/>
              </Grid>
              <ListBox x:Name="TopProgsList" Grid.Row="1" Style="{StaticResource List}">
                <ListBox.ItemTemplate>
                  <DataTemplate>
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                      <Border Width="30" Height="30" CornerRadius="8" Background="{StaticResource Accent}" HorizontalAlignment="Left">
                        <TextBlock Text="{Binding Initial}" Foreground="White" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="0,0,12,0">
                        <TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                        <ProgressBar Value="{Binding Percent, Mode=OneWay}" Maximum="100" Height="5" Margin="0,6,0,0"/>
                      </StackPanel>
                      <TextBlock Grid.Column="2" Text="{Binding SizeText}" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </Grid>
                  </DataTemplate>
                </ListBox.ItemTemplate>
              </ListBox>
            </Grid>
          </Border>
          <Border Grid.Column="2" Style="{StaticResource CardBorder}">
            <Grid>
              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
              <StackPanel Margin="0,0,0,10">
                <TextBlock Text="Archivos más grandes" FontSize="16" FontWeight="Bold"/>
                <TextBlock x:Name="HomeFilesHint" Text="Analiza una unidad para ver los archivos gigantes (+200 MB). Doble clic abre su ubicación." FontSize="12" Foreground="#8B92A6" Margin="0,3,0,0" TextWrapping="Wrap"/>
              </StackPanel>
              <ListBox x:Name="TopFilesList" Grid.Row="1" Style="{StaticResource List}">
                <ListBox.ItemTemplate>
                  <DataTemplate>
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="34"/><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                      <TextBlock Text="&#xE8A5;" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#00C2FF" VerticalAlignment="Center"/>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="0,0,12,0">
                        <TextBlock Text="{Binding Name}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                        <TextBlock Text="{Binding Detail}" FontSize="11" Foreground="#8B92A6" TextTrimming="CharacterEllipsis"/>
                      </StackPanel>
                      <TextBlock Grid.Column="2" Text="{Binding SizeText}" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </Grid>
                  </DataTemplate>
                </ListBox.ItemTemplate>
              </ListBox>
            </Grid>
          </Border>
        </Grid>
      </Grid>

      <!-- ===== PROGRAMAS ===== -->
      <Grid x:Name="PageProgs" Visibility="Collapsed">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid>
          <StackPanel>
            <TextBlock Text="Programas instalados" Style="{StaticResource H1}"/>
            <TextBlock x:Name="ProgSummary" Text="Cargando…" Style="{StaticResource Hint}" Margin="0,6,0,0"/>
          </StackPanel>
          <Button x:Name="BtnRefreshProgs" Style="{StaticResource Btn}" HorizontalAlignment="Right" VerticalAlignment="Top">
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="&#xE72C;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
              <TextBlock Text="Actualizar"/>
            </StackPanel>
          </Button>
        </Grid>
        <Grid Grid.Row="1" Margin="0,18,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="360"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <TextBox x:Name="SearchBox" Style="{StaticResource Search}"/>
          <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
            <TextBlock Text="Ordenar:" Foreground="#8B92A6" VerticalAlignment="Center" Margin="0,0,8,0" FontSize="12"/>
            <Border Background="#171B24" CornerRadius="9" Padding="3" BorderBrush="#2A3142" BorderThickness="1">
              <StackPanel Orientation="Horizontal">
                <RadioButton x:Name="SortSize" Style="{StaticResource SortBtn}" Content="Tamaño" IsChecked="True" GroupName="sort"/>
                <RadioButton x:Name="SortName" Style="{StaticResource SortBtn}" Content="Nombre" GroupName="sort"/>
                <RadioButton x:Name="SortDate" Style="{StaticResource SortBtn}" Content="Más recientes" GroupName="sort"/>
              </StackPanel>
            </Border>
          </StackPanel>
        </Grid>
        <Grid Grid.Row="2" Margin="13,4,23,6">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="46"/><ColumnDefinition Width="*"/><ColumnDefinition Width="190"/><ColumnDefinition Width="90"/><ColumnDefinition Width="96"/>
          </Grid.ColumnDefinitions>
          <TextBlock Grid.Column="1" Text="PROGRAMA" FontSize="11" FontWeight="SemiBold" Foreground="#5D6478"/>
          <TextBlock Grid.Column="2" Text="PROPORCIÓN" FontSize="11" FontWeight="SemiBold" Foreground="#5D6478"/>
          <TextBlock Grid.Column="3" Text="TAMAÑO" FontSize="11" FontWeight="SemiBold" Foreground="#5D6478" HorizontalAlignment="Right"/>
          <TextBlock Grid.Column="4" Text="INSTALADO" FontSize="11" FontWeight="SemiBold" Foreground="#5D6478" HorizontalAlignment="Right"/>
        </Grid>
        <Border Grid.Row="3" Style="{StaticResource CardBorder}" Padding="8">
          <ListBox x:Name="ProgramsList" Style="{StaticResource List}">
            <ListBox.ItemTemplate>
              <DataTemplate>
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="46"/><ColumnDefinition Width="*"/><ColumnDefinition Width="190"/><ColumnDefinition Width="90"/><ColumnDefinition Width="96"/>
                  </Grid.ColumnDefinitions>
                  <Border Width="36" Height="36" CornerRadius="10" Background="{StaticResource Accent}" HorizontalAlignment="Left">
                    <TextBlock Text="{Binding Initial}" Foreground="White" FontWeight="Bold" FontSize="15" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                  </Border>
                  <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="0,0,16,0">
                    <TextBlock Text="{Binding Name}" FontSize="14" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                    <TextBlock Text="{Binding SubLine}" FontSize="11.5" Foreground="#8B92A6" TextTrimming="CharacterEllipsis" Margin="0,2,0,0"/>
                  </StackPanel>
                  <ProgressBar Grid.Column="2" Value="{Binding Percent, Mode=OneWay}" Maximum="100" VerticalAlignment="Center" Margin="0,0,16,0"/>
                  <TextBlock Grid.Column="3" Text="{Binding SizeText}" FontSize="13.5" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                  <TextBlock Grid.Column="4" Text="{Binding InstallDateText}" FontSize="12" Foreground="#8B92A6" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
              </DataTemplate>
            </ListBox.ItemTemplate>
          </ListBox>
        </Border>
        <Border Grid.Row="4" Style="{StaticResource CardBorder}" Margin="0,12,0,8" Padding="16,12">
          <Grid>
            <StackPanel VerticalAlignment="Center">
              <TextBlock x:Name="SelProgName" Text="Selecciona un programa de la lista" FontWeight="SemiBold" FontSize="14" TextTrimming="CharacterEllipsis"/>
              <TextBlock x:Name="SelProgInfo" Text="La desinstalación a fondo ejecuta el desinstalador oficial y luego borra carpetas, restos, servicios y registro." FontSize="12" Foreground="#8B92A6" TextTrimming="CharacterEllipsis" Margin="0,2,420,0"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Button x:Name="BtnOpenProgDir" Style="{StaticResource Btn}" Margin="0,0,10,0" IsEnabled="False">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE838;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Abrir ubicación"/>
                </StackPanel>
              </Button>
              <Button x:Name="BtnUninstall" Style="{StaticResource BtnDanger}" IsEnabled="False">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Desinstalar a fondo"/>
                </StackPanel>
              </Button>
            </StackPanel>
          </Grid>
        </Border>
      </Grid>

      <!-- ===== EXPLORAR DISCO ===== -->
      <Grid x:Name="PageFolders" Visibility="Collapsed">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid>
          <StackPanel>
            <TextBlock Text="Explorar disco" Style="{StaticResource H1}"/>
            <TextBlock Text="Las carpetas se ordenan de mayor a menor. Doble clic para entrar en una carpeta." Style="{StaticResource Hint}" Margin="0,6,0,0"/>
          </StackPanel>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top">
            <TextBlock Text="Analizar:" Foreground="#8B92A6" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <ItemsControl x:Name="DriveButtons">
              <ItemsControl.ItemsPanel><ItemsPanelTemplate><StackPanel Orientation="Horizontal"/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
              <ItemsControl.ItemTemplate>
                <DataTemplate>
                  <Button Style="{StaticResource Btn}" Tag="{Binding Root}" Margin="0,0,8,0" Padding="14,8">
                    <StackPanel Orientation="Horizontal" IsHitTestVisible="False">
                      <TextBlock Text="&#xEDA2;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                      <TextBlock Text="{Binding Name}"/>
                    </StackPanel>
                  </Button>
                </DataTemplate>
              </ItemsControl.ItemTemplate>
            </ItemsControl>
          </StackPanel>
        </Grid>

        <Border x:Name="ScanPanel" Grid.Row="1" Style="{StaticResource CardBorder}" Margin="0,18,0,0" Visibility="Collapsed">
          <StackPanel>
            <Grid>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="&#xE895;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="#9C86FF" RenderTransformOrigin="0.5,0.5" VerticalAlignment="Center">
                  <TextBlock.RenderTransform><RotateTransform/></TextBlock.RenderTransform>
                  <TextBlock.Triggers>
                    <EventTrigger RoutedEvent="Loaded">
                      <BeginStoryboard>
                        <Storyboard RepeatBehavior="Forever">
                          <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(RotateTransform.Angle)" From="0" To="360" Duration="0:0:1.2"/>
                        </Storyboard>
                      </BeginStoryboard>
                    </EventTrigger>
                  </TextBlock.Triggers>
                </TextBlock>
                <TextBlock x:Name="ScanTitle" Text="Analizando…" FontWeight="SemiBold" FontSize="14" Margin="12,0,0,0" VerticalAlignment="Center"/>
              </StackPanel>
              <Button x:Name="BtnCancelScan" Style="{StaticResource BtnSmall}" Content="Cancelar" HorizontalAlignment="Right"/>
            </Grid>
            <ProgressBar x:Name="ScanBar" Maximum="100" Height="8" Margin="0,14,0,8"/>
            <TextBlock x:Name="ScanText" FontSize="12" Foreground="#C8CCD8"/>
            <TextBlock x:Name="ScanCurrent" FontSize="11" Foreground="#5D6478" TextTrimming="CharacterEllipsis" Margin="0,2,0,0"/>
          </StackPanel>
        </Border>

        <Grid Grid.Row="2" Margin="0,18,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
          <Button x:Name="BtnUp" Style="{StaticResource Btn}" Padding="11,9" IsEnabled="False" ToolTip="Subir un nivel">
            <TextBlock Text="&#xE74A;" FontFamily="Segoe MDL2 Assets"/>
          </Button>
          <StackPanel Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
            <TextBlock x:Name="PathText" Text="Ninguna unidad analizada todavía" FontSize="15" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
            <TextBlock x:Name="PathInfo" Text="Pulsa una unidad arriba a la derecha para empezar." FontSize="12" Foreground="#8B92A6"/>
          </StackPanel>
        </Grid>

        <Border Grid.Row="3" Style="{StaticResource CardBorder}" Padding="8">
          <Grid>
            <ListBox x:Name="FolderList" Style="{StaticResource List}">
              <ListBox.ItemTemplate>
                <DataTemplate>
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="40"/><ColumnDefinition Width="*"/><ColumnDefinition Width="230"/><ColumnDefinition Width="90"/><ColumnDefinition Width="64"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="{Binding Icon}" FontFamily="Segoe MDL2 Assets" FontSize="20" VerticalAlignment="Center">
                      <TextBlock.Style>
                        <Style TargetType="TextBlock">
                          <Setter Property="Foreground" Value="#F5B83D"/>
                          <Style.Triggers>
                            <DataTrigger Binding="{Binding Kind}" Value="file"><Setter Property="Foreground" Value="#00C2FF"/></DataTrigger>
                            <DataTrigger Binding="{Binding Kind}" Value="small"><Setter Property="Foreground" Value="#8B92A6"/></DataTrigger>
                          </Style.Triggers>
                        </Style>
                      </TextBlock.Style>
                    </TextBlock>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="0,0,16,0">
                      <TextBlock Text="{Binding Name}" FontSize="14" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                      <TextBlock Text="{Binding Detail}" FontSize="11.5" Foreground="#8B92A6" TextTrimming="CharacterEllipsis" Margin="0,2,0,0"/>
                    </StackPanel>
                    <ProgressBar Grid.Column="2" Value="{Binding Percent, Mode=OneWay}" Maximum="100" VerticalAlignment="Center" Margin="0,0,16,0"/>
                    <TextBlock Grid.Column="3" Text="{Binding SizeText}" FontSize="13.5" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    <TextBlock Grid.Column="4" Text="{Binding PercentText}" FontSize="12" Foreground="#8B92A6" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                  </Grid>
                </DataTemplate>
              </ListBox.ItemTemplate>
            </ListBox>
            <StackPanel x:Name="FolderEmpty" VerticalAlignment="Center" HorizontalAlignment="Center">
              <TextBlock Text="&#xEDA2;" FontFamily="Segoe MDL2 Assets" FontSize="46" Foreground="#2E3548" HorizontalAlignment="Center"/>
              <TextBlock Text="Analiza una unidad para ver qué ocupa el espacio" Foreground="#5D6478" FontSize="14" Margin="0,14,0,0" HorizontalAlignment="Center"/>
            </StackPanel>
          </Grid>
        </Border>

        <Border Grid.Row="4" Style="{StaticResource CardBorder}" Margin="0,12,0,8" Padding="16,12">
          <Grid>
            <TextBlock x:Name="FolderNote" Text="Consejo: «Eliminar» borra de forma permanente (sin papelera). Windows, Archivos de programa y las carpetas de usuario están protegidas."
                       FontSize="12" Foreground="#8B92A6" TextWrapping="Wrap" VerticalAlignment="Center" Margin="0,0,330,0"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Button x:Name="BtnOpenFolder" Style="{StaticResource Btn}" Margin="0,0,10,0">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE838;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Abrir en Explorador"/>
                </StackPanel>
              </Button>
              <Button x:Name="BtnDeleteItem" Style="{StaticResource BtnDanger}">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Eliminar"/>
                </StackPanel>
              </Button>
            </StackPanel>
          </Grid>
        </Border>
      </Grid>

      <!-- ===== LIMPIEZA ===== -->
      <Grid x:Name="PageClean" Visibility="Collapsed">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Margin="0,0,0,18">
          <TextBlock Text="Limpieza rápida" Style="{StaticResource H1}"/>
          <TextBlock Text="Basura del sistema que se puede borrar sin riesgo. Marca lo que quieras eliminar." Style="{StaticResource Hint}" Margin="0,6,0,0"/>
        </StackPanel>
        <Border Grid.Row="1" Style="{StaticResource CardBorder}" Padding="8">
          <ListBox x:Name="CleanList" Style="{StaticResource List}">
            <ListBox.ItemTemplate>
              <DataTemplate>
                <Grid>
                  <Grid.ColumnDefinitions><ColumnDefinition Width="36"/><ColumnDefinition Width="44"/><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
                  <CheckBox IsChecked="{Binding Checked, Mode=TwoWay}" VerticalAlignment="Center"/>
                  <Border Grid.Column="1" Width="34" Height="34" CornerRadius="9" Background="#1F2638" HorizontalAlignment="Left">
                    <TextBlock Text="{Binding Icon}" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#9C86FF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                  </Border>
                  <StackPanel Grid.Column="2" VerticalAlignment="Center">
                    <TextBlock Text="{Binding Name}" FontSize="14" FontWeight="SemiBold"/>
                    <TextBlock Text="{Binding Desc}" FontSize="11.5" Foreground="#8B92A6" TextTrimming="CharacterEllipsis"/>
                  </StackPanel>
                  <TextBlock Grid.Column="3" Text="{Binding SizeText}" FontSize="14" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
              </DataTemplate>
            </ListBox.ItemTemplate>
          </ListBox>
        </Border>
        <Border Grid.Row="2" Style="{StaticResource CardBorder}" Margin="0,12,0,8" Padding="16,12">
          <Grid>
            <StackPanel VerticalAlignment="Center">
              <TextBlock x:Name="CleanTotal" Text="Midiendo…" FontSize="15" FontWeight="SemiBold"/>
              <TextBlock x:Name="CleanInfo" Text="Los archivos en uso se omiten automáticamente." FontSize="12" Foreground="#8B92A6"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Button x:Name="BtnRemeasure" Style="{StaticResource Btn}" Margin="0,0,10,0">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE72C;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Volver a medir"/>
                </StackPanel>
              </Button>
              <Button x:Name="BtnClean" Style="{StaticResource BtnPrimary}">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xEA99;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Limpiar seleccionados"/>
                </StackPanel>
              </Button>
            </StackPanel>
          </Grid>
        </Border>
      </Grid>

      <!-- Barra de estado -->
      <TextBlock x:Name="StatusText" Grid.Row="1" Text="Listo." FontSize="12" Foreground="#6B7286" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
    </Grid>

    <!-- ================= OVERLAY DESINSTALACIÓN ================= -->
    <Grid x:Name="Overlay" Grid.ColumnSpan="2" Background="#D0080A0F" Visibility="Collapsed">
      <Border Background="#151922" BorderBrush="#2A3142" BorderThickness="1" CornerRadius="18" Width="820" Height="620" Padding="28">
        <Grid>
          <!-- Confirmación -->
          <Grid x:Name="ConfirmPanel">
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <StackPanel Orientation="Horizontal">
              <Border Width="46" Height="46" CornerRadius="12" Background="{StaticResource DangerGrad}">
                <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
              <StackPanel Margin="14,0,0,0" VerticalAlignment="Center">
                <TextBlock x:Name="OvTitle" Text="Desinstalar a fondo" FontSize="20" FontWeight="Bold" Foreground="White"/>
                <TextBlock x:Name="OvSub" Text="" FontSize="12" Foreground="#8B92A6"/>
              </StackPanel>
            </StackPanel>
            <StackPanel Grid.Row="1" Margin="0,20,0,0">
              <CheckBox x:Name="OptRunOfficial" IsChecked="True" Content="Ejecutar primero el desinstalador oficial del programa (recomendado)" Margin="0,0,0,10"/>
              <CheckBox x:Name="OptSilent" IsChecked="True" Content="Modo silencioso: no mostrar ventanas del desinstalador (cuando el programa lo admite)"/>
            </StackPanel>
            <StackPanel Grid.Row="2" Margin="0,22,0,8">
              <TextBlock Text="Se eliminará todo lo marcado:" FontWeight="SemiBold" FontSize="14"/>
              <TextBlock x:Name="LeftLoading" Text="Buscando carpetas residuales, accesos directos, servicios y entradas de registro…" FontSize="12" Foreground="#8B92A6" Margin="0,4,0,0"/>
            </StackPanel>
            <Border Grid.Row="3" Background="#11141B" CornerRadius="12" Padding="6" BorderBrush="#232938" BorderThickness="1">
              <ListBox x:Name="LeftList" Style="{StaticResource List}">
                <ListBox.ItemTemplate>
                  <DataTemplate>
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="32"/><ColumnDefinition Width="30"/><ColumnDefinition Width="*"/><ColumnDefinition Width="86"/></Grid.ColumnDefinitions>
                      <CheckBox IsChecked="{Binding Checked, Mode=TwoWay}" VerticalAlignment="Center"/>
                      <TextBlock Grid.Column="1" Text="{Binding Icon}" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#9C86FF" VerticalAlignment="Center"/>
                      <StackPanel Grid.Column="2" VerticalAlignment="Center">
                        <TextBlock Text="{Binding Path}" FontSize="12.5" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" ToolTip="{Binding Path}"/>
                        <TextBlock Text="{Binding Kind}" FontSize="11" Foreground="#8B92A6"/>
                        <TextBlock Text="{Binding Warning}" FontSize="11" Foreground="#FFB547" TextWrapping="Wrap"/>
                      </StackPanel>
                      <TextBlock Grid.Column="3" Text="{Binding SizeText}" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </Grid>
                  </DataTemplate>
                </ListBox.ItemTemplate>
              </ListBox>
            </Border>
            <Grid Grid.Row="4" Margin="0,18,0,0">
              <TextBlock Text="Se borra directamente, sin papelera. No se puede deshacer." Foreground="#FF7A8F" FontSize="12" VerticalAlignment="Center"/>
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="BtnCancelUninstall" Style="{StaticResource Btn}" Content="Cancelar" Margin="0,0,10,0"/>
                <Button x:Name="BtnDoUninstall" Style="{StaticResource BtnDanger}" IsEnabled="False">
                  <StackPanel Orientation="Horizontal">
                    <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                    <TextBlock Text="Desinstalar y borrar todo"/>
                  </StackPanel>
                </Button>
              </StackPanel>
            </Grid>
          </Grid>

          <!-- Progreso -->
          <Grid x:Name="ProgressPanel" Visibility="Collapsed">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <StackPanel Orientation="Horizontal">
              <Border Width="46" Height="46" CornerRadius="12" Background="{StaticResource Accent}">
                <TextBlock x:Name="ProgGlyph" Text="&#xE895;" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center" RenderTransformOrigin="0.5,0.5">
                  <TextBlock.RenderTransform><RotateTransform/></TextBlock.RenderTransform>
                  <TextBlock.Triggers>
                    <EventTrigger RoutedEvent="Loaded">
                      <BeginStoryboard>
                        <Storyboard RepeatBehavior="Forever">
                          <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(RotateTransform.Angle)" From="0" To="360" Duration="0:0:1.2"/>
                        </Storyboard>
                      </BeginStoryboard>
                    </EventTrigger>
                  </TextBlock.Triggers>
                </TextBlock>
              </Border>
              <StackPanel Margin="14,0,0,0" VerticalAlignment="Center">
                <TextBlock x:Name="ProgTitle" Text="Desinstalando…" FontSize="20" FontWeight="Bold" Foreground="White"/>
                <TextBlock x:Name="ProgSub" Text="No cierres la aplicación. Si aparece la ventana del desinstalador, complétala." FontSize="12" Foreground="#8B92A6"/>
              </StackPanel>
            </StackPanel>
            <Border Grid.Row="1" Background="#0C0E13" CornerRadius="12" Margin="0,20,0,0" BorderBrush="#232938" BorderThickness="1">
              <TextBox x:Name="LogBox" Background="Transparent" BorderThickness="0" Foreground="#B9F5D8" FontFamily="Cascadia Mono, Consolas"
                       FontSize="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Padding="14"/>
            </Border>
            <Grid Grid.Row="2" Margin="0,18,0,0">
              <TextBlock x:Name="ProgFreed" Text="" FontSize="15" FontWeight="SemiBold" Foreground="#2ED39A" VerticalAlignment="Center"/>
              <Button x:Name="BtnCloseOverlay" Style="{StaticResource BtnPrimary}" Content="Cerrar" HorizontalAlignment="Right" IsEnabled="False" Padding="26,9"/>
            </Grid>
          </Grid>
        </Grid>
      </Border>
    </Grid>
  </Grid>
</Window>
'@

$window = [Windows.Markup.XamlReader]::Parse($xaml)
foreach ($m in [regex]::Matches($xaml, 'x:Name="([A-Z]\w+)"')) {
    $n = $m.Groups[1].Value
    $el = $window.FindName($n)
    if ($el) { Set-Variable -Name $n -Value $el -Scope Script }
}

# =====================================================================
#  Lógica
# =====================================================================
$script:Programs = $null
$script:SortMode = 'size'
$script:ScanTask = $null; $script:SizeTask = $null; $script:LeftTask = $null
$script:JobTask = $null; $script:MeasureTask = $null; $script:CleanTask = $null; $script:DelTask = $null
$script:CurNode = $null; $script:ScanRoot = $null; $script:ScanDrive = $null
$script:CleanLoaded = $false

function Set-Status([string]$msg) { $StatusText.Text = $msg }

function Show-Page([string]$name) {
    foreach ($p in 'PageHome', 'PageProgs', 'PageFolders', 'PageClean') {
        $el = Get-Variable -Name $p -ValueOnly -Scope Script
        if ($p -eq $name) { $el.Visibility = 'Visible' } else { $el.Visibility = 'Collapsed' }
    }
    if ($name -eq 'PageClean' -and -not $script:CleanLoaded) { Load-Clean }
}

# ---------- Unidades ----------
function Load-Drives {
    $script:Drives = [DiskPilot.DriveCard]::GetAll()
    $DrivesList.ItemsSource = $null; $DrivesList.ItemsSource = $script:Drives
    $DriveButtons.ItemsSource = $null; $DriveButtons.ItemsSource = $script:Drives
}

# ---------- Programas ----------
function Load-Programs {
    $script:Programs = [DiskPilot.Programs]::Load()
    Update-ProgView
    $ProgSummary.Text = "{0} programas encontrados · calculando el tamaño real de cada carpeta…" -f $script:Programs.Count
    $HomeProgHint.Text = 'Calculando tamaños reales…'
    $script:SizeTask = [DiskPilot.Programs]::SizeAsync($script:Programs)
}

function Update-ProgView {
    if (-not $script:Programs) { return }
    $q = $SearchBox.Text.Trim()
    $items = @($script:Programs)
    if ($q) {
        $items = @($items | Where-Object {
            ($_.Name -and $_.Name.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -ge 0) -or
            ($_.Publisher -and $_.Publisher.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -ge 0) })
    }
    switch ($script:SortMode) {
        'size' { $items = @($items | Sort-Object -Property @{Expression = { $_.Size }; Descending = $true }, Name) }
        'name' { $items = @($items | Sort-Object -Property Name) }
        'date' { $items = @($items | Sort-Object -Property InstallDate -Descending) }
    }
    $sel = $ProgramsList.SelectedItem
    $ProgramsList.ItemsSource = $items
    if ($sel -and $items -contains $sel) { $ProgramsList.SelectedItem = $sel }
}

function Finish-Sizing {
    $max = 1L; $total = 0L
    foreach ($p in $script:Programs) { if ($p.Size -gt $max) { $max = $p.Size }; if ($p.Size -gt 0) { $total += $p.Size } }
    foreach ($p in $script:Programs) { $p.Percent = [Math]::Max([long]0, [long]$p.Size) * 100.0 / $max }
    $ProgSummary.Text = "{0} programas · {1} en total entre todos" -f $script:Programs.Count, [DiskPilot.Fmt]::Size($total)
    $top = @($script:Programs | Sort-Object -Property @{Expression = { $_.Size }; Descending = $true } | Select-Object -First 12)
    $TopProgsList.ItemsSource = $top
    $HomeProgHint.Text = "Suman {0} en total. Selecciona uno en «Programas» para desinstalarlo." -f [DiskPilot.Fmt]::Size($total)
    Update-ProgView
}

# ---------- Escaneo de carpetas ----------
function Start-Scan([string]$root) {
    if ($script:ScanTask -and -not $script:ScanTask.IsCompleted) { Set-Status 'Ya hay un análisis en curso.'; return }
    $NavFolders.IsChecked = $true
    $script:ScanDrive = $script:Drives | Where-Object { $_.Root -eq $root } | Select-Object -First 1
    $ScanPanel.Visibility = 'Visible'; $ScanBar.Value = 0
    $ScanTitle.Text = "Analizando $root …"
    $FolderList.ItemsSource = $null; $FolderEmpty.Visibility = 'Collapsed'
    $PathText.Text = $root; $PathInfo.Text = 'Leyendo el sistema de archivos…'
    $BtnUp.IsEnabled = $false
    $script:ScanStart = Get-Date
    $script:ScanTask = [DiskPilot.Scanner]::ScanAsync($root)
}

function Show-Node($node) {
    $script:CurNode = $node
    $items = [DiskPilot.Scanner]::GetItems($node)
    $FolderList.ItemsSource = $items
    $FolderEmpty.Visibility = 'Collapsed'
    $PathText.Text = $node.Path
    $info = "{0} en {1:N0} archivos" -f [DiskPilot.Fmt]::Size($node.Size), $node.Files
    if (-not $node.Parent -and $script:ScanDrive) {
        $hidden = $script:ScanDrive.Used - $node.Size
        if ($hidden -gt 2GB) {
            $info += "   ·   ≈ {0} usados que no aparecen en carpetas (puntos de restauración, instantáneas del sistema, archivos protegidos)" -f [DiskPilot.Fmt]::Size($hidden)
        }
    }
    $PathInfo.Text = $info
    $BtnUp.IsEnabled = [bool]$node.Parent
}

# ---------- Limpieza ----------
function Load-Clean {
    $script:CleanLoaded = $true
    $script:CleanItems = [DiskPilot.Cleaner]::Targets()
    $CleanList.ItemsSource = $script:CleanItems
    $CleanTotal.Text = 'Midiendo…'
    $script:MeasureTask = [DiskPilot.Cleaner]::MeasureAsync($script:CleanItems)
}
function Update-CleanTotal {
    $t = 0L
    foreach ($c in $script:CleanItems) { if ($c.Checked -and $c.Size -gt 0) { $t += $c.Size } }
    $CleanTotal.Text = "Seleccionado para liberar: {0}" -f [DiskPilot.Fmt]::Size($t)
}

# ---------- Desinstalación ----------
function Begin-Uninstall {
    $p = $ProgramsList.SelectedItem
    if (-not $p) { Set-Status 'Selecciona primero un programa de la lista.'; return }
    if ($script:JobTask -and -not $script:JobTask.IsCompleted) { return }
    $script:UninstProg = $p
    $OvTitle.Text = "Desinstalar a fondo: " + $p.Name
    $sz = if ($p.Size -ge 0) { [DiskPilot.Fmt]::Size($p.Size) } else { 'tamaño desconocido' }
    $OvSub.Text = "{0}   ·   {1}" -f $(if ($p.Publisher) { $p.Publisher } else { 'Editor desconocido' }), $sz
    $hasCmd = [bool]($p.UninstallString -or $p.QuietUninstallString)
    $OptRunOfficial.IsChecked = $hasCmd; $OptRunOfficial.IsEnabled = $hasCmd
    $OptSilent.IsChecked = $true
    $LeftList.ItemsSource = $null
    $LeftLoading.Text = 'Buscando carpetas residuales, accesos directos, servicios y entradas de registro…'
    $BtnDoUninstall.IsEnabled = $false
    $ConfirmPanel.Visibility = 'Visible'; $ProgressPanel.Visibility = 'Collapsed'; $Overlay.Visibility = 'Visible'
    $script:LeftTask = [DiskPilot.Leftovers]::FindAsync($p, $script:Programs)
}

function Run-Uninstall {
    $p = $script:UninstProg
    $job = New-Object DiskPilot.UninstallJob
    $job.Name = $p.Name
    if ($OptRunOfficial.IsChecked) {
        $exe = $null; $arg = $null
        if ([DiskPilot.Uninstaller]::BuildCommand($p, [bool]$OptSilent.IsChecked, [ref]$exe, [ref]$arg)) { $job.Exe = $exe; $job.Args = $arg }
    }
    $n = 0
    foreach ($i in @($LeftList.ItemsSource)) { if ($i.Checked) { $job.Items.Add($i); $n++ } }
    if (-not $job.Exe -and $n -eq 0) { Set-Status 'No hay nada marcado para eliminar.'; return }
    $LogBox.Text = ''; $ProgFreed.Text = ''
    $ProgTitle.Text = "Desinstalando " + $p.Name + "…"
    $ProgSub.Text = 'No cierres la aplicación. Si aparece la ventana del desinstalador, complétala.'
    $ProgGlyph.Text = [string][char]0xE895
    $BtnCloseOverlay.IsEnabled = $false
    $ConfirmPanel.Visibility = 'Collapsed'; $ProgressPanel.Visibility = 'Visible'
    $script:JobTask = [DiskPilot.Uninstaller]::RunAsync($job)
}

function Flush-Log {
    $q = [DiskPilot.Uninstaller]::Log
    $line = $null; $any = $false
    while ($q.TryDequeue([ref]$line)) { $LogBox.AppendText($line + "`r`n"); $any = $true }
    if ($any) { $LogBox.ScrollToEnd() }
}

# ---------- Temporizador central (tareas en segundo plano) ----------
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(250)
$timer.Add_Tick({
    try {
        # Escaneo de disco
        if ($script:ScanTask) {
            $t = $script:ScanTask
            if ($t.IsCompleted) {
                $script:ScanTask = $null
                $ScanPanel.Visibility = 'Collapsed'
                if ($t.IsFaulted) { Set-Status ('Error al analizar: ' + $t.Exception.InnerException.Message) }
                else {
                    $script:ScanRoot = $t.Result
                    Show-Node $t.Result
                    $TopFilesList.ItemsSource = [DiskPilot.Scanner]::TopFiles(40)
                    $HomeFilesHint.Text = "Archivos de más de 200 MB en {0}. Doble clic abre su ubicación." -f $t.Result.Path
                    $secs = [int]((Get-Date) - $script:ScanStart).TotalSeconds
                    if ([DiskPilot.Scanner]::Cancel) { Set-Status 'Análisis cancelado: los datos mostrados están incompletos.' }
                    else { Set-Status ("Análisis completado en {0} s · {1:N0} archivos revisados." -f $secs, [DiskPilot.Scanner]::FilesScanned) }
                }
            }
            else {
                $done = [DiskPilot.Scanner]::BytesScanned
                $used = if ($script:ScanDrive) { $script:ScanDrive.Used } else { 0 }
                $pct = if ($used -gt 0) { [Math]::Min(99.0, $done * 100.0 / $used) } else { 0 }
                $ScanBar.Value = $pct
                $ScanText.Text = "{0:0}%   ·   {1:N0} archivos   ·   {2} revisados" -f $pct, [DiskPilot.Scanner]::FilesScanned, [DiskPilot.Fmt]::Size($done)
                $ScanCurrent.Text = [DiskPilot.Scanner]::Current
            }
        }

        # Tamaños de programas
        if ($script:SizeTask) {
            if ($script:SizeTask.IsCompleted) { $script:SizeTask = $null; Finish-Sizing; Set-Status 'Tamaños de programas calculados.' }
            else { $ProgSummary.Text = "{0} programas · calculando tamaño real de las carpetas… {1}/{0}" -f $script:Programs.Count, [DiskPilot.Programs]::Sized }
        }

        # Búsqueda de restos
        if ($script:LeftTask -and $script:LeftTask.IsCompleted) {
            $t = $script:LeftTask; $script:LeftTask = $null
            if ($t.IsFaulted) { $LeftLoading.Text = 'Error buscando restos: ' + $t.Exception.InnerException.Message }
            else {
                $LeftList.ItemsSource = $t.Result
                $LeftLoading.Text = "{0} elementos encontrados. Desmarca lo que quieras conservar." -f $t.Result.Count
            }
            $BtnDoUninstall.IsEnabled = $true
        }

        # Trabajo de desinstalación
        if ($script:JobTask) {
            Flush-Log
            if ($script:JobTask.IsCompleted) {
                $script:JobTask = $null
                Flush-Log
                $ProgTitle.Text = 'Desinstalación completada'
                $ProgSub.Text = 'Puedes cerrar esta ventana.'
                $ProgGlyph.Text = [string][char]0xE73E
                $ProgFreed.Text = "Espacio liberado: " + [DiskPilot.Fmt]::Size([DiskPilot.Uninstaller]::Freed)
                $BtnCloseOverlay.IsEnabled = $true
            }
        }

        # Limpieza: medición
        if ($script:MeasureTask -and $script:MeasureTask.IsCompleted) { $script:MeasureTask = $null; Update-CleanTotal }
        if ($script:CleanTask -and $script:CleanTask.IsCompleted) {
            $t = $script:CleanTask; $script:CleanTask = $null
            $BtnClean.IsEnabled = $true
            $freed = if ($t.IsFaulted) { 0 } else { $t.Result }
            $CleanInfo.Text = "Última limpieza: se liberaron {0}." -f [DiskPilot.Fmt]::Size($freed)
            Set-Status ("Limpieza terminada: {0} liberados." -f [DiskPilot.Fmt]::Size($freed))
            Update-CleanTotal; Load-Drives
        }

        # Borrado desde el explorador
        if ($script:DelTask -and $script:DelTask.IsCompleted) {
            $t = $script:DelTask; $script:DelTask = $null
            $BtnDeleteItem.IsEnabled = $true
            $it = $script:DelItem
            if (-not $t.IsFaulted -and $t.Result) {
                [DiskPilot.Scanner]::Remove($it)
                Set-Status ("Eliminado: {0} ({1} liberados)" -f $it.FullPath, $it.SizeText)
            }
            else { Set-Status ("No se pudo borrar todo en {0}: algunos archivos están en uso y se eliminarán al reiniciar." -f $it.FullPath) }
            if ($script:CurNode) { Show-Node $script:CurNode }
            Load-Drives
        }
    }
    catch { Set-Status ('Error: ' + $_.Exception.Message) }
})

# ---------- Eventos ----------
$NavHome.Add_Checked({ Show-Page 'PageHome' })
$NavProgs.Add_Checked({ Show-Page 'PageProgs' })
$NavFolders.Add_Checked({ Show-Page 'PageFolders' })
$NavClean.Add_Checked({ Show-Page 'PageClean' })
$BtnGoProgs.Add_Click({ $NavProgs.IsChecked = $true })

$driveClick = [System.Windows.RoutedEventHandler] {
    param($s, $e)
    $b = $e.OriginalSource
    if ($b -is [System.Windows.Controls.Button] -and $b.Tag) { Start-Scan ([string]$b.Tag) }
}
$DrivesList.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, $driveClick)
$DriveButtons.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, $driveClick)

$BtnCancelScan.Add_Click({ [DiskPilot.Scanner]::Cancel = $true })
$BtnUp.Add_Click({ if ($script:CurNode -and $script:CurNode.Parent) { Show-Node $script:CurNode.Parent } })
$FolderList.Add_MouseDoubleClick({
    $it = $FolderList.SelectedItem
    if ($it -and $it.Kind -eq 'dir' -and $it.Node) { Show-Node $it.Node }
})
$FolderList.Add_KeyDown({
    param($s, $e)
    if ($e.Key -eq 'Back' -and $script:CurNode -and $script:CurNode.Parent) { Show-Node $script:CurNode.Parent }
    if ($e.Key -eq 'Enter') { $it = $FolderList.SelectedItem; if ($it -and $it.Kind -eq 'dir') { Show-Node $it.Node } }
})
$BtnOpenFolder.Add_Click({
    $it = $FolderList.SelectedItem
    if ($it -and $it.Kind -eq 'file') { Start-Process explorer.exe "/select,`"$($it.FullPath)`"" }
    elseif ($it) { Start-Process explorer.exe "`"$($it.FullPath)`"" }
    elseif ($script:CurNode) { Start-Process explorer.exe "`"$($script:CurNode.Path)`"" }
})
$BtnDeleteItem.Add_Click({
    $it = $FolderList.SelectedItem
    if (-not $it) { Set-Status 'Selecciona una carpeta o archivo.'; return }
    if ($it.Kind -eq 'small') { Set-Status 'Ese elemento agrupa archivos sueltos pequeños; elimina la carpeta completa o ábrela en el Explorador.'; return }
    if ([DiskPilot.Safety]::IsProtected($it.FullPath)) {
        [System.Windows.MessageBox]::Show("«$($it.FullPath)» es una ubicación protegida del sistema y no se puede borrar desde aquí.`n`nSi pertenece a un programa, desinstálalo desde la sección «Programas».", 'Ubicación protegida', 'OK', 'Information') | Out-Null
        return
    }
    $r = [System.Windows.MessageBox]::Show("¿Eliminar DEFINITIVAMENTE?`n`n$($it.FullPath)`n`nTamaño: $($it.SizeText)`n`nNo pasa por la papelera y no se puede deshacer.", 'Confirmar eliminación', 'YesNo', 'Warning')
    if ($r -ne 'Yes') { return }
    $script:DelItem = $it
    $BtnDeleteItem.IsEnabled = $false
    Set-Status ("Eliminando {0}…" -f $it.FullPath)
    $script:DelTask = [DiskPilot.Cleaner]::DeletePathAsync($it.FullPath)
})
$TopFilesList.Add_MouseDoubleClick({
    $it = $TopFilesList.SelectedItem
    if ($it) { Start-Process explorer.exe "/select,`"$($it.FullPath)`"" }
})

$SearchBox.Add_TextChanged({ Update-ProgView })
$SortSize.Add_Checked({ $script:SortMode = 'size'; Update-ProgView })
$SortName.Add_Checked({ $script:SortMode = 'name'; Update-ProgView })
$SortDate.Add_Checked({ $script:SortMode = 'date'; Update-ProgView })
$BtnRefreshProgs.Add_Click({ if (-not $script:SizeTask) { Load-Programs } })
$ProgramsList.Add_SelectionChanged({
    $p = $ProgramsList.SelectedItem
    if ($p) {
        $SelProgName.Text = $p.Name
        $SelProgInfo.Text = if ($p.InstallDir) { $p.InstallDir } else { 'Ubicación desconocida (se usará el desinstalador oficial y la búsqueda de restos)' }
        $BtnUninstall.IsEnabled = $true
        $BtnOpenProgDir.IsEnabled = [bool]$p.InstallDir
    }
    else { $BtnUninstall.IsEnabled = $false; $BtnOpenProgDir.IsEnabled = $false }
})
$ProgramsList.Add_MouseDoubleClick({ Begin-Uninstall })
$BtnOpenProgDir.Add_Click({ $p = $ProgramsList.SelectedItem; if ($p -and $p.InstallDir) { Start-Process explorer.exe "`"$($p.InstallDir)`"" } })
$BtnUninstall.Add_Click({ Begin-Uninstall })
$BtnCancelUninstall.Add_Click({ $Overlay.Visibility = 'Collapsed' })
$BtnDoUninstall.Add_Click({ Run-Uninstall })
$BtnCloseOverlay.Add_Click({
    $Overlay.Visibility = 'Collapsed'
    $p = $script:UninstProg
    if ($p -and -not [DiskPilot.Programs]::StillInstalled($p)) {
        [void]$script:Programs.Remove($p)
        Finish-Sizing
    }
    Load-Drives
    Set-Status ("Desinstalación de {0} finalizada." -f $p.Name)
})

$CleanList.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::CheckedEvent, [System.Windows.RoutedEventHandler] { Update-CleanTotal })
$CleanList.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::UncheckedEvent, [System.Windows.RoutedEventHandler] { Update-CleanTotal })
$BtnRemeasure.Add_Click({ Load-Clean })
$BtnClean.Add_Click({
    $sel = @($script:CleanItems | Where-Object { $_.Checked })
    if ($sel.Count -eq 0) { Set-Status 'No hay nada seleccionado.'; return }
    $names = ($sel | ForEach-Object { " • " + $_.Name + "  (" + $_.SizeText + ")" }) -join "`n"
    $r = [System.Windows.MessageBox]::Show("Se eliminará definitivamente:`n`n$names`n`n¿Continuar?", 'Confirmar limpieza', 'YesNo', 'Warning')
    if ($r -ne 'Yes') { return }
    $BtnClean.IsEnabled = $false
    $CleanInfo.Text = 'Limpiando… (los archivos en uso se omiten)'
    $script:CleanTask = [DiskPilot.Cleaner]::CleanAsync($script:CleanItems)
})

$window.Add_SourceInitialized({
    $h = (New-Object System.Windows.Interop.WindowInteropHelper($window)).Handle
    [DiskPilot.Native]::DarkTitle($h)
})
$window.Add_Closing({ [DiskPilot.Scanner]::Cancel = $true; $timer.Stop() })

# ---------- Arranque ----------
$VersionText.Text = "Control de almacenamiento · v$AppVersion"
$window.Title = "DiskPilot v$AppVersion — Almacenamiento y desinstalación a fondo"
if (-not $IsAdmin) {
    $AdminGlyph.Text = [string][char]0xE7BA; $AdminGlyph.Foreground = '#FFB547'
    $AdminText.Text = 'Sin permisos de admin'; $AdminSub.Text = 'Algunas funciones fallarán'
}
Load-Drives
Load-Programs
$timer.Start()

if ($SelfTest) {
    # Prueba sin interfaz: compila, carga programas y escanea una carpeta pequeña
    $t = [DiskPilot.Scanner]::ScanAsync($env:WINDIR + '\Web'); $t.Wait()
    "Escaneo OK: {0} en {1} archivos" -f [DiskPilot.Fmt]::Size($t.Result.Size), $t.Result.Files
    "Programas: {0}" -f $script:Programs.Count
    $script:SizeTask.Wait(); Finish-Sizing
    $script:Programs | Sort-Object Size -Descending | Select-Object -First 10 Name, SizeText, InstallDir | Format-Table -AutoSize | Out-String -Width 250
    "Protegido C:\Windows\System32: " + [DiskPilot.Safety]::IsProtected('C:\Windows\System32')
    "Protegido C:\Program Files: " + [DiskPilot.Safety]::IsProtected('C:\Program Files')
    "Protegido C:\Users: " + [DiskPilot.Safety]::IsProtected('C:\Users')
    "Protegido C:\Program Files\Foo: " + [DiskPilot.Safety]::IsProtected('C:\Program Files\Foo')
    exit
}

if ($Screenshot) {
    $script:shotTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:shotTimer.Interval = [TimeSpan]::FromSeconds(6)
    $script:shotPage = 0
    $script:shotTimer.Add_Tick({
        $page = @('Home', 'Progs')[$script:shotPage]
        $el = $window.Content
        $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap([int]$el.ActualWidth, [int]$el.ActualHeight, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
        $rtb.Render($el)
        $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))
        $fs = [IO.File]::Create(($Screenshot -replace '\.png$', "-$page.png")); $enc.Save($fs); $fs.Close()
        $script:shotPage++
        if ($script:shotPage -eq 1) { $NavProgs.IsChecked = $true; $ProgramsList.SelectedIndex = 0 }
        else { $window.Close() }
    })
    $script:shotTimer.Start()
}

[void]$window.ShowDialog()
