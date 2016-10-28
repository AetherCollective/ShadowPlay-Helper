#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icon.ico
#AutoIt3Wrapper_Outfile=C:\Users\betal\OneDrive\Documents\Scripts\ShadowPlay Helper\ShadowPlay Helper.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <File.au3>
#include <MsgBoxConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <TrayConstants.au3>
#include <WindowsConstants.au3>
Global $WinTitle = "ShadowPlay Helper"
Global $hotkey, $sVideoPath

;Detect ShadowPlay Saved Video Path
$sBinaryVideoPath = RegRead("HKEY_CURRENT_USER\SOFTWARE\NVIDIA Corporation\Global\ShadowPlay\NVSPCAPS", "DefaultPathW")
If @error Then MsgBox(BitOR($MB_ICONERROR, $MB_SYSTEMMODAL, $MB_SETFOREGROUND), $WinTitle, "Could not detect Video Path. Nvidia ShadowPlay is either not installed or not properly configured. Exiting.")

;Convert detected path from binary to string so we can use it and remove the whitespace
$sVideoPath = BinaryToString($sBinaryVideoPath, 2)
$sVideoPath = StringStripWS($sVideoPath, 2)


;Setup
$hotkey = RegRead("HKEY_CURRENT_USER\SOFTWARE\BetaLeaf Software\ShadowPlay Helper", "Hotkey")
If @error Then _ShowGUI()
HotKeySet($hotkey, "_ViewLastFile")
Opt("TrayAutoPause", 0)
Opt("TrayOnEventMode", 1)
Opt("TrayMenuMode", 2)
$tBoot = TrayCreateItem("Start on Boot")
TrayItemSetOnEvent($tBoot, "_ToggleStartWithWindows")
If RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ShadowPlay Helper") <> "" Then
	TrayItemSetState($tBoot, $TRAY_CHECKED)
Else
	TrayItemSetState($tBoot, $TRAY_UNCHECKED)
EndIf
TrayCreateItem("Configure")
TrayItemSetOnEvent(-1, "_ShowGUI")
While 1
	Sleep(60000)
