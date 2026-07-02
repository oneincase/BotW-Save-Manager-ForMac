using System.Diagnostics;
using System.Runtime.CompilerServices;

namespace BotwSaveManager.Core.Helpers
{
    public static class Logger
    {
        private static readonly string SourceRoot = AppDomain.CurrentDomain.BaseDirectory;

        public static string? CurrentLog { get; set; }

        public static void Initialize(TraceListener? customListener = null)
        {
            // Use a writable directory for logs
            string logDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "BotwSaveManager",
                "Logs"
            );

            Directory.CreateDirectory(logDir);
            CurrentLog = Path.Combine(logDir, $"{DateTime.Now:yyyy-MM-dd-HH-mm}.log");
            TextWriterTraceListener listener = new(CurrentLog);

            AddTraceListener(listener, 1);

            if (customListener != null) {
                AddTraceListener(customListener, 2);
            }

            Trace.AutoFlush = true;

            // Write an initial log entry to verify logging works
            Write("Logger initialized");
        }

        public static void Write(object msg, [CallerMemberName] string method = "", [CallerFilePath] string filepath = "", [CallerLineNumber] int lineNumber = 0)
        {
            string meta = $"{DateTime.Now:dd:mm:ss:fff} [{method}] | \"{GetRelativePath(filepath)}\":{lineNumber} | ";
            Trace.WriteLine($"{meta}{msg.ToString()?.Replace("\n", $"\n{new string(' ', meta.Length)}")}".ToCommonPath());
            Trace.Flush();
        }

        private static string GetRelativePath(string filepath)
        {
            try
            {
                return Path.GetRelativePath(SourceRoot, filepath);
            }
            catch
            {
                return filepath;
            }
        }

        private static void AddTraceListener(TraceListener listener, int pos)
        {
            if (Trace.Listeners.Count > pos) {
                Trace.Listeners[pos] = listener;
            }
            else {
                Trace.Listeners.Add(listener);
            }
        }
    }
}
