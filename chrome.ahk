#include acc.ahk
;==================================================

JEE_ChromeGetTabNames(hWnd, vSep="`n")
{
oAcc := Acc_ObjectFromWindow(hWnd)
oAcc := Acc_Child(oAcc, 1), oAcc := Acc_Child(oAcc, 2)
oAcc := Acc_Child(oAcc, 2), oAcc := Acc_Child(oAcc, 2)

vOutput := ""
For each, oChild in Acc_Children(oAcc)
{
vTabText := Acc_Child(oChild, 1).accName(0)
if !(vTabText == "")
vOutput .= vTabText vSep
}
vOutput := SubStr(vOutput, 1, -StrLen(vSep)) ;trim right

oAcc := ""
Return vOutput
}

;==================================================

JEE_ChromeFocusTabByNum(hWnd, vNum)
{
oAcc := Acc_ObjectFromWindow(hWnd)
oAcc := Acc_Child(oAcc, 1), oAcc := Acc_Child(oAcc, 2)
oAcc := Acc_Child(oAcc, 2), oAcc := Acc_Child(oAcc, 2)

vRet := 0
For each, oChild in Acc_Children(oAcc)
{
if (A_Index = vNum+1)
if (1, oChild.accDoDefaultAction(0), vRet := A_Index)
break
}

Return vRet
}

;==================================================

JEE_ChromeTabExists(hWnd, vTitle)
{
oAcc := Acc_ObjectFromWindow(hWnd)
oAcc := Acc_Child(oAcc, 1), oAcc := Acc_Child(oAcc, 2)
oAcc := Acc_Child(oAcc, 2), oAcc := Acc_Child(oAcc, 2)

vCount := 0
vRet := 0
For each, oChild in Acc_Children(oAcc)
{
vTabText := oChild.accName(0)
if (InStr(vTabText,vTitle))
	Return 1
}

oAcc := ""
Return 0
}

JEE_ChromeFocusTabByName(hWnd, vTitle, vNum=1)
{
if(vTitle="")
	return 0
oAcc := Acc_ObjectFromWindow(hWnd)
oAcc := Acc_Child(oAcc, 1), oAcc := Acc_Child(oAcc, 2)
oAcc := Acc_Child(oAcc, 2), oAcc := Acc_Child(oAcc, 2)

vCount := 0
vRet := 0
For each, oChild in Acc_Children(oAcc)
{
vTabText := oChild.accName(0)
if (InStr(vTabText,vTitle))
vCount ++
if (vCount = vNum)
if (1, oChild.accDoDefaultAction(0), vRet := A_Index)
break
}

oAcc := ""
Return vRet
}

;==================================================
