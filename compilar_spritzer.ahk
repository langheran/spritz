#Include RunAsTask.ahk
RunAsTask()
While(WinExist("ahk_exe Spritz.exe"))
{
	WinClose, ahk_exe Spritz.exe
	WinKill, ahk_exe Spritz.exe
    Run, Taskkill /f /im Spritz.exe
}
Run, compile_spritzer.bat
ExitApp