// DiskPilot.exe - lanzador nativo. Lleva DiskPilot.ps1 incrustado y lo ejecuta
// con PowerShell (incluido en Windows) con permisos de administrador.
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

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
    [STAThread]
    static int Main(string[] args)
    {
        try
        {
            string dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DiskPilot");
            Directory.CreateDirectory(dir);
            string script = Path.Combine(dir, "DiskPilot-__VERSION__.ps1");

            byte[] data;
            using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("DiskPilot.ps1"))
            {
                data = new byte[s.Length];
                int read = 0;
                while (read < data.Length) read += s.Read(data, read, data.Length - read);
            }
            if (!File.Exists(script) || new FileInfo(script).Length != data.Length) File.WriteAllBytes(script, data);

            string ps = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe");
            var psi = new ProcessStartInfo(ps,
                "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File \"" + script + "\" " + string.Join(" ", args));
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;
            Process.Start(psi);
            return 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show("No se pudo iniciar DiskPilot:\n\n" + ex.Message, "DiskPilot", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
