#Include CWebView.ahk
#Persistent
#SingleInstance, force
SetBatchLines, -1

OnMessage(0x201, "WM_LBUTTONDOWN")

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

spritzSpeed:=250
ttsSpeed:=-2
SpeakMode:=0

;Gui Add, ActiveX, x0 y0 w640 h480 vWB, Shell.Explorer
;;wb := ComObjCreate("InternetExplorer.Application")
;wb.visible := True
;wb.silent := false ;Surpress JS Error boxes
;wb.Navigate("http://localhost:8000")
;while wb.busy
;	sleep 100
;doc := wb.document
;ComObjConnect(WB, WB_events) 
;
;Gui 1: -Caption +LastFound +AlwaysOnTop +OwnDialogs
;WinSet, TransColor, 123456
;Gui 1:Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%

Gui 1: New, -Caption +LastFound +AlwaysOnTop +OwnDialogs +ToolWindow hWndhGUI1
WinSet, TransColor, 123456
Gui 1:Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%

htmlGUI := new CWebView(1,"x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
htmlGUI.SetURL("http://localhost:8007")
Sleep,100
SendInput !{Esc}
return

!#q::
ExitApp

#^!SC01B::
if(!SpeakMode){
	if(spritzSpeed>400)
		return
	spritzSpeed:=spritzSpeed+50
	spritzCommand:="SPRITZ_Popup.setSpeed(" . spritzSpeed . ");"
	htmlGUI.Exec(spritzCommand)
}
else
{
	if(ttsSpeed>7)
		return
	ttsSpeed:=ttsSpeed+1
	GoSub, SetTTSSpeed
}
return

#^!-::
if(!SpeakMode){
	if(spritzSpeed<=200)
		return
	spritzSpeed:=spritzSpeed-50
	spritzCommand:="SPRITZ_Popup.setSpeed(" . spritzSpeed . ");"
	htmlGUI.Exec(spritzCommand)
}
else
{
	if(ttsSpeed<=-4)
		return
	ttsSpeed:=ttsSpeed-1
	GoSub, SetTTSSpeed
}
return

SetTTSSpeed:
if(Voice)
	say("-")
Voice := TTS_CreateVoice("Microsoft Mark Mobile",ttsSpeed,,10)
return

#!r::
$!Left::
spritzCommand:="SPRITZ_Popup.controller.backBtn.click();"
htmlGUI.Exec(spritzCommand)
return

#!f::
$!Right::
spritzCommand:="SPRITZ_Popup.controller.forwardBtn.click();"
htmlGUI.Exec(spritzCommand)
return

$!Down::
spritzCommand:="SPRITZ_Popup.controller.backBtn.click();"
htmlGUI.Exec(spritzCommand)
Sleep, 100
spritzCommand:="SPRITZ_Popup.controller.forwardBtn.click();"
htmlGUI.Exec(spritzCommand)
return

$!Up::
#!p::
spritzCommand:="SPRITZ_Popup.togglePause();"
htmlGUI.Exec(spritzCommand)
return

GetSelectedText:
BlockInput, on
clipboardBkp:=ClipboardAll
Clipboard=
SetKeyDelay, 100
Loop, 10
{
	Send, ^c
	if(Clipboard!="")
	{
		break
	}
}
ToolTip
say=%Clipboard%
Clipboard:=clipboardBkp
BlockInput, off
return

$#!s::
SpeakMode:=!SpeakMode
if(SpeakMode)
	value:="Text to Speech mode"
else
	value:="Spritz mode"
spritzCommand:="$('#speakmode-value').html('" . value . "');"
htmlGUI.Exec(spritzCommand)
return

say(sayText)
{
   global Voice
   global ttsSpeed
   if(!Voice)
		Voice := TTS_CreateVoice("Microsoft Mark Mobile",ttsSpeed,,10)
	TTS(Voice, "Speak", sayText)
   ;msgbox, Parar lectura?
}

$#s::
if(SpeakMode)
{
	GoSub, GetSelectedText
	say(say)
}
else
{
	Tooltip, Spritzify
	Gosub, GetSelectedText
	say := regexreplace(say, "\n+$") ;
	StringReplace, say, say, `r`n,%A_Space%\`n, All
	StringReplace, say, say, `n,%A_Space%\`n, All
	StringReplace, say, say, `r,%A_Space%\`n, All
	StringReplace, say, say, `", \`", All ;"
	if(say="")
		return
	;$("#spritzer").html('');
	;SPRITZ_Popup.init();
	spritzCommand=
	( Ltrim Join
	var say="%say%
	";`n
	SPRITZ_Popup.showText({text:say});
	)
	;tooltip, % spritzCommand
	htmlGUI.Exec(spritzCommand)
}
return

^r::
Reload

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
global say
GoSub, GetSelectedText
spritzCommand=
( Ltrim Join
var say="%say%
";`n
SPRITZ_Popup.showText({text:say});
)
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
	  
	  padding-top: 100px;
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
	
  </style>
</head>
<body>
	<div id="spritzer"></div>	 
</body>

<script type="text/javascript" src="javascripts/initialize.js"></script>
<script type="text/javascript">
	SPRITZ_Popup.showText({text:"Spritz loaded"});
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
		wb.Stop() ;blocked all navigation, we want our own stuff happening
	}
	DownloadComplete(wb, NewURL) {
		wb.Stop() ;blocked all navigation, we want our own stuff happening
	}
	DocumentComplete(wb, NewURL) {
		wb.Stop() ;blocked all navigation, we want our own stuff happening
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

#include, %A_ScriptDir%\AHKhttp.ahk
#include %A_ScriptDir%\AHKsock.ahk