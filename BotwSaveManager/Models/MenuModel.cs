using Avalonia.MenuFactory.Attributes;
using AvaloniaGenerics.Dialogs;
using BotwSaveManager.Core;
using BotwSaveManager.Core.Helpers;
using BotwSaveManager.ViewModels;
using BotwSaveManager.Views;
using Material.Icons;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BotwSaveManager.Models
{
    public class MenuModel
    {
        [Menu("打开存档文件夹", "_文件", "Ctrl + O", Icon = MaterialIconKind.FolderOpenOutline)]
        public async void OpenSaveFolder()
        {
            string? folder = await BrowserDialog.Folder.ShowDialog("选择 Botw 存档文件夹");

            if (folder != null) {
                try {
                    BotwSave save = new(folder, true);
                    ViewModel.Content = new BotwSaveView(save);
                }
                catch (Exception ex)  {
                    Logger.Write(ex);
                    await MessageBox.Show(ex.Message, "错误", icon: MaterialIconKind.FileDocumentErrorOutline);
                }
            }
        }

        [Menu("转换存档", "_文件", "F3", Icon = MaterialIconKind.ContentSaveMoveOutline)]
        public async void ConvertSave()
        {
            string? folder = await BrowserDialog.Folder.ShowDialog("选择 Botw 存档文件夹");

            if (folder != null) {
                try {
                    BotwSave save = new(folder, true);
                    if (await MessageBox.Show($"识别到 {save.SaveType} 存档，是否转换为 {save.SaveType.Reverse()}？", "提示", MessageBoxButtons.YesNoCancel, icon: MaterialIconKind.ContentSaveMoveOutline) == MessageBoxResult.Yes) {
                        string? output = await BrowserDialog.Folder.ShowDialog("选择 Botw 存档文件夹");
                        if (output != null) {
                            App.LogsView.Load();
                            await Task.Run(() => save.ConvertPlatform(output));
                            await MessageBox.Show($"存档转换成功！", "提示", icon: MaterialIconKind.InfoCircleOutline);
                            App.LogsView.Unload();
                        }
                    }
                }
                catch (Exception ex) {
                    Logger.Write(ex);
                    await MessageBox.Show(ex.Message, "错误", icon: MaterialIconKind.FileDocumentErrorOutline);
                }
            }
        }

        [Menu("打开调试日志", "_文件", Icon = MaterialIconKind.FileDocumentErrorOutline, IsSeparator = true)]
        public void OpenDebugLog()
        {
            App.LogsView.Load();
        }

        [Menu("清除调试日志", "_文件", Icon = MaterialIconKind.FileDocumentRemoveOutline)]
        public void ClearDebugLog()
        {
            (App.LogsView.DataContext as LogsViewModel)?.LogTrace.Clear();
        }

        [Menu("清除日志文件夹", "_文件", Icon = MaterialIconKind.FolderCancelOutline, IsSeparator = true)]
        public async void ClearLogsFolder()
        {
            Logger.Write("正在清除日志文件夹...");

            string logDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "BotwSaveManager",
                "Logs"
            );

            int i = 0;
            if (Directory.Exists(logDir)) {
                foreach (var file in Directory.EnumerateFiles(logDir, "*.log", SearchOption.TopDirectoryOnly)) {
                    if (!file.ToCommonPath().EndsWith(Logger.CurrentLog!)) {
                        File.Delete(file);
                        i++;
                    }
                }
            }

            string prompt = $"已从日志文件夹中删除 {i} 个日志文件";
            await MessageBox.Show(prompt, "提示", icon: MaterialIconKind.InfoCircleOutline);
            Logger.Write(prompt);
        }

        [Menu("退出", "_文件", "Alt + F4", Icon = MaterialIconKind.ExitToApp, IsSeparator = true)]
        public async void Quit()
        {
            Environment.Exit(0);
        }

        [Menu("帮助", "_关于", "F1", Icon = MaterialIconKind.Help)]
        public void Help()
        {
            HelpView help = new();
            help.ShowDialog(View);
        }

        [Menu("自述文件", "_关于", "F2", Icon = MaterialIconKind.HandshakeOutline)]
        public async void Readme()
        {
            await MessageBox.Show(Resource.Load("README.md").ToString(), "自述文件", formatting: Formatting.Markdown, icon: MaterialIconKind.HandshakeOutline);
        }
    }
}
