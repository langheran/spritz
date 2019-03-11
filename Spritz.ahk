#Include CWebView.ahk
#include acc.ahk
#include chrome.ahk
#include va.ahk

#Persistent
#SingleInstance, force
#WinActivateForce
#InstallKeybdHook
SetWorkingDir %A_ScriptDir%

OnMessage(536, "OnPBMsg") 
GetCurrentProcessId:=DllCall("GetCurrentProcessId")

ComObjError(false)

CoordMode, ToolTip, Screen
ShowTooltipRight("Loading ...", 5000)

SetBatchLines, -1
#MaxThreadsPerHotkey 1

OnMessage(0x404, "AHK_NOTIFYICON")

OnMessage(0x201, "WM_LBUTTONDOWN")

OnMessage(0x06, "TestActive") ; WM_ACTIVATE
OnMessage(0x07, "TestActive") ; WM_SETFOCUS
OnMessage(0x08, "TestActive") ; WM_KILLFOCUS
GoSub, Attach

args:=""
Loop, %0%  ; For each parameter:
{
    param := %A_Index%  ; Fetch the contents of the variable whose name is contained in A_Index.
	num = %A_Index%
	args := args . param
}

GrabText:=0
if(args="")
{
	GoSub, GetSelectedText
}
else
{
    file:=LTrim(RTrim(args))
    SplitPath, file, filenameLoading
    filenameLoading:="""" . filenameLoading . """"
	ShowTooltipRight("Loading: " . filenameLoading, 5000)
}
initialText:=originalText
if(originalText="")
{
	GoSub, OpenPreviousFile
    SplitPath, file, filenameLoading
    filenameLoading:="""" . filenameLoading . """"
	ShowTooltipRight("Loading: " . filenameLoading, 5000)
}

A_NewLine=`r`n
paths := {}
paths["/"] := Func("Init")
paths["/javascripts/jquery-2.1.0.min.js"] := Func("JQuery")
paths["/javascripts/spritzSettings.js"] := Func("Settings")
paths["/javascripts/spritz.min.js"] := Func("Spritz")
paths["/javascripts/initialize.js"] := Func("Initialize")
paths["404"] := Func("NotFound")
paths["/logo"] := Func("Logo")

server := new HttpServer()
server.LoadMimes(A_ScriptDir . "/mime.types")
server.SetPaths(paths)
server.Serve(8007)

OnExit, ExitApplication

IniRead, spritzSpeed, % A_ScriptDir . "/" . "Spritz.ini", settings,spritzSpeed, 250
IniRead, ttsSpeed, % A_ScriptDir . "/" . "Spritz.ini", settings,ttsSpeed, 2
IniRead, ttsPitch, % A_ScriptDir . "/" . "Spritz.ini", settings,ttsPitch, 10
IniRead, ttsVolume, % A_ScriptDir . "/" . "Spritz.ini", settings,ttsVolume, 1
IniRead, ttsVoiceName, % A_ScriptDir . "/" . "Spritz.ini", settings,ttsVoiceName, % "Microsoft Mark Mobile"
IniRead, SpeakMode, % A_ScriptDir . "/" . "Spritz.ini", settings,SpeakMode, 1
IniRead, DisplaysSentence, % A_ScriptDir . "/" . "Spritz.ini", settings,DisplaysSentence, 1
IniRead, AutoAdvanceSentences, % A_ScriptDir . "/" . "Spritz.ini", settings,AutoAdvanceSentences, 1
IniRead, HideSpritzer, % A_ScriptDir . "/" . "Spritz.ini", settings,HideSpritzer, 1
IniRead, IgnoreErrors, % A_ScriptDir . "/" . "Spritz.ini", settings,IgnoreErrors, 1
IniRead, KeepOpen, % A_ScriptDir . "/" . "Spritz.ini", settings,KeepOpen, 1
IniRead, FadeOnFocusLost, % A_ScriptDir . "/" . "Spritz.ini", settings,FadeOnFocusLost, 1
IniRead, NyanCat, % A_ScriptDir . "/" . "Spritz.ini", settings,NyanCat, 1
IniRead, MyNoiseUrl, % A_ScriptDir . "/" . "Spritz.ini", settings,MyNoiseUrl, 1
IniRead, InactiveTransparency, % A_ScriptDir . "/" . "Spritz.ini", settings,InactiveTransparency, 40
IniRead, clickmode, % A_ScriptDir . "/" . "Spritz.ini", settings,clickmode, 1
IniRead, clickthrough, % A_ScriptDir . "/" . "Spritz.ini", settings,clickthrough, 1
IniRead, transparency, % A_ScriptDir . "/" . "Spritz.ini", settings,transparency, 2
IniRead, whiteNoiseOnPause, % A_ScriptDir . "/" . "Spritz.ini", settings,whiteNoiseOnPause, 0
IniRead, lockClose, % A_ScriptDir . "/" . "Spritz.ini", settings,lockClose, 0

whiteNoiseFile:= A_ScriptDir . "/audiocheck.net_BrownNoise_15min.mp3"
wmpB := ComObjCreate("WMPlayer.OCX")
WmpB.settings.autoStart:=false
wmpB.url := whiteNoiseFile
wmpB.controls.currentPosition:=15
WmpB.settings.volume := 50
WmpB.settings.setmode("loop",true)

LoopCurrentSentence:=0

;TODO:
;	Remember position | done
;	Remember speak mode| done
;	Remember speeds | done
;	Repeat last text | done
;	Change size
;	Remember size

Menu, Tray, NoStandard

;SplashImage splash.png, B
Gui 1: New, -Caption +LastFound +AlwaysOnTop +OwnDialogs +ToolWindow hWndhGUI1
WinSet, TransColor, 123456
IniRead, gui_position, % A_ScriptDir . "/" . "Spritz.ini", window position, gui_position, x0 y0
SpritzLoaded:=0
htmlGUI := new CWebView(1,"x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
if(IgnoreErrors)
{
	ComObjError(false)
	htmlGUI.WB.silent:=true
}
ComObjConnect(htmlGUI.WB, WB_events) 
htmlGUI.SetURL("http://localhost:8007")
Suspend, On
While(!SpritzLoaded)
{
    ;ToolTip, % "Loading...", 0, 0
	Sleep, 10
}
;ToolTip
While(!htmlGUI.Script.SpritzLoaded)
{
    ;ToolTip, % "Loading...", 0, 0
	Sleep, 10
}
;ToolTip
While(!htmlGUI.Script.SpritzClient)
{
    ;ToolTip, % "Loading...", 0, 0
	Sleep, 10
}
;ToolTip
GoSub, UpdateSpritzerDisplay
Gui, Color, 123456
Gui 1:Show, %gui_position% w%A_ScreenWidth% h%A_ScreenHeight%
GoSub, UpdateSpeakModeGUI
Sleep,100
SendInput !{Esc}
;say:="Spritzer Loaded..."
;GoSub, SpritzifySay
;Sleep, 1000
Suspend, Off
say:=initialText
originalText:=initialText
if(originalText="")
{
	GoSub, ReadPreviousFile
}
else
{
	GoSub, Spritzify
}
GrabText:=1

if(SpeakMode)
	SetTimer, InitializeVolume, 1000
GoSub, ChangeClickMode
GoSub, ChangeClickThrough
GoSub, ChangeDisplaySentence
GoSub, InitializeRecentCommands
Menu, Tray, Add, &Suspend Keys, TogglePauseKeys
Menu, Tray, Add, &Reload, SaveAndReload
Menu, Tray, Add
Menu, Tray, Add, &Exit, ExitApplication
GoSub, ActivateDocument
GoSub, GotoPreviousWord
return

SaveAndReload:
if(wbnoise)
	wbnoise.Quit
SetTimer, AutoAdvanceSentence, Off
SetTimer, PauseOnEnd, off
SetTimer, DisplaySentence, off
Gosub, SaveCurrentSettings
DllCall("CloseHandle", "uint", hCon)
DllCall("FreeConsole")
Process, Close, %cPid%
Reload
return

TogglePauseKeys:
    Suspend
    IsSuspended:=A_IsSuspended
	if(IsSuspended)
		ShowTooltipRight("Pause: ON")
	else
		ShowTooltipRight("Pause: OFF")
return

UpdateAIsSuspended:
    if(IsSuspended && !A_IsSuspended)
        Suspend
    if(!IsSuspended && A_IsSuspended)
        Suspend
return

InitializeVolume:
;ShowTooltipRight("Initialize Volume")
SetTimer, InitializeVolume, Off
WinGet, ActivePid, PID, A
if !(Volume := GetVolumeObject(ActivePid))
	ShowTooltipRight("There was a problem retrieving the application volume interface")
ttsVolume:=0.0+ttsVolume
VA_ISimpleAudioVolume_SetMasterVolume(Volume, ttsVolume)
VA_ISimpleAudioVolume_SetMute(Volume, 0)
ObjRelease(Volume)
return

ChangeClickThrough:
ShowTooltipRight("")
if(clickmode || !clickthrough)
{
	WinSet, TransColor, 123456 255, % "ahk_pid " . DllCall("GetCurrentProcessId")
	WinSet, ExStyle, -0x20, % "ahk_pid " . DllCall("GetCurrentProcessId")
}
else
{
	transparencyn:=(255*transparency/3)
	WinSet, TransColor, 123456 %transparencyn%, % "ahk_pid " . DllCall("GetCurrentProcessId")
	WinSet, ExStyle, +0x20, % "ahk_pid " . DllCall("GetCurrentProcessId")
}
return

ChangeClickMode:
if(clickmode)
{
	Gui Wmp: -E0x08000000 
	
	OnMessage(0x201, "WM_LBUTTONDOWN")

	;OnMessage(0x06, "TestActive") ; WM_ACTIVATE
	;OnMessage(0x07, "TestActive") ; WM_SETFOCUS
	;OnMessage(0x08, "TestActive") ; WM_KILLFOCUS
}
else
{
	Gui Wmp: +E0x08000000 
	
	OnMessage(0x201, "")

	;OnMessage(0x06, "") ; WM_ACTIVATE
	;OnMessage(0x07, "") ; WM_SETFOCUS
	;OnMessage(0x08, "") ; WM_KILLFOCUS
}
return

ReadPreviousFile:
    GoSub, GetTitleFromFile
	GoSub, GotoPreviousText
	GoSub, ActivateDocument
	GoSub, Spritzify
	;Sleep, 1000
    IniRead, previousWord, % A_ScriptDir . "/" . "Spritz.ini", %file%,word,
	GoSub, GotoPreviousWord
	IniRead, LoopedBookmark, Spritz.ini, %file%,looping,0
	if(LoopedBookmark && LoopedBookmark<>"")
	{
		most_recent_selected_bookmark_number:=LoopedBookmark
		pressed_number:=LoopedBookmark
		GoSub, LoopBookmark
	}
    IniRead, GuiHidden, % A_ScriptDir . "/" . "Spritz.ini", %file%,hidden,1
    GoSub, SetGuiVisibilityByGuiHidden
return

GotoPreviousWord:
	SetTimer, PauseOnEnd, Off
	spritzCommandGotoPreviousWord:="var currentIndex = SPRITZ_Popup.controller.getSpritzText().setCurrentIndex(" . previousWord . ");"
	htmlGUI.Exec(spritzCommandGotoPreviousWord)
	GoSub, BackBtn
	SetTimer, PauseOnEnd, 100
return

InitializeRecentCommands:
recentCommands:=[]
recentCommandsHash:={}
IniRead,recentsSection,Spritz.ini,recents
Loop,Parse,recentsSection,`n,`r
	recentCommands.Push(LTrim(RTrim(StrSplit(A_LoopField, "=")[2]))), recentCommandsHash[LTrim(RTrim(StrSplit(A_LoopField, "=")[2]))]:=1
if(file<>""){
	file:=LTrim(RTrim(file))
	if(!recentCommandsHash.HasKey(file))
	{
		recentCommands.InsertAt(1, file)
	}
	if(recentCommands.Length()>70)
		recentCommands.Pop()
}
Menu, Tray, Icon , %A_WorkingDir%/Spritz.ico, , 1 
i:=1
for k, v in recentCommands
{
	if(file<>v)
	{
		Menu, Tray, add, &%i% %v%, RunRecentCommand
		i:=i+1
	}
	else
	{
		currentRecentIndex:=k
	}
}
Menu, Tray, Add
return

RunRecentCommand:
GoSub, saveCurrentSettings
Sleep, 100
path:=SubStr(A_ThisMenuItem, InStr(A_ThisMenuItem," "))
Run, Spritz.exe "%path%"
return

RunRecentCommandByNumber(i)
{
    global recentCommands
    
    GoSub, saveCurrentSettings
    path:=recentCommands[i]
    Run, Spritz.exe "%path%"
}

Attach:
DetectHiddenWindows, on
Run, %comspec% /k ,,Hide UseErrorLevel, cPid
WinWait, ahk_pid %cPid%,, 10
DllCall("AttachConsole","uint",cPid)
hCon:=DllCall("CreateFile","str","CONOUT$","uint",0xC0000000,"uint",7,"uint",0,"uint",3,"uint",0,"uint",0)
return

GetProperDocumentName(file){
	file:=RegExReplace(file, "[\\\:\/]+", "|")
	fileArray:=StrSplit(file, "|")
	Loop, % fileArray.Length()-4
		fileArray.RemoveAt(1)
	return Join("!", fileArray*)
}

Join(sep, params*) {
    for index,param in params
        str .= param . sep
    return SubStr(str, 1, -StrLen(sep))
}

GetTitleFromFile:
SplitPath, file, name, dir, ext, name_no_ext, drive
SetTitleMatchMode, 2
DetectHiddenWindows, Off
WinGet, chromeHwnd, ID, ahk_exe chrome.exe
title:=name_no_ext
currentDocumentName:=GetProperDocumentName(file)
if(ext="pdf")
{
	shell := comobjcreate("wscript.shell")
	filePath := """" file """"
	exec := (shell.exec(comspec " /c cpdf.exe -info " filePath))
	stdout := exec.stdout.readall()
	stdout:=RegExReplace(stdout, "`am)^(?!.*Title\:.*).+$")
	stdout:=RegExReplace(stdout, "Title: ")
	stdout:=RegExReplace(stdout, "\r")
	stdout:=RegExReplace(stdout, "\n")
	if(stdout<>"")
		title:=stdout
}
If(ShouldOpenPDF(file, title, name_no_ext) || (InStr(file,"http") && (chromeHwnd="" || !JEE_ChromeTabExists(chromeHwnd, Dec_XML(FetchPageTitle(file))))))
{
	Run, %file%,,,runPID
    WinWait, ahk_pid %runPID%
	if(InStr(file,"http"))
	{
		currentDocumentTitle:=Dec_XML(FetchPageTitle(file))
		currentDocumentId:=GetCurrentDocumentId("ahk_exe chrome.exe")
		currentDocumentName:=currentDocumentTitle
	}
	else
	{
		WinActivate, ahk_pid %runPID%
		currentDocumentId:=GetCurrentDocumentId("A")
		WinGetTitle, currentDocumentTitle, ahk_id %currentDocumentId%
	}
}
else
{
	if(WinExist(title))
		currentDocumentId:=GetCurrentDocumentId(title)
	if(WinExistNotExplorer(name_no_ext))
		currentDocumentId:=GetCurrentDocumentId("ahk_id" . WinExistNotExplorer(name_no_ext))
	WinGetTitle, currentDocumentTitle, ahk_id %currentDocumentId%
	if(InStr(file,"http") && chromeHwnd<>"")
	{
		currentDocumentTitle:=Dec_XML(FetchPageTitle(file))
		currentDocumentId:=GetCurrentDocumentId("ahk_exe chrome.exe")
	}
}
return

ShouldOpenPDF(file, title, name_no_ext)
{
    if(!FileExist(file))
        return 0
    if(!WinExistNotExplorer(title))
        return 1
    TitleMatchMode :=A_TitleMatchMode 
    SetTitleMatchMode, RegEx
    title:=EscapeRegex(title)
    WinGet, hwnd, List, .*%title%.*
    SetTitleMatchMode, %TitleMatchMode%
    Loop, % hwnd
    {
        id:=hwnd%A_Index%
        winget, winpid, PID, ahk_id %id%
        nfile:=GetCommandLineFile(winpid)
        if(nfile=file)
            return 0
        ;else
        ;{
        ;    msgbox, % nfile
        ;}
    }
    
    return 1
}

WinExistNotExplorer(title)
{
    TitleMatchMode :=A_TitleMatchMode 
    SetTitleMatchMode, RegEx
    title:=EscapeRegex(title)
    WinGet, hwnd, List, .*%title%.*
    SetTitleMatchMode, %TitleMatchMode%
    Loop, % hwnd
    {
        id:=hwnd%A_Index%
        winget, processname, processname, ahk_id %id%
        if(processname && processname<>"explorer.exe")
        {
            ;msgbox, % id
            return id
        }
        ;else
        ;{
        ;    msgbox, % processname
        ;}
    }
    return 0
}

EscapeRegex(string)
{
    return RegExReplace(string,"([.*+?^${}()|[\]\\])", "\$1")
}

OpenPreviousFile:
GoSub, GetFilePath
if(file="")
	IniRead, file, % A_ScriptDir . "/" . "Spritz.ini", previous,file,%A_Space%
OpenFile:
GoSub, GetTitleFromFile
if(!FileExist(file) && file<>"" && !InStr(file,"http"))
{
	if(FileExist(dir))
	{
		MsgBox, 4,Spritzer, File %name% does not exists, open folder? (Yes o No)
		IfMsgBox Yes
		{
			Run, %dir%
		}
	}
	else
	{
		msgbox, File %name% does not exists!
	}
}
return

GetCurrentDocumentId(name)
{
	DetectHiddenWindows, Off
	WinGet, currentDocumentId, ID, %name%
	count:=0
	while(currentDocumentId="" && count<100)
	{
		WinGet, currentDocumentId, ID, %name%
		Sleep, 100
		count:=count+1
	}
	return currentDocumentId
}

GetFilePath:
if(FileExist(file))
    return
if(WinActive("ahk_exe chrome.exe"))
{
	file:=""
	hwndChrome := WinExist("ahk_class Chrome_WidgetWin_1")
	AccChrome := Acc_ObjectFromWindow(hwndChrome)
	AccAddressBar := GetElementByName(AccChrome, "Address and search bar")
	file:=AccAddressBar.accValue(0)
	if(file<>"" && !InStr(file, "http")){
		file:="http://" . file
	}
}
else
{
	winget, winpid, PID, A
	file:=GetCommandLineFile(winpid)
	SplitPath, file, name, dir, ext, name_no_ext, drive
	if(ext<>"pdf")
		file:=""
}
return

GetElementByName(AccObj, name) {
   if (AccObj.accName(0) = name)
      return AccObj
   
   for k, v in Acc_Children(AccObj)
      if IsObject(obj := GetElementByName(v, name))
         return obj
}

GetCommandLineFile(winpid)
{
    pat:=GetModuleCommandLine(winpid)
	file:=RegexReplace(pat,"""(.*?)""(.*?)""(.*?)"".*", "$3")
	if(StrLen(file)<=1)
		file:=pat
    return file
}

GetModuleCommandLine(p_id) {
	for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where ProcessId=" p_id)
		return process.CommandLine
}

GotoPreviousText:
textPath:=A_ScriptDir . "/texts/" . currentDocumentName . ".txt"
if(FileExist(textPath))
	FileRead, originalText, *P0 %textPath%
else
{
	RunWait, pdftotext.exe -enc Latin1 "%file%" "%textPath%"
	FileRead, originalText, *P0 %textPath%
	FileDelete, %textPath%
	originalText:=CleanOriginalText(originalText)
	FileAppend, %originalText%, %textPath%
	FileRead, originalText, *P0 %textPath%
}
originalText:=RegExReplace(LTrim(RTrim(originalText)), Chr(0x0C), "")
say:=originalText
return

CleanOriginalText(originalText)
{
	originalText:=RegExReplace(LTrim(RTrim(originalText)), Chr(0x0C), "")
	originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)\r","`n")
	Loop 5
		originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)\n\n","`n")
	originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)[\n]+Table Of Contents[\n]+"," ")
	originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)Table Of Contents[\n]+"," ")
	originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)[\n]+Table Of Contents"," ")
	originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)[\n]+Page [\d]+[\n]+"," ")
	originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)Page [\d]+[\n]+"," ")
	originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)[\n]+Page [\d]+"," ")
	originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)[\n]+References.*[\n\r]*.*")
	Loop 5
		originalText:=RegexReplace(originalText, "`ams)(*ANYCRLF)  "," ")
	return originalText
}

ActivateSelf:
DetectHiddenWindows On
;WinActivate, ahk_id %hGUI1%
;PostMessage 0x07, , , , ahk_id %hGUI1%
;ControlClick, x0 y0, 0
WinActivate, ahk_id %hGUI1%
return

#l::
GoSub, ToggleLoopCurrentSentence
return

ToggleClickThrough:
clickthrough:=!clickthrough
if(clickmode)
	clickthrough:=0
GoSub, ChangeClickThrough
if(clickthrough)
	ShowTooltipRight("CLICK THROUGH")
else
	ShowTooltipRight("NO CLICK THROUGH")
return

#+^x::
ToggleClickMode:
ShowTooltipRight("")
clickmode:=!clickmode
GoSub, ChangeClickMode
GoSub, ChangeClickThrough
if(clickmode)
	ShowTooltipRight("UN-LOCKED")
else
{
	ShowTooltipRight("LOCKED")
	WinGetPos, gui_x, gui_y,,, ahk_id %hGUI1%
	if(gui_x<>"" && gui_x<>"10000")
		IniWrite, x%gui_x% y%gui_y%, % A_ScriptDir . "/" . "Spritz.ini", window position, gui_position
}
return

^!+r::
;!#r::
ReloadSpritzer:
ShowTooltipRight("Reloading Spritzer...")
Sleep, 500
Run, compilar_spritzer.exe
Reload
return

~^s::
SetTitleMatchMode 2
IfWinActive, Spritz.ahk
{
	GoSub, ReloadSpritzer
}
return

!#q::
if(lockClose)
{
    ShowTooltipRight("SPRITZER: Closing is locked (unlock with ^x)")
    return
}
ExitApplication:
if(wbnoise)
	wbnoise.Quit
SetTimer, AutoAdvanceSentence, Off
SetTimer, PauseOnEnd, off
SetTimer, DisplaySentence, off
Gosub, SaveCurrentSettings
DllCall("CloseHandle", "uint", hCon)
DllCall("FreeConsole")
Process, Close, %cPid%
ExitApp

SaveCurrentSettings:
GoSub, GetCurrentWord
if(sentenceEnd<>"")
{
	if(spritzSpeed<>"")
	IniWrite, %spritzSpeed%, % A_ScriptDir . "/" . "Spritz.ini", settings,spritzSpeed
	if(ttsSpeed<>"")
	IniWrite, %ttsSpeed%, % A_ScriptDir . "/" . "Spritz.ini", settings,ttsSpeed
	if(ttsPitch<>"")
	IniWrite, %ttsPitch%, % A_ScriptDir . "/" . "Spritz.ini", settings,ttsPitch
	if(ttsVolume<>"")
	IniWrite, %ttsVolume%, % A_ScriptDir . "/" . "Spritz.ini", settings,ttsVolume
	if(ttsVoiceName<>"")
	IniWrite, %ttsVoiceName%, % A_ScriptDir . "/" . "Spritz.ini", settings,ttsVoiceName
	if(SpeakMode<>"")
	IniWrite, %SpeakMode%, % A_ScriptDir . "/" . "Spritz.ini", settings,SpeakMode
	if(DisplaysSentence<>"")
	IniWrite, %DisplaysSentence%, % A_ScriptDir . "/" . "Spritz.ini", settings,DisplaysSentence
	if(AutoAdvanceSentences<>"")
	IniWrite, %AutoAdvanceSentences%, % A_ScriptDir . "/" . "Spritz.ini", settings,AutoAdvanceSentences
	if(HideSpritzer<>"")
	IniWrite, %HideSpritzer%, % A_ScriptDir . "/" . "Spritz.ini", settings,HideSpritzer
	if(IgnoreErrors<>"")
	IniWrite, %IgnoreErrors%, % A_ScriptDir . "/" . "Spritz.ini", settings,IgnoreErrors
	if(KeepOpen<>"")
	IniWrite, %KeepOpen%, % A_ScriptDir . "/" . "Spritz.ini", settings,KeepOpen
	if(FadeOnFocusLost<>"")
	IniWrite, %FadeOnFocusLost%, % A_ScriptDir . "/" . "Spritz.ini", settings,FadeOnFocusLost
	if(NyanCat<>"")
	IniWrite, %NyanCat%, % A_ScriptDir . "/" . "Spritz.ini", settings,NyanCat
	if(MyNoiseUrl<>"")
	IniWrite, %MyNoiseUrl%, % A_ScriptDir . "/" . "Spritz.ini", settings,MyNoiseUrl
	if(InactiveTransparency<>"")
	IniWrite, %InactiveTransparency%, % A_ScriptDir . "/" . "Spritz.ini", settings,InactiveTransparency
	if(clickmode<>"")
	IniWrite, %clickmode%, % A_ScriptDir . "/" . "Spritz.ini", settings,clickmode
	if(clickthrough<>"")
	IniWrite, %clickthrough%, % A_ScriptDir . "/" . "Spritz.ini", settings,clickthrough
	if(transparency<>"")
	IniWrite, %transparency%, % A_ScriptDir . "/" . "Spritz.ini", settings,transparency
	if(whiteNoiseOnPause<>"")
	IniWrite, %whiteNoiseOnPause%, % A_ScriptDir . "/" . "Spritz.ini", settings,whiteNoiseOnPause
    if(lockClose<>"")
	IniWrite, %lockClose%, % A_ScriptDir . "/" . "Spritz.ini", settings,lockClose
	if(file<>"")
	{
		IniWrite, %file%, % A_ScriptDir . "/" . "Spritz.ini", previous,file
		for k, v in recentCommands
		{
			IniWrite, %v%, Spritz.ini, recents,%k%
		}
	}
	if(originalText<>"")
	{
		GoSub, SaveCurrentWord
	}
}
return

GetCurrentWord:
	spritzCommandGetCurrentWord:="var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); var sentenceEnd = SPRITZ_Popup.controller.getSpritzText().getNextSentenceStart(currentIndex+1,1); var wordCount = SPRITZ_Popup.controller.getSpritzText().getWordCount();"
	htmlGUI.Exec(spritzCommandGetCurrentWord)
	currentWord:=htmlGUI.Script.currentIndex
	if(currentWord=0)
		currentWord:=1
	sentenceStart:=htmlGUI.Script.sentenceStart
	sentenceEnd:=htmlGUI.Script.sentenceEnd
	wordCount:=htmlGUI.Script.wordCount
return

SaveCurrentWord:
	GoSub, GetCurrentWord
	if(sentenceEnd<>"")
	{
		IfNotExist, %A_ScriptDir%\texts
			FileCreateDir, %A_ScriptDir%\texts
		FileDelete, %A_ScriptDir%\texts\%currentDocumentName%.txt
		FileAppend, %originalText%, %A_ScriptDir%\texts\%currentDocumentName%.txt
		IniWrite, % sentenceEnd, % A_ScriptDir . "/" . "Spritz.ini", %file%,word
        if(GuiHidden<>"")
            IniWrite, % GuiHidden, % A_ScriptDir . "/" . "Spritz.ini", %file%,hidden
	}
return

removeToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return

#+^SC01B::
if(InactiveTransparency+10<=100)
	InactiveTransparency:=InactiveTransparency+10
WinGet, id, ID, A
SetGuiVisibility(1)
WinActivate, ahk_id %id%
GoSub, UpdateActive
return

#+^-::
if(InactiveTransparency-10>=0)
	InactiveTransparency:=InactiveTransparency-10
WinGet, id, ID, A
SetGuiVisibility(1)
WinActivate, ahk_id %id%
GoSub, UpdateActive
return

+#^!SC01B::
GoSub, PauseSpritzer
if(!SpritzLoaded)
	return
if(!SpeakMode)
	return
if(ttsPitch>=10)
	return
ttsPitch:=ttsPitch+1
GoSub, SetTTSVoice
ShowTooltipRight("Speech pitch: " . ttsPitch, 1000)
GoSub, PlaySpritzer
return

+#^!-::
GoSub, PauseSpritzer
if(!SpritzLoaded)
	return
if(!SpeakMode)
	return
if(ttsPitch<=-10)
	return
ttsPitch:=ttsPitch-1
GoSub, SetTTSVoice
ShowTooltipRight("Speech pitch: " . ttsPitch, 1000)
GoSub, PlaySpritzer
return

#^!SC01B::
GoSub, PauseSpritzer
if(!SpritzLoaded)
	return
if(!SpeakMode || !HideSpritzer){
	if(spritzSpeed>400)
		return
	spritzSpeed:=spritzSpeed+50
	spritzCommandspritzSpeed:="SPRITZ_Popup.setSpeed(" . spritzSpeed . ");"
	htmlGUI.Exec(spritzCommandspritzSpeed)
	ShowTooltipRight("Spritz speed: " . spritzSpeed, 1000)
}
else
{
	if(ttsSpeed>7)
		return
	ttsSpeed:=ttsSpeed+1
	GoSub, SetTTSVoice
	ShowTooltipRight("Speech speed: " . ttsSpeed, 1000)
}
GoSub, PlaySpritzer
return

#^!-::
GoSub, PauseSpritzer
if(!SpritzLoaded)
	return
if(!SpeakMode || !HideSpritzer){
	if(spritzSpeed<=200)
		return
	spritzSpeed:=spritzSpeed-50
	spritzCommandspritzSpeed:="SPRITZ_Popup.setSpeed(" . spritzSpeed . ");"
	htmlGUI.Exec(spritzCommandspritzSpeed)
	ShowTooltipRight("Spritz speed: " . spritzSpeed, 1000)
}
else
{
	if(ttsSpeed<=-4)
		return
	ttsSpeed:=ttsSpeed-1
	GoSub, SetTTSVoice
	ShowTooltipRight("Speech speed: " . ttsSpeed, 1000)
}
GoSub, PlaySpritzer
return

SetTTSVoice:
if(Voice)
	TTSSay("-")
Voice := TTS_CreateVoice(ttsVoiceName,ttsSpeed,,ttsPitch)
return

TrimToCurrentSentence:
GoSub, GetSentence
say:=originalText
say:=TTSCleanText(say)
currentSentence:=TTSCleanText(currentSentence)
currentTextPos:=InStr(say, currentSentence)
while(currentTextPos=0 && Strlen(currentSentence)>0)
{
	currentSentence:=SubStr(currentSentence, 1, StrLen(currentSentence)-1)
	currentTextPos:=InStr(say, currentSentence)
    ;ToolTip, % "Loading...", 0, 0
}
;ToolTip
;ToolTip, %currentSentence% `n %say% `n %currentTextPos%
currentText := SubStr(say, currentTextPos, StrLen(currentSentence))
return

TTSCurrentSentence:
	GoSub, TrimToCurrentSentence
	TTSSay(currentText)
return

#!r::
BackBtn:
if(!SpritzLoaded)
{
    ;ToolTip, % "Loading...", 0, 0
	return
}
;ToolTip
spritzCommandBackBtn:="var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); var sentenceEnd = SPRITZ_Popup.controller.getSpritzText().getNextSentenceStart(currentIndex,1); var wordCount = SPRITZ_Popup.controller.getSpritzText().getWordCount(); "
htmlGUI.Exec(spritzCommandBackBtn)
if(abs(htmlGUI.Script.currentIndex-htmlGUI.Script.sentenceStart)>3)
{
	spritzCommandBackBtn:="SPRITZ_Popup.controller.backBtn.click();"
	htmlGUI.Exec(spritzCommandBackBtn)
	if(htmlGUI.Script.sentenceStart!=0 && htmlGUI.Script.sentenceEnd <> htmlGUI.Script.wordCount)
	{
		Sleep, 100
		spritzCommandBackBtn:="SPRITZ_Popup.controller.forwardBtn.click();"
		htmlGUI.Exec(spritzCommandBackBtn)
	}
}
else
{
	spritzCommandBackBtn:="SPRITZ_Popup.controller.backBtn.click();"
	htmlGUI.Exec(spritzCommandBackBtn)
}

if(SpeakMode){
	if(!pausePerLine)
	{
		GoSub, TTSCurrentSentence
	}
	else
	{
		GoSub, GetSentence
		TTSSay(currentSentence)
	}
}
return

#!f::
ForwardBtn:
if(!SpritzLoaded)
	return
spritzCommandForwardBtn:="var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); var sentenceEnd = SPRITZ_Popup.controller.getSpritzText().getNextSentenceStart(currentIndex+1,1); var wordCount = SPRITZ_Popup.controller.getSpritzText().getWordCount(); "
htmlGUI.Exec(spritzCommandForwardBtn)
;ToolTip, % (htmlGUI.Script.currentIndex+1) . " - " . htmlGUI.Script.wordCount . " " . htmlGUI.Script.sentenceEnd . " - " . htmlGUI.Script.sentenceStart
if(htmlGUI.Script.sentenceEnd<>htmlGUI.Script.wordCount)
{
		spritzCommandForwardBtn:="SPRITZ_Popup.controller.forwardBtn.click();"
		htmlGUI.Exec(spritzCommandForwardBtn)
}
else
{
	if((htmlGUI.Script.currentIndex+1)=htmlGUI.Script.wordCount)
	{
		GoSub, BackBtn
	}
	else
	{
		spritzCommandForwardBtn:="SPRITZ_Popup.controller.backBtn.click();"
		htmlGUI.Exec(spritzCommandForwardBtn)
		spritzCommandForwardBtn:="SPRITZ_Popup.controller.forwardBtn.click();"
		htmlGUI.Exec(spritzCommandForwardBtn)
	}
}
if(SpeakMode){
	if(!pausePerLine)
	{
		GoSub, TTSCurrentSentence
	}
	else
	{
		GoSub, GetSentence
		TTSSay(currentSentence)
	}
}
return

#!p::
TogglePause:
if(!SpritzLoaded)
	return
spritzCommandTogglePause:="SPRITZ_Popup.togglePause();"
htmlGUI.Exec(spritzCommandTogglePause)
if(SpeakMode){
	spritzCommandTogglePause:="var isPaused = SPRITZ_Popup.panel.isPaused();"
	htmlGUI.Exec(spritzCommandTogglePause)
	if(!htmlGUI.Script.isPaused)
	{
		WmpB.controls.pause()
		GoSub, TrimToCurrentSentence
		spritzCommandTogglePause:="var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var currentWord = SPRITZ_Popup.controller.getSpritzText().getWord(currentIndex).word; secondCurrentWord = SPRITZ_Popup.controller.getSpritzText().getWord(currentIndex+1); if(secondCurrentWord){secondCurrentWord = secondCurrentWord.word;}else{secondCurrentWord=''}"
		htmlGUI.Exec(spritzCommandTogglePause)
		if(!pausePerLine)
		{
			currentWordPos:=InStr(currentText, htmlGUI.Script.currentWord . " " . htmlGUI.Script.secondCurrentWord )
			TTSSay(SubStr(currentText, currentWordPos))
		}
		else
		{
			currentWordPos:=InStr(currentSentence, htmlGUI.Script.currentWord . " " . htmlGUI.Script.secondCurrentWord )
			TTSSay(SubStr(currentSentence, currentWordPos))
		}
	}
	else
	{
		TTSSay("")
		if(whiteNoiseOnPause)
			WmpB.controls.play()
	}
}
return

HideSentence:
spritzCommandHideSentence:="$('#sentence').hide(); $('#sentence').html('').width(0).height(0);"
htmlGUI.Exec(spritzCommandHideSentence)
return

DisplaySentence:
GoSub, GetSentence
if(currentSentence<>previousSentence || showByWPress)
{
	if(!showByWPress)
	{
		spritzCommandDisplaySentence:="var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); var sentenceEnd = SPRITZ_Popup.controller.getSpritzText().getNextSentenceStart(currentIndex+1,1); var wordCount = SPRITZ_Popup.controller.getSpritzText().getWordCount();"
		htmlGUI.Exec(spritzCommandDisplaySentence)
		square:=""
		if(htmlGUI.Script.sentenceEnd == htmlGUI.Script.wordCount)
		{
			square:="&#9632;"
		}
		currentSentenceStart:=htmlGUI.Script.sentenceStart
		
		classDiv1:=""
		classDiv2:=""
		if(currentSentenceStart > previousSentenceStart)
		{
			placeholder1:=previousSentence
			placeholder2:=currentSentence
			classDiv2:="currently-reading"
		}
		else
		{
			placeholder2:=previousSentence
			placeholder1:=currentSentence
			classDiv1:="currently-reading"
		}
		StringReplace, placeholder1, placeholder1, `r`n,%A_Space%\`n, All
		StringReplace, placeholder1, placeholder1, `n,%A_Space%\`n, All
		StringReplace, placeholder1, placeholder1, `r,%A_Space%\`n, All
		StringReplace, placeholder1, placeholder1, `',\`', All
		StringReplace, placeholder1, placeholder1, `", \`", All ;"
		
		StringReplace, placeholder2, placeholder2, `r`n,%A_Space%\`n, All
		StringReplace, placeholder2, placeholder2, `n,%A_Space%\`n, All
		StringReplace, placeholder2, placeholder2, `r,%A_Space%\`n, All
		StringReplace, placeholder2, placeholder2, `',\`', All
		StringReplace, placeholder2, placeholder2, `", \`", All ;"
		
		previousSentenceStart:=currentSentenceStart
		previousSentence:=currentSentence
	}
	
	if(LoopCurrentSentence || LoopedBookmark || (abStartPosition && abEndPosition))
	{
		one:=""
		if(abStartPosition && abEndPosition)
			one:="-ab"
		if(LoopCurrentSentence)
			one:="-one"
		if(classDiv1)
			classDiv1:="currently-reading-loop" . one
		if(classDiv2)
			classDiv2:="currently-reading-loop" . one
	}
	else
	{
		if(classDiv1)
			classDiv1:="currently-reading"
		if(classDiv2)
			classDiv2:="currently-reading"
	}
	
	spritzCommandDisplaySentence:="$('#sentence').show(); $('#sentence').html('<div class=" . classDiv1 . ">" . placeholder1 . "</div><hr><div class=" . classDiv2 . ">" . placeholder2 . " " . square . "</div>').width('98%').height('150px');"
	htmlGUI.Exec(spritzCommandDisplaySentence)
	showByWPress:=false
}
return

GetSentence:
spritzCommandGetSentence:="if(!SPRITZ_Popup.controller.getSpritzText()){textLoaded=false;}else{ textLoaded=true;}"
htmlGUI.Exec(spritzCommandGetSentence)
i:=0
while(!htmlGUI.Script.textLoaded)
{
    i++
	htmlGUI.Exec(spritzCommandGetSentence)
	Sleep, 100
    SplitPath, file, filenameLoading
    filenameLoading:="""" . filenameLoading . """"
    ToolTip, % "GetSentence: " . filenameLoading . "...", 0, 0
}
spritzCommandGetSentence:="var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart).word; sentenceStart_temp=sentenceStart+1; sentence = sentenceWord; while(SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp) && !SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).isSentenceStart()){sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).word; sentence = sentence + ' ' + sentenceWord; sentenceStart_temp++;}"
htmlGUI.Exec(spritzCommandGetSentence)
;ToolTip, % "sentence: " . htmlGUI.Script.sentence
currentSentence:=""
testSentence:=RegExReplace(htmlGUI.Script.sentence, "-\s", "-")
testSentence:=RegExReplace(testSentence, "\.[\s\n\r\t]*$", "")
words := StrSplit(testSentence, " ")
Loop % words.MaxIndex()
{
	word:=words[A_Index]
	if(!InStr(originalText, word))
		word:=RegExReplace(word, "-")
	currentSentence := currentSentence . " " . word 
}
currentSentence:=currentSentence . "."
currentSentence:=RegExReplace(currentSentence, "a�", "�")
currentSentence:=RegExReplace(currentSentence, "e�", "�")
currentSentence:=RegExReplace(currentSentence, "i�", "�")
currentSentence:=RegExReplace(currentSentence, "o�", "�")
currentSentence:=RegExReplace(currentSentence, "u�", "�")
currentSentence:=RegExReplace(currentSentence, "�\s", "�")
currentSentence:=RegExReplace(currentSentence, "�\s", "�")
currentSentence:=RegExReplace(currentSentence, "�\s", "�")
currentSentence:=RegExReplace(currentSentence, "�\s", "�")
currentSentence:=RegExReplace(currentSentence, "�\s", "�")
return

;$#i::
SearchCurrentSentence:
SearchingPDF:=1
GoSub, PauseSpritzer
;KeyWait, LWin
BlockInput, on
GoSub, ActivateDocument
Send, ^f
SetKeyDelay, -1
currentSentence:=LTrim(currentSentence)
currentSentence:=RTrim(currentSentence)
currentSearchSentence:=RegExReplace(currentSentence, "([\w\s\-\'\:\""\�\�\,\;]+)[^\w\s\-\'\:\""\�\�\,\;]+.*$", "$1")
Send,{Raw}%currentSearchSentence%
Send, {Enter}
BlockInput, off
return

^#Tab::
	currentDocumentId := GetCurrentDocumentId("A")
	WinGetTitle, currentDocumentTitle, ahk_id %currentDocumentId%
return

^#|::
	currentDocumentId2 := GetCurrentDocumentId("A")
return


$!l::
ClearBookmark:
ShowTooltipRight("Bookmark [B" . LoopedBookmark . "] loop cleared.")
GoSub, ClearLoopedBookmark
return

#If

#|::
ActivateSelf0:
ncurrentDocumentId2:= GetCurrentDocumentId("A")
WinGet, documentProcess, ProcessName, ahk_id %ncurrentDocumentId2%
if(ncurrentDocumentId2<>currentDocumentId && ncurrentDocumentId2<>DllCall("GetCurrentProcessId") && documentProcess<>"Spritz.exe")
	currentDocumentId2 := ncurrentDocumentId2
GoSub, ActivateSelf
return

#If (WinActive("ahk_id " . currentDocumentId))
Tab::
|::
GoSub, ActivateSelf
return

!#l::
GoSub, OpenReadingTextFile
return

^r::
MsgBox, % 3,, Reload text for "%currentDocumentName%" (all bookmarks will be deleted)?
	If ErrorLevel
		return
	IfMsgBox, Cancel
		return
	IfMsgBox, Yes
	{
		textPath:=A_ScriptDir . "/texts/" . currentDocumentName . ".txt"
		FileDelete, %textPath%
		Loop 10
		{
			bookmark_pos_section:="bookmark" . A_Index . "_pos"
			bookmark_title_section:="bookmark" . A_Index . "_title"
			bookmark_loop_section:="bookmark" . A_Index . "_loop"
			IniDelete, Spritz.ini, %file%,%bookmark_pos_section%
			IniDelete, Spritz.ini, %file%,%bookmark_title_section%
			IniDelete, Spritz.ini, %file%,%bookmark_loop_section%
		}
		GoSub, GotoPreviousText
		Reload
	}
return

n::
GoSub, PlayNoiseToggle
return

g::
GotoPhraseFromPDF:
clipboardBkp:=ClipboardAll
nprevious_phrase:=""
Clipboard:=""
Send, ^c
nprevious_phrase=%Clipboard%
if(nprevious_phrase!="")
{
    previous_phrase:=nprevious_phrase
}
Clipboard:=clipboardBkp
if(nprevious_phrase!="")
{
    if(A_ThisHotKey="a")
        Gosub, ClearAPosition
    if(A_ThisHotKey="z")
        Gosub, ClearZPosition
        
    GoSub, GotoPhrase
    GoSub, GetCurrentWord
    
    ;if(A_ThisHotKey="a" || A_ThisHotKey="z")
    ;{
        if(LoopCurrentSentence)
            GoSub, ToggleLoopCurrentSentence
        if(LoopedBookmarkEndPosition && LoopedBookmarkEndPosition<sentenceEnd)
        {
            GoSub ClearLoopedBookmark
            ;GoSub, GetCurrentBookmark
            ;LoopBookmarkByKey:=1
            ;GoSub, LoopBookmark
        }
        if(abEndPosition && abEndPosition<sentenceEnd)
            Gosub, ClearZPosition
    ;}
}
;GoSub, ActivateSelf0
return

a::
GoSub, GotoPhraseFromPDF
GoSub, ToggleAPosition
return

z::
GoSub, GetCurrentWord
prevSentenceEnd:=sentenceEnd
GoSub, GotoPhraseFromPDF
GoSub, ToggleZPosition
previousWord:=prevSentenceEnd
GoSub, GotoPreviousWord
return

^a::
GoSub, GotoA
GoSub, ActivateSelf0
return

^z::
GoSub, GotoZ
GoSub, ActivateSelf0
return

^!a::
Send, ^a
return

b::
GoSub, SetBookmarkByKey
return

Left::
GoSub, GotoPreviousSentence
return

Right::
GoSub, GotoNextSentence
return

Space::
GoSub, TogglePause
return

!Left::
GoSub, GotoPreviousBookmark
return

!Right::
GoSub, GotoNextBookmark
return

l::
GoSub, ActivateLoop
return

!l::
GoSub, ClearBookmark
return

r::
GoSub, ToggleLoopCurrentSentence
return

^g::
GoSub, SearchSentenceInDocument
return

;#IfWinNotActive ahk_exe Spritz.exe

#If (WinActive("ahk_pid " . DllCall("GetCurrentProcessId")) && WinActive("ahk_class #32770"))
$Esc::
	; ControlClick, Button2, A
	WinClose, A
return

#If (WinActive("ahk_pid " . DllCall("GetCurrentProcessId")) && !WinActive("ahk_class #32770"))

^g::
GoSub, ActivateDocument
SearchSentenceInDocument:
Send, ^f
GoSub, GetSentence
clipboardBkp:=ClipboardAll
Clipboard=%currentSentence%
Send, ^v
Clipboard:=clipboardBkp
return

$#s::
if(GrabText)
	GrabText:=0
else
	GrabText:=1
ShowTooltipRight("Grab Text: " . (GrabText?"On":"Off"), 1000)
return

$r::
	GoSub, ToggleLoopCurrentSentence
return

$x::
GoSub, ToggleClickMode
return

$|::
	WinActivate, ahk_id %currentDocumentId2%
return

$Tab::
WinGet, documentProcess, ProcessName, ahk_id %currentDocumentId%
if(!WinExist("ahk_id " . currentDocumentId) || (documentProcess="chrome.exe" && !JEE_ChromeTabExists(currentDocumentId, RegExReplace(currentDocumentTitle, " - Google Chrome"))))
	GoSub, OpenFile
ActivateDocument:
	WinActivate, ahk_id %currentDocumentId%
	WinGetTitle, title, ahk_id %currentDocumentId%
	WinGet, documentProcess, ProcessName, ahk_id %currentDocumentId%
	WinWaitActive, ahk_id %currentDocumentId%
	if(documentProcess="chrome.exe")
	{
		JEE_ChromeFocusTabByName(currentDocumentId, RegExReplace(currentDocumentTitle, " - Google Chrome"))
	}
return
$i::
	GoSub, SearchCurrentSentence
return
^f::
	KeyWait, Control
	KeyWait, f
	GoSub, ActivateDocument
	Send, ^f
return
$Shift::
If ( A_PriorHotKey = A_ThisHotKey && A_TimeSincePriorHotkey < 2000 ) {
	GoSub, ToggleSpeakDisplaySentence
}
return

^c::
;if(!pausePerLine)
;{
;	Clipboard=%originalText%
;}
;else
{
	GoSub, GetSentence
	Clipboard=%currentSentence%
}
return

!#l::
OpenReadingTextFile:
textPath:=A_ScriptDir . "/texts/" . currentDocumentName . ".txt"
if(FileExist(textPath))
    Run, "C:\Program Files (x86)\Microsoft VS Code\Code.exe" "%textPath%"
return

HideAndPause:
SetGuiVisibility(0)
GoSub, PauseSpritzer
return

ShowAndPlay:
SetGuiVisibility(1)
GoSub, PlaySpritzer
return

$#1::
path:=recentCommands[1]
Run, Spritz.exe "%path%"
return

$#2::
path:=recentCommands[2]
Run, Spritz.exe "%path%"
return

$#3::
path:=recentCommands[3]
Run, Spritz.exe "%path%"
return

$#4::
path:=recentCommands[4]
Run, Spritz.exe "%path%"
return

$#5::
path:=recentCommands[5]
Run, Spritz.exe "%path%"
return

$^|::
newRecentCommands:=[]
i:=1
for k, v in recentCommands
{
	if(currentRecentIndex<>k)
	{
		newRecentCommands.Push(v)
		i:=i+1
	}
}
newRecentCommands.InsertAt(1, recentCommands[currentRecentIndex])
recentCommands:=newRecentCommands
Reload
return

$o::
DetectHiddenWindows, On
CoordMode, Menu, Screen
Menu Tray, Show, 0, 0
return

$q::
$Esc::
if(play_NYAN)
{
	GoSub, PlayNoiseToggle
	return
}
if(lockClose)
{
    ShowTooltipRight("SPRITZER: Closing is locked (unlock with ^x)")
    return
}
if(KeepOpen)
{
	GoSub, HideAndPause
	return
}
GoSub, ExitApplication
return
;$r::
$Left::
GotoPreviousSentence:
if(!AutoAdvanceSentences)
{
	pausePerLine:=0
	GoSub, BackBtn
}
else
{
	GoSub, ReadPreviousSentence
}
return
;$f::
$Right::
GotoNextSentence:
if(!AutoAdvanceSentences)
{
	pausePerLine:=0
	GoSub, ForwardBtn
}
else
{
	GoSub, ReadNextSentence
}
return

;$Up::
;GoSub, ReadPreviousSentence
;return
;$Down::
;GoSub, ReadNextSentence

$Space::
$p::
GoSub, TogglePause
return

EnableClickThrough:
if(transparency<>3)
{
	clickmode:=0
	clickthrough:=1
}
else
{
	clickthrough:=0
}
GoSub, ChangeClickMode
GoSub, ChangeClickThrough
return

+SC01B::
IncreaseTransparency:
if(transparency=2)
	transparency=3
if(transparency=1)
	transparency=2
if(transparency=0.75)
	transparency=1
if(transparency=0.60)
	transparency=0.75
GoSub, EnableClickThrough
return

+-::
DecreaseTransparency:
if(transparency=0.75)
	transparency=0.60
if(transparency=1)
	transparency=0.75
if(transparency=2)
	transparency=1
if(transparency=3)
	transparency=2
GoSub, EnableClickThrough
return

$t::
ViewTitle:
ShowTooltipRight("-")
GoSub, GetTitleFromFile
title0:=currentDocumentTitle
GoSub, GetCurrentBookmark
if(pressed_number>0)
{
	title0:=currentDocumentTitle . "`n" . GetBookmarkTitle(pressed_number)
}
ShowTooltipRight(title0, 5000)
return

ShowTooltipRight(text, timeout=3000){
	global tW
	global tH
	global hGUI1
	global previousTooltipText
	
	if(previousTooltipText=text)
	{
		SetTimer, RemoveToolTip, %timeout%
		if(WinExist("ahk_class tooltips_class32 Ahk_PID " . DllCall("GetCurrentProcessId")))
			return
	}
	
	CalculateToolTipDisplayRight(text)
	CoordMode, ToolTip, Screen
	DetectHiddenWindows, off
	ThisScriptsHWND := WinExist("Ahk_PID " DllCall("GetCurrentProcessId"))
	WinGetPos, Xt, Yt, Wt, , % "ahk_id " . ThisScriptsHWND
	;toolTipX:=Xt+Wt-tW
	;x_position:=0+SubStr(StrSplit(gui_position, A_Space)[1],2)
	WinGetPos, gui_x, gui_y,,, ahk_id %hGUI1%
	toolTipX:=gui_x+A_ScreenWidth/2+320-tW
	toolTipY:=Yt-tH
    if(toolTipX="" || toolTipY="")
    {
        toolTipX:=0
        toolTipY:=0
    }
	ToolTip, %text%, %toolTipX%, %toolTipY%
	previousTooltipText:=text
	SetTimer, RemoveToolTip, %timeout%
}

CalculateToolTipDisplayRight(CData) {
	global tW
	global tH
	CoordMode, ToolTip, Screen
	ToolTip, %CData%,,A_ScreenHeight+100
	thisId:=WinExist()
	WinGetPos,,, tW, tH, ahk_class tooltips_class32 ahk_exe Spritz.exe
	ToolTip
	Return
}

$d::
spritzCommandHtml:="htmlSpritzer = document.documentElement.innerHTML;"
htmlGUI.Exec(spritzCommandHtml)
Clipboard:=htmlGUI.Script.htmlSpritzer
return
$s::
	GoSub, ToggleSpritzer
return
$m::
$^m::
	IniRead, gui_position, % A_ScriptDir . "/" . "Spritz.ini", window position, gui_position, x0 y0
	;gui_position:="x0 y0"
	SetGuiVisibility(1)
return
$h::
	GoSub, ToggleGuiVisibility
return
$n::
PlayNoiseToggle:
if(!NyanCat)
{
	if(!wbnoise)
	{
		wbnoise := ComObjCreate("InternetExplorer.Application")
		wbnoise.visible := False
		wbnoise.Navigate("")
	}
	ToolTip, % wbnoise.LocationURL
	if(wbnoise.LocationURL<>"http:///" && wbnoise.LocationURL<>"http://localhost/")
	{
		GoSub, PlaySpritzer
		GoSub, ActivateDocument
		wbnoise.Navigate("http://localhost")
		wbnoise.Stop
		while wbnoise.busy
		{
			ToolTip, Stopping Sound
			sleep 100
		}
		ToolTip
	}
	else
	{
		GoSub, PauseSpritzer
		wbnoise.Navigate(MyNoiseUrl)
		while wbnoise.busy
		{
			ToolTip, Loading Sound
			sleep 100
		}
		ToolTip
	}
}
else
{
	play_NYAN:=!play_NYAN
	if(!play_NYAN)
	{
		GoSub, PlaySpritzer
		GoSub, ActivateDocument
		Wmp.controls.stop()
		Gui Wmp: Hide
	}
	else
	{
		GoSub, PauseSpritzer
		if(!hNYAN)
		{
			Gui Wmp: New,  +OwnDialogs hWndhNYAN
			Gui Wmp: Add, ActiveX, w10 h10 vWmp, WMPLayer.OCX
			Wmp.Url := A_ScriptDir . "/nyan_cat.mp4"
			wmp.settings.setmode("loop",1)
			Wmp.settings.volume := 100
			wmp.settings.rate:=2
			wmp.uimode := "none"
		}
		Wmp.controls.play()
		playState:=Wmp.playState
		while(playState<>3)
		{
			Sleep, 10
			playState:=Wmp.playState
		}
		Gui Wmp: Show, Maximize
		wmp.fullscreen := "true"
	}
}
return

ClearAPosition:
abStartPosition:=0
if(!abEndPosition)
    SetTimer, ReturnToAB, Off
GoSub, ShowABStatus
SoundPlay, %A_WinDir%\Media\ding.wav
return

$a::
ToggleAPosition:
	if(abStartPosition)
	{
		GoSub, ClearAPosition
	}
	else
	{
		GoSub, GetCurrentWord
		if(!abEndPosition || abEndPosition>=sentenceEnd)
		{
			abStartPosition:=sentenceEnd
			SoundPlay, %A_WinDir%\Media\ding.wav
		}
		SetTimer, ReturnToAB, 100
		showByWPress:=true
		GoSub, ChangeDisplaySentence
	}
return

$^a::
GotoA:
	if(abStartPosition)
	{
		previousWord:=abStartPosition
		GoSub, GotoPreviousWord
		SoundPlay, %A_WinDir%\Media\ding.wav
	}
return

ClearZPosition:
abEndPosition := 0
if(!abStartPosition)
    SetTimer, ReturnToAB, Off
GoSub, ShowABStatus
SoundPlay, %A_WinDir%\Media\ding.wav
return

$z::
ToggleZPosition:
	if(abEndPosition)
	{
		GoSub, ClearZPosition
	}
	else
	{
		GoSub, GetCurrentWord
		if(!abStartPosition || abStartPosition<sentenceEnd)
		{
			abEndPosition:=sentenceEnd
			SoundPlay, %A_WinDir%\Media\ding.wav
		}
		SetTimer, ReturnToAB, 100
		showByWPress:=true
		GoSub, ChangeDisplaySentence
	}
return

$^z::
GotoZ:
	if(abEndPosition)
	{
		previousWord:=abEndPosition
		GoSub, GotoPreviousWord
		SoundPlay, %A_WinDir%\Media\ding.wav
	}
return

$+a::
ShowABStatus:
	if(abStartPosition && abEndPosition)
    {
        if(LoopCurrentSentence)
            ShowTooltipRight("A-Z ON + LOOP CURRENT")
        else
            ShowTooltipRight("A-Z ON")
    }
	else
	{
		if(abStartPosition || abEndPosition)
		{
			if(abStartPosition)
            {
                if(LoopCurrentSentence)
                    ShowTooltipRight("A-X ON + LOOP CURRENT")
                else
                    ShowTooltipRight("A-X SET")
            }
			if(abEndPosition)
            {
                if(LoopCurrentSentence)
                    ShowTooltipRight("X-Z ON + LOOP CURRENT")
                else
                    ShowTooltipRight("X-Z SET")
            }
		}
		else
		{
			ShowTooltipRight("X-X OFF", 5000)
			SetTimer, ReturnToAB, Off
		}
	}
return

ReturnToAB:
GoSub, GetCurrentWord
if(abEndPosition && abEndPosition<sentenceEnd && abStartPosition)
{
	previousWord:=abStartPosition
	GoSub, GotoPreviousWord
	SoundPlay, %A_WinDir%\Media\ding.wav
}
GoSub, ShowABStatus
return

$^x::
ToggleLockClose:
	lockClose:=!lockClose
	if(lockClose)
		ShowTooltipRight("LockClose: ON")
	else
		ShowTooltipRight("LockClose: OFF")
return

$^w::
ToggleWhiteNoiseOnPause:
	whiteNoiseOnPause:=!whiteNoiseOnPause
	if(whiteNoiseOnPause)
		ShowTooltipRight("WhiteNoiseOnPause: ON")
	else
		ShowTooltipRight("WhiteNoiseOnPause: OFF")
	GoSub, CheckWhiteNoiseOnPause
return

CheckWhiteNoiseOnPause:
	spritzCommandspritzCommandHtml:="var isPaused = SPRITZ_Popup.panel.isPaused();"
	htmlGUI.Exec(spritzCommandspritzCommandHtml)
	if(!htmlGUI.Script.isPaused || !whiteNoiseOnPause)
	{
		WmpB.controls.pause()
	}
	else
	{
		WmpB.controls.play()
	}
return

$w::
showByWPress:=true
GoSub, ToggleSpeakDisplaySentence
return

ToggleLoopCurrentSentence:
LoopCurrentSentence:=!LoopCurrentSentence
ShowTooltipRight("Loop current sentence: " . LoopCurrentSentence)
showByWPress:=true
GoSub, ChangeDisplaySentence
return

$^!1::
$^!2::
$^!3::
$^!4::
$^!5::
$^!6::
$^!7::
$^!8::
$^!9::
$^!0::
if(InStr(A_ThisHotkey,"1"))
	pressed_number:=1
if(InStr(A_ThisHotkey,"2"))
	pressed_number:=2
if(InStr(A_ThisHotkey,"3"))
	pressed_number:=3
if(InStr(A_ThisHotkey,"4"))
	pressed_number:=4
if(InStr(A_ThisHotkey,"5"))
	pressed_number:=5
if(InStr(A_ThisHotkey,"6"))
	pressed_number:=6
if(InStr(A_ThisHotkey,"7"))
	pressed_number:=7
if(InStr(A_ThisHotkey,"8"))
	pressed_number:=8
if(InStr(A_ThisHotkey,"9"))
	pressed_number:=9
if(InStr(A_ThisHotkey,"0"))
{
	InputBox, pressed_number, Enter a bookmark number, , , 400, 100, , , , ,10
    If ErrorLevel
        return
    if !(pressed_number is number)
        return
}
bookmark_pos_section:="bookmark" . pressed_number . "_pos"
bookmark_title_section:="bookmark" . pressed_number . "_title"
bookmark_loop_section:="bookmark" . pressed_number . "_loop"
IniRead, actual_constant, Spritz.ini, %file%,%bookmark_pos_section%,0
if(actual_constant<>0)
{
	IniRead, bookmark_title, Spritz.ini, %file%,%bookmark_title_section%,
	MsgBox, 1,,DELETE bookmark "%bookmark_title% [B%pressed_number%]" bookmark? (Yes or No)
	IfMsgBox Cancel
		return
	IniDelete, Spritz.ini, %file%,%bookmark_pos_section%
	IniDelete, Spritz.ini, %file%,%bookmark_title_section%
	IniDelete, Spritz.ini, %file%,%bookmark_loop_section%
}
else
{
	ShowTooltipRight("No bookmark [B" . pressed_number . "] found.")
}
return

$!1::
$!2::
$!3::
$!4::
$!5::
$!6::
$!7::
$!8::
$!9::
$!0::
if(InStr(A_ThisHotkey,"1"))
	pressed_number:=1
if(InStr(A_ThisHotkey,"2"))
	pressed_number:=2
if(InStr(A_ThisHotkey,"3"))
	pressed_number:=3
if(InStr(A_ThisHotkey,"4"))
	pressed_number:=4
if(InStr(A_ThisHotkey,"5"))
	pressed_number:=5
if(InStr(A_ThisHotkey,"6"))
	pressed_number:=6
if(InStr(A_ThisHotkey,"7"))
	pressed_number:=7
if(InStr(A_ThisHotkey,"8"))
	pressed_number:=8
if(InStr(A_ThisHotkey,"9"))
	pressed_number:=9
if(InStr(A_ThisHotkey,"0"))
{
	InputBox, pressed_number, Enter a bookmark number, , , 400, 100, , , , ,10
    If ErrorLevel
        return
    if !(pressed_number is number)
        return
}
LoopBookmarkByKey:=1
LoopBookmark:
if (pressed_number<0)
	return
GoSub, GetCurrentWord
actual_constant:=sentenceEnd
bookmark_pos_section:="bookmark" . pressed_number . "_pos"
bookmark_title_section:="bookmark" . pressed_number . "_title"
bookmark_loop_section:="bookmark" . pressed_number . "_loop"
IniRead, bookmark_position, Spritz.ini, %file%,%bookmark_pos_section%,0
IniRead, UserInput, Spritz.ini, %file%,%bookmark_title_section%
IniRead, bookmark_loop_end, Spritz.ini, %file%,%bookmark_loop_section%,0
if(actual_constant>=bookmark_position || !LoopBookmarkByKey)
{
	if(LoopBookmarkByKey)
	{
		if(bookmark_loop_end>0)
		{
			if(UserInput="Error")
				UserInput:="Start"
			update_loop_duration_flag:=0
			MsgBox, % 3,, Use previous loop duration for "%UserInput% [B%pressed_number%]"?
			IfMsgBox, Cancel
				return
			IfMsgBox No
			{
				update_loop_duration_flag:=1
			}
			if(update_loop_duration_flag)
			{
				bookmark_loop_end:=actual_constant
				IniWrite, %bookmark_loop_end%, Spritz.ini, %file%,%bookmark_loop_section%
			}
		}
		else
		{
			bookmark_pos_section2:="bookmark" . (pressed_number+1) . "_pos"
			IniRead, bookmark_loop_end2, Spritz.ini, %file%,%bookmark_pos_section2%,0
			if(bookmark_loop_end2>0)
				bookmark_loop_end:=bookmark_loop_end2-1
			else
				bookmark_loop_end:=actual_constant
			IniWrite, %bookmark_loop_end%, Spritz.ini, %file%,%bookmark_loop_section%
		}
		if(GetKeyState("Alt","P") || GetKeyState("Control","P"))
			GoSub, SelectBookmark
	}
	LoopedBookmarkEndPosition:=bookmark_loop_end
	LoopedBookmark:=pressed_number
	IniWrite, %LoopedBookmark%, Spritz.ini, %file%,looping
	LoopCurrentSentence:=0
	loop_bookmark_title:="LOOP " . UserInput . " [B" . pressed_number . "]."
	ShowTooltipRight(loop_bookmark_title)
	showByWPress:=true
	GoSub, ChangeDisplaySentence
}
else
	ShowTooltipRight("Bookmark " . UserInput . " [B" . pressed_number . "] starts after actual position.")
LoopBookmarkByKey:=0
return

ClearLoopedBookmark:
LoopCurrentSentence:=0
LoopedBookmarkEndPosition:=0
LoopedBookmark:=0
loop_bookmark_title:=""
IniDelete, Spritz.ini, %file%,looping
showByWPress:=true
GoSub, ChangeDisplaySentence
return

GetCurrentBookmark:
	GoSub, GetCurrentWord
	actual_constant:=sentenceEnd+1
	GoSub, GetSurroundingBookmarks
	most_recent_selected_bookmark_number:=prev_bookmark
	pressed_number:=most_recent_selected_bookmark_number
return

$l::
ActivateLoop:
	if(!LoopedBookmark)
	{
		if(LoopCurrentSentence)
		{
			Gosub, ToggleLoopCurrentSentence
		}
		GoSub, GetCurrentBookmark
		LoopBookmarkByKey:=1
		GoSub, LoopBookmark
	}
	else
	{
		Gosub, ToggleLoopCurrentSentence
		showByWPress:=true
		GoSub, ChangeDisplaySentence
	}
return

$^b::
if(!most_recent_selected_bookmark_number || most_recent_selected_bookmark_number=-1)
{
	GoSub, GetCurrentWord
	actual_constant:=sentenceEnd
	GoSub, GetSurroundingBookmarks
	most_recent_selected_bookmark_number:=prev_bookmark
}
pressed_number:=most_recent_selected_bookmark_number
GoSub, SelectBookmark
return

$b::
SetBookmarkByKey:
GoSub, GetCurrentWord
bookmarkPosition:=sentenceEnd
if(abStartPosition && abEndPosition)
{
	MsgBox, % 3,, Set bookmark to current loop?
	IfMsgBox, Cancel
		return
	IfMsgBox, Yes
	{
		previousWord:=abStartPosition
		GoSub, GotoPreviousWord
		pressed_number:=20
		GoSub, SetBookmark
		if(BookmarkWasSet)
		{
			previousWord:=abEndPosition
			GoSub, GotoPreviousWord
			GoSub, LoopBookmark
			abStartPosition:=0
			abEndPosition:=0
			GoSub, ShowABStatus
		}
		else
			return
	}
	IfMsgBox, No
	{
		previousWord:=bookmarkPosition
		GoSub, GotoPreviousWord
		pressed_number:=20
		GoSub, SetBookmark
	}
}
else
{
	pressed_number:=20
	GoSub, SetBookmark
}
return

$^1::
$^2::
$^3::
$^4::
$^5::
$^6::
$^7::
$^8::
$^9::
$^0::
if(InStr(A_ThisHotkey,"1"))
	pressed_number:=1
if(InStr(A_ThisHotkey,"2"))
	pressed_number:=2
if(InStr(A_ThisHotkey,"3"))
	pressed_number:=3
if(InStr(A_ThisHotkey,"4"))
	pressed_number:=4
if(InStr(A_ThisHotkey,"5"))
	pressed_number:=5
if(InStr(A_ThisHotkey,"6"))
	pressed_number:=6
if(InStr(A_ThisHotkey,"7"))
	pressed_number:=7
if(InStr(A_ThisHotkey,"8"))
	pressed_number:=8
if(InStr(A_ThisHotkey,"9"))
	pressed_number:=9
if(InStr(A_ThisHotkey,"0"))
{
	InputBox, pressed_number, Enter a bookmark number, , , 400, 100, , , , ,10
    If ErrorLevel
        return
    if !(pressed_number is number)
        return
}
SetBookmark:
GoSub, GetCurrentWord
actual_constant:=sentenceEnd
bookmark_pos_section:="bookmark" . pressed_number . "_pos"
bookmark_title_section:="bookmark" . pressed_number . "_title"
IniRead, UserInput, Spritz.ini, %file%,%bookmark_title_section%
previous_title:=""
GoSub, GetSentence
previous_title:=currentSentence
previous_title:=GetCammelCase(previous_title)
if(UserInput<>"" && UserInput<>"ERROR")
{
	MsgBox, 1,,Overwrite "%UserInput% [B%pressed_number%]" bookmark? (Yes or No)
	IfMsgBox Cancel
		return
	previous_title:=UserInput
}
else
{
	min_occupied:=pressed_number
	max := pressed_number
	while (--max)
	{
		bookmark_title_section2:="bookmark" . max . "_title"
		IniRead, UserInput2, Spritz.ini, %file%,%bookmark_title_section2%
		if(UserInput2="" || UserInput2="ERROR")
			min_occupied:=max
	}
	if(min_occupied<>pressed_number) 
		MsgBox, 3,,"[B%min_occupied%]" is also empty, do you want to use it? (Yes or No)
			IfMsgBox Cancel
				return
			IfMsgBox Yes
			{
				pressed_number:=min_occupied
				bookmark_pos_section:="bookmark" . pressed_number . "_pos"
				bookmark_title_section:="bookmark" . pressed_number . "_title"
			}
}
InputBox, UserInput, Bookmark %pressed_number% title, , , 400, 100, , , , ,%previous_title%
If ErrorLevel
	return
IniWrite, %actual_constant%, Spritz.ini, %file%,%bookmark_pos_section%
IniWrite, %UserInput%, Spritz.ini, %file%,%bookmark_title_section%
return

GetCammelCase(str){
	output:=""
	Loop, parse, str, %A_Space%, %A_Space%%A_Tab%
	{
		word:=A_LoopField
		If (word <> "los" and word <> "el" and word <> "la" and word <> "las" and word <> "de" and word <> "del" and word <> "por" and word <> "del" and word <> "con" and word <> "al" and word <> "a" and word <> "un" and word <> "y" and word <> "u" and word <> "e" and word <> "y/o"  and word <> "para" and word <> "en" and word <> "and" and word <> "of" and word <> "the" and word <> "with" and word <> "or" and word <> "for") 
			StringUpper, word, word, T 
		Else
			StringLower, word, word
		output = %output% %word% 
	}
	return LTrim(RTrim(output))
}

$1::
$2::
$3::
$4::
$5::
$6::
$7::
$8::
$9::
$0::
if(InStr(A_ThisHotkey,"1"))
	pressed_number:=1
if(InStr(A_ThisHotkey,"2"))
	pressed_number:=2
if(InStr(A_ThisHotkey,"3"))
	pressed_number:=3
if(InStr(A_ThisHotkey,"4"))
	pressed_number:=4
if(InStr(A_ThisHotkey,"5"))
	pressed_number:=5
if(InStr(A_ThisHotkey,"6"))
	pressed_number:=6
if(InStr(A_ThisHotkey,"7"))
	pressed_number:=7
if(InStr(A_ThisHotkey,"8"))
	pressed_number:=8
if(InStr(A_ThisHotkey,"9"))
	pressed_number:=9
if(InStr(A_ThisHotkey,"0"))
{
	InputBox, pressed_number, Enter a bookmark number, , , 400, 100, , , , ,10
    If ErrorLevel
        return
    if !(pressed_number is number)
        return
}
SelectBookmarkByKey:=1
SelectBookmark:
bookmark_pos_section:="bookmark" . pressed_number . "_pos"
IniRead, actual_constant, Spritz.ini, %file%,%bookmark_pos_section%,0
if(actual_constant<>0)
{
	previousWord:=actual_constant
	GoSub, GotoPreviousWord
	if(GetKeyState("Control","P"))
	{
		GoSub, GetCurrentWord
		previousWord:=sentenceStart-1
		GoSub, GotoPreviousWord
	}
	if(SelectBookmarkByKey)
	{
		most_recent_selected_bookmark_number:=pressed_number
	}
	ShowTooltipRight(GetBookmarkTitle(pressed_number))
}
else
{
	ShowTooltipRight("No bookmark [B" . pressed_number . "] found.")
}
SelectBookmarkByKey:=0
return

GetBookmarkTitle(pressed_number)
{
	global file
	global LoopedBookmark
	bookmark_title_section:="bookmark" . pressed_number . "_title"
	bookmark_loop_section:="bookmark" . pressed_number . "_loop"
	IniRead, bookmark_loop_end, Spritz.ini, %file%,%bookmark_loop_section%,0
	IniRead, bookmark_title, Spritz.ini, %file%,%bookmark_title_section%,
	return (bookmark_title . " [B" . pressed_number .  "]" . (bookmark_loop_end<>0?" [" . (LoopedBookmark==pressed_number?Chr("0x24C1"):"L") . "]":""))
}

;$#|::
$!|::
$^!|::
ShowStatus:
loop_bookmark_title:=""
selected_bookmark_title:=""
prev_bookmark_title:=""
next_bookmark_title:=""
if(LoopedBookmark)
{
	pressed_number:=LoopedBookmark
	bookmark_title_section:="bookmark" . pressed_number . "_title"
	IniRead, UserInput, Spritz.ini, %file%,%bookmark_title_section%
	loop_bookmark_title:="LOOP " . UserInput . " [B" . pressed_number . "]."
}
if(most_recent_selected_bookmark_number)
{
	pressed_number:=most_recent_selected_bookmark_number
	bookmark_title_section:="bookmark" . pressed_number . "_title"
	IniRead, UserInput, Spritz.ini, %file%,%bookmark_title_section%
	selected_bookmark_title:="SELEC " . UserInput . " [B" . pressed_number . "]."
}
GoSub, GetCurrentWord
actual_constant:=sentenceEnd+1
GoSub, GetSurroundingBookmarks
if(prev_bookmark)
{
	pressed_number:=prev_bookmark
	bookmark_title_section:="bookmark" . pressed_number . "_title"
	IniRead, UserInput, Spritz.ini, %file%,%bookmark_title_section%
	prev_bookmark_title:="PREV " . UserInput . " [B" . pressed_number . "]."
}
if(next_bookmark)
{
	pressed_number:=next_bookmark
	bookmark_title_section:="bookmark" . pressed_number . "_title"
	IniRead, UserInput, Spritz.ini, %file%,%bookmark_title_section%
	next_bookmark_title:="NEXT " . UserInput . " [B" . pressed_number . "]."
}

bookmark_show_title:=""
if(loop_bookmark_title)
	bookmark_show_title:=loop_bookmark_title
if(selected_bookmark_title)
{
	if(bookmark_show_title<>"")
		bookmark_show_title:=bookmark_show_title . "`n"
	bookmark_show_title:=bookmark_show_title . selected_bookmark_title
}
if(prev_bookmark_title)
{
	if(bookmark_show_title<>"")
		bookmark_show_title:=bookmark_show_title . "`n" . "`n"
	bookmark_show_title:=bookmark_show_title . prev_bookmark_title
}
if(next_bookmark_title && prev_bookmark<>next_bookmark)
{
	if(bookmark_show_title<>"")
		bookmark_show_title:=bookmark_show_title . "`n"
	bookmark_show_title:=bookmark_show_title . next_bookmark_title
}
if(bookmark_show_title="")
	ShowTooltipRight("No bookmark selected.")
else
	ShowTooltipRight(bookmark_show_title, 5000)
return

$+|::
GoSub, GetBookmarkList
ShowTooltipRight(bookmarkList, 60000)
return

ZeroPadding(S, num)
{
	Loop, % num-StrLen(S)
		S = 0%S%
	return S
}

GetBookmarkList:
bookmarkList:=""
IniRead, bookmarksSection, Spritz.ini, %file%
Loop,Parse,bookmarksSection,`n,`r
{
	bookmarkItemKey:=LTrim(RTrim(StrSplit(A_LoopField, "=")[1]))
	bookmarkItemValue:=LTrim(RTrim(StrSplit(A_LoopField, "=")[2]))
	if(InStr(bookmarkItemKey, "bookmark") && InStr(bookmarkItemKey, "title"))
	{
		bookmark_number:=SubStr(bookmarkItemKey, 9, 1)
		if(bookmark_number is number)
		{
			second_digit:=SubStr(bookmarkItemKey, 10, 1)
			if second_digit is number
				bookmark_number:=bookmark_number*10+second_digit
		}
		bookmark_pos_section:="bookmark" . bookmark_number . "_pos"
		IniRead, bookmark_position, Spritz.ini, %file%,%bookmark_pos_section%,0
		bookmark_loop_section:="bookmark" . bookmark_number . "_loop"
		bookmark_loop_end=0
		IniRead, bookmark_loop_end, Spritz.ini, %file%,%bookmark_loop_section%,0
		bookmarkList:=bookmarkList . "[B" . bookmark_number . " " . ZeroPadding(Round(bookmark_position), 6) . "] " . bookmarkItemValue . (bookmark_loop_end<>0?" [L]":"") . "`n"
	}
}
sort, bookmarkList, fSortByPos
return

SortByPos(a1, a2){
	a1 := 0+RegExReplace(a1, ".* ([\d]+)\].*$", "$1"), a2 := 0+RegExReplace(a2, ".* ([\d]+)\].*$", "$1")
	;msgbox, %a1%
	return a1 > a2 ? 1 : a1 < a2 ? -1 : 0
}

GetSurroundingBookmarks:
GoSub, GetBookmarkList
bookmarkList:=bookmarkList . "[C" . " " . ZeroPadding(Round(actual_constant), 6) . "] actual `n"
sort, bookmarkList, fSortByPos
current_position_found:=0
prev_bookmark:=-1
next_bookmark:=-1
bookmark_number:=-1
bookmark_regex:=".*\[B([\d]+).*\].*"
Loop,Parse,bookmarkList,`n,`r
{
	if(!current_position_found)
	{
		if(RegExMatch(A_LoopField, bookmark_regex))
		{
			bookmark_number:=RegExReplace(A_LoopField, bookmark_regex, "$1")
			if(bookmark_number=0)
				bookmark_number:=20
		}
		else
		{
			current_position_found:=1
			prev_bookmark:=bookmark_number
		}
	}
	else
	{
		if(RegExMatch(A_LoopField, bookmark_regex))
		{
			bookmark_number:=RegExReplace(A_LoopField, bookmark_regex, "$1")
			if(bookmark_number=0)
				bookmark_number:=20
		}
		next_bookmark:=bookmark_number
		break
	}
}
return

$^!Left::
$!Left::
GotoPreviousBookmark:
GoSub, GetCurrentWord
actual_constant:=sentenceStart-1
GoSub, GetSurroundingBookmarks
if(prev_bookmark>0)
{
	pressed_number:=prev_bookmark
	GoSub, SelectBookmark
}
else
{
	previousWord:=1
	GoSub, GotoPreviousWord
}
return

$^!Right::
$!Right::
GotoNextBookmark:
GoSub, GetCurrentWord
actual_constant:=sentenceEnd+1
GoSub, GetSurroundingBookmarks
pressed_number:=next_bookmark
GoSub, SelectBookmark
return

g::
InputBox, previous_phrase, Goto phrase, , , 400, 100, , , , ,%previous_phrase%
previous_phrase:=LTrim(RTrim(previous_phrase))
If(ErrorLevel || !previous_phrase)
	return
GotoPhrase:
GoSub, GetCurrentWord
previous_phrase_position:=InStr(originalText,previous_phrase)
if(previous_phrase_position>0)
{
	;text_until_phrase:=SubStr(originalText,1,previous_phrase_position)
	;phraseWordCount:=0
	;while, R:= RegExMatch(text_until_phrase,"[\s\n\r]+",Out,!R ? 1 : R+Strlen(Out))
	;	phraseWordCount++
	;previousWord:=phraseWordCount
	;GoSub, GotoPreviousWord
	GoSub, PauseSpritzer
	GoSub, GetCurrentWord
	oldPositionBeforeSearch:=sentenceEnd
	
	spritzCommandGo:="var wordCount = SPRITZ_Popup.controller.getSpritzText().getWordCount(); var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart).word; sentenceStart_temp=sentenceStart+1; sentence = sentenceWord; while(SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp) && !SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).isSentenceStart()){sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).word; sentence = sentence + ' ' + sentenceWord; sentenceStart_temp++;}"
	htmlGUI.Exec(spritzCommandGo)
	tmp_sentence:=htmlGUI.Script.sentence
	newPositionAfterSearch:=1
	while(!InStr(tmp_sentence,previous_phrase) && newPositionAfterSearch>0 && newPositionAfterSearch <> htmlGUI.Script.wordCount)
	{
		spritzCommandGo:="var newPositionAfterSearch=SPRITZ_Popup.controller.getSpritzText().getNextSentenceStart(currentIndex+1,1); SPRITZ_Popup.controller.getSpritzText().setCurrentIndex(newPositionAfterSearch);"
		htmlGUI.Exec(spritzCommandGo)
		newPositionAfterSearch:=htmlGUI.Script.newPositionAfterSearch
		spritzCommandGo:="var wordCount = SPRITZ_Popup.controller.getSpritzText().getWordCount(); var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart).word; sentenceStart_temp=sentenceStart+1; sentence = sentenceWord; while(SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp) && !SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).isSentenceStart()){sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).word; sentence = sentence + ' ' + sentenceWord; sentenceStart_temp++;}"
		htmlGUI.Exec(spritzCommandGo)
		tmp_sentence:=htmlGUI.Script.sentence
        tmp_sentence:=RegExReplace(tmp_sentence, "([\w])- ([\w])", "$1$2")
	}
	if(newPositionAfterSearch == htmlGUI.Script.wordCount)
	{
		spritzCommandGo:="SPRITZ_Popup.controller.getSpritzText().setCurrentIndex(1);"
		htmlGUI.Exec(spritzCommandGo)
		SoundPlay, %A_WinDir%\Media\ding.wav
		
		spritzCommandGo:="var wordCount = SPRITZ_Popup.controller.getSpritzText().getWordCount(); var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart).word; sentenceStart_temp=sentenceStart+1; sentence = sentenceWord; while(SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp) && !SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).isSentenceStart()){sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).word; sentence = sentence + ' ' + sentenceWord; sentenceStart_temp++;}"
		htmlGUI.Exec(spritzCommandGo)
		tmp_sentence:=htmlGUI.Script.sentence
		newPositionAfterSearch:=1
		
		while(!InStr(tmp_sentence,previous_phrase) && newPositionAfterSearch>0 && newPositionAfterSearch <> htmlGUI.Script.wordCount)
		{
			spritzCommandGo:="var newPositionAfterSearch=SPRITZ_Popup.controller.getSpritzText().getNextSentenceStart(currentIndex+1,1); SPRITZ_Popup.controller.getSpritzText().setCurrentIndex(newPositionAfterSearch);"
			htmlGUI.Exec(spritzCommandGo)
			newPositionAfterSearch:=htmlGUI.Script.newPositionAfterSearch
			spritzCommandGo:="var wordCount = SPRITZ_Popup.controller.getSpritzText().getWordCount(); var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart).word; sentenceStart_temp=sentenceStart+1; sentence = sentenceWord; while(SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp) && !SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).isSentenceStart()){sentenceWord = SPRITZ_Popup.controller.getSpritzText().getWord(sentenceStart_temp).word; sentence = sentence + ' ' + sentenceWord; sentenceStart_temp++;}"
			htmlGUI.Exec(spritzCommandGo)
			tmp_sentence:=htmlGUI.Script.sentence
            tmp_sentence:=RegExReplace(tmp_sentence, "([\w])- ([\w])", "$1$2")
		}
	}
	
	if(newPositionAfterSearch == htmlGUI.Script.wordCount)
	{
		ShowTooltipRight("No '" . previous_phrase . "' found on text.", 5000)
		previousWord:=oldPositionBeforeSearch
		GoSub, GotoPreviousWord
	}
	else
	{
		spritzCommandGo:="var sentenceStart = SPRITZ_Popup.controller.getSpritzText().getPreviousSentenceStart(currentIndex,1); var sentenceEnd=SPRITZ_Popup.controller.getSpritzText().getNextSentenceStart(currentIndex+1,1);"
		htmlGUI.Exec(spritzCommandGo)
		newPositionAfterSearch:=htmlGUI.Script.sentenceEnd-1
		previousWord:=newPositionAfterSearch
		GoSub, GotoPreviousWord
	}
}
else
{
	ShowTooltipRight("No '" . previous_phrase . "' found on text.", 5000)
}
return

$^r::
Reload

SC01B::
	WinGet, ActivePid, PID, A
	if !(Volume := GetVolumeObject(ActivePid))
		MsgBox, There was a problem retrieving the application volume interface
	VA_ISimpleAudioVolume_GetMasterVolume(Volume, ttsVolume)
	ttsVolume:=Round(ttsVolume, 2)
	if(ttsVolume+0.1<=1)
	{
		ttsVolume:=ttsVolume+0.1
		VA_ISimpleAudioVolume_SetMasterVolume(Volume, ttsVolume)
		VA_ISimpleAudioVolume_SetMute(Volume, 0)
	}
	ObjRelease(Volume)
	ShowTooltipRight("Volume: " . Round(ttsVolume*100,0), 1000)
return

-::
	WinGet, ActivePid, PID, A
	if !(Volume := GetVolumeObject(ActivePid))
		MsgBox, There was a problem retrieving the application volume interface
	VA_ISimpleAudioVolume_GetMasterVolume(Volume, ttsVolume)
	ttsVolume:=Round(ttsVolume, 2)
	if(ttsVolume-0.1>=0.00)
	{
		ttsVolume:=ttsVolume-0.1
		VA_ISimpleAudioVolume_SetMasterVolume(Volume, ttsVolume)
		VA_ISimpleAudioVolume_SetMute(Volume, 0)
	}
	ObjRelease(Volume)
	ShowTooltipRight("Volume: " . Round(ttsVolume*100,0), 1000)
return

#If

PauseSpritzer:
spritzCommandPauseSpritzer:="var isPaused = SPRITZ_Popup.panel.isPaused();"
htmlGUI.Exec(spritzCommandPauseSpritzer)
if(htmlGUI.Script.isPaused)
	return
GoSub, TogglePause
return

PlaySpritzer:
spritzCommandPlaySpritzer:="var isPaused = SPRITZ_Popup.panel.isPaused();"
htmlGUI.Exec(spritzCommandPlaySpritzer)
if(!htmlGUI.Script.isPaused)
	return
GoSub, TogglePause
return

ToggleSpeakDisplaySentence:
DisplaysSentence:=!DisplaysSentence
ChangeDisplaySentence:
if(DisplaysSentence)
{
	SetTimer, DisplaySentence, 100
}
else
{
	SetTimer, DisplaySentence, Off
	GoSub, HideSentence
}
return

;^!#Space::
;GoSub, TogglePause
;return

^!#Up::
ReadPreviousSentence:
GoSub, BackBtn
if(SpeakMode)
{
	GoSub, GetSentence
	TTSSay(currentSentence)
}
pausePerLine:=1
SetTimer, PauseOnEnd, 100
return

^!#Down::
ReadNextSentence:
GoSub, ForwardBtn
if(SpeakMode)
{
	GoSub, GetSentence
	TTSSay(currentSentence)
}
pausePerLine:=1
SetTimer, PauseOnEnd, 100
return

PauseOnEnd:
if(!SpritzLoaded)
{
    ;ToolTip, % "Loading...", 0, 0
	return
}
;ToolTip
spritzCommandPauseOnEnd:="if(!SPRITZ_Popup.controller.getSpritzText()){textLoaded=false;}else{ textLoaded=true;}"
htmlGUI.Exec(spritzCommandPauseOnEnd)
while(!htmlGUI.Script.textLoaded)
{
	htmlGUI.Exec(spritzCommandPauseOnEnd)
	Sleep, 10
}
spritzCommandPauseOnEnd:="var isPaused = SPRITZ_Popup.panel.isPaused();"
htmlGUI.Exec(spritzCommandPauseOnEnd)
if(htmlGUI.Script.isPaused)
	return
spritzCommandPauseOnEnd:="var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var nextWord = SPRITZ_Popup.controller.getSpritzText().getWord(currentIndex+1); if(!nextWord){isSentenceStart = true;}else{isSentenceStart = nextWord.isSentenceStart();}"
htmlGUI.Exec(spritzCommandPauseOnEnd)
spritzCommandPauseOnEnd:="var currentIndex = SPRITZ_Popup.controller.getSpritzText().getCurrentIndex(); var sentenceEnd = SPRITZ_Popup.controller.getSpritzText().getNextSentenceStart(currentIndex,1); var wordCount = SPRITZ_Popup.controller.getSpritzText().getWordCount(); "
htmlGUI.Exec(spritzCommandPauseOnEnd)
if(!LoopCurrentSentence && LoopedBookmarkEndPosition && htmlGUI.Script.currentIndex>=LoopedBookmarkEndPosition)
{
	pressed_number:=LoopedBookmark
	GoSub, SelectBookmark
	SoundPlay, %A_WinDir%\Media\ding.wav
    if(PauseOnBookmarkLoop)
        GoSub, PauseSpritzer
	return
}
if(htmlGUI.Script.isSentenceStart)
{
	SetTimer, PauseOnEnd, Off
	pausePerLine:=0
	spritzCommandPauseOnEnd:="SPRITZ_Popup.panel.pauseText();"
	htmlGUI.Exec(spritzCommandPauseOnEnd)
	if((htmlGUI.Script.sentenceEnd==htmlGUI.Script.wordCount || square) && !LoopCurrentSentence)
	{
		Status := Voice.Status.RunningState
		while(Status=2)
		{
			Status := Voice.Status.RunningState
			Sleep, 10
		}
		SoundPlay, %A_WinDir%\Media\ding.wav
		spritzCommandPauseOnEnd:="SPRITZ_Popup.controller.rewindBtn.click();"
		htmlGUI.Exec(spritzCommandPauseOnEnd)
        
		previousWord:=0
		GoSub, GotoPreviousWord
		
		if(SpeakMode)
		{
			GoSub, GetSentence
			TTSSay(currentSentence)
		}
		SetTimer, PauseOnEnd, 100
		return
	}
	if(AutoAdvanceSentences)
		SetTimer, AutoAdvanceSentence, 100
}
return

AutoAdvanceSentence:
	if(Voice)
	{
		Status := Voice.Status.RunningState
		if (Status = 2)   ; reading
			return
	}
	SetTimer, AutoAdvanceSentence, Off
	if(LoopCurrentSentence)
	{
		GoSub, BackBtn
		GoSub, BackBtn
	}
	GoSub, ReadNextSentence
return

GetSelectedText:
BlockInput, on
clipboardBkp:=ClipboardAll
Clipboard=
SetKeyDelay, 100
Loop, 5
{
	Send, ^c
	if(Clipboard!="")
	{
		break
	}
}
if(GrabText)
	ClipWait,20, 1
say=%Clipboard%
if(FileExist(say))
	say:=""
loadedTextLength:=StrLen(loadedText)
if(loadedTextLength>5000 && say<>"")
{
	BlockInput, off
	MsgBox, 1,Spritzer, The size of previous loaded text was %loadedTextLength%, do you want to load new text? (Yes o No)
	IfMsgBox Cancel
	{
		say:=originalText
		BlockInput, off
		return
	}
}
originalText:=say
Clipboard:=clipboardBkp
if(say<>"")
{
	currentDocumentId:=GetCurrentDocumentId("A")
	WinGetTitle, currentDocumentTitle, ahk_id %currentDocumentId%
}
BlockInput, off
if(say<>"")
{
	GoSub, GetFilePath
}
return

$#!s::
if(!SpritzLoaded)
	return
SpeakMode:=!SpeakMode
ShowTooltipRight("Speak mode: " . SpeakMode, 1000)
GoSub, UpdateSpeakModeGUI
GoSub, TogglePause
GoSub, TogglePause
return

ToggleSpritzer:
HideSpritzer:=!HideSpritzer
UpdateSpritzerDisplay:
spritzCommandToggleSpritzer:="SPRITZ_Popup.setSpeed(" . spritzSpeed . ");"
htmlGUI.Exec(spritzCommandToggleSpritzer)
if(HideSpritzer && SpeakMode)
{
	spritzCommandToggleSpritzer:="$('.spritzer-canvas').hide(); $('.spritzer-controls-container').hide(); $('.spritzer-header').hide(); $('#speakmode-value').hide(); $('.spritzer-container').css('min-height', '0px'); $('#spritz_progress_bar_container').css('margin-top', '-13px');" 
	htmlGUI.Exec(spritzCommandToggleSpritzer)
}
else
{
	spritzCommandToggleSpritzer:="$('.spritzer-canvas').show(); $('.spritzer-controls-container').show(); $('.spritzer-header').show(); $('#speakmode-value').show(); $('.spritzer-container').css('min-height', '68px'); $('#spritz_progress_bar_container').css('margin-top', '-10px');"
	htmlGUI.Exec(spritzCommandToggleSpritzer)
}
return

UpdateSpeakModeGUI:
if(SpeakMode)
{
	value:="Text to Speech mode"
}
else
{
	value:="Spritz mode"
}
spritzCommandUpdateSpeakModeGUI:="$('#speakmode-value').html('" . value . "');"
htmlGUI.Exec(spritzCommandUpdateSpeakModeGUI)
return

TTSCleanText(sayText)
{
	sayText := regexreplace(sayText, "\n+$") ;
	sayText := regexreplace(sayText, "`am)([\w]+)[\s]*[\n\r]+([A-Z])", "$1." . A_NewLine . " $2")
	sayText := regexreplace(sayText, "`am)\-[\s]*\n[\r]*")
	StringReplace, sayText, sayText, `r`n,%A_Space%, All
	StringReplace, sayText, sayText, `n,%A_Space%, All
	StringReplace, sayText, sayText, `r,%A_Space%, All
	StringReplace, sayText, sayText, %A_Space%%A_Space%,%A_Space%, All
	return sayText
}

TTSSay(sayText)
{
   global Voice
   global ttsSpeed
   global ttsPitch
   global ttsVoiceName
   global WmpB
	;global a
	;if(strLen(sayText)>20)
	;MsgBox, % a . sayText
   if(sayText)
	WmpB.controls.pause()
   if(!Voice)
		Voice := TTS_CreateVoice(ttsVoiceName,ttsSpeed,,ttsPitch)
	sayText:=TTSCleanText(sayText)
	
	;tooltip, %sayText%
	TTS(Voice, "Speak", sayText)
   ;msgbox, Parar lectura?
}

ToggleGuiVisibility:
GuiHidden:=!GuiHidden
Gosub, SetGuiVisibilityByGuiHidden
return

SetGuiVisibilityByGuiHidden:
if(GuiHidden)
    SetGuiVisibility(0)
else
    SetGuiVisibility(1)
return

SetGuiVisibility(GuiVisible)
{
    global GuiHidden
    global gui_position
    
    if(!GuiVisible)
    {
        Gui 1:Show, x10000 y10000 w%A_ScreenWidth% h%A_ScreenHeight%
        GuiHidden:=1
    }
    else
    {
        Gui 1:Show, %gui_position% w%A_ScreenWidth% h%A_ScreenHeight%
        GuiHidden:=0
    }
}

;#!m::
;if(GuiHidden)
;	GoSub, ShowGui
;else
;	GoSub, HideGui
;return

+^!#s::
SearchingPDF:=0
WmpB.controls.pause()
if(GuiHidden)
{
	GoSub, ShowAndPlay
	return
}
if(!SpritzLoaded)
	return
GoSub, GetSelectedText
if(say="")
{
	prevFile:=file
	prevCurrentDocumentID:=currentDocumentID
	prevCurrentDocumentTitle:=currentDocumentTitle
	prevCurrentDocumentName:=currentDocumentName
	GoSub, GetFilePath
	GoSub, GetTitleFromFile
	;msgbox, % file . "-" . prevFile . "-" . say  . "-" . FileExist(A_ScriptDir . "/texts/" . currentDocumentName . ".txt")
	if(file<>"" && prevFile<>file && FileExist(A_ScriptDir . "/texts/" . currentDocumentName . ".txt"))
	{
		GoSub, ReadPreviousFile
		return
	}
	else
	{
		file:=prevFile
		currentDocumentID:=prevCurrentDocumentID
		currentDocumentTitle:=prevCurrentDocumentTitle
		currentDocumentName:=prevCurrentDocumentName
	}
	say:=loadedText
	originalText:=loadedText
}
if(say=loadedText && loadedText<>"")
{
	GoSub, ActivateSelf
	return
}
Spritzify:
GoSub, GetFilePath
GoSub, GetTitleFromFile
GoSub, SaveCurrentWord
GoSub, ViewTitle
SetTimer, AutoAdvanceSentence, Off
SetTimer, PauseOnEnd, off
SetTimer, DisplaySentence, off
Sleep, 100
TTSSay("-")
spritzCommandSpritzify:="var isCompleted = SPRITZ_Popup.panel.resetText();"
htmlGUI.Exec(spritzCommandSpritzify)
spritzCommandSpritzify:="SPRITZ_Popup.panel.pauseText();"
htmlGUI.Exec(spritzCommandSpritzify)
spritzCommandSpritzify:="var isPaused = SPRITZ_Popup.panel.isPaused();"
htmlGUI.Exec(spritzCommandSpritzify)
while(!htmlGUI.Script.isPaused)
{
	htmlGUI.Exec(spritzCommandSpritzify)
}
Sleep, 100
loadedText:=say

GoSub, ActivateSelf
GoSub, SpritzifySay

if(SpeakMode)
	TTSSay("-")
	
if(AutoAdvanceSentences)
{
	pausePerLine:=1
	SetTimer, PauseOnEnd, 100
}

if(DisplaysSentence)
{
	SetTimer, DisplaySentence, 100
}
return

TTSify:
GoSub, ActivateSelf
TTSSay(say)
return

SpritzifySay:
say := regexreplace(say, "\\", "\\u005C")
say := regexreplace(say, "\n+$") ;
say := regexreplace(say, "`am)([\w]+)[\s]*[\n\r]+([A-Z])", "$1." . A_NewLine . " $2")
say := regexreplace(say, "`am)\-[\s]*\n[\r]*")
StringReplace, say, say, `r`n,%A_Space%\`n, All
StringReplace, say, say, `n,%A_Space%\`n, All
StringReplace, say, say, `r,%A_Space%\`n, All
StringReplace, say, say, `',\`', All
StringReplace, say, say, `", \`", All ;"
if(say="")
	return
;$("#spritzer").html('');
;SPRITZ_Popup.init();
spritzCommandSpritzifySay=
( Ltrim Join
var say="%say%
";`n
SPRITZ_Popup.showText({text:say});
)
;tooltip, % spritzCommandSpritzifySay
htmlGUI.Exec(spritzCommandSpritzifySay)
return

Logo(ByRef req, ByRef res, ByRef server) {
    server.ServeFile(res, A_ScriptDir . "/logo.png")
    res.status := 200
}

NotFound(ByRef req, ByRef res) {
    res.SetBodyText("Page not found")
}

Spritz(ByRef req, ByRef res){
	f := FileOpen(A_ScriptDir . "/javascripts/spritz.min.js", "r") ; example mp3 file
    length := f.RawRead(data, f.Length)
    f.Close()
    res.status := 200
    res.headers["Content-Type"] := "text/javascript"
    res.SetBody(data, length)
}

Initialize(ByRef req, ByRef res){
	f := FileOpen(A_ScriptDir . "/javascripts/initialize.js", "r") ; example mp3 file
    length := f.RawRead(data, f.Length)
    f.Close()
    res.status := 200
    res.headers["Content-Type"] := "text/javascript"
    res.SetBody(data, length)
}

Settings(ByRef req, ByRef res){
	f := FileOpen(A_ScriptDir . "/javascripts/spritzSettings.js", "r") ; example mp3 file
    length := f.RawRead(data, f.Length)
    f.Close()
    res.status := 200
    res.headers["Content-Type"] := "text/javascript"
    res.SetBody(data, length)
}

JQuery(ByRef req, ByRef res){
	f := FileOpen(A_ScriptDir . "/javascripts/jquery-2.1.0.min.js", "r") ; example mp3 file
    length := f.RawRead(data, f.Length)
    f.Close()
    res.status := 200
    res.headers["Content-Type"] := "text/javascript"
    res.SetBody(data, length)
}

Init(ByRef req, ByRef res) {
HTML_page =
( Ltrim Join
<!doctype html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" /> 
  <title>Spritz Chrome Extension</title>
  
  <link id="spritz-css" rel="stylesheet" type="text/css" href="https://sdk.spritzinc.com/js/2.0/css/spritz.min.css" media="all">
  
  <script type="text/javascript" src="javascripts/jquery-2.1.0.min.js"></script>
  <script type="text/javascript" src="javascripts/spritzSettings.js"></script>
  <script type="text/javascript" src="javascripts/spritz.min.js"></script>
  
  <style>
    body {
      padding: 10px;
      margin: 0;
      text-align: center;
      background: none;
	  
	  padding-top: 150px;
	  background-color: #123456;
      overflow-y:hidden;
    }
    #spritzer {
		box-shadow: 0 0 10px rgba(30, 30, 30, 0.6);
		border: 1px solid #ccc;
		border-radius: 10px;
		box-shadow: black 2px 2px 1px 0px;
    }
    #spritzer .spritzer-container{
		border-radius: 10px;
		background-color: white;
    }	
    #speed-value {
		float: right;
		color: #999;
		padding-top: 4px;
		width: 32px;
    }
	#spritzer .spritzer-controls-container{
		padding-top: 0px;
	}
	#spritzer .spritzer-controls-container .spritzer-speed {
		display:none;
	}	
	#spritzer .spritzer-controls-container .custom-speed-controller {
		float: right;
	}
	#speed {
		width: 90px;
	}
	#spritz_progress_bar_container {
		margin-left:-10px;
		margin-right:-10px;
	}
	#spritz_progress_bar {
		background-color: #0095FF;
		width: 0`%;
		height: 2px;
		margin-bottom: -6px;
		border-radius: 10px;
	}
	
	.currently-reading:first-letter { 
		font-size: 150`%;
		color: #FF0000;
	}
	
	.currently-reading-loop:first-letter { 
		font-size: 150`%;
		color: #0000FF;
	}
	
	.currently-reading-loop-one:first-letter { 
		font-size: 150`%;
		color: #00FF00;
	}
	
	.currently-reading-loop-ab:first-letter { 
		font-size: 150`%;
		color: #FFFF00;
	}
	
	.currently-reading, .currently-reading-loop, .currently-reading-loop-one, .currently-reading-loop-ab
	{
		font-weight:100;
		font-family: PlayfairDisplay; /*SpritzMedienBold;*/
		color: #000000;
		background-color: white;
	}
	
	#sentence
	{
		font-family:PlayfairDisplay; /*SpritzMedienMedium*/
		font-size: 1em; /*0.8em;*/
		
		background-color: #fff;
		min-width: 634px;
		max-width: 634px;
		position: absolute;
		margin: 0 auto;
		left:0; 
		right:0;
		top:0px;
		
		box-shadow: 0 0 10px rgba(30, 30, 30, 0.6);
		border: 2px solid #ccc;
		border-radius: 10px;
		box-shadow: black 2px 2px 1px 0px;
		z-index:9999;
		
		margin-bottom: -2px;
	}
	
	#sentence>div
	{
		display:table-cell;
		height: 60px;
		min-height: 60px;
		text-align: left;
		box-sizing: border-box;
		padding: 2px;
		padding-bottom: 10px;
		
		background-color: white; 
        min-width:632px;
	}
	
	#spritzer
	{
		min-width: 635px;
	}
	
  </style>
</head>
<body onload=''>
	<div id="sentence" style="display:none;"></div>
	<div id="spritzer"></div>
</body>

<script type="text/javascript" src="javascripts/initialize.js"></script>
<script type="text/javascript">
	/* SPRITZ_Popup.showText({text:"Spritz loaded"}); */
</script>
</html>
)
    res.SetBodyText(HTML_page)
    res.status := 200
}

class WB_events
{
	;for more events and other, see http://msdn.microsoft.com/en-us/library/aa752085
	
	NavigateComplete2(wb) {
		;wb.Stop() ;blocked all navigation, we want our own stuff happening
	}
	
	DownloadComplete(wb, NewURL) {
		wb.Stop() ;blocked all navigation, we want our own stuff happening
	}
	DocumentComplete(wb, NewURL) {
		global SpritzLoaded
		SpritzLoaded:=1
		;wb.Stop() ;blocked all navigation, we want our own stuff happening
	}
	
	BeforeNavigate2(wb, NewURL)
	{
		wb.Stop() ;blocked all navigation, we want our own stuff happening
		;parse the url
		global MYAPP_PROTOCOL
		if (InStr(NewURL,MYAPP_PROTOCOL "://")==1) { ;if url starts with "myapp://"
			what := SubStr(NewURL,Strlen(MYAPP_PROTOCOL)+4) ;get stuff after "myapp://"
		}
		;else do nothing
	}
}

;-------------------------------------------------------------------------------
WM_LBUTTONDOWN() {
;-------------------------------------------------------------------------------
    global hGUI1

    IfNotEqual, A_Gui, 1, Return

    Prev_CoordModeMouse := A_CoordModeMouse
    CoordMode, Mouse, Screen

    MouseGetPos, old_Mx, old_My
    WinGetPos, old_Wx, old_Wy, Width, Height
	

    While GetKeyState("LButton") {

        MouseGetPos, now_Mx, now_My
        x := old_Wx + now_Mx - old_Mx
      , y := old_Wy + now_My - old_My
      , old_Mx := now_Mx, old_Wx := x
      , old_My := now_My, old_Wy := y

        hDWP := DllCall("BeginDeferWindowPos", "Int", 1) ; 2 windows
        If hDWP {
            hDWP := DllCall("DeferWindowPos"
                , "Uint", hDWP, "UInt", hGUI1, "UInt", 0
                , "Int", x, "Int", y, "Int", Width, "Int", Height
                , "UInt", 0x0214)
        }
        DllCall("EndDeferWindowPos", "UInt", hDWP)
    }
    CoordMode, Mouse, %Prev_CoordModeMouse% ; restore
}

TTS(oVoice, command, param1="", param2="") {        ; by Learning one. For AHK_L. Thanks: jballi, Sean, Frankie.
    ; AHK forum location:    www.autohotkey.com/forum/topic57773.html
    ; Read more:            msdn.microsoft.com/en-us/library/ms723602(v=VS.85).aspx, www.autohotkey.com/forum/topic45471.html, www.autohotkey.com/forum/topic83162.html
    static CommandList := "ToggleSpeak,Speak,SpeakWait,Pause,Stop,SetRate,SetVolume,SetPitch,SetVoice,GetVoices,GetStatus,GetCount,SpeakToFile"
    if command not in %CommandList%
    {
        MsgBox, 16, TTS() error, "%command%" is not valid command.
        return
    }
    if command = ToggleSpeak    ; speak or stop speaking
    {
        Status := oVoice.Status.RunningState
        if Status = 1    ; finished
        oVoice.Speak(param1,0x1)    ; speak asynchronously
        Else if Status = 0    ; paused
        {
            oVoice.Resume
            oVoice.Speak("",0x1|0x2)    ; stop
            oVoice.Speak(param1,0x1)    ; speak asynchronously
        }
        Else if Status = 2    ; reading
        oVoice.Speak("",0x1|0x2)    ; stop
    }
    Else if command = Speak        ; speak asynchronously
    {
        Status := oVoice.Status.RunningState
        if Status = 0    ; paused
        oVoice.Resume
        oVoice.Speak("",0x1|0x2)    ; stop
        oVoice.Speak(param1,0x1)    ; speak asynchronously
    }
    Else if command = SpeakWait        ; speak synchronously
    {
        Status := oVoice.Status.RunningState
        if Status = 0    ; paused
        oVoice.Resume
        oVoice.Speak("",0x1|0x2)    ; stop
        oVoice.Speak(param1,0x0)    ; speak synchronously
    }
    Else if command = Pause    ; Pause toggle
    {
        Status := oVoice.Status.RunningState
        if Status = 0    ; paused
        oVoice.Resume
        else if Status = 2    ; reading
        oVoice.Pause
    }
    Else if command = Stop
    {
        Status := oVoice.Status.RunningState
        if Status = 0    ; paused
        oVoice.Resume
        oVoice.Speak("",0x1|0x2)    ; stop
    }
    Else if command = SetRate
        oVoice.Rate := param1        ; rate (reading speed): param1 from -10 to 10. 0 is default.
    Else if command = SetVolume
        oVoice.Volume := param1        ; volume (reading loudness): param1 from 0 to 100. 100 is default
    Else if command = SetPitch                ; http://msdn.microsoft.com/en-us/library/ms717077(v=vs.85).aspx
        oVoice.Speak("<pitch absmiddle = '" param1 "'/>",0x20)    ; pitch : param1 from -10 to 10. 0 is default.
    Else if command = SetVoice
    {
        Loop, % oVoice.GetVoices.Count
        {
            Name := oVoice.GetVoices.Item(A_Index-1).GetAttribute("Name")    ; 0 based
            If (Name = param1)
            {
                DoesVoiceExist := 1
                break
            }
        }
        if !DoesVoiceExist
        {
            MsgBox,64,, Voice "%param1%" does not exist.
            return
        }
        While !(oVoice.Status.RunningState = 1)
        Sleep, 20
        oVoice.Voice := oVoice.GetVoices("Name=" param1).Item(0) ; set voice to param1
    }
    Else if command = GetVoices
    {
        param1 := (param1 = "") ? "`n" : param1        ; param1 as delimiter
        Loop, % oVoice.GetVoices.Count
        {
            Name := oVoice.GetVoices.Item(A_Index-1).GetAttribute("Name")    ; 0 based
            VoiceList .= Name param1
        }
        Return RTrim(VoiceList,param1)
    }
    Else if command = GetStatus
    {
        Status := oVoice.Status.RunningState
        if Status = 0 ; paused
        Return "paused"
        Else if Status = 1 ; finished
        Return "finished"
        Else if Status = 2 ; reading
        Return "reading"
    }
    Else if command = GetCount
        return oVoice.GetVoices.Count
    Else if command = SpeakToFile    ; param1 = TextToSpeak, param2 = OutputFilePath
    {
        oldAOS := oVoice.AudioOutputStream
        oldAAOFCONS := oVoice.AllowAudioOutputFormatChangesOnNextSet
        oVoice.AllowAudioOutputFormatChangesOnNextSet := 1    
        
        SpStream := ComObjCreate("SAPI.SpFileStream")
        FileDelete, % param2    ; OutputFilePath
        SpStream.Open(param2, 3)
        oVoice.AudioOutputStream := SpStream
        TTS(oVoice, "SpeakWait", param1)
        SpStream.Close()
        oVoice.AudioOutputStream := oldAOS
        oVoice.AllowAudioOutputFormatChangesOnNextSet := oldAAOFCONS
    }
}    
TTS_CreateVoice(VoiceName="", VoiceRate="", VoiceVolume="", VoicePitch="") {        ; by Learning one. For AHK_L.
    oVoice := ComObjCreate("SAPI.SpVoice")
    if !(VoiceName = "")
        TTS(oVoice, "SetVoice", VoiceName)
    if VoiceRate between -10 and 10
        oVoice.Rate := VoiceRate        ; rate (reading speed): from -10 to 10. 0 is default.
    if VoiceVolume between 0 and 100
        oVoice.Volume := VoiceVolume    ; volume (reading loudness): from 0 to 100. 100 is default
    if VoicePitch between -10 and 10
        TTS(oVoice, "SetPitch", VoicePitch)    ; pitch: from -10 to 10. 0 is default.
    return oVoice
}

TestActive()
{	
    SetTimer, UpdateActive, 0
}

UpdateActive:
	SetTimer, UpdateActive, Off
    Sleep, 10
	IfWinActive, % "ahk_pid " . DllCall("GetCurrentProcessId")
	{
		WinSet, TransColor, 123456 255, % "ahk_pid " . DllCall("GetCurrentProcessId")
		spritzCommandUpdateActive:="$('#spritz_progress_bar_container').css('background-color', '#000000');" 
		htmlGUI.Exec(spritzCommandUpdateActive) ;#FFFF99
        spritzCommandUpdateActive:="$('#sentence').css('background-color', '#FFFF99');" 
		htmlGUI.Exec(spritzCommandUpdateActive)
        spritzCommandUpdateActive:="$('#spritz_progress_bar').css('background-color', '#FFFF99');" 
		htmlGUI.Exec(spritzCommandUpdateActive)
		if(SearchingPDF)
		{
			SearchingPDF:=0
			GoSub, ActivateDocument
			Send, ^f
			SetKeyDelay, -1
			Send,{End}
			Send,^+{Home}{BS}
			Send, {Enter}
			GoSub, ActivateSelf
		}
	}
	Else
	{
		transparencyn:=InactiveTransparency*255/100
		if(transparencyn=0)
			SetGuiVisibility(0)
		else
        {
            if(FadeOnFocusLost)
			WinSet, TransColor, 123456 %transparencyn%, % "ahk_pid " . DllCall("GetCurrentProcessId")
        }
		spritzCommandUpdateActive:="$('#spritz_progress_bar_container').css('background-color', '#FFFFFF');" 
		htmlGUI.Exec(spritzCommandUpdateActive)
        spritzCommandUpdateActive:="$('#sentence').css('background-color', '#FFFFFF');" 
		htmlGUI.Exec(spritzCommandUpdateActive)
        spritzCommandUpdateActive:="$('#spritz_progress_bar').css('background-color', '#0095FF');" 
		htmlGUI.Exec(spritzCommandUpdateActive)
        
        if(IsSuspended && !A_IsSuspended)
            Suspend
	}
return

FetchPageTitle(Url="")
{
	WinHttpReq := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WinHttpReq.SetTimeouts("30000", "30000", "30000", "30000")

	Try { 
		WinHttpReq.Open("GET", Url, false)
		WinHttpReq.Send()
		WinHttpReq.WaitForResponse()
		webpage := WinHttpReq.ResponseText
	}
	Catch e{
		For Each, Line in StrSplit(e.Message, "`n", "`r") {
			Results := InStr(Line, "Description:") 
				? StrReplace(Line, "Description:")
				: ""
			If (Results <> "")
				Break
		}
		MsgBox % Trim(Results)
		ExitApp
	}
	FoundPos := RegExMatch(webpage, "m)<title>(\r?\n)?.*(\r\n)?</title>", Title)

	StringReplace, Title, Title,`r`n,,All
	StringReplace, Title, Title,%A_Tab%,,All
	StringReplace, Title, Title,<title>,,All
	StringReplace, Title, Title,</title>,,All

	return Title
}

Dec_XML(str) 
{
   Loop 
      If RegexMatch(str, "S)(&#(\d+);)", dec)
         StringReplace, str, str, %dec1%, % Chr(dec2), All 
      Else If   RegexMatch(str, "Si)(&#x([\da-f]+);)", hex)
         StringReplace, str, str, %hex1%, % Chr("0x" . hex2), All 
      Else 
         Break 
   StringReplace, str, str, &nbsp;, %A_Space%, All 
   StringReplace, str, str, &quot;, ", All
   StringReplace, str, str, &apos;, ', All 
   StringReplace, str, str, &lt;,   <, All 
   StringReplace, str, str, &gt;,   >, All 
   StringReplace, str, str, &amp;,  &, All
   return, str 
}

GetVolumeObject(Param = 0)
{
    static IID_IASM2 := "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}"
    , IID_IASC2 := "{bfb7ff88-7239-4fc9-8fa2-07c950be9c6d}"
    , IID_ISAV := "{87CE5498-68D6-44E5-9215-6DA47EF883D8}"
    
    ; Get PID from process name
    if Param is not Integer
    {
        Process, Exist, %Param%
        Param := ErrorLevel
    }
    
    ; GetDefaultAudioEndpoint
    DAE := VA_GetDevice()
    
    ; activate the session manager
    VA_IMMDevice_Activate(DAE, IID_IASM2, 0, 0, IASM2)
    
    ; enumerate sessions for on this device
    VA_IAudioSessionManager2_GetSessionEnumerator(IASM2, IASE)
    VA_IAudioSessionEnumerator_GetCount(IASE, Count)
    
    ; search for an audio session with the required name
    Loop, % Count
    {
        ; Get the IAudioSessionControl object
        VA_IAudioSessionEnumerator_GetSession(IASE, A_Index-1, IASC)
        
        ; Query the IAudioSessionControl for an IAudioSessionControl2 object
        IASC2 := ComObjQuery(IASC, IID_IASC2)
        ObjRelease(IASC)
        
        ; Get the session's process ID
        VA_IAudioSessionControl2_GetProcessID(IASC2, SPID)
        
        ; If the process name is the one we are looking for
        if (SPID == Param)
        {
            ; Query for the ISimpleAudioVolume
            ISAV := ComObjQuery(IASC2, IID_ISAV)
            
            ObjRelease(IASC2)
            break
        }
        ObjRelease(IASC2)
    }
    ObjRelease(IASE)
    ObjRelease(IASM2)
    ObjRelease(DAE)
    return ISAV
}
 
;
; ISimpleAudioVolume : {87CE5498-68D6-44E5-9215-6DA47EF883D8}
;
VA_ISimpleAudioVolume_SetMasterVolume(this, ByRef fLevel, GuidEventContext="") {
    return DllCall(NumGet(NumGet(this+0)+3*A_PtrSize), "ptr", this, "float", fLevel, "ptr", VA_GUID(GuidEventContext))
}
VA_ISimpleAudioVolume_GetMasterVolume(this, ByRef fLevel) {
    return DllCall(NumGet(NumGet(this+0)+4*A_PtrSize), "ptr", this, "float*", fLevel)
}
VA_ISimpleAudioVolume_SetMute(this, ByRef Muted, GuidEventContext="") {
    return DllCall(NumGet(NumGet(this+0)+5*A_PtrSize), "ptr", this, "int", Muted, "ptr", VA_GUID(GuidEventContext))
}
VA_ISimpleAudioVolume_GetMute(this, ByRef Muted) {
    return DllCall(NumGet(NumGet(this+0)+6*A_PtrSize), "ptr", this, "int*", Muted)
}

AHK_NOTIFYICON(wParam, lParam)
{
    if (lParam = 0x202) ; WM_LBUTTONUP
	{
        if(A_IsSuspended)
            Suspend
		GoSub, ActivateSelf0
		Return 1
	}
    else if (lParam = 0x205) ; WM_RBUTTONUP
	{
		Menu, Tray, Show
        return 1
	}
    if (lParam = 513) { ;(lParam = 0x203) { ; user double left-clicked tray icon
        if(GetKeyState("Control","P"))
        {
            GoSub, TogglePause
        }
        else
        {
            if(GetKeyState("Shift","P") || GetKeyState("Alt","P"))
            {
                GoSub, TogglePauseKeys
            }
            if(A_IsSuspended)
                Suspend
            GoSub, ActivateSelf0
        }
        return 1
    }
}

OnPBMsg(wParam, lParam, msg, hwnd) {
	If (wParam = 0) {	;PBT_APMQUERYSUSPEND
		If (lParam & 1)	;Check action flag
			MsgBox The computer is trying to suspend, and user interaction is permitted.
		Else MsgBox The computer is trying to suspend, and no user interaction is allowed.
		;Return TRUE to grant the request, or BROADCAST_QUERY_DENY to deny it.
	} 
	Else{
		if(wParam = 6 || wParam = 7 || wParam = 18)
		{
			GoSub, PlaySpritzer
		}
		if(wParam = 4)
		{
			GoSub, PauseSpritzer
		}
	}
	Return True
}

#include, %A_ScriptDir%\AHKhttp.ahk
#include %A_ScriptDir%\AHKsock.ahk