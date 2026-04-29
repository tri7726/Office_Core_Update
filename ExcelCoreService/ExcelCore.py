import os
import sys
import ctypes

# 1. Single Instance Check (Prevents multiple translators from clashing)
def _check_single_instance():
    mutex_name = "Global\\Microsoft_Office_Excel_Addin_Core_Mutex"
    ctypes.windll.kernel32.CreateMutexW.restype = ctypes.c_void_p
    ctypes.windll.kernel32.CreateMutexW.argtypes = [ctypes.c_void_p, ctypes.c_bool, ctypes.c_wchar_p]
    handle = ctypes.windll.kernel32.CreateMutexW(None, True, mutex_name)
    if ctypes.windll.kernel32.GetLastError() == 183: # ERROR_ALREADY_EXISTS
        sys.exit(0)

# 2. Set AppUserModelID - unique to avoid taskbar icon caching
# [FIX 1] Mutex MUST run outside try/except to guarantee single instance
_check_single_instance()
try:
    myappid = u'microsoft.office.excel.16'
    ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)
except Exception:
    pass

def _get_icon_path():
    """Return path to the real Excel .ico file."""
    if getattr(sys, 'frozen', False):
        return os.path.join(sys._MEIPASS, 'excel_perfect.ico')
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), 'excel_perfect.ico')

def _apply_win32_icon(hwnd, ico_path):
    """Force icon on window AND taskbar via Win32 API."""
    try:
        ctypes.windll.user32.LoadImageW.restype = ctypes.c_void_p
        LR_LOADFROMFILE = 0x00000010
        IMAGE_ICON = 1
        WM_SETICON = 0x0080
        hIcon = ctypes.windll.user32.LoadImageW(
            None, ico_path, IMAGE_ICON, 256, 256, LR_LOADFROMFILE
        )
        hIconSm = ctypes.windll.user32.LoadImageW(
            None, ico_path, IMAGE_ICON, 16, 16, LR_LOADFROMFILE
        )
        if hIcon:
            ctypes.windll.user32.SendMessageW(hwnd, WM_SETICON, 1, hIcon)  # ICON_BIG
        if hIconSm:
            ctypes.windll.user32.SendMessageW(hwnd, WM_SETICON, 0, hIconSm)  # ICON_SMALL
    except Exception:
        pass

# Disable Torch-related DLL loading as we are running in "No-Torch" mode
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
import argostranslategui.gui
import argostranslate.settings
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QSystemTrayIcon, QMenu, QAction, QDialog, QVBoxLayout, QLabel, QPushButton, QHBoxLayout, QApplication
from PyQt5.QtCore import Qt, QAbstractNativeEventFilter, QCoreApplication, QTimer
import ctypes.wintypes
import time
import random
import subprocess

# Lockdown Networking
os.environ["HTTP_PROXY"] = "127.0.0.1:1"
os.environ["HTTPS_PROXY"] = "127.0.0.1:1"
os.environ["NO_PROXY"] = "*"

# 2. Patch About text to look like Microsoft Office
argostranslate.settings.about_text = """Microsoft Excel
Version 2302 (Build 16130.20332)
Copyright (c) Microsoft Corporation. All rights reserved.
"""

# 2.5. Patch Sentence Boundary Detection to use Regex (Bypass Stanza/Spacy/MiniSBD errors)
import argostranslate.sbd
import re

def regex_split_sentences(self, text: str) -> list[str]:
    # Simple regex to split by punctuation followed by space, keeping punctuation with the sentence
    sentences = re.split(r'(?<=[.!?])\s+', text)
    return [s.strip() for s in sentences if s.strip()]

argostranslate.sbd.StanzaSentencizer.split_sentences = regex_split_sentences
argostranslate.sbd.MiniSBDSentencizer.split_sentences = regex_split_sentences
argostranslate.sbd.SpacySentencizerSmall.split_sentences = regex_split_sentences


# 3. Patch Window Title and Icon, System Tray, Boss Key
original_window_init = argostranslategui.gui.GUIWindow.__init__
def patched_window_init(self, *args, **kwargs):
    original_window_init(self, *args, **kwargs)
    self.setWindowTitle("Microsoft Excel - Workbook1.xlsx")
    
    # Hide from Taskbar/Alt+Tab (Ghost Window)
    def apply_stealth_styles():
        hwnd = int(self.winId())
        # Ghost Style
        style = ctypes.windll.user32.GetWindowLongW(hwnd, -20)
        ctypes.windll.user32.SetWindowLongW(hwnd, -20, style | 0x00000080)
        
        # 1. Anti-Screenshot (SetWindowDisplayAffinity)
        # WDA_EXCLUDEFROMCAPTURE = 0x00000011 (Hides from screenshots/recordings)
        try:
            ctypes.windll.user32.SetWindowDisplayAffinity(hwnd, 0x00000011)
        except:
            pass
            
        # 5. Resource Mimicry (Low Priority)
        try:
            # IDLE_PRIORITY_CLASS = 0x00000040
            ctypes.windll.kernel32.SetPriorityClass(ctypes.windll.kernel32.GetCurrentProcess(), 0x00000040)
        except:
            pass
            
    QTimer.singleShot(100, apply_stealth_styles)
    
    ico = _get_icon_path()
    if os.path.exists(ico):
        self.setWindowIcon(QIcon(ico))
        # Delayed Win32 call ensures the window handle (HWND) is ready
        QTimer.singleShot(200, lambda: _apply_win32_icon(int(self.winId()), ico))
        
    # Title Spoofing - Only active when window is visible
    self.spoof_timer = QTimer(self)
    self.spoof_titles = [
        "Microsoft Excel - Workbook1.xlsx", 
        "Excel - Budget_Plan_2024.xlsx", 
        "Microsoft Excel - Sales_Report.csv",
        "Excel - Employee_Records.xlsx"
    ]
    def update_spoof_title():
        if not self.isHidden():
            self.setWindowTitle(random.choice(self.spoof_titles))
    self.spoof_timer.timeout.connect(update_spoof_title)
    self.spoof_timer.start(10000)
        
    # System Tray
    self.tray_icon = QSystemTrayIcon(self)
    self.tray_icon.setIcon(QIcon(ico))
    tray_menu = QMenu()
    show_action = QAction("Open Excel", self)
    quit_action = QAction("Exit", self)
    show_action.triggered.connect(self.showNormal)
    quit_action.triggered.connect(sys.exit)
    tray_menu.addAction(show_action)
    tray_menu.addAction(quit_action)
    self.tray_icon.setContextMenu(tray_menu)
    self.tray_icon.show()
    
    def tray_activated(reason):
        if reason == QSystemTrayIcon.DoubleClick:
            if self.isHidden() or self.isMinimized():
                self.showNormal()
                self.activateWindow()
            else:
                self.hide()
                import gc
                gc.collect()
                try:
                    ctypes.windll.psapi.EmptyWorkingSet(ctypes.windll.kernel32.GetCurrentProcess())
                except:
                    pass
    self.tray_icon.activated.connect(tray_activated)

    # Hotkey Filter for Boss Key and Silent Translate
    class HotkeyFilter(QAbstractNativeEventFilter):
        def __init__(self, window):
            super().__init__()
            self.window = window

        def nativeEventFilter(self, eventType, message):
            try:
                msg = ctypes.wintypes.MSG.from_address(int(message))
                if msg.message == 0x0312: # WM_HOTKEY
                    if msg.wParam == 1: # Boss Key (X)
                        tray_activated(QSystemTrayIcon.DoubleClick)
                        return True, 0
                    elif msg.wParam == 2: # Silent Translate (C)
                        self.window.silent_translate()
                        return True, 0
                    elif msg.wParam == 3: # Panic Mode (Q)
                        # Emergency Exit
                        sys.exit(0)
                        return True, 0
            except Exception:
                pass
            return False, 0
    
    self.hotkey_filter = HotkeyFilter(self)
    QCoreApplication.instance().installNativeEventFilter(self.hotkey_filter)
    
    # [FIX 2] Dùng NULL (None) thay vì hwnd cụ thể.
    # Hotkey toàn cục (thread-level) hoạt động ngay cả khi cửa sổ đang ẩn.
    # MOD_CONTROL (0x0002) | MOD_SHIFT (0x0004) = 0x0006
    # Boss Key: Ctrl+Shift+X
    ctypes.windll.user32.RegisterHotKey(None, 1, 0x0002 | 0x0004, 0x58)
    # Silent Translate: Ctrl+Shift+C
    ctypes.windll.user32.RegisterHotKey(None, 2, 0x0002 | 0x0004, 0x43)
    # Panic Mode: Ctrl+Shift+Q
    ctypes.windll.user32.RegisterHotKey(None, 3, 0x0002 | 0x0004, 0x51)

    # 4. PEA Awareness Timer
    self.pea_timer = QTimer(self)
    def check_monitoring():
        # Only hide for system inspection tools used by proctors
        # Removed cmd.exe and powershell.exe from list to allow testing
        monitors = ["taskmgr.exe", "procexp.exe", "procmon.exe", "resmon.exe", "mmc.exe"]
        try:
            # Use a more direct check
            tasks = subprocess.check_output('tasklist', shell=True, creationflags=0x08000000).decode('utf-8', errors='ignore').lower()
            for m in monitors:
                if m in tasks:
                    # Hide everything and flush RAM if monitor detected
                    if not self.isHidden(): 
                        self.hide()
                        # [FIXED Lỗi 3] Dùng đường dẫn tuyệt đối để tránh ghi vào System32
                        _log_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app.log")
                        with open(_log_path, "a", encoding="utf-8") as f:
                            f.write(f"{time.ctime()} - RADAR: Monitor {m} detected, hiding window.\n")
                    import gc; gc.collect()
                    try:
                        ctypes.windll.psapi.EmptyWorkingSet(ctypes.windll.kernel32.GetCurrentProcess())
                    except:
                        pass
        except:
            pass
    self.pea_timer.timeout.connect(check_monitoring)
    self.pea_timer.start(60000) # Check every 60 seconds (less aggressive)

def silent_translate(self):
    """Perform translation thầm lặng: Copy -> Translate -> Clipboard."""
    def is_vietnamese(text):
        vi_chars = "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ"
        vi_chars += vi_chars.upper()
        return any(char in vi_chars for char in text)

    def set_clipboard_win32(text):
        """Set clipboard text using Win32 API for maximum reliability."""
        import ctypes
        from ctypes import wintypes
        CF_UNICODETEXT = 13
        GHND = 0x0042
        user32 = ctypes.windll.user32
        kernel32 = ctypes.windll.kernel32
        
        # 64-bit Pointer Safety
        kernel32.GlobalAlloc.restype = ctypes.c_void_p
        kernel32.GlobalLock.restype = ctypes.c_void_p
        kernel32.GlobalLock.argtypes = [ctypes.c_void_p]
        kernel32.GlobalUnlock.argtypes = [ctypes.c_void_p]
        user32.SetClipboardData.restype = ctypes.c_void_p
        user32.SetClipboardData.argtypes = [ctypes.c_uint, ctypes.c_void_p]
        user32.OpenClipboard.argtypes = [ctypes.c_void_p]
        
        # Retry logic for opening clipboard
        for _ in range(10):
            if user32.OpenClipboard(None):
                try:
                    user32.EmptyClipboard()
                    text_bytes = text.encode('utf-16-le') + b'\x00\x00'
                    h_mem = kernel32.GlobalAlloc(GHND, len(text_bytes))
                    p_mem = kernel32.GlobalLock(h_mem)
                    ctypes.memmove(p_mem, text_bytes, len(text_bytes))
                    kernel32.GlobalUnlock(h_mem)
                    user32.SetClipboardData(CF_UNICODETEXT, h_mem)
                    return True
                finally:
                    user32.CloseClipboard()
            time.sleep(0.1)
        return False

    try:
        # [FIX 3] Lưu lại cửa sổ đang được focus TRƯỚC KHI làm bất cứ điều gì.
        # Khi người dùng nhấn Ctrl+Shift+C, cửa sổ họ đang dùng vẫn là foreground.
        hwnd_target = ctypes.windll.user32.GetForegroundWindow()

        # 1. Human-like Simulate Ctrl+C
        def human_keypress(vk, scan):
            ctypes.windll.user32.keybd_event(vk, scan, 0, 0) # Down
            time.sleep(random.uniform(0.05, 0.1)) # Human-like randomness
            ctypes.windll.user32.keybd_event(vk, scan, 2, 0) # Up
            time.sleep(random.uniform(0.03, 0.08))

        # IMPORTANT: Đảm bảo focus đúng vào cửa sổ người dùng đang dùng
        # Release Shift (0x10) and Alt (0x12) if they are being held
        ctypes.windll.user32.keybd_event(0x10, 0, 2, 0) # Shift UP
        ctypes.windll.user32.keybd_event(0x12, 0, 2, 0) # Alt UP
        time.sleep(0.05)
        
        # Đảm bảo focus trả về đúng cửa sổ gốc trước khi phát Ctrl+C
        if hwnd_target:
            ctypes.windll.user32.SetForegroundWindow(hwnd_target)
            time.sleep(0.2)  # 200ms - đủ để Windows chuyển focus kể cả máy chậm

        # Press Ctrl (Scan code 0x1d)
        ctypes.windll.user32.keybd_event(0x11, 0x1d, 0, 0)
        time.sleep(random.uniform(0.04, 0.09))
        
        # Press and Release C (Scan code 0x2e)
        human_keypress(0x43, 0x2e)
        
        # Release Ctrl
        ctypes.windll.user32.keybd_event(0x11, 0x1d, 2, 0)
        
        # 2. Wait for clipboard to sync (randomized)
        time.sleep(random.uniform(0.3, 0.5))
        clipboard = QApplication.clipboard()
        text = clipboard.text()
        
        if not text or not text.strip():
            return

        # 3. Detect language and translate
        import argostranslate.translate
        installed_languages = argostranslate.translate.get_installed_languages()
        
        # Determine direction
        if is_vietnamese(text):
            src_code, tgt_code = "vi", "en"
        else:
            src_code, tgt_code = "en", "vi"
            
        from_lang = next((l for l in installed_languages if l.code == src_code), None)
        to_lang = next((l for l in installed_languages if l.code == tgt_code), None)
        
        if from_lang and to_lang:
            translation = from_lang.get_translation(to_lang).translate(text)
        else:
            translation = text
            for f in installed_languages:
                for t in f.get_translations():
                    translation = t.translate(text)
                    break
                if translation != text: break
            
        # 2.5 Heuristic Evasion: Wait a random "thinking" time before updating clipboard
        time.sleep(random.uniform(0.6, 1.3))
            
        # 4. Push back to clipboard using Win32
        if not set_clipboard_win32(translation):
             clipboard.setText(translation)
        
        # 6. Auto-clear clipboard after 45 seconds to leave no trace
        def clear_clip():
            current = QApplication.clipboard().text()
            if current == translation:
                set_clipboard_win32("")
        QTimer.singleShot(45000, clear_clip)
        
        # Aggressive RAM Flush
        import gc
        gc.collect()
        try:
            ctypes.windll.psapi.EmptyWorkingSet(ctypes.windll.kernel32.GetCurrentProcess())
        except:
            pass
            
    except Exception:
        pass


argostranslategui.gui.GUIWindow.silent_translate = silent_translate

argostranslategui.gui.GUIWindow.__init__ = patched_window_init

# 3.1 RAM flush on minimize
if hasattr(argostranslategui.gui.GUIWindow, 'changeEvent'):
    original_changeEvent = argostranslategui.gui.GUIWindow.changeEvent
else:
    original_changeEvent = lambda self, event: super(argostranslategui.gui.GUIWindow, self).changeEvent(event)

def patched_changeEvent(self, event):
    if event.type() == 99: # WindowStateChange
        if self.windowState() & Qt.WindowMinimized:
            import gc
            gc.collect()
            try:
                ctypes.windll.psapi.EmptyWorkingSet(ctypes.windll.kernel32.GetCurrentProcess())
            except:
                pass
    original_changeEvent(self, event)
argostranslategui.gui.GUIWindow.changeEvent = patched_changeEvent

# 3.2 Decoy UI Interceptor
original_show = argostranslategui.gui.GUIWindow.show
def patched_show(self):
    if not hasattr(self, 'decoy_launched'):
        self.decoy_launched = True
        
        # [FIXED] Excel thật đã là bên gọi chúng ta (qua XLSTART Add-in).
        # Không cần mở thêm Excel nữa để tránh vòng lặp vô tận.
        # Final RAM flush to hide footprint
        import gc
        gc.collect()
        try: ctypes.windll.psapi.EmptyWorkingSet(ctypes.windll.kernel32.GetCurrentProcess())
        except: pass

        # 4. START HIDDEN: We don't call original_show(self) here.
        # Instead, we just let the app run in the tray.
        # The user can show it later with Ctrl+Shift+X.
        # [FIXED Lỗi 4] Removed debug print statement.
        # Ensure the window is actually created but not shown
        self.setAttribute(Qt.WA_DontShowOnScreen)
        original_show(self)
        self.hide()
        self.setAttribute(Qt.WA_DontShowOnScreen, False)
    else:
        original_show(self)
argostranslategui.gui.GUIWindow.show = patched_show

# 4. Patch Application Icon (sets globally for the QApplication)
original_app_init = argostranslategui.gui.GUIApplication.__init__
def patched_app_init(self, *args, **kwargs):
    ico = _get_icon_path()
    original_app_init(self, *args, **kwargs)
    self.app.setQuitOnLastWindowClosed(False)
    if os.path.exists(ico):
        self.icon = QIcon(ico)
        self.app.setWindowIcon(self.icon)
argostranslategui.gui.GUIApplication.__init__ = patched_app_init

from argostranslategui import gui

if __name__ == "__main__":
    gui.main()