WEnd
Func _ViewLastFile()
	; Get All Directories in Search Path
	$aFolders = _FileListToArrayRec($sVideoPath, "*", BitOR($FLTA_FOLDERS, $FLTAR_NOHIDDEN), $FLTAR_RECUR)
	If IsArray($aFolders) = 0 Then
		TrayTip($WinTitle, "Nothing to playback.", 5)
		Return -1 ;No folders to search.
	EndIf
	$LatestFolder = ""
	$LatestFile = ""
	$LatestTime = 0
	For $i = 1 To $aFolders[0]
		$search = FileFindFirstFile($sVideoPath & "\" & $aFolders[$i] & "\*.mp4")

		; Check if the search was successful
		If $search <> -1 Then
			While 1
				$file = FileFindNextFile($search)
				If @error Then ExitLoop
				If StringInStr(FileGetAttrib($sVideoPath & "\" & $aFolders[$i] & "\" & $file), "D") > 0 Then
					; Skip directories
				Else
					$FileTime = FileGetTime($sVideoPath & "\" & $aFolders[$i] & "\" & $file, 0, 1)
					If $FileTime > $LatestTime Then
						$LatestFolder = $aFolders[$i]
						$LatestFile = $file
						$LatestTime = $FileTime
					EndIf
				EndIf
			WEnd
			FileClose($search)
		EndIf
	Next
	If $LatestFile = "" Then
		TrayTip($WinTitle, "Nothing to playback.", 5)
		Return -1 ;No video to playback.
	EndIf
	ShellExecute($sVideoPath & "\" & $LatestFolder & "\" & $LatestFile)
EndFunc   ;==>_ViewLastFile
Func _ShowGUI()
	$Form1 = GUICreate($WinTitle, 543, 35)
	$Label1 = GUICtrlCreateLabel("View Last Recorded Video:", 8, 8, 133, 17)
	$Ctrl = GUICtrlCreateCheckbox("Ctrl", 144, 8, 32, 17)
	$Alt = GUICtrlCreateCheckbox("Alt", 182, 8, 30, 17)
	$Shift = GUICtrlCreateCheckbox("Shift", 214, 8, 38, 17)
	$Windows = GUICtrlCreateCheckbox("Windows", 254, 8, 60, 17)
	$Button1 = GUICtrlCreateButton("Save", 464, 1, 75, 32)
	$Input1 = GUICtrlCreateInput("", 320, 8, 137, 21)
	$sKey = ""
	If $hotkey <> "" Then
		$tKey = $hotkey
		If StringInStr($tKey, "^") > 0 Then
			GUICtrlSetState($Ctrl, 1)
			$tKey = StringReplace($tKey, "^", "")
		EndIf
		If StringInStr($tKey, "!") > 0 Then
			GUICtrlSetState($Alt, 1)
			$tKey = StringReplace($tKey, "!", "")
		EndIf
		If StringInStr($tKey, "+") > 0 Then
			GUICtrlSetState($Shift, 1)
			$tKey = StringReplace($tKey, "+", "")
		EndIf
		If StringInStr($tKey, "#") > 0 Then
			GUICtrlSetState($Windows, 1)
			$tKey = StringReplace($tKey, "#", "")
		EndIf
		$tKey = StringTrimRight(StringTrimLeft($tKey, 1), 1)
		GUICtrlSetData($Input1, $tKey)
	EndIf
	GUISetState()
	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				If $hotkey <> "" Then
					GUISetState(@SW_HIDE)
					ExitLoop
				Else
					Exit
				EndIf
			Case $Button1
				If StringLen(GUICtrlRead($Input1)) > 0 Then
					If GUICtrlRead($Ctrl) = $GUI_CHECKED Then $sKey &= "^"
					If GUICtrlRead($Alt) = $GUI_CHECKED Then $sKey &= "!"
					If GUICtrlRead($Shift) = $GUI_CHECKED Then $sKey &= "+"
					If GUICtrlRead($Windows) = $GUI_CHECKED Then $sKey &= "#"

					$sKey &= "{"
					$sKey &= GUICtrlRead($Input1)
					$sKey &= "}"

					RegWrite("HKEY_CURRENT_USER\SOFTWARE\BetaLeaf Software\ShadowPlay Helper", "Hotkey", "Reg_SZ", $sKey)
					If $hotkey <> "" Then HotKeySet($hotkey)
					$hotkey = RegRead("HKEY_CURRENT_USER\SOFTWARE\BetaLeaf Software\ShadowPlay Helper", "Hotkey")
					HotKeySet($hotkey, "_ViewLastFile")
					GUISetState(@SW_HIDE)
					ExitLoop
				Else
					MsgBox(BitOR($MB_ICONINFORMATION, $MB_SYSTEMMODAL, $MB_SETFOREGROUND), $WinTitle, "Hotkey cannot be blank.")
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>_ShowGUI
Func _ToggleStartWithWindows()
	RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ShadowPlay Helper")
	If @error Then
		If RegWrite("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ShadowPlay Helper", "Reg_SZ", @ScriptFullPath) = 1 Then
			TrayItemSetState($tBoot, $TRAY_CHECKED)
		Else
			TrayTip($WinTitle, "Could not enable Start with Windows!", 5)
		EndIf
	Else
		If MsgBox(BitOR($MB_ICONQUESTION, $MB_YESNO, $MB_SYSTEMMODAL, $MB_SETFOREGROUND), $WinTitle, "Are you sure?") = $IDYES Then
			If RegDelete("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "ShadowPlay Helper") <> 1 Then
				TrayTip($WinTitle, "Could not disable Start with Windows!", 5)
			Else
				TrayItemSetState($tBoot, $TRAY_UNCHECKED)
			EndIf
		EndIf
	EndIf
EndFunc   ;==>_ToggleStartWithWindows
