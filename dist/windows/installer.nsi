; installer.nsi
;
; NSIS install script for counterpartyd
!include "StrFunc.nsh"
!include ReplaceInFile.nsh ;for ReplaceInFile
!include nsDialogs.nsh ;for install dialogs
!include LogicLib.nsh ;for install dialogs
!include EnvVarUpdate.nsh ;to add counterpartyd path to PATH

;--------------------------------

; The name of the installer
Name "counterpartyd"

; The file to write
OutFile "counterpartyd_install.exe"

; The default installation directory
!ifdef IS_64BIT
InstallDir $PROGRAMFILES64\counterpartyd
!else
InstallDir $PROGRAMFILES\counterpartyd
!endif

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\counterpartyd" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

LicenseData "..\counterpartyd\LICENSE"

;--------------------------------

; Pages
Page license
Page components
Page directory
Page custom nsGetBitcoindConfigSettings nsSaveBitcoindConfigSettings
Page custom nsGetCounterpartydConfigSettings nsSaveCounterpartydConfigSettings
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

; Variables
Var Dialog
Var lblLabel
Var lblHostname
Var lblPort
Var lblUsername
Var lblPassword
Var txtHostname
Var txtPort
Var txtUsername
Var pwdPassword

Var lblXCPLabel
Var lblXCPHostname
Var lblXCPPort
Var lblXCPUsername
Var lblXCPPassword
Var txtXCPHostname
Var txtXCPPort
Var txtXCPUsername
Var pwdXCPPassword

Var dataHostname
Var dataPort
Var dataUsername
Var dataPassword

Var dataXCPHostname
Var dataXCPPort
Var dataXCPUsername
Var dataXCPPassword

;--------------------------------
Function nsGetBitcoindConfigSettings
  ;see http://www.symantec.com/connect/articles/update-sql-your-nsis-installer
  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog

  ${If} $Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 24u "Please enter in your bitcoind connection information:"
  Pop $lblLabel

  ${NSD_CreateLabel} 0 24u 36u 12u "Hostname"
  Pop $lblHostname

  ${NSD_CreateLabel} 0 36u 36u 12u "Port"
  Pop $lblPort

  ${NSD_CreateLabel} 0 48u 36u 12u "Username"
  Pop $lblUsername

  ${NSD_CreateLabel} 0 60u 36u 12u "Password"
  Pop $lblPassword

  ${NSD_CreateText} 36u 24u 100% 12u "localhost"
  Pop $txtHostname

  ${NSD_CreateText} 36u 36u 100% 12u "8332"
  Pop $txtPort

  ${NSD_CreateText} 36u 48u 100% 12u "rpc"
  Pop $txtUsername

  ${NSD_CreatePassword} 36u 60u 100% 12u ""
  Pop $pwdPassword

  nsDialogs::Show
FunctionEnd

Function nsSaveBitcoindConfigSettings
  ;get entered data
  ${NSD_GetText} $txtHostname $dataHostname
  ${NSD_GetText} $txtPort $dataPort
  ${NSD_GetText} $txtUsername $dataUsername
  ${NSD_GetText} $pwdPassword $dataPassword

  ${If} $dataPassword == ""
        MessageBox MB_OK "REQUIRED: Please enter a password to use with bitcoind authentication"
        Abort
  ${EndIf}  
FunctionEnd

Function nsGetCounterpartydConfigSettings
  nsDialogs::Create /NOUNLOAD 1018
  Pop $Dialog

  ${If} $Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 24u "Please enter in the info on how counterpartyd should listen for API requests:"
  Pop $lblXCPLabel

  ${NSD_CreateLabel} 0 24u 36u 12u "bind to"
  Pop $lblXCPHostname

  ${NSD_CreateLabel} 0 36u 36u 12u "bind port"
  Pop $lblXCPPort

  ${NSD_CreateLabel} 0 48u 36u 12u "username"
  Pop $lblXCPUsername

  ${NSD_CreateLabel} 0 60u 36u 12u "password"
  Pop $lblXCPPassword

  ${NSD_CreateText} 36u 24u 100% 12u "localhost"
  Pop $txtXCPHostname

  ${NSD_CreateText} 36u 36u 100% 12u "4000"
  Pop $txtXCPPort

  ${NSD_CreateText} 36u 48u 100% 12u "counterpartyrpc"
  Pop $txtXCPUsername

  ${NSD_CreatePassword} 36u 60u 100% 12u ""
  Pop $pwdXCPPassword

  nsDialogs::Show
FunctionEnd

Function nsSaveCounterpartydConfigSettings
  ;get entered data
  ${NSD_GetText} $txtXCPHostname $dataXCPHostname
  ${NSD_GetText} $txtXCPPort $dataXCPPort
  ${NSD_GetText} $txtXCPUsername $dataXCPUsername
  ${NSD_GetText} $pwdXCPPassword $dataXCPPassword
  
  ${If} $dataXCPPassword == ""
        MessageBox MB_OK "REQUIRED: Please enter a password to use with counterpartyd API authentication"
        Abort
  ${EndIf}  
FunctionEnd

;--------------------------------
; The stuff to install
Section "counterpartyd (required)"

  SectionIn RO
  InitPluginsDir

  SetShellVarContext current
  Var /GLOBAL CPDATADIR
  StrCpy $CPDATADIR "$APPDATA\Counterparty\counterpartyd"
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File "..\..\bin\build\*"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\counterpartyd "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\counterpartyd" "DisplayName" "counterpartyd"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\counterpartyd" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\counterpartyd" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\counterpartyd" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
  
  ;copy in the config file
  CreateDirectory $CPDATADIR
  CopyFiles $INSTDIR\counterpartyd.conf.default $CPDATADIR\counterpartyd.conf
  
  ;modify the config file based on what was entered earlier by the user
  !insertmacro _ReplaceInFile "$CPDATADIR\counterpartyd.conf" "BITCOIND_RPC_CONNECT" "$dataHostname"
  !insertmacro _ReplaceInFile "$CPDATADIR\counterpartyd.conf" "BITCOIND_RPC_PORT" "$dataPort"
  !insertmacro _ReplaceInFile "$CPDATADIR\counterpartyd.conf" "BITCOIND_RPC_USER" "$dataUsername"
  !insertmacro _ReplaceInFile "$CPDATADIR\counterpartyd.conf" "BITCOIND_RPC_PASSWORD" "$dataPassword"

  !insertmacro _ReplaceInFile "$CPDATADIR\counterpartyd.conf" "RPC_HOST" "$dataXCPHostname"
  !insertmacro _ReplaceInFile "$CPDATADIR\counterpartyd.conf" "RPC_PORT" "$dataXCPPort"
  !insertmacro _ReplaceInFile "$CPDATADIR\counterpartyd.conf" "RPC_USER" "$dataXCPUsername"
  !insertmacro _ReplaceInFile "$CPDATADIR\counterpartyd.conf" "RPC_PASSWORD" "$dataXCPPassword"
  
  ; Install a service - ServiceType own process - StartType automatic - NoDependencies - Logon as System Account
  ;SimpleSC::InstallService "counterpartyd" "Counterparty Daemon" "16" "2" "$INSTDIR\counterpartyd.exe" "" "" ""
  ;Pop $0 ; returns an errorcode (<>0) otherwise success (0)
  
  ; Start a service. Be sure to pass the service name, not the display name.
  ;SimpleSC::StartService "counterpartyd" "" 30
  ;Pop $0 ; returns an errorcode (<>0) otherwise success (0)
SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"
  CreateDirectory "$SMPROGRAMS\counterpartyd"
  CreateShortCut "$SMPROGRAMS\counterpartyd\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\counterpartyd\counterpartyd.lnk" "$INSTDIR\counterpartyd.exe" "--log-file=-" "$INSTDIR\counterpartyd.exe" 0
SectionEnd

; Optional section (can be disabled by the user)
Section "Start counterpartyd on Login?"
  CreateShortCut "$SMSTARTUP\counterpartyd.lnk" "$INSTDIR\counterpartyd.exe" "--log-file=-" "$INSTDIR\counterpartyd.exe" 0
SectionEnd

; Optional section (can be disabled by the user)
Section "Add to PATH?"
  ;add the counterpartyd to PATH
  ${EnvVarUpdate} $0 "PATH" "A" "HKCU" "$INSTDIR"  
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  ; Stop a service and waits for file release. Be sure to pass the service name, not the display name.
  ;SimpleSC::StopService "counterpartyd" 1 30
  ;Pop $0 ; returns an errorcode (<>0) otherwise success (0)
  
  ; Remove a service
  ;SimpleSC::RemoveService "counterpartyd"
  ;Pop $0 ; returns an errorcode (<>0) otherwise success (0)
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\counterpartyd"
  DeleteRegKey HKLM SOFTWARE\counterpartyd

  ; Remove files and uninstaller
  RMDir /r $INSTDIR

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\counterpartyd\*.*"
  Delete "$SMSTARTUP\counterpartyd.lnk"

  ; Remove directories used
  RMDir "$SMPROGRAMS\counterpartyd"
  RMDir "$INSTDIR"
SectionEnd
