#Include CWebView.ahk
#Persistent
#SingleInstance, force
SetBatchLines, -1

paths := {}
paths["/"] := Func("Init")
paths["/javascripts/jquery-2.1.0.min.js"] := Func("JQuery")
paths["/javascripts/spritzSettings.js"] := Func("Settings")
paths["/javascripts/spritz.min.js.js"] := Func("Spritz")
paths["/javascripts/initialize.js"] := Func("Initialize")
paths["404"] := Func("NotFound")
paths["/logo"] := Func("Logo")

server := new HttpServer()
server.LoadMimes(A_ScriptDir . "/mime.types")
server.SetPaths(paths)
server.Serve(8007)

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

Gui 1: -Caption +LastFound +AlwaysOnTop +OwnDialogs +ToolWindow
WinSet, TransColor, 123456
Gui 1:Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%

htmlGUI := new CWebView(1,"x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
htmlGUI.SetURL("http://localhost:8007")

return

!#q::
ExitApp

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

#!p::
spritzCommand:="SPRITZ_Popup.togglePause();"
htmlGUI.Exec(spritzCommand)
return

$!s::
Tooltip, Spritzify
; linea cómo estás en linea
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
  <script type="text/javascript" src="https://sdk.spritzinc.com/js/2.0/js/spritz.min.js"></script>
  
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

#include, %A_ScriptDir%\AHKhttp.ahk
#include %A_ScriptDir%\AHKsock.ahk