# =====================================================================
#  DiskPilot v1.5.0 - Analizador de disco y desinstalador a fondo para Windows
#  Requiere: Windows 10/11 con PowerShell 5.1 (incluido en Windows)
# =====================================================================
param(
    [switch]$NoElevate,
    [switch]$SelfTest,
    [string]$Screenshot,
    [string]$TestCategory
)
$ErrorActionPreference = 'Continue'
$AppVersion = '1.5.0'
# @@LOGO_BEGIN (generado por build\make-logo.ps1)
$LogoPng = 'iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAABB1SURBVHhe7Z15eBXlFcb9qyhq6U53utsd60ZdIFWpVBFxaaWtSJSsgHCTIC6VJsoSSAIJ2QmEsGUhYQlLEpKAAUGgsqTQYERIwqJEQLxKa2Ot9rx9zp07l2EgkDvzfTNzL/M+z/snAeb3zred802uuEKyPHGISIyhEZ44pLAnxFPdhHhqemoMdYwfA7CfGqt43DjFY9lPAWP8jh+vOG6C4li2B4jxOzpBcVSi4tFJip+cqPgJ9tNAJHsSMIr9DPC43yOfVfzYc4r/zH4e+JPff/yL4hEvKH6UPRn4g9+//6viR5IVP8xOUfwQ+0XgQfZLwHC/H5iieNgU6hg2hZrYQ6cihX3fNEQOnYqIgcnopX+ejpdnFPp4ohGZEEvlCbHkTYgFPHGKJ8QrVsFf7vB9AZiq+P5piodOV3xfKpu6fpdKq4bMQOS96eirf9aOUlI0IhNjqCkxBkiMBRi8C98MfOBe9gzgd+yZwJCZ1DwkjeIcNTIkjcbwxChq9YF34UuEDwxJA+5JA347kzp/m45IPQtLNTEKEUnR1JQU7QfvwrcEvi8A6YrvzqDmu9IwXM9GqpJHoVdSFJUzeBe+ffAHZyi+OwO4axY1DcpCHz0r4fJEol/SaGp24TsH/t2zOAC+EHREpKO/npkwJUbTgKQo6nThOxE+cOds4M5Z5I2YJWFKmDiaRiRFUZcL38HwZwO/yVQcMZs8eoaGxfAnRingXfghAJ+dBQzMxLN6lkHLP+y7b36IwR/k9x1ZJqYD34LPnfNDFv7AOcAdc6jrtiwDC0PfVs9d7Yc0fF8AstnUEZEX5DGyu88PF/jA7dnAbTm0Xc+4WyVG0RAXfvjAvz2HAwDcNofi9KwvqKQoZeh34YcR/Bzg1hzqHLjwEkUkLuy48MMQfq7iX+de5HzAt/CLpg4XfpjCz2OT96buFoSJ0eRx4YczfGAAO58y9ex9Soih7S78cIcP3JJPnXr2Vzwdib4u/MsBvt8FNOCcACREU5wL//KAf3MBcHM+Us4NQAzVufAvE/gFwE0F1BqAz6v/hFjqCmf4nllAQibwfB6QWgLUbwVaDgJtRwmn3lO87wChuRXYtBNYWqv4sZlhCL9Qcf9C9PMFwBOL4eEGf1IWkLkYWFQNLKs76627gTP/IgSj//6X0HaMULMVGDUrPODfOBe4Ya7/TIDn/1CHH5kMvJAD5JYCZeuASg101W8e1qM1prdOEDbtBp4pDl34/gCkKiOAcmMnJOFPzAAKKxTgWuvh72rRYxSj9/9JaHwt9ODfWAT8qohKfAGYEEsloQZ/wgw/+NpLw2/YBnz6aXDDfrDiIFS8HDrwb/CZmpQA+O7qhQb86BeB7MV+8D2Av2y9uKG/JzrpJWRXhwJ84Pp5/p3A+Hhqdjr8J5OBjGKgguf3IOCzg130idDhTsLERc6F/6t5vinA6wvAU/HkdTL8pzOA8rVAlQo+CPjrNunRWCeedpqaHQp/HnD9fEAZARwMf0q+At4IfHbdFj0W63XgKOHRXOfBPycAToM/6gUga6E5+KqdIF4bxMxzFvz+xf4AOA3+k38F5leKgV+xHvjoP9avAS6kDz8izFnrHPjnBMAp8D2pwJJV4uBX1APtbzkjACxeF6x81RnwAwFwEvwK/2JPFHz22s3yzwGCVf1u++H/coEmAHbD52Ff9Juv9aGjzgoAB7Kw3l74gQDYDZ8XfCLnfD181a3tegz26qOPCZOr7IP/ixI1ADbC562eqNX+xeCr3rlfqe45Re//i/BwkT3wAwGwE/60Auvglzec9at7gSPHCd4z9ofh2CmyBf7PtQGwA/5zs62Dv7QOmF0BvLAAGJcLjMs7v56fswpYXA/UbAP2txM+7LIuHH9vI8vh/3yhPwB2wI950fjxbk/hL6oB0kqBMdnGO3nSKoHXXleqfbJVusVa+D/TBsBK+FzVyyyRB5/f9uRi4JFpYtu4FjXKDQKvB6yEHwiA1fC5pGukqncp+KV1QOpiYESq3B6+dTuUUz0ZWr7DOvg/XaQJgFXwuZkjv1Q8/AVrgMgM6xo4H80Djp0UHwLeGg4vtgZ+IABWwudOHtHw86rOvvVWwNdW9Xa/qUdoXq/stwb+TxarAbAIPrunbVx68N3BT1tqf98+n+2LPGrmUWDUUvnwAwGwCv7zc8IPvlrVW/GqHqM5tRwh6fB/rA2AbPjcuj2vUhx8HvadAl+t6u14Q4/RuHhEGbZQLvwfL/EHwAr4US+Jg88LPrvm/O7gq1W9w++ImwpW75YL/zptAGTCZyfni4HPWz0rV/vBwGc/PFfZz4vQwU6SCj8QANnw+apWfpl5+Oxpi5wLX63qlbysR2lMH39CUuH/aKkmADLhj0wGyru5rqUHfzH4fLTLp3tOhq9W9bjAI0LFr8iDHwiATPjs57LNw2fz8W4owOeiTmatHqUxtRwlafB/WKoJgCz4fEV7zlLz8NW3XxT8JwqAvLXAmm1A3WtA7lpgbLEY+GpVT8QowEfOsuAHAiATPt/PX7LGHHw2z/0i4CeXAgePdQ/m+LuEjGrz8NkLmvQ/3Zim1MmB/4MyTQBkwY+Zbh4+OzbLPPyNu4FPPukevlZbWwgP5hmHr1b1eCFnVnX75MAPBEAWfPXLHGbhl6wzD//YieBBvHeGMLLIOHyu6B06Hvzfq9f2g3Lgf79cDYAk+Oxnc8zB5/at9DJz8PnNN6p97WQYPnv1Tv1PDF4tx0gK/EAAZMHnjzGlzD0ffDDw2ZOKjMPnOb+nw353mttgDD5X9CYs0/+04NVxUgmAaPjfCwRAEnw2f5DJDHz2mBxj8NkdAoZg7g0cVhA8fLWka7ZSeOIDkgL/exX+AMiCz59hyyo1B5/9+Gxj8MfN1z9K4ypsMAafbbZ7iP+8DPjfDQRAEnx2fqU5+OWNxuDzAU+5oCNZ1tb9xlu3T75vLgA8gsiA/91l/gDIgs8fYZy/yhz8hbXG4LPr/qZ/lMa1t11p2w4WPrvDwA5Er8eqxMP/jjYAMuDz1zdLVhuHz15QYww+H+9u3KN/jMa1t8N43z5X9cxqbLV4+N+p9AdAFnz23BXnw9a7O/iqjcDns/0VAr8OsuMAGYLP5VyzUwBLBvx+2gDIgM/f3s0sOx94MPDLGoERs4OHz0WdyWX6x2hcVduMwWef+be5APAiUAb8QABkwecPL89YdD70YOCXbQCicoOHr1b1PhDQnPHJp4Q/lRiDz7V8s8fB7/5TCYBo+N+u0gRABnz+6nZK8fngg4HPHl9kDD67TMBXwja1GId//yL9TwteR0+TFPiBAMiCz59cf6agZ/C3NJ+1Fj77pVJj8NWS7utHjL+BPH/fV2QMPrtYwDqk9ThJgf+t5WoAJMHnb+2Pz+4ePl/RPn6SLnhf/53ThMadSgAK1hiHzyXd+BLlNC9Y8dD/UrVx+NzI0dwR/N+r187DcuAHAiALPpsbOC8E/2APP9ny9ilC5SbgD1nG4Kv1fA5BexDbsdNnCDPXmYPPNrsAZNW1yIH/TW0AZMDn9i1u3+ZOXhV81UblrQ9GHIJJC43D19bzl7+q3Ly5mLa+bm7YV+E/t0b/k41p/jY58L+5wh8AWfBV5y4/G4CWQ/r/Xs/UfNA8fLWk+9h8ZVu34w3C0ZOKdx8iVP8NiFlifMGn797lOr5Z8Q7inmVy4H9DGwBZ8LmRY3Lx2bf/Um/fxZS92jx8IyVdI/CHLjH3f1XVcYqkwQ8EQCZ8Nv+aFQ7AXpM3ad86SSEBn725Vf+vN6baFnnwv75SEwBZ8NVOnsJqMV/srHrF+fDHrTB/+MPiKuAfV8qDHwiAbPhczp26BDgm4N4cf6LFyfDZ3MIlQtwIIhP+11apAZAMnx2dA5wWUBRh7e8gx8KvEtADqGrzm3LhBwIgG75azz9wWEwAWGt2OA9+RqP59i+tJtXLhf9VbQBkw+eS7goB5/Kq+EEvbXIO/JHLzLd+acXn/7Lhf7XaHwAr4HM9/4E0sd/uV0PgBPhcsROp9M3y4ffVBkA2fLWev0vQ9kgVh2DZFvvg87Av8s1n8d7fCviBAFgFn0u6j2aJHQVUvXbAevi84BOx3dOKAx1fYw38r6zWBMAK+GpJd73AZk2tOk8TJlXIhz+yAmgWuKDV6h9vK2+/FfADAbASvlrS9QqeM1XxG/T3NiB6sXj4fLzLJ3yi33pVfHQ8oto6+F9eowbAYvjswhr9f1+s+GHuaQMmrzQPn0/2NrSIn+v12nzQWvjnBMBK+GpVb4/J2kBPdeoDQtM/gPTansOf1Qjsage8AnoKe6ITZwiDl1sL/0tqAOyAr1b1TrxnzQNWxcP3ux8Q3nqXsO8IsLsd2NWmtH6xRVTwgtWH//EP/RbD/9JaNQA2weeijqdEzq4gVPTp/whpm+2BHwiAXfDVql6RQ367px2qbLYP/hcDAbARvlrVq5G0NXSydh6xF/4X1/kDYDd8tarXKPAun9N19D2yHf4XtAGwG75a1dvYrH9U4SeGP3iF/fC/UOMPgFPgq1W9ul36RxY+csKwr8L/vD4AToCvVvUqtgAfX+DCSKiKV/ur9jkLviYA1OUk+GpV7/lK5YJGqIv3+XZu9bqD/7lafwCGTaVWp8FXq3oPFQH7Tdzts1vcJ2DXIc+l4H+uhrqUAEyhJifC11b1VuwIrSmBTxy3tcOW490ewVcC0OELwP3TqcTJ8NWq3uMLgT1tJLTvTrT438YlXaurekHDrwWuraMmXwCGTqNUp8PXlnTHlgFvvu28EHAfHzdyWlnPNwq/Tx3Qp5bK1QB4QgW+tqQ7owY41Gn/iMCVvJyt1vTwCYNfB3x2PWUqAZhOI0INvrakO7oMqN8LnBB076An8n5I2NYGpGyU37otBz5wTR15fAG4Nx19QxW+vp6fsBLY+gbwzvviRwYe4je0AvHr5F7XsgI+u3c9rvMFwBeCVNoe6vD1nTzcxpW1EdhyAGh7h3yhuFQ715ku8l3JettLvi9zsCv3QOoVbTvgX7ueWgPwfQGYgZRwg6/6Yr9sIW0DkL1J3nf4HAm/Hri2gVLPCcA903Hd5QZfxrd3QwJ+vW/+H3BOAHwhmEkdLvzLAH4DderZ+zQkjVJd+OEOH7i6wb/904t3A/ekUZcLP3zh964n75U16KtnH9DgmeRx4YcnfH8AlL1/dxqYjF6DM6jThR+G8Hnub0IvPfPzNDidPC788IJ/dQNwZSPF6Vl3q7tmUbMLP3zg926g7XrGF1VEFvrdlUFeF35YwPd+Zj366RlfUhEZiLhzNnW58EMaftdVGxChZ9tjRWRSnAs/NOFf3RjkvN+dBmVSpgs/9OD33tDNgY8RDcqiAhd+6MC/qoEK9AxNa2AWeVz4zobPc76QYb873ZFNQ27PJq8L35HwvaYWfD3VrTm47vYc6nDhOwh+IzUb2uoZ1cCF6HVrNlJ+nUteF7598Pl495Ln+zI1KAt9bs2jzAG51OXCtw4+V/V6NyDlmk3oo2diiwYUot8t+VRycx51ufDlwWfwXM+/aEnXTvHUcEs+ht9UQCU3FlKnC988/GvqqePaeiq4ar0FCzzRumke+t9YiJQbiqjghiJqYl9fRF0u/AvAr6Euvq7lcz0VXLMeKVc2oL/+mbpyJVT/BxAbHykKk+0tAAAAAElFTkSuQmCC'
# @@LOGO_END

# ---------- Elevación a administrador ----------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$IsAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin -and -not $NoElevate -and -not $SelfTest -and -not $Screenshot) {
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    } catch { }
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

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
using System.Security.Cryptography;
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

        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        static extern int SetCurrentProcessExplicitAppUserModelID(string id);
        public static void SetAppId(string id) { try { SetCurrentProcessExplicitAppUserModelID(id); } catch { } }

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
        public List<Segment> Segments { get; set; }
        public string ChartNote { get; set; }

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

        // Recorre un árbol llamando a onFile(ruta, tamaño, fechaModificación). Omite archivos en la nube no descargados.
        public static void Walk(string root, Func<string, bool> enterDir, Action<string, long, long> onFile, Func<bool> cancel)
        {
            var st = new Stack<string>(); st.Push(root.TrimEnd('\\'));
            while (st.Count > 0)
            {
                if (cancel()) return;
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
                        string full = b + "\\" + n;
                        if ((fd.dwFileAttributes & 0x10) != 0)
                        {
                            if ((fd.dwFileAttributes & 0x400) == 0 && enterDir(full)) st.Push(full);
                        }
                        else
                        {
                            if ((fd.dwFileAttributes & 0x441400) != 0) continue;
                            long s = ((long)fd.nFileSizeHigh << 32) | fd.nFileSizeLow;
                            long t = ((long)fd.ftLastWriteTime.dwHighDateTime << 32) | (uint)fd.ftLastWriteTime.dwLowDateTime;
                            onFile(full, s, t);
                        }
                    } while (FindNextFileW(h, out fd));
                }
                finally { FindClose(h); }
            }
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
            long s = (it.Kind == "dir" && it.Node != null) ? it.Node.Size : it.Size;
            if (it.Kind == "dir") owner.Dirs.Remove(it.Node);
            else if (it.Kind == "file") owner.BigFiles.RemoveAll(x => x.Key == it.Name);
            else return;
            for (var p = owner; p != null; p = p.Parent) p.Size -= s;
        }
    }

    // ------------------------------------------------------------------
    //  Gráfica por categorías (estilo Steam)
    // ------------------------------------------------------------------
    public class Segment
    {
        public string Name { get; set; }
        public string Color { get; set; }
        public long Size { get; set; }
        public string SizeText { get; set; }
        public double Percent { get; set; }
        public double W { get; set; }
        public string Tip { get; set; }
        public int Cat { get; set; }
        public string Root { get; set; }
    }

    public class Breakdown
    {
        public DirNode Root;
        public List<Segment> Segments;
        public long[] Totals;
        public Dictionary<DirNode, int> Cat = new Dictionary<DirNode, int>();
        public Dictionary<DirNode, long> Attr = new Dictionary<DirNode, long>();
    }

    public static class Categorizer
    {
        static readonly string[] Names = { "Juegos", "Programas", "Sistema", "Datos de apps", "Archivos personales", "Temporales y papelera", "Otros", "No visible", "Libre" };
        static readonly string[] Colors = { "#1A9FFF", "#7C5CFF", "#8792AB", "#2ED39A", "#F5B83D", "#FF4D6A", "#C86BFA", "#56607A", "#2B3142" };
        static readonly string[] GameDirs = { "steamapps", "steamlibrary", "epic games", "riot games", "gog games", "gog galaxy", "xboxgames",
            "ea games", "rockstar games", "ubisoft game launcher", "origin games", "games", "juegos", "roberts space industries" };
        static readonly string[] GamePubs = { "valve", "epic games", "riot", "rockstar", "ubisoft", "electronic arts", "arenanet", "cloud imperium",
            "roberts space", "activision", "blizzard", "bethesda", "cd projekt", "saber interactive", "arrowhead", "bandai", "capcom", "square enix",
            "sega", "2k games", "paradox", "unknown worlds", "the indie stone", "squad", "mojang", "krafton", "bungie", "mihoyo", "hoyoverse",
            "cognosphere", "hi-rez", "wargaming", "gaijin", "facepunch", "re-logic", "jakehub", "respawn", "techland", "warner bros", "devolver",
            "team17", "klei", "coffee stain", "larian", "fromsoftware", "bohemia", "cfx.re", "garena", "nexon", "smilegate", "pearl abyss",
            "amazon games", "innersloth", "psyonix", "digital extremes", "grinding gear", "gearbox", "io interactive", "remedy", "insomniac",
            "sony interactive", "xbox game studios", "kerbal", "private division", "landfall", "ghost ship", "frontier developments" };

        public static bool IsGame(ProgramInfo p)
        {
            string pub = (p.Publisher ?? "").ToLowerInvariant();
            foreach (var g in GamePubs) if (pub.Contains(g)) return true;
            string d = (p.InstallDir ?? "").ToLowerInvariant() + "\\";
            foreach (var g in GameDirs) if (d.Contains("\\" + g + "\\")) return true;
            return false;
        }

        static List<Segment> Build(long[] acc, long total)
        {
            long sum = 0; foreach (var a in acc) sum += Math.Max(0, a);
            double t = Math.Max(1, Math.Max(total, sum));
            var l = new List<Segment>();
            for (int i = 0; i < acc.Length; i++)
            {
                if (acc[i] <= 0) continue;
                var s = new Segment();
                s.Name = Names[i]; s.Cat = i; s.Color = Colors[i]; s.Size = acc[i]; s.SizeText = Fmt.Size(acc[i]);
                s.Percent = acc[i] * 100.0 / t;
                s.Tip = s.Name + ": " + s.SizeText + " (" + s.Percent.ToString("0.#") + "%)";
                l.Add(s);
            }
            return l;
        }

        public static void SetWidths(List<Segment> l, double w)
        {
            if (l == null) return;
            foreach (var s in l) s.W = Math.Max(0, Math.Floor(s.Percent * w / 100.0));
        }

        // Vista rápida sin escanear: usa el tamaño de las carpetas de los programas instalados
        public static List<Segment> Quick(DriveCard d, List<ProgramInfo> progs)
        {
            var acc = new long[9];
            if (progs != null)
            {
                var dirs = new List<ProgramInfo>();
                foreach (var p in progs)
                    if (!string.IsNullOrEmpty(p.InstallDir) && p.Size > 0 && p.InstallDir.StartsWith(d.Root, StringComparison.OrdinalIgnoreCase)) dirs.Add(p);
                dirs.Sort((a, b) => a.InstallDir.Length.CompareTo(b.InstallDir.Length));
                var taken = new List<string>();
                foreach (var p in dirs)
                {
                    string k = p.InstallDir.TrimEnd('\\') + "\\";
                    bool nested = false;
                    foreach (var t in taken) if (k.StartsWith(t, StringComparison.OrdinalIgnoreCase)) { nested = true; break; }
                    if (nested) continue;
                    taken.Add(k);
                    acc[IsGame(p) ? 0 : 1] += p.Size;
                }
            }
            acc[6] = Math.Max(0, d.Used - acc[0] - acc[1]);
            acc[8] = d.Free;
            var q = Build(acc, d.Total);
            foreach (var s in q) s.Root = d.Root;
            return q;
        }

        static int Match(DirNode n, Dictionary<string, int> pd, int depth)
        {
            string name = n.Name.ToLowerInvariant();
            string p = n.Path.ToLowerInvariant().TrimEnd('\\');
            int c;
            if (Array.IndexOf(GameDirs, name) >= 0) return 0;
            if (pd.TryGetValue(p, out c)) return c;
            if (depth == 1)
            {
                if (name == "windows" || name == "system volume information" || name == "recovery" || name == "$windows.~bt" ||
                    name == "$windows.~ws" || name == "windows.old" || name == "$winreagent" || name == "boot") return 2;
                if (name == "program files" || name == "program files (x86)") return 1;
                if (name == "programdata") return 3;
                if (name == "$recycle.bin") return 5;
                if (name == "users") return 4;
            }
            if (name == "appdata") return 3;
            if (name == "temp" || name == "tmp") return 5;
            if (name == "windowsapps") return 1;
            if (name == "programs" && p.EndsWith("\\appdata\\local\\programs")) return 1;
            return -1;
        }

        static bool IsSys(string fn)
        {
            fn = fn.ToLowerInvariant();
            return fn == "pagefile.sys" || fn == "hiberfil.sys" || fn == "swapfile.sys" || fn == "memory.dmp";
        }

        // Asigna categoría a cada carpeta y calcula cuánto aporta a su categoría (sin contar subcarpetas de otra categoría)
        static long Visit(DirNode n, int cat, int depth, long[] acc, Dictionary<string, int> pd, Breakdown b)
        {
            if (depth > 0) { int m = Match(n, pd, depth); if (m >= 0) cat = m; }
            b.Cat[n] = cat;
            long sub = 0, same = 0;
            foreach (var c in n.Dirs)
            {
                long a = Visit(c, cat, depth + 1, acc, pd, b);
                sub += c.Size;
                if (b.Cat[c] == cat) same += a;
            }
            long own = n.Size - sub;
            if (depth == 0)
                foreach (var f in n.BigFiles)
                    if (IsSys(f.Key)) { acc[2] += f.Value; own -= f.Value; }
            own = Math.Max(0, own);
            acc[cat] += own;
            long attr = own + same;
            b.Attr[n] = attr;
            return attr;
        }

        public static Breakdown Analyze(DirNode root, long total, long free, List<ProgramInfo> progs)
        {
            var pd = new Dictionary<string, int>();
            if (progs != null)
                foreach (var p in progs)
                {
                    if (string.IsNullOrEmpty(p.InstallDir)) continue;
                    string k = p.InstallDir.ToLowerInvariant().TrimEnd('\\');
                    if (!pd.ContainsKey(k)) pd[k] = IsGame(p) ? 0 : 1;
                }
            var b = new Breakdown(); b.Root = root;
            var acc = new long[9];
            Visit(root, 6, 0, acc, pd, b);
            acc[7] = Math.Max(0, (total - free) - root.Size);
            acc[8] = free;
            b.Totals = acc;
            b.Segments = Build(acc, total);
            foreach (var s in b.Segments) s.Root = root.Path;
            return b;
        }

        // Desglose completo tras analizar una unidad
        public static List<Segment> Classify(DirNode root, long total, long free, List<ProgramInfo> progs)
        {
            return Analyze(root, total, free, progs).Segments;
        }

        static DiskItem Item(string name, string full, long size, double t, string kind, string icon, string detail, DirNode node, DirNode owner)
        {
            var d = new DiskItem();
            d.Name = name; d.FullPath = full; d.Size = size; d.SizeText = Fmt.Size(size);
            d.Percent = size * 100.0 / t;
            d.PercentText = d.Percent < 0.1 ? "<0.1%" : d.Percent.ToString("0.0") + "%";
            d.Kind = kind; d.Icon = icon; d.Detail = detail; d.Node = node; d.Owner = owner;
            return d;
        }

        static DiskItem DirItem(DirNode n, Breakdown b, double t)
        {
            long a = b.Attr[n];
            string where = n.Parent == null ? "Raíz de la unidad" : "En " + n.Parent.Path;
            string extra = n.Size > a + (1L << 20) ? "   ·   la carpeta completa ocupa " + Fmt.Size(n.Size) : "";
            return Item(n.Parent == null ? n.Path : n.Name, n.Path, a, t, "dir", "", where + extra, n, n.Parent);
        }

        static List<DiskItem> Expand(DirNode node, Breakdown b, int cat, double t)
        {
            var l = new List<DiskItem>();
            foreach (var c in node.Dirs) if (b.Cat[c] == cat && b.Attr[c] > 0) l.Add(DirItem(c, b, t));
            long own = node.Size; foreach (var c in node.Dirs) own -= c.Size;
            bool root = node.Parent == null;
            string pfx = node.Path.TrimEnd('\\') + "\\";
            long big = 0;
            foreach (var f in node.BigFiles)
            {
                if (root && IsSys(f.Key)) { own -= f.Value; continue; }
                l.Add(Item(f.Key, pfx + f.Key, f.Value, t, "file", "", "Archivo en " + node.Path, null, node));
                big += f.Value;
            }
            long small = own - big;
            if (small > (1L << 20) && node.SmallCount > 0)
                l.Add(Item(node.SmallCount.ToString("N0") + " archivos pequeños sueltos", node.Path, small, t, "small", "", "En " + node.Path, node, node));
            return l;
        }

        // Carpetas y archivos concretos que forman una categoría (las carpetas dominantes se abren automáticamente)
        public static List<DiskItem> Items(Breakdown b, int cat, int max)
        {
            double t = Math.Max(1, (b.Totals != null && cat < b.Totals.Length) ? b.Totals[cat] : 1);
            var work = new List<DiskItem>();
            var st = new Stack<DirNode>(); st.Push(b.Root);
            while (st.Count > 0)
            {
                var n = st.Pop();
                int c; if (!b.Cat.TryGetValue(n, out c)) continue;
                if (c == cat && (n.Parent == null || b.Cat[n.Parent] != cat) && b.Attr[n] > 0) work.Add(DirItem(n, b, t));
                foreach (var ch in n.Dirs) st.Push(ch);
            }
            if (cat == 2)
                foreach (var f in b.Root.BigFiles)
                    if (IsSys(f.Key)) work.Add(Item(f.Key, b.Root.Path.TrimEnd('\\') + "\\" + f.Key, f.Value, t, "file", "", "Archivo del sistema en la raíz", null, b.Root));

            for (int iter = 0; iter < 12; iter++)
            {
                DiskItem top = null;
                foreach (var it in work) if (it.Kind == "dir" && (top == null || it.Size > top.Size)) top = it;
                if (top == null || top.Size < t * 0.30) break;
                var ex = Expand(top.Node, b, cat, t);
                bool anyDir = false; foreach (var e in ex) if (e.Kind == "dir" || e.Kind == "file") anyDir = true;
                if (!anyDir) break;
                work.Remove(top); work.AddRange(ex);
            }
            work.Sort((x, y) => y.Size.CompareTo(x.Size));
            if (work.Count > max) work.RemoveRange(max, work.Count - max);
            return work;
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
        public string DisplayIcon;
        bool sel;
        public bool Selected { get { return sel; } set { sel = value; N("Selected"); } }
        string icon;
        public string IconPath { get { return icon; } set { icon = value; N("IconPath"); } }
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
                                if (dn == "DiskPilot" && S(s, "Publisher") == "Cordobot") continue; // no listarse a sí mismo
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
                                p.DisplayIcon = S(s, "DisplayIcon");
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
        public string Group { get; set; }
        public ProgramInfo Owner;
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

        static HashSet<ProgramInfo> batch = new HashSet<ProgramInfo>();
        static HashSet<string> gSeen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        public static Task<List<Leftover>> FindAsync(ProgramInfo p, List<ProgramInfo> all)
        {
            var l = new List<ProgramInfo>(); l.Add(p);
            return FindManyAsync(l, all);
        }

        // Varios programas a la vez: las carpetas compartidas solo entre programas del lote se pueden borrar
        public static Task<List<Leftover>> FindManyAsync(List<ProgramInfo> sel, List<ProgramInfo> all)
        {
            return Task.Factory.StartNew(() =>
            {
                batch = new HashSet<ProgramInfo>(sel);
                gSeen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                var res = new List<Leftover>();
                foreach (var p in sel)
                {
                    var r = Find(p, all);
                    foreach (var x in r) { x.Group = p.Name; x.Owner = p; }
                    res.AddRange(r);
                }
                return res;
            });
        }

        static int SharedWith(string dir, ProgramInfo p, List<ProgramInfo> all)
        {
            int n = 0; string me = dir.TrimEnd('\\');
            foreach (var o in all)
            {
                if (o == p || batch.Contains(o) || string.IsNullOrEmpty(o.InstallDir)) continue;
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
            var seen = gSeen;
            string inst = string.IsNullOrEmpty(p.InstallDir) ? null : p.InstallDir.TrimEnd('\\');

            // 1) Carpeta de instalación
            if (inst != null && !seen.Contains(inst) && Directory.Exists(inst) && !Safety.IsProtected(inst))
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

        public static int Current, Total;
        public static Task RunManyAsync(List<UninstallJob> jobs)
        {
            Freed = 0; PendingReboot = 0; Total = jobs.Count; Current = 0;
            string dummy; while (Log.TryDequeue(out dummy)) { }
            return Task.Factory.StartNew(() =>
            {
                foreach (var j in jobs)
                {
                    Current++;
                    if (Total > 1) L("═════════ Programa " + Current + " de " + Total + ": " + j.Name + " ═════════");
                    try { Run(j); } catch (Exception ex) { L("Error: " + ex.Message); }
                }
            }, TaskCreationOptions.LongRunning);
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
            L("COMPLETADO: " + j.Name + ".  Espacio liberado en total: " + Fmt.Size(Freed));
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
    //  Iconos de los programas
    // ------------------------------------------------------------------
    public static class Icons
    {
        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        static extern uint PrivateExtractIcons(string file, int index, int cx, int cy, IntPtr[] icons, uint[] ids, uint n, uint flags);
        [DllImport("user32.dll")]
        static extern bool DestroyIcon(IntPtr h);
        static readonly string Dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DiskPilot\\icons");

        public static Task LoadAsync(List<ProgramInfo> list)
        {
            var copy = new List<ProgramInfo>(list);
            return Task.Factory.StartNew(() =>
            {
                try { Directory.CreateDirectory(Dir); } catch { }
                Parallel.ForEach(copy, new ParallelOptions { MaxDegreeOfParallelism = 4 }, p => { try { Load(p); } catch { } });
            }, TaskCreationOptions.LongRunning);
        }

        static string Hash(string s)
        {
            using (var md5 = MD5.Create())
                return BitConverter.ToString(md5.ComputeHash(System.Text.Encoding.UTF8.GetBytes(s.ToLowerInvariant()))).Replace("-", "");
        }

        static bool Source(ProgramInfo p, out string file, out int idx)
        {
            file = null; idx = 0;
            if (!string.IsNullOrEmpty(p.DisplayIcon))
            {
                string s = p.DisplayIcon.Trim();
                var m = Regex.Match(s, @"^(.*?),\s*(-?\d+)$");
                if (m.Success) { s = m.Groups[1].Value; int.TryParse(m.Groups[2].Value, out idx); }
                s = Environment.ExpandEnvironmentVariables(s.Trim().Trim('"'));
                if (File.Exists(s) && !s.EndsWith("msiexec.exe", StringComparison.OrdinalIgnoreCase)) { file = s; return true; }
                idx = 0;
            }
            if (!string.IsNullOrEmpty(p.InstallDir) && Directory.Exists(p.InstallDir))
            {
                string best = null; int bestScore = -1; string nn = Leftovers.Norm(p.Name);
                string[] exes; try { exes = Directory.GetFiles(p.InstallDir, "*.exe"); } catch { exes = new string[0]; }
                foreach (var e in exes)
                {
                    string fn = Path.GetFileNameWithoutExtension(e).ToLowerInvariant();
                    if (fn.StartsWith("unins") || fn.Contains("uninstall") || fn.Contains("crash") || fn.Contains("update") ||
                        fn.Contains("helper") || fn.Contains("setup") || fn.Contains("report")) continue;
                    int score = 1; string ne = Leftovers.Norm(fn);
                    if (ne.Length > 2 && nn.Length > 2 && (nn.Contains(ne) || ne.Contains(nn))) score = 3;
                    if (score > bestScore) { bestScore = score; best = e; }
                }
                if (best != null) { file = best; return true; }
            }
            return false;
        }

        static void Load(ProgramInfo p)
        {
            string src; int idx;
            if (!Source(p, out src, out idx)) return;
            string png = Path.Combine(Dir, Hash(src + "|" + idx) + ".png");
            if (!File.Exists(png))
            {
                string tmp = png + "." + Guid.NewGuid().ToString("N") + ".tmp";
                var hs = new IntPtr[1]; var ids = new uint[1];
                uint got = 0;
                try { got = PrivateExtractIcons(src, idx, 48, 48, hs, ids, 1, 0); } catch { }
                if (got == 0 || got == 0xFFFFFFFF || hs[0] == IntPtr.Zero)
                {
                    try
                    {
                        using (var ic = System.Drawing.Icon.ExtractAssociatedIcon(src))
                        {
                            if (ic == null) return;
                            using (var bmp = ic.ToBitmap()) bmp.Save(tmp, System.Drawing.Imaging.ImageFormat.Png);
                        }
                    }
                    catch { return; }
                }
                else
                {
                    try
                    {
                        using (var ic = System.Drawing.Icon.FromHandle(hs[0]))
                        using (var bmp = ic.ToBitmap()) bmp.Save(tmp, System.Drawing.Imaging.ImageFormat.Png);
                    }
                    finally { DestroyIcon(hs[0]); }
                }
                try { if (!File.Exists(png)) File.Move(tmp, png); else File.Delete(tmp); } catch { try { File.Delete(tmp); } catch { } }
            }
            if (File.Exists(png)) p.IconPath = png;
        }
    }

    // ------------------------------------------------------------------
    //  Archivos duplicados (tamaño -> hash parcial -> hash completo)
    // ------------------------------------------------------------------
    public class DupFile : Bindable
    {
        bool c;
        public bool Checked { get { return c; } set { c = value; N("Checked"); } }
        public string Name { get; set; }
        public string Folder { get; set; }
        public string FullPath { get; set; }
        public long Size { get; set; }
        public string SizeText { get; set; }
        public string ModifiedText { get; set; }
        public string Group { get; set; }
        public int GroupId { get; set; }
        public DateTime Modified;
    }

    public static class DupFinder
    {
        [StructLayout(LayoutKind.Sequential)]
        struct BHFI
        {
            public uint attr;
            public System.Runtime.InteropServices.ComTypes.FILETIME c, a, w;
            public uint vol, sizeHi, sizeLo, links, idxHi, idxLo;
        }
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetFileInformationByHandle(Microsoft.Win32.SafeHandles.SafeFileHandle h, out BHFI info);

        public static volatile bool Cancel;
        public static long Found, Candidates, HashDone, HashTotal, Wasted;
        public static int Groups;
        public static string Stage = "";

        class F { public string P; public long S; public long T; }

        static readonly string[] SkipNames = { "steamapps", "steamlibrary", "epic games", "riot games", "gog games", "xboxgames",
            "windowsapps", "ea games", "rockstar games", "node_modules", ".git", "program files", "program files (x86)", "programdata", "appdata",
            ".gradle", ".android", ".m2", ".nuget", ".cargo", ".rustup", ".conda", "anaconda3", "miniconda3", ".vscode", ".cache", "unity", "library" };

        public static Task<List<DupFile>> FindAsync(string[] roots, long min, bool excludeApps)
        {
            Cancel = false; Found = 0; Candidates = 0; HashDone = 0; HashTotal = 0; Wasted = 0; Groups = 0;
            Stage = "Buscando archivos";
            return Task.Factory.StartNew(() => Run(roots, min, excludeApps), TaskCreationOptions.LongRunning);
        }

        static bool Enter(string dir, bool ex, string win)
        {
            if (dir.Equals(win, StringComparison.OrdinalIgnoreCase)) return false;
            string n = Path.GetFileName(dir).ToLowerInvariant();
            if (n == "$recycle.bin" || n == "system volume information" || n == "$windows.~bt" || n == "$windows.~ws") return false;
            if (ex && Array.IndexOf(SkipNames, n) >= 0) return false;
            return true;
        }

        static int ReadFull(Stream s, byte[] b, int n) { int r = 0, x; while (r < n && (x = s.Read(b, r, n - r)) > 0) r += x; return r; }

        static string PartialHash(F f)
        {
            try
            {
                using (var fs = new FileStream(f.P, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete, 65536))
                {
                    BHFI bi;
                    if (GetFileInformationByHandle(fs.SafeFileHandle, out bi) && bi.links > 1) return null; // enlaces duros: no son copias reales
                    using (var md5 = MD5.Create())
                    {
                        const int chunk = 65536; var buf = new byte[chunk];
                        int n = ReadFull(fs, buf, chunk); md5.TransformBlock(buf, 0, n, null, 0);
                        if (f.S > chunk * 3)
                        {
                            fs.Seek(f.S / 2, SeekOrigin.Begin); n = ReadFull(fs, buf, chunk); md5.TransformBlock(buf, 0, n, null, 0);
                            fs.Seek(-chunk, SeekOrigin.End); n = ReadFull(fs, buf, chunk); md5.TransformBlock(buf, 0, n, null, 0);
                        }
                        md5.TransformFinalBlock(buf, 0, 0);
                        return Convert.ToBase64String(md5.Hash);
                    }
                }
            }
            catch { return null; }
        }

        static string FullHash(F f)
        {
            try
            {
                using (var fs = new FileStream(f.P, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete, 1 << 20, FileOptions.SequentialScan))
                using (var md5 = MD5.Create())
                {
                    var buf = new byte[1 << 20]; int n;
                    while ((n = fs.Read(buf, 0, buf.Length)) > 0)
                    {
                        if (Cancel) return null;
                        md5.TransformBlock(buf, 0, n, null, 0);
                        Interlocked.Add(ref HashDone, n);
                    }
                    md5.TransformFinalBlock(buf, 0, 0);
                    return Convert.ToBase64String(md5.Hash);
                }
            }
            catch { return null; }
        }

        static List<List<F>> Split(List<F> g, bool partial)
        {
            var d = new Dictionary<string, List<F>>();
            foreach (var f in g)
            {
                if (Cancel) break;
                string h = partial ? PartialHash(f) : FullHash(f);
                if (h == null) continue;
                List<F> l; if (!d.TryGetValue(h, out l)) { l = new List<F>(); d[h] = l; }
                l.Add(f);
            }
            var res = new List<List<F>>();
            foreach (var kv in d) if (kv.Value.Count > 1) res.Add(kv.Value);
            return res;
        }

        static List<DupFile> Run(string[] roots, long min, bool ex)
        {
            string win = Environment.GetFolderPath(Environment.SpecialFolder.Windows).TrimEnd('\\');
            var bySize = new Dictionary<long, List<F>>();
            var seenPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var r in roots)
                Scanner.Walk(r, d => Enter(d, ex, win), (p, s, t) =>
                {
                    Found++;
                    if (s < min || !seenPaths.Add(p)) return;
                    List<F> l; if (!bySize.TryGetValue(s, out l)) { l = new List<F>(); bySize[s] = l; }
                    var f = new F(); f.P = p; f.S = s; f.T = t; l.Add(f);
                }, () => Cancel);

            var stage1 = new List<List<F>>();
            foreach (var kv in bySize) if (kv.Value.Count > 1) { stage1.Add(kv.Value); Candidates += kv.Value.Count; }

            Stage = "Comparando inicio, mitad y final";
            var stage2 = new List<List<F>>();
            foreach (var g in stage1) { if (Cancel) break; stage2.AddRange(Split(g, true)); }

            long tot = 0; foreach (var g in stage2) foreach (var f in g) tot += f.S;
            HashTotal = tot;
            Stage = "Verificando el contenido completo";
            var groups = new List<List<F>>();
            foreach (var g in stage2) { if (Cancel) break; groups.AddRange(Split(g, false)); }

            groups.Sort((a, b) => (b[0].S * (b.Count - 1)).CompareTo(a[0].S * (a.Count - 1)));
            var res = new List<DupFile>(); int gi = 0;
            foreach (var g in groups)
            {
                if (gi >= 3000) break;
                gi++;
                g.Sort((a, b) => a.T.CompareTo(b.T)); // la copia más antigua primero
                long waste = g[0].S * (g.Count - 1);
                Wasted += waste;
                string head = "#" + gi + "   " + Path.GetFileName(g[0].P) + "   ·   " + g.Count + " copias de " + Fmt.Size(g[0].S) +
                              "   ·   " + Fmt.Size(waste) + " recuperables";
                foreach (var f in g)
                {
                    var d = new DupFile();
                    d.Name = Path.GetFileName(f.P); d.Folder = Path.GetDirectoryName(f.P); d.FullPath = f.P;
                    d.Size = f.S; d.SizeText = Fmt.Size(f.S);
                    try { d.Modified = DateTime.FromFileTime(f.T); d.ModifiedText = d.Modified.ToString("dd/MM/yyyy HH:mm"); } catch { d.ModifiedText = ""; }
                    d.Group = head; d.GroupId = gi;
                    res.Add(d);
                }
            }
            Groups = gi;
            Stage = "Listo";
            return res;
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

        public static Task<long> DeleteFilesAsync(List<string> files)
        {
            return Task.Factory.StartNew(() =>
            {
                long freed = 0;
                foreach (var f in files)
                {
                    try
                    {
                        if (Safety.IsProtected(f) || !File.Exists(f)) continue;
                        long s = new FileInfo(f).Length;
                        File.SetAttributes(f, FileAttributes.Normal);
                        File.Delete(f);
                        freed += s;
                    }
                    catch { }
                }
                return freed;
            }, TaskCreationOptions.LongRunning);
        }

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
    Add-Type -TypeDefinition $cs -Language CSharp -ReferencedAssemblies System.Drawing
}
[DiskPilot.Native]::SetAppId('Cordobot.DiskPilot')

function Get-LogoImage {
    if (-not $LogoPng) { return $null }
    try {
        $bytes = [Convert]::FromBase64String($LogoPng)
        $ms = New-Object System.IO.MemoryStream(, $bytes)
        $bi = New-Object System.Windows.Media.Imaging.BitmapImage
        $bi.BeginInit(); $bi.CacheOption = 'OnLoad'; $bi.StreamSource = $ms; $bi.EndInit(); $bi.Freeze()
        return $bi
    }
    catch { return $null }
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

    <Style x:Key="Chip" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Foreground" Value="#E8EAF0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="Transparent" CornerRadius="6" Padding="5,2">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Background" Value="#262E42"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="BarSeg" TargetType="Button">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}"/>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Opacity" Value="0.75"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
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
          <Image x:Name="SideLogo" Width="40" Height="40" RenderOptions.BitmapScalingMode="HighQuality"/>
          <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
            <TextBlock Text="DiskPilot" FontSize="19" FontWeight="Bold" Foreground="White"/>
            <TextBlock x:Name="VersionText" Text="Control de almacenamiento" FontSize="11" Foreground="#8B92A6"/>
          </StackPanel>
        </StackPanel>
        <StackPanel Grid.Row="1">
          <RadioButton x:Name="NavHome" Style="{StaticResource Nav}" Tag="&#xE80F;" Content="Resumen" IsChecked="True" GroupName="nav"/>
          <RadioButton x:Name="NavProgs" Style="{StaticResource Nav}" Tag="&#xE71D;" Content="Programas" GroupName="nav"/>
          <RadioButton x:Name="NavFolders" Style="{StaticResource Nav}" Tag="&#xE8B7;" Content="Explorar disco" GroupName="nav"/>
          <RadioButton x:Name="NavDups" Style="{StaticResource Nav}" Tag="&#xE8C8;" Content="Duplicados" GroupName="nav"/>
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
              <Border Style="{StaticResource CardBorder}" Width="400" Margin="0,0,16,16">
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
                  <Border Width="356" Height="10" HorizontalAlignment="Left" Background="#242A38">
                    <Border.Clip><RectangleGeometry Rect="0,0,356,10" RadiusX="5" RadiusY="5"/></Border.Clip>
                    <ItemsControl ItemsSource="{Binding Segments}">
                      <ItemsControl.ItemsPanel><ItemsPanelTemplate><StackPanel Orientation="Horizontal"/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                      <ItemsControl.ItemTemplate>
                        <DataTemplate><Button Style="{StaticResource BarSeg}" Width="{Binding W}" Height="10" Background="{Binding Color}" ToolTip="{Binding Tip}" Tag="{Binding}"/></DataTemplate>
                      </ItemsControl.ItemTemplate>
                    </ItemsControl>
                  </Border>
                  <ItemsControl ItemsSource="{Binding Segments}" Margin="0,12,0,0">
                    <ItemsControl.ItemsPanel><ItemsPanelTemplate><WrapPanel/></ItemsPanelTemplate></ItemsControl.ItemsPanel>
                    <ItemsControl.ItemTemplate>
                      <DataTemplate>
                        <Button Style="{StaticResource Chip}" Tag="{Binding}" Margin="-5,0,6,4" ToolTip="Ver qué carpetas y archivos forman esta categoría">
                          <StackPanel Orientation="Horizontal" IsHitTestVisible="False">
                            <Ellipse Width="8" Height="8" Fill="{Binding Color}" VerticalAlignment="Center"/>
                            <TextBlock Text="{Binding Name}" FontSize="11" FontWeight="SemiBold" Foreground="#AEB4C4" Margin="6,0,5,0" VerticalAlignment="Center"/>
                            <TextBlock Text="{Binding SizeText}" FontSize="11" Foreground="#8B92A6" VerticalAlignment="Center"/>
                          </StackPanel>
                        </Button>
                      </DataTemplate>
                    </ItemsControl.ItemTemplate>
                  </ItemsControl>
                  <TextBlock Text="{Binding ChartNote}" FontSize="11" Foreground="#5D6478" Margin="0,4,0,0" TextWrapping="Wrap"/>
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
                      <Grid Width="30" Height="30" HorizontalAlignment="Left">
                    <Border CornerRadius="8" Background="{StaticResource Accent}">
                      <Border.Style>
                        <Style TargetType="Border">
                          <Setter Property="Visibility" Value="Collapsed"/>
                          <Style.Triggers>
                            <DataTrigger Binding="{Binding IconPath}" Value="{x:Null}"><Setter Property="Visibility" Value="Visible"/></DataTrigger>
                          </Style.Triggers>
                        </Style>
                      </Border.Style>
                      <TextBlock Text="{Binding Initial}" Foreground="White" FontWeight="Bold" FontSize="13" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <Image Source="{Binding IconPath}" Width="26" Height="26" RenderOptions.BitmapScalingMode="HighQuality"/>
                  </Grid>
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
            <ColumnDefinition Width="34"/><ColumnDefinition Width="50"/><ColumnDefinition Width="*"/><ColumnDefinition Width="190"/><ColumnDefinition Width="90"/><ColumnDefinition Width="96"/>
          </Grid.ColumnDefinitions>
          <TextBlock Grid.Column="2" Text="PROGRAMA" FontSize="11" FontWeight="SemiBold" Foreground="#5D6478"/>
          <TextBlock Grid.Column="3" Text="PROPORCIÓN" FontSize="11" FontWeight="SemiBold" Foreground="#5D6478"/>
          <TextBlock Grid.Column="4" Text="TAMAÑO" FontSize="11" FontWeight="SemiBold" Foreground="#5D6478" HorizontalAlignment="Right"/>
          <TextBlock Grid.Column="5" Text="INSTALADO" FontSize="11" FontWeight="SemiBold" Foreground="#5D6478" HorizontalAlignment="Right"/>
        </Grid>
        <Border Grid.Row="3" Style="{StaticResource CardBorder}" Padding="8">
          <ListBox x:Name="ProgramsList" Style="{StaticResource List}">
            <ListBox.ItemTemplate>
              <DataTemplate>
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="34"/><ColumnDefinition Width="50"/><ColumnDefinition Width="*"/><ColumnDefinition Width="190"/><ColumnDefinition Width="90"/><ColumnDefinition Width="96"/>
                  </Grid.ColumnDefinitions>
                  <CheckBox IsChecked="{Binding Selected, Mode=TwoWay}" VerticalAlignment="Center" ToolTip="Marcar para desinstalar varios a la vez"/>
                  <Grid Grid.Column="1" Width="36" Height="36" HorizontalAlignment="Left">
                    <Border CornerRadius="10" Background="{StaticResource Accent}">
                      <Border.Style>
                        <Style TargetType="Border">
                          <Setter Property="Visibility" Value="Collapsed"/>
                          <Style.Triggers>
                            <DataTrigger Binding="{Binding IconPath}" Value="{x:Null}"><Setter Property="Visibility" Value="Visible"/></DataTrigger>
                          </Style.Triggers>
                        </Style>
                      </Border.Style>
                      <TextBlock Text="{Binding Initial}" Foreground="White" FontWeight="Bold" FontSize="15" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <Image Source="{Binding IconPath}" Width="32" Height="32" RenderOptions.BitmapScalingMode="HighQuality"/>
                  </Grid>
                  <StackPanel Grid.Column="2" VerticalAlignment="Center" Margin="0,0,16,0">
                    <TextBlock Text="{Binding Name}" FontSize="14" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                    <TextBlock Text="{Binding SubLine}" FontSize="11.5" Foreground="#8B92A6" TextTrimming="CharacterEllipsis" Margin="0,2,0,0"/>
                  </StackPanel>
                  <ProgressBar Grid.Column="3" Value="{Binding Percent, Mode=OneWay}" Maximum="100" VerticalAlignment="Center" Margin="0,0,16,0"/>
                  <TextBlock Grid.Column="4" Text="{Binding SizeText}" FontSize="13.5" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                  <TextBlock Grid.Column="5" Text="{Binding InstallDateText}" FontSize="12" Foreground="#8B92A6" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
              </DataTemplate>
            </ListBox.ItemTemplate>
          </ListBox>
        </Border>
        <Border Grid.Row="4" Style="{StaticResource CardBorder}" Margin="0,12,0,8" Padding="16,12">
          <Grid>
            <StackPanel VerticalAlignment="Center">
              <TextBlock x:Name="SelProgName" Text="Selecciona un programa o marca varias casillas" FontWeight="SemiBold" FontSize="14" TextTrimming="CharacterEllipsis"/>
              <TextBlock x:Name="SelProgInfo" Text="La desinstalación a fondo ejecuta el desinstalador oficial y luego borra carpetas, restos, servicios y registro." FontSize="12" Foreground="#8B92A6" TextTrimming="CharacterEllipsis" Margin="0,2,600,0"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Button x:Name="BtnClearSel" Style="{StaticResource Btn}" Margin="0,0,10,0" Visibility="Collapsed">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE711;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Desmarcar"/>
                </StackPanel>
              </Button>
              <Button x:Name="BtnOpenProgDir" Style="{StaticResource Btn}" Margin="0,0,10,0" IsEnabled="False">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE838;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Abrir ubicación"/>
                </StackPanel>
              </Button>
              <Button x:Name="BtnUninstall" Style="{StaticResource BtnDanger}" IsEnabled="False">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock x:Name="UninstallLabel" Text="Desinstalar a fondo"/>
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

        <Border x:Name="ChartCard" Grid.Row="1" Style="{StaticResource CardBorder}" Margin="0,18,0,0" Padding="20,16" Visibility="Collapsed">
          <StackPanel>
            <Grid>
              <TextBlock x:Name="ChartTitle" Text="Qué ocupa el disco" FontSize="15" FontWeight="Bold"/>
              <TextBlock x:Name="ChartSub" FontSize="12" Foreground="#8B92A6" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </Grid>
            <Border x:Name="ChartBarHost" Height="14" Margin="0,12,0,12" Background="#242A38"/>
            <WrapPanel x:Name="ChartLegend"/>
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

      <!-- ===== DETALLE DE CATEGORÍA ===== -->
      <Grid x:Name="PageCat" Visibility="Collapsed">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Orientation="Horizontal">
          <Button x:Name="BtnCatBack" Style="{StaticResource Btn}" Padding="11,9" VerticalAlignment="Center" ToolTip="Volver al resumen">
            <TextBlock Text="&#xE72B;" FontFamily="Segoe MDL2 Assets"/>
          </Button>
          <Border x:Name="CatDot" Width="16" Height="16" CornerRadius="8" Margin="18,0,12,0" VerticalAlignment="Center" Background="#C86BFA"/>
          <StackPanel VerticalAlignment="Center">
            <TextBlock x:Name="CatTitle" Text="Categoría" Style="{StaticResource H1}"/>
            <TextBlock x:Name="CatSub" Style="{StaticResource Hint}" Margin="0,2,0,0"/>
          </StackPanel>
        </StackPanel>
        <Border Grid.Row="1" Style="{StaticResource CardBorder}" Margin="0,18,0,0" Padding="16,12">
          <Grid>
            <DockPanel Margin="0,0,250,0" LastChildFill="True">
              <TextBlock DockPanel.Dock="Left" Text="&#xE946;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="#9C86FF" VerticalAlignment="Top" Margin="0,1,12,0"/>
              <TextBlock x:Name="CatHint" FontSize="12.5" Foreground="#C8CCD8" TextWrapping="Wrap" VerticalAlignment="Center"/>
            </DockPanel>
            <Button x:Name="BtnCatAction" Style="{StaticResource BtnPrimary}" HorizontalAlignment="Right" VerticalAlignment="Center" Visibility="Collapsed" Content="Acción"/>
          </Grid>
        </Border>
        <Border Grid.Row="2" Style="{StaticResource CardBorder}" Padding="8" Margin="0,14,0,0">
          <Grid>
            <ListBox x:Name="CatList" Style="{StaticResource List}">
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
            <TextBox x:Name="CatRaw" Visibility="Collapsed" Background="Transparent" BorderThickness="0" Foreground="#B9F5D8"
                     FontFamily="Cascadia Mono, Consolas" FontSize="12" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Padding="14"/>
          </Grid>
        </Border>
        <Border Grid.Row="3" Style="{StaticResource CardBorder}" Margin="0,12,0,8" Padding="16,12">
          <Grid>
            <TextBlock x:Name="CatInfo" FontSize="12" Foreground="#8B92A6" TextWrapping="Wrap" VerticalAlignment="Center" Margin="0,0,520,0"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Button x:Name="BtnCatOpen" Style="{StaticResource Btn}" Margin="0,0,10,0">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE838;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Abrir en Explorador"/>
                </StackPanel>
              </Button>
              <Button x:Name="BtnCatBrowse" Style="{StaticResource Btn}" Margin="0,0,10,0">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE8B7;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Ver contenido"/>
                </StackPanel>
              </Button>
              <Button x:Name="BtnCatDelete" Style="{StaticResource BtnDanger}">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Eliminar"/>
                </StackPanel>
              </Button>
            </StackPanel>
          </Grid>
        </Border>
      </Grid>

      <!-- ===== DUPLICADOS ===== -->
      <Grid x:Name="PageDups" Visibility="Collapsed">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel>
          <TextBlock Text="Archivos duplicados" Style="{StaticResource H1}"/>
          <TextBlock Text="Encuentra copias idénticas (mismo contenido, comparado byte a byte) y borra las que sobran. En cada grupo siempre se conserva al menos una copia." Style="{StaticResource Hint}" Margin="0,6,0,0"/>
        </StackPanel>
        <Border Grid.Row="1" Style="{StaticResource CardBorder}" Margin="0,18,0,0" Padding="18,14">
          <Grid>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
              <TextBlock Text="Buscar en:" Foreground="#8B92A6" VerticalAlignment="Center" Margin="0,0,10,0"/>
              <ItemsControl x:Name="DupDriveButtons">
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
              <Button x:Name="BtnDupFolder" Style="{StaticResource Btn}" Padding="14,8">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE8DA;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Elegir carpeta…"/>
                </StackPanel>
              </Button>
              <TextBlock Text="Tamaño mínimo:" Foreground="#8B92A6" VerticalAlignment="Center" Margin="24,0,8,0"/>
              <Border Background="#11141B" CornerRadius="9" Padding="3" BorderBrush="#2A3142" BorderThickness="1">
                <StackPanel Orientation="Horizontal">
                  <RadioButton x:Name="DupMin1" Style="{StaticResource SortBtn}" Content="1 MB" GroupName="dupmin"/>
                  <RadioButton x:Name="DupMin10" Style="{StaticResource SortBtn}" Content="10 MB" IsChecked="True" GroupName="dupmin"/>
                  <RadioButton x:Name="DupMin100" Style="{StaticResource SortBtn}" Content="100 MB" GroupName="dupmin"/>
                </StackPanel>
              </Border>
            </StackPanel>
            <CheckBox x:Name="DupExclude" IsChecked="True" HorizontalAlignment="Right" VerticalAlignment="Center" Content="Excluir programas y juegos"
                      ToolTip="Omite Archivos de programa, ProgramData, AppData y bibliotecas de juegos (Steam, Epic, Riot…). Borrar archivos repetidos dentro de un programa puede romperlo."/>
          </Grid>
        </Border>
        <Border x:Name="DupProgress" Grid.Row="2" Style="{StaticResource CardBorder}" Margin="0,14,0,0" Visibility="Collapsed">
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
                <TextBlock x:Name="DupTitle" Text="Buscando…" FontWeight="SemiBold" FontSize="14" Margin="12,0,0,0" VerticalAlignment="Center"/>
              </StackPanel>
              <Button x:Name="BtnCancelDups" Style="{StaticResource BtnSmall}" Content="Cancelar" HorizontalAlignment="Right"/>
            </Grid>
            <ProgressBar x:Name="DupBar" Maximum="100" Height="8" Margin="0,14,0,8"/>
            <TextBlock x:Name="DupText" FontSize="12" Foreground="#C8CCD8"/>
          </StackPanel>
        </Border>
        <Border Grid.Row="3" Style="{StaticResource CardBorder}" Padding="8" Margin="0,14,0,0">
          <Grid>
            <ListBox x:Name="DupList" Style="{StaticResource List}" VirtualizingPanel.IsVirtualizingWhenGrouping="True">
              <ListBox.GroupStyle>
                <GroupStyle>
                  <GroupStyle.HeaderTemplate>
                    <DataTemplate>
                      <Border Background="#1B2030" CornerRadius="8" Padding="12,7" Margin="0,10,0,2">
                        <TextBlock Text="{Binding Name}" FontWeight="SemiBold" FontSize="12.5" Foreground="#B9A8FF" TextTrimming="CharacterEllipsis"/>
                      </Border>
                    </DataTemplate>
                  </GroupStyle.HeaderTemplate>
                </GroupStyle>
              </ListBox.GroupStyle>
              <ListBox.ItemTemplate>
                <DataTemplate>
                  <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="34"/><ColumnDefinition Width="34"/><ColumnDefinition Width="*"/><ColumnDefinition Width="130"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                    <CheckBox IsChecked="{Binding Checked, Mode=TwoWay}" VerticalAlignment="Center"/>
                    <TextBlock Grid.Column="1" Text="&#xE8A5;" FontFamily="Segoe MDL2 Assets" FontSize="17" Foreground="#00C2FF" VerticalAlignment="Center"/>
                    <StackPanel Grid.Column="2" VerticalAlignment="Center" Margin="0,0,12,0">
                      <TextBlock Text="{Binding Name}" FontSize="13" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                      <TextBlock Text="{Binding Folder}" FontSize="11" Foreground="#8B92A6" TextTrimming="CharacterEllipsis" ToolTip="{Binding FullPath}"/>
                    </StackPanel>
                    <TextBlock Grid.Column="3" Text="{Binding ModifiedText}" FontSize="11.5" Foreground="#8B92A6" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    <TextBlock Grid.Column="4" Text="{Binding SizeText}" FontSize="13" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                  </Grid>
                </DataTemplate>
              </ListBox.ItemTemplate>
            </ListBox>
            <StackPanel x:Name="DupEmpty" VerticalAlignment="Center" HorizontalAlignment="Center">
              <TextBlock Text="&#xE8C8;" FontFamily="Segoe MDL2 Assets" FontSize="46" Foreground="#2E3548" HorizontalAlignment="Center"/>
              <TextBlock x:Name="DupEmptyText" Text="Elige una unidad o una carpeta para buscar archivos duplicados" Foreground="#5D6478" FontSize="14" Margin="0,14,0,0" HorizontalAlignment="Center"/>
            </StackPanel>
          </Grid>
        </Border>
        <Border Grid.Row="4" Style="{StaticResource CardBorder}" Margin="0,12,0,8" Padding="16,12">
          <Grid>
            <StackPanel VerticalAlignment="Center">
              <TextBlock x:Name="DupTotal" Text="Sin resultados todavía" FontSize="15" FontWeight="SemiBold"/>
              <TextBlock x:Name="DupInfo" Text="«Marcar copias sobrantes» deja sin marcar la copia más antigua de cada grupo." FontSize="12" Foreground="#8B92A6" TextTrimming="CharacterEllipsis" Margin="0,0,560,0"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Button x:Name="BtnDupOpen" Style="{StaticResource Btn}" Margin="0,0,10,0">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE838;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Abrir ubicación"/>
                </StackPanel>
              </Button>
              <Button x:Name="BtnDupAuto" Style="{StaticResource Btn}" Margin="0,0,10,0">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE73A;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Marcar copias sobrantes"/>
                </StackPanel>
              </Button>
              <Button x:Name="BtnDupDelete" Style="{StaticResource BtnDanger}" IsEnabled="False">
                <StackPanel Orientation="Horizontal">
                  <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" Margin="0,1,8,0"/>
                  <TextBlock Text="Eliminar marcados"/>
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
              <ListBox x:Name="LeftList" Style="{StaticResource List}" VirtualizingPanel.IsVirtualizingWhenGrouping="True">
                <ListBox.GroupStyle>
                  <GroupStyle>
                    <GroupStyle.HeaderTemplate>
                      <DataTemplate>
                        <TextBlock Text="{Binding Name}" FontWeight="Bold" FontSize="13" Foreground="#B9A8FF" Margin="10,12,0,4"/>
                      </DataTemplate>
                    </GroupStyle.HeaderTemplate>
                  </GroupStyle>
                </ListBox.GroupStyle>
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
$script:FullSeg = @{}
$script:Breakdowns = @{}; $script:PendingCat = $null
$script:DupTask = $null; $script:DupDelTask = $null; $script:DupItems = $null; $script:LeftItems = $null

function Set-Status([string]$msg) { $StatusText.Text = $msg }

function Show-Page([string]$name) {
    foreach ($p in 'PageHome', 'PageProgs', 'PageFolders', 'PageDups', 'PageClean', 'PageCat') {
        $el = Get-Variable -Name $p -ValueOnly -Scope Script
        if ($p -eq $name) { $el.Visibility = 'Visible' } else { $el.Visibility = 'Collapsed' }
    }
    if ($name -eq 'PageClean' -and -not $script:CleanLoaded) { Load-Clean }
}

# ---------- Unidades ----------
function Load-Drives {
    $script:Drives = [DiskPilot.DriveCard]::GetAll()
    foreach ($d in $script:Drives) {
        if ($script:FullSeg.ContainsKey($d.Root)) {
            $d.Segments = $script:FullSeg[$d.Root]
            $d.ChartNote = 'Haz clic en una categoría para ver qué carpetas y archivos la forman.'
        }
        else {
            $d.Segments = [DiskPilot.Categorizer]::Quick($d, $script:Programs)
            $d.ChartNote = 'Vista rápida: haz clic en «Otros» (o en cualquier categoría) para analizar y ver exactamente qué archivos son.'
        }
        foreach ($s in $d.Segments) { $s.Root = $d.Root }
        [DiskPilot.Categorizer]::SetWidths($d.Segments, 356)
    }
    $DrivesList.ItemsSource = $null; $DrivesList.ItemsSource = $script:Drives
    $DriveButtons.ItemsSource = $null; $DriveButtons.ItemsSource = $script:Drives
    $DupDriveButtons.ItemsSource = $null; $DupDriveButtons.ItemsSource = $script:Drives
}

# ---------- Programas ----------
function Load-Programs {
    $script:Programs = [DiskPilot.Programs]::Load()
    Update-ProgView
    $ProgSummary.Text = "{0} programas encontrados · calculando el tamaño real de cada carpeta…" -f $script:Programs.Count
    $HomeProgHint.Text = 'Calculando tamaños reales…'
    $script:SizeTask = [DiskPilot.Programs]::SizeAsync($script:Programs)
    $script:IconTask = [DiskPilot.Icons]::LoadAsync($script:Programs)
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
    Load-Drives
}

# ---------- Escaneo de carpetas ----------
function Start-Scan([string]$root) {
    if ($script:ScanTask -and -not $script:ScanTask.IsCompleted) { Set-Status 'Ya hay un análisis en curso.'; return }
    $NavFolders.IsChecked = $true
    $script:ScanDrive = $script:Drives | Where-Object { $_.Root -eq $root } | Select-Object -First 1
    $ScanPanel.Visibility = 'Visible'; $ScanBar.Value = 0
    $ChartCard.Visibility = 'Collapsed'
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
function Get-UninstallTargets {
    $c = @($script:Programs | Where-Object { $_.Selected })
    if ($c.Count -eq 0 -and $ProgramsList.SelectedItem) { $c = @($ProgramsList.SelectedItem) }
    return , $c
}

function Update-ProgSelection {
    if (-not $script:Programs) { return }
    $c = @($script:Programs | Where-Object { $_.Selected })
    $p = $ProgramsList.SelectedItem
    if ($c.Count -gt 0) {
        $tot = 0L; foreach ($x in $c) { if ($x.Size -gt 0) { $tot += $x.Size } }
        $SelProgName.Text = "{0} programa(s) marcados  ·  {1} en total" -f $c.Count, [DiskPilot.Fmt]::Size($tot)
        $names = ($c | Select-Object -First 5 | ForEach-Object { $_.Name }) -join ',  '
        if ($c.Count -gt 5) { $names += '…' }
        $SelProgInfo.Text = $names
        $UninstallLabel.Text = "Desinstalar {0} a fondo" -f $c.Count
        $BtnUninstall.IsEnabled = $true
        $BtnClearSel.Visibility = 'Visible'
    }
    else {
        $UninstallLabel.Text = 'Desinstalar a fondo'
        $BtnClearSel.Visibility = 'Collapsed'
        if ($p) {
            $SelProgName.Text = $p.Name
            $SelProgInfo.Text = if ($p.InstallDir) { $p.InstallDir } else { 'Ubicación desconocida (se usará el desinstalador oficial y la búsqueda de restos)' }
            $BtnUninstall.IsEnabled = $true
        }
        else {
            $SelProgName.Text = 'Selecciona un programa o marca varias casillas'
            $SelProgInfo.Text = 'Marca las casillas para desinstalar varios programas de una vez.'
            $BtnUninstall.IsEnabled = $false
        }
    }
    $BtnOpenProgDir.IsEnabled = [bool]($p -and $p.InstallDir)
}

function Begin-Uninstall {
    $targets = Get-UninstallTargets
    if ($targets.Count -eq 0) { Set-Status 'Selecciona o marca al menos un programa.'; return }
    if ($script:JobTask -and -not $script:JobTask.IsCompleted) { return }
    $script:UninstProgs = $targets
    $tot = 0L; foreach ($x in $targets) { if ($x.Size -gt 0) { $tot += $x.Size } }
    if ($targets.Count -eq 1) {
        $p = $targets[0]
        $OvTitle.Text = "Desinstalar a fondo: " + $p.Name
        $OvSub.Text = "{0}   ·   {1}" -f $(if ($p.Publisher) { $p.Publisher } else { 'Editor desconocido' }), [DiskPilot.Fmt]::Size($tot)
    }
    else {
        $OvTitle.Text = "Desinstalar a fondo {0} programas" -f $targets.Count
        $OvSub.Text = "Se desinstalarán uno tras otro   ·   {0} en total" -f [DiskPilot.Fmt]::Size($tot)
    }
    $hasCmd = $false
    foreach ($x in $targets) { if ($x.UninstallString -or $x.QuietUninstallString) { $hasCmd = $true } }
    $OptRunOfficial.IsChecked = $hasCmd; $OptRunOfficial.IsEnabled = $hasCmd
    $OptSilent.IsChecked = $true
    $LeftList.ItemsSource = $null; $script:LeftItems = $null
    $LeftLoading.Text = 'Buscando carpetas residuales, accesos directos, servicios y entradas de registro…'
    $BtnDoUninstall.IsEnabled = $false
    $ConfirmPanel.Visibility = 'Visible'; $ProgressPanel.Visibility = 'Collapsed'; $Overlay.Visibility = 'Visible'
    $list = New-Object 'System.Collections.Generic.List[DiskPilot.ProgramInfo]'
    foreach ($x in $targets) { $list.Add($x) }
    $script:LeftTask = [DiskPilot.Leftovers]::FindManyAsync($list, $script:Programs)
}

function Run-Uninstall {
    $jobs = New-Object 'System.Collections.Generic.List[DiskPilot.UninstallJob]'
    $items = @($script:LeftItems)
    foreach ($p in $script:UninstProgs) {
        $job = New-Object DiskPilot.UninstallJob
        $job.Name = $p.Name
        if ($OptRunOfficial.IsChecked) {
            $exe = $null; $arg = $null
            if ([DiskPilot.Uninstaller]::BuildCommand($p, [bool]$OptSilent.IsChecked, [ref]$exe, [ref]$arg)) { $job.Exe = $exe; $job.Args = $arg }
        }
        foreach ($i in $items) { if ($i -and $i.Checked -and [object]::ReferenceEquals($i.Owner, $p)) { $job.Items.Add($i) } }
        if ($job.Exe -or $job.Items.Count -gt 0) { $jobs.Add($job) }
    }
    if ($jobs.Count -eq 0) { Set-Status 'No hay nada marcado para eliminar.'; return }
    $LogBox.Text = ''; $ProgFreed.Text = ''
    $ProgTitle.Text = if ($jobs.Count -gt 1) { "Desinstalando 1 de {0}…" -f $jobs.Count } else { "Desinstalando " + $jobs[0].Name + "…" }
    $ProgSub.Text = 'No cierres la aplicación. Si aparece la ventana de algún desinstalador, complétala.'
    $ProgGlyph.Text = [string][char]0xE895
    $BtnCloseOverlay.IsEnabled = $false
    $ConfirmPanel.Visibility = 'Collapsed'; $ProgressPanel.Visibility = 'Visible'
    $script:JobTask = [DiskPilot.Uninstaller]::RunManyAsync($jobs)
}

# ---------- Gráfica por categorías ----------
$script:BrushConv = New-Object System.Windows.Media.BrushConverter
function New-Brush([string]$c) { $script:BrushConv.ConvertFromString($c) }

function Render-Chart($segs, [string]$title, [string]$sub) {
    $ChartTitle.Text = $title; $ChartSub.Text = $sub + '   ·   haz clic en una categoría para ver su contenido'
    $g = New-Object System.Windows.Controls.Grid
    $ChartLegend.Children.Clear()
    $i = 0
    foreach ($s in $segs) {
        $cd = New-Object System.Windows.Controls.ColumnDefinition
        $cd.Width = New-Object System.Windows.GridLength([Math]::Max([double]1, [double]$s.Size), ([System.Windows.GridUnitType]::Star))
        $g.ColumnDefinitions.Add($cd)
        $b = New-Object System.Windows.Controls.Border
        $b.Background = New-Brush $s.Color; $b.ToolTip = $s.Tip; $b.Tag = $s; $b.Cursor = [System.Windows.Input.Cursors]::Hand
        $b.Add_MouseLeftButtonUp($script:SegClick)
        [System.Windows.Controls.Grid]::SetColumn($b, $i); [void]$g.Children.Add($b); $i++

        $sp = New-Object System.Windows.Controls.StackPanel
        $sp.Orientation = 'Horizontal'; $sp.Margin = New-Object System.Windows.Thickness(0, 0, 24, 8); $sp.ToolTip = 'Ver qué contiene: ' + $s.Name
        $sp.Tag = $s; $sp.Cursor = [System.Windows.Input.Cursors]::Hand; $sp.Background = [System.Windows.Media.Brushes]::Transparent
        $sp.Add_MouseLeftButtonUp($script:SegClick)
        $el = New-Object System.Windows.Shapes.Ellipse
        $el.Width = 10; $el.Height = 10; $el.Fill = New-Brush $s.Color; $el.VerticalAlignment = 'Center'
        $t1 = New-Object System.Windows.Controls.TextBlock
        $t1.Text = $s.Name.ToUpper(); $t1.FontSize = 11.5; $t1.FontWeight = [System.Windows.FontWeights]::SemiBold
        $t1.Foreground = New-Brush '#AEB4C4'; $t1.Margin = New-Object System.Windows.Thickness(7, 0, 7, 0); $t1.VerticalAlignment = 'Center'
        $t2 = New-Object System.Windows.Controls.TextBlock
        $t2.Text = $s.SizeText; $t2.FontSize = 13; $t2.FontWeight = [System.Windows.FontWeights]::Bold
        $t2.Foreground = New-Brush '#FFFFFF'; $t2.VerticalAlignment = 'Center'
        $t3 = New-Object System.Windows.Controls.TextBlock
        $t3.Text = "  {0:0.#}%" -f $s.Percent; $t3.FontSize = 11.5; $t3.Foreground = New-Brush '#6B7286'; $t3.VerticalAlignment = 'Center'
        [void]$sp.Children.Add($el); [void]$sp.Children.Add($t1); [void]$sp.Children.Add($t2); [void]$sp.Children.Add($t3)
        [void]$ChartLegend.Children.Add($sp)
    }
    $ChartBarHost.Child = $g
    $ChartCard.Visibility = 'Visible'
}

# ---------- Detalle de categoría ----------
$script:SegClick = [System.Windows.Input.MouseButtonEventHandler] {
    param($sender, $e)
    $s = $sender.Tag
    if ($s) { Open-Category $s.Root $s.Cat }
}

$script:CatHints = @{
    0 = 'Juegos instalados. Para quitar uno por completo usa «Programas» (desinstalación a fondo) o su launcher (Steam, Epic…).'
    1 = 'Carpetas de programas instalados. Desinstálalos desde «Programas» para borrar también sus restos.'
    2 = 'Windows, archivo de paginación (pagefile.sys) e hibernación (hiberfil.sys). Están protegidos; la hibernación se puede desactivar en «Limpieza rápida».'
    3 = 'Configuración y cachés de programas (AppData y ProgramData). Aquí suelen quedar restos de programas ya desinstalados que puedes borrar.'
    4 = 'Tus archivos: Descargas, Documentos, Vídeos, Escritorio, proyectos, cachés de desarrollo… Revisa lo que ya no necesites.'
    5 = 'Archivos temporales y papelera: se pueden borrar sin riesgo desde «Limpieza rápida».'
    6 = 'Carpetas que no están en las ubicaciones estándar de Windows: juegos o proyectos instalados directamente en la raíz del disco, copias de seguridad, descargas de launchers, etc.'
    7 = 'Espacio ocupado que no aparece en ninguna carpeta: puntos de restauración e instantáneas del sistema (VSS), archivos protegidos o metadatos del disco. Se reduce desde «Protección del sistema».'
}

function Open-Category([string]$root, [int]$cat) {
    if ($cat -ge 8) { Set-Status 'Ese es el espacio libre de la unidad.'; return }
    if (-not $script:Breakdowns.ContainsKey($root)) {
        if ($script:ScanTask) { Set-Status 'Espera a que termine el análisis en curso.'; return }
        $script:PendingCat = @($root, $cat)
        Start-Scan $root
        Set-Status ("Analizando {0} para mostrar qué contiene cada categoría…" -f $root)
        return
    }
    $bd = $script:Breakdowns[$root]
    $seg = $bd.Segments | Where-Object { $_.Cat -eq $cat } | Select-Object -First 1
    $script:CatRoot = $root; $script:CatIdx = $cat
    $name = if ($seg) { $seg.Name } else { 'Categoría' }
    $CatTitle.Text = "{0} en {1}" -f $name, $root.TrimEnd('\')
    $CatSub.Text = if ($seg) { "{0}  ·  {1:0.#}% del disco" -f $seg.SizeText, $seg.Percent } else { 'Vacío' }
    $CatDot.Background = New-Brush $(if ($seg) { $seg.Color } else { '#56607A' })
    $CatHint.Text = $script:CatHints[$cat]
    $BtnCatAction.Visibility = 'Collapsed'
    switch ($cat) {
        { $_ -eq 2 -or $_ -eq 5 } { $BtnCatAction.Content = 'Ir a Limpieza rápida'; $BtnCatAction.Tag = 'clean'; $BtnCatAction.Visibility = 'Visible' }
        { $_ -eq 0 -or $_ -eq 1 } { $BtnCatAction.Content = 'Ir a Programas'; $BtnCatAction.Tag = 'progs'; $BtnCatAction.Visibility = 'Visible' }
        7 { $BtnCatAction.Content = 'Abrir Protección del sistema'; $BtnCatAction.Tag = 'vss'; $BtnCatAction.Visibility = 'Visible' }
    }
    if ($cat -eq 7) {
        $CatList.Visibility = 'Collapsed'; $CatRaw.Visibility = 'Visible'
        $out = [DiskPilot.Uninstaller]::RunHidden('vssadmin.exe', 'list shadowstorage', 15000)
        if (-not $out) { $out = 'Sin datos: se necesitan permisos de administrador para consultar las instantáneas.' }
        $CatRaw.Text = "Espacio reservado para puntos de restauración e instantáneas (vssadmin list shadowstorage):`r`n`r`n" + $out
        $CatInfo.Text = 'En «Protección del sistema» → Configurar puedes bajar el uso máximo o eliminar los puntos de restauración.'
        $BtnCatOpen.IsEnabled = $false; $BtnCatBrowse.IsEnabled = $false; $BtnCatDelete.IsEnabled = $false
    }
    else {
        $CatList.Visibility = 'Visible'; $CatRaw.Visibility = 'Collapsed'
        $items = [DiskPilot.Categorizer]::Items($bd, $cat, 120)
        $CatList.ItemsSource = $items
        $CatInfo.Text = "{0} elementos ordenados por tamaño. Doble clic o «Ver contenido» para entrar en una carpeta." -f $items.Count
        $BtnCatOpen.IsEnabled = $true; $BtnCatBrowse.IsEnabled = $true; $BtnCatDelete.IsEnabled = -not $script:DelTask
    }
    foreach ($n in @($NavHome, $NavProgs, $NavFolders, $NavDups, $NavClean)) { $n.IsChecked = $false }
    Show-Page 'PageCat'
}

function Browse-CatItem($it) {
    if (-not $it) { Set-Status 'Selecciona una carpeta de la lista.'; return }
    $root = $script:CatRoot; $bd = $script:Breakdowns[$root]
    $node = if ($it.Kind -eq 'dir') { $it.Node } else { $it.Owner }
    if (-not $node -or -not $bd) { return }
    $script:ScanDrive = $script:Drives | Where-Object { $_.Root -eq $root } | Select-Object -First 1
    $script:ScanRoot = $bd.Root
    if ($script:ScanDrive) {
        Render-Chart $bd.Segments ("Qué ocupa " + $script:ScanDrive.Name) ("{0} usados de {1}" -f [DiskPilot.Fmt]::Size($script:ScanDrive.Used), [DiskPilot.Fmt]::Size($script:ScanDrive.Total))
    }
    $NavFolders.IsChecked = $true
    Show-Node $node
}

function Refresh-Breakdown([string]$root) {
    if (-not $root -or -not $script:Breakdowns.ContainsKey($root)) { return }
    $d = [DiskPilot.DriveCard]::GetAll() | Where-Object { $_.Root -eq $root } | Select-Object -First 1
    if (-not $d) { return }
    $bd = [DiskPilot.Categorizer]::Analyze($script:Breakdowns[$root].Root, $d.Total, $d.Free, $script:Programs)
    $script:Breakdowns[$root] = $bd; $script:FullSeg[$root] = $bd.Segments
    Load-Drives
    if ($script:ScanDrive -and $script:ScanDrive.Root -eq $root -and $ChartCard.Visibility -eq 'Visible') {
        Render-Chart $bd.Segments ("Qué ocupa " + $d.Name) ("{0} usados de {1}" -f [DiskPilot.Fmt]::Size($d.Used), [DiskPilot.Fmt]::Size($d.Total))
    }
}

function Delete-DiskItem($it) {
    if (-not $it) { Set-Status 'Selecciona una carpeta o archivo.'; return }
    if ($script:DelTask) { Set-Status 'Ya se está borrando algo; espera a que termine.'; return }
    if ($it.Kind -eq 'small') { Set-Status 'Ese elemento agrupa archivos sueltos pequeños; ábrelo con «Ver contenido» o en el Explorador.'; return }
    if ([DiskPilot.Safety]::IsProtected($it.FullPath)) {
        [System.Windows.MessageBox]::Show("«$($it.FullPath)» es una ubicación protegida del sistema y no se puede borrar desde aquí.`n`nSi pertenece a un programa, desinstálalo desde la sección «Programas».", 'Ubicación protegida', 'OK', 'Information') | Out-Null
        return
    }
    $size = if ($it.Kind -eq 'dir' -and $it.Node) { [DiskPilot.Fmt]::Size($it.Node.Size) } else { $it.SizeText }
    $r = [System.Windows.MessageBox]::Show("¿Eliminar DEFINITIVAMENTE?`n`n$($it.FullPath)`n`nTamaño: $size`n`nNo pasa por la papelera y no se puede deshacer.", 'Confirmar eliminación', 'YesNo', 'Warning')
    if ($r -ne 'Yes') { return }
    $script:DelItem = $it
    $BtnDeleteItem.IsEnabled = $false; $BtnCatDelete.IsEnabled = $false
    Set-Status ("Eliminando {0}…" -f $it.FullPath)
    $script:DelTask = [DiskPilot.Cleaner]::DeletePathAsync($it.FullPath)
}

# ---------- Duplicados ----------
function Start-Dups([string[]]$roots) {
    if ($script:DupTask) { Set-Status 'Ya hay una búsqueda de duplicados en curso.'; return }
    $min = if ($DupMin1.IsChecked) { 1MB } elseif ($DupMin100.IsChecked) { 100MB } else { 10MB }
    $DupList.ItemsSource = $null; $script:DupItems = $null
    $DupEmpty.Visibility = 'Collapsed'; $DupProgress.Visibility = 'Visible'; $DupBar.Value = 0
    $DupTitle.Text = "Buscando duplicados en " + ($roots -join ', ') + " …"
    $DupTotal.Text = 'Buscando…'; $BtnDupDelete.IsEnabled = $false
    $script:DupStart = Get-Date
    $script:DupTask = [DiskPilot.DupFinder]::FindAsync([string[]]$roots, [long]$min, [bool]$DupExclude.IsChecked)
}

function Show-Dups($items) {
    $script:DupItems = $items
    if (-not $items -or $items.Count -eq 0) {
        $DupList.ItemsSource = $null
        $DupEmptyText.Text = 'No se encontraron archivos duplicados con esos criterios.'
        $DupEmpty.Visibility = 'Visible'
        $DupTotal.Text = 'Sin duplicados'; $DupInfo.Text = ''
        $BtnDupDelete.IsEnabled = $false
        return
    }
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($items)
    $view.GroupDescriptions.Clear()
    $view.GroupDescriptions.Add((New-Object System.Windows.Data.PropertyGroupDescription 'Group'))
    $DupList.ItemsSource = $view
    $DupEmpty.Visibility = 'Collapsed'
    Update-DupTotal
}

function Update-DupTotal {
    if (-not $script:DupItems) { return }
    $groups = @{}; $waste = 0L; $sel = 0L; $n = 0
    foreach ($d in $script:DupItems) {
        if ($groups.ContainsKey($d.GroupId)) { $waste += $d.Size } else { $groups[$d.GroupId] = 1 }
        if ($d.Checked) { $sel += $d.Size; $n++ }
    }
    $DupTotal.Text = "{0} grupos de duplicados  ·  {1} recuperables" -f $groups.Count, [DiskPilot.Fmt]::Size($waste)
    $DupInfo.Text = if ($n -gt 0) { "{0} archivos marcados para borrar  ·  {1}" -f $n, [DiskPilot.Fmt]::Size($sel) } else { '«Marcar copias sobrantes» deja sin marcar la copia más antigua de cada grupo.' }
    $BtnDupDelete.IsEnabled = $n -gt 0
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
                    if ($script:ScanDrive -and -not [DiskPilot.Scanner]::Cancel) {
                        $bd = [DiskPilot.Categorizer]::Analyze($t.Result, $script:ScanDrive.Total, $script:ScanDrive.Free, $script:Programs)
                        $script:Breakdowns[$script:ScanDrive.Root] = $bd
                        $script:FullSeg[$script:ScanDrive.Root] = $bd.Segments
                        Render-Chart $bd.Segments ("Qué ocupa " + $script:ScanDrive.Name) ("{0} usados de {1}" -f [DiskPilot.Fmt]::Size($script:ScanDrive.Used), [DiskPilot.Fmt]::Size($script:ScanDrive.Total))
                        Load-Drives
                        if ($script:PendingCat -and $script:PendingCat[0] -eq $script:ScanDrive.Root) {
                            $pc = $script:PendingCat; $script:PendingCat = $null
                            Open-Category $pc[0] $pc[1]
                        }
                    }
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
                $script:LeftItems = $t.Result
                $lv = [System.Windows.Data.CollectionViewSource]::GetDefaultView($t.Result)
                $lv.GroupDescriptions.Clear()
                $lv.GroupDescriptions.Add((New-Object System.Windows.Data.PropertyGroupDescription 'Group'))
                $LeftList.ItemsSource = $lv
                $LeftLoading.Text = "{0} elementos encontrados. Desmarca lo que quieras conservar." -f $t.Result.Count
            }
            $BtnDoUninstall.IsEnabled = $true
        }

        # Trabajo de desinstalación
        if ($script:JobTask) {
            Flush-Log
            if (-not $script:JobTask.IsCompleted -and [DiskPilot.Uninstaller]::Total -gt 1) {
                $ProgTitle.Text = "Desinstalando {0} de {1}…" -f [DiskPilot.Uninstaller]::Current, [DiskPilot.Uninstaller]::Total
            }
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

        # Duplicados
        if ($script:DupTask) {
            $t = $script:DupTask
            if ($t.IsCompleted) {
                $script:DupTask = $null
                $DupProgress.Visibility = 'Collapsed'
                if ($t.IsFaulted) { Set-Status ('Error buscando duplicados: ' + $t.Exception.InnerException.Message) }
                else {
                    Show-Dups $t.Result
                    $secs = [int]((Get-Date) - $script:DupStart).TotalSeconds
                    Set-Status ("Búsqueda de duplicados terminada en {0} s · {1:N0} archivos revisados." -f $secs, [DiskPilot.DupFinder]::Found)
                }
            }
            else {
                $tot = [DiskPilot.DupFinder]::HashTotal
                if ($tot -gt 0) { $DupBar.Value = [Math]::Min(99.0, [DiskPilot.DupFinder]::HashDone * 100.0 / $tot) }
                $DupText.Text = "{0}…   ·   {1:N0} archivos revisados   ·   {2:N0} candidatos   ·   {3} de {4} comparados" -f [DiskPilot.DupFinder]::Stage, [DiskPilot.DupFinder]::Found, [DiskPilot.DupFinder]::Candidates, [DiskPilot.Fmt]::Size([DiskPilot.DupFinder]::HashDone), [DiskPilot.Fmt]::Size($tot)
            }
        }
        if ($script:DupDelTask -and $script:DupDelTask.IsCompleted) {
            $t = $script:DupDelTask; $script:DupDelTask = $null
            $freed = if ($t.IsFaulted) { 0 } else { $t.Result }
            $left = @($script:DupItems | Where-Object { [IO.File]::Exists($_.FullPath) })
            $cnt = @{}; foreach ($d in $left) { $cnt[$d.GroupId] = 1 + [int]$cnt[$d.GroupId] }
            $keep = New-Object 'System.Collections.Generic.List[DiskPilot.DupFile]'
            foreach ($d in $left) { if ($cnt[$d.GroupId] -gt 1) { $d.Checked = $false; $keep.Add($d) } }
            Show-Dups $keep
            $BtnDupAuto.IsEnabled = $true
            Set-Status ("Duplicados eliminados: {0} liberados." -f [DiskPilot.Fmt]::Size($freed))
            Load-Drives
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
            $BtnDeleteItem.IsEnabled = $true; $BtnCatDelete.IsEnabled = $true
            $it = $script:DelItem
            if (-not $t.IsFaulted -and $t.Result) {
                [DiskPilot.Scanner]::Remove($it)
                Set-Status ("Eliminado: {0}" -f $it.FullPath)
            }
            else { Set-Status ("No se pudo borrar todo en {0}: algunos archivos están en uso y se eliminarán al reiniciar." -f $it.FullPath) }
            Load-Drives
            Refresh-Breakdown ([IO.Path]::GetPathRoot($it.FullPath))
            if ($PageFolders.Visibility -eq 'Visible' -and $script:CurNode) { Show-Node $script:CurNode }
            if ($PageCat.Visibility -eq 'Visible') { Open-Category $script:CatRoot $script:CatIdx }
        }
    }
    catch { Set-Status ('Error: ' + $_.Exception.Message) }
})

# ---------- Eventos ----------
$NavHome.Add_Checked({ Show-Page 'PageHome' })
$NavProgs.Add_Checked({ Show-Page 'PageProgs' })
$NavFolders.Add_Checked({ Show-Page 'PageFolders' })
$NavClean.Add_Checked({ Show-Page 'PageClean' })
$NavDups.Add_Checked({ Show-Page 'PageDups' })
$BtnCatBack.Add_Click({ $NavHome.IsChecked = $true; Show-Page 'PageHome' })
$CatList.Add_MouseDoubleClick({ Browse-CatItem $CatList.SelectedItem })
$BtnCatBrowse.Add_Click({ Browse-CatItem $CatList.SelectedItem })
$BtnCatDelete.Add_Click({ Delete-DiskItem $CatList.SelectedItem })
$BtnCatOpen.Add_Click({
    $it = $CatList.SelectedItem
    if (-not $it) { Set-Status 'Selecciona un elemento de la lista.'; return }
    if ($it.Kind -eq 'file') { Start-Process explorer.exe "/select,`"$($it.FullPath)`"" }
    else { Start-Process explorer.exe "`"$($it.FullPath)`"" }
})
$BtnCatAction.Add_Click({
    switch ([string]$BtnCatAction.Tag) {
        'clean' { $NavClean.IsChecked = $true }
        'progs' { $NavProgs.IsChecked = $true }
        'vss' { Start-Process 'SystemPropertiesProtection.exe' }
    }
})

$dupDriveClick = [System.Windows.RoutedEventHandler] {
    param($s, $e)
    $b = $e.OriginalSource
    if ($b -is [System.Windows.Controls.Button] -and $b.Tag) { Start-Dups @([string]$b.Tag) }
}
$DupDriveButtons.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, $dupDriveClick)
$BtnDupFolder.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Elige la carpeta donde buscar archivos duplicados'
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Start-Dups @($dlg.SelectedPath) }
})
$BtnCancelDups.Add_Click({ [DiskPilot.DupFinder]::Cancel = $true })
$DupList.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::CheckedEvent, [System.Windows.RoutedEventHandler] { Update-DupTotal })
$DupList.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::UncheckedEvent, [System.Windows.RoutedEventHandler] { Update-DupTotal })
$BtnDupAuto.Add_Click({
    if (-not $script:DupItems) { return }
    $seen = @{}
    foreach ($d in $script:DupItems) {
        # Se conserva la primera copia de cada grupo (la más antigua)
        if ($seen.ContainsKey($d.GroupId)) { $d.Checked = $true } else { $seen[$d.GroupId] = 1; $d.Checked = $false }
    }
    Update-DupTotal
})
$BtnDupOpen.Add_Click({ $d = $DupList.SelectedItem; if ($d) { Start-Process explorer.exe "/select,`"$($d.FullPath)`"" } })
$DupList.Add_MouseDoubleClick({ $d = $DupList.SelectedItem; if ($d) { Start-Process explorer.exe "/select,`"$($d.FullPath)`"" } })
$BtnDupDelete.Add_Click({
    if (-not $script:DupItems) { return }
    $sel = @($script:DupItems | Where-Object { $_.Checked })
    if ($sel.Count -eq 0) { return }
    $kept = @{}
    foreach ($d in $script:DupItems) { if (-not $d.Checked) { $kept[$d.GroupId] = 1 } }
    foreach ($d in $sel) {
        if (-not $kept.ContainsKey($d.GroupId)) {
            [System.Windows.MessageBox]::Show("Has marcado TODAS las copias de «$($d.Name)».`n`nDeja al menos una sin marcar en cada grupo.", 'Falta conservar una copia', 'OK', 'Warning') | Out-Null
            return
        }
    }
    $tot = 0L; foreach ($d in $sel) { $tot += $d.Size }
    $r = [System.Windows.MessageBox]::Show(("Se borrarán definitivamente {0} archivos duplicados ({1}).`n`nEn cada grupo se conserva al menos una copia.`n`n¿Continuar?" -f $sel.Count, [DiskPilot.Fmt]::Size($tot)), 'Eliminar duplicados', 'YesNo', 'Warning')
    if ($r -ne 'Yes') { return }
    $paths = New-Object 'System.Collections.Generic.List[string]'
    foreach ($d in $sel) { $paths.Add($d.FullPath) }
    $BtnDupDelete.IsEnabled = $false; $BtnDupAuto.IsEnabled = $false
    Set-Status ("Eliminando {0} duplicados…" -f $sel.Count)
    $script:DupDelTask = [DiskPilot.Cleaner]::DeleteFilesAsync($paths)
})

$ProgramsList.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::CheckedEvent, [System.Windows.RoutedEventHandler] { Update-ProgSelection })
$ProgramsList.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::UncheckedEvent, [System.Windows.RoutedEventHandler] { Update-ProgSelection })
$BtnClearSel.Add_Click({ foreach ($p in $script:Programs) { $p.Selected = $false }; Update-ProgSelection })
$ChartBarHost.Add_SizeChanged({
    $r = New-Object System.Windows.Rect(0, 0, $ChartBarHost.ActualWidth, $ChartBarHost.ActualHeight)
    $ChartBarHost.Clip = New-Object System.Windows.Media.RectangleGeometry($r, 7, 7)
})
$BtnGoProgs.Add_Click({ $NavProgs.IsChecked = $true })

$driveClick = [System.Windows.RoutedEventHandler] {
    param($s, $e)
    $b = $e.OriginalSource
    if ($b -is [System.Windows.Controls.Button] -and $b.Tag) {
        if ($b.Tag -is [DiskPilot.Segment]) { Open-Category $b.Tag.Root $b.Tag.Cat }
        else { Start-Scan ([string]$b.Tag) }
    }
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
$BtnDeleteItem.Add_Click({ Delete-DiskItem $FolderList.SelectedItem })
$TopFilesList.Add_MouseDoubleClick({
    $it = $TopFilesList.SelectedItem
    if ($it) { Start-Process explorer.exe "/select,`"$($it.FullPath)`"" }
})

$SearchBox.Add_TextChanged({ Update-ProgView })
$SortSize.Add_Checked({ $script:SortMode = 'size'; Update-ProgView })
$SortName.Add_Checked({ $script:SortMode = 'name'; Update-ProgView })
$SortDate.Add_Checked({ $script:SortMode = 'date'; Update-ProgView })
$BtnRefreshProgs.Add_Click({ if (-not $script:SizeTask) { Load-Programs } })
$ProgramsList.Add_SelectionChanged({ Update-ProgSelection })
$BtnOpenProgDir.Add_Click({ $p = $ProgramsList.SelectedItem; if ($p -and $p.InstallDir) { Start-Process explorer.exe "`"$($p.InstallDir)`"" } })
$BtnUninstall.Add_Click({ Begin-Uninstall })
$BtnCancelUninstall.Add_Click({ $Overlay.Visibility = 'Collapsed' })
$BtnDoUninstall.Add_Click({ Run-Uninstall })
$BtnCloseOverlay.Add_Click({
    $Overlay.Visibility = 'Collapsed'
    $names = @()
    foreach ($p in @($script:UninstProgs)) {
        $names += $p.Name
        $p.Selected = $false
        if (-not [DiskPilot.Programs]::StillInstalled($p)) { [void]$script:Programs.Remove($p) }
    }
    Finish-Sizing
    Update-ProgSelection
    Set-Status ("Desinstalación finalizada: {0}" -f ($names -join ', '))
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
$script:Logo = Get-LogoImage
if ($script:Logo) { $window.Icon = $script:Logo; $SideLogo.Source = $script:Logo }
$VersionText.Text = "Versión $AppVersion"
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

if ($Screenshot -and $TestCategory) {
    # Prueba: abre «Otros» de una unidad (lanza el análisis) y captura la pantalla del detalle
    $window.Add_ContentRendered({ Open-Category $TestCategory 6 })
    $script:shotTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:shotTimer.Interval = [TimeSpan]::FromSeconds(3)
    $script:shotTimer.Add_Tick({
        if (-not $script:testStart) { $script:testStart = Get-Date }
        Add-Content ($Screenshot -replace '\.png$', '-status.txt') ("{0:T}  {1}" -f (Get-Date), $StatusText.Text)
        if ($PageCat.Visibility -ne 'Visible' -and ((Get-Date) - $script:testStart).TotalSeconds -lt 300) { return }
        $script:shotTimer.Stop()
        $el = $window.Content
        $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap([int]$el.ActualWidth, [int]$el.ActualHeight, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
        $rtb.Render($el)
        $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))
        $fs = [IO.File]::Create(($Screenshot -replace '\.png$', '-Cat.png')); $enc.Save($fs); $fs.Close()
        $window.Close()
    })
    $script:shotTimer.Start()
}
elseif ($Screenshot) {
    $script:shotTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:shotTimer.Interval = [TimeSpan]::FromSeconds(9)
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
        if ($script:shotPage -eq 1) { $NavProgs.IsChecked = $true; $ProgramsList.SelectedIndex = 0; $ProgramsList.Items[1].Selected = $true; $ProgramsList.Items[2].Selected = $true; Update-ProgSelection }
        else { $window.Close() }
    })
    $script:shotTimer.Start()
}

[void]$window.ShowDialog()
