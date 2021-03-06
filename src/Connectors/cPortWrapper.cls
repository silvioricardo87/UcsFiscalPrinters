VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cPortWrapper"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'=========================================================================
'
' UcsFP20 (c) 2008-2019 by Unicontsoft
'
' Unicontsoft Fiscal Printers Component 2.0
'
' This project is licensed under the terms of the MIT license
' See the LICENSE file in the project root for more information
'
'=========================================================================
'
' Persistent COM port wrapper
'
'=========================================================================
Option Explicit
DefObj A-Z
Private Const MODULE_NAME As String = "cPortWrapper"

#Const ImplUseShared = (USE_SHARED <> 0)

#If Not ImplUseShared Then
    Private Logger                  As Object
#End If

'=========================================================================
' API
'=========================================================================

'--- for CreateFile
Private Const GENERIC_READ                  As Long = &H80000000
Private Const GENERIC_WRITE                 As Long = &H40000000
Private Const OPEN_EXISTING                 As Long = 3
Private Const INVALID_HANDLE_VALUE          As Long = -1
Private Const FILE_FLAG_OVERLAPPED          As Long = &H40000000

Private Declare Function CreateFile Lib "kernel32" Alias "CreateFileA" (ByVal lpFileName As String, ByVal dwDesiredAccess As Long, ByVal dwShareMode As Long, ByVal lpSecurityAttributes As Long, ByVal dwCreationDisposition As Long, ByVal dwFlagsAndAttributes As Long, ByVal hTemplateFile As Long) As Long
Private Declare Function CloseHandle Lib "kernel32" (ByVal hObject As Long) As Long

'=========================================================================
' Constants and member variables
'=========================================================================

Private m_sPort             As String
Private m_hComm             As Long
Private m_bReleased         As Boolean

'=========================================================================
' Error handling
'=========================================================================

Private Sub PrintError(sFunction As String)
    Debug.Print "Critical error: " & Err.Description & " [" & MODULE_NAME & "." & sFunction & "]"
    If Not Logger Is Nothing Then
        Logger.Log vbLogEventTypeError, MODULE_NAME, sFunction & "(" & Erl & ")", Err.Description
    End If
End Sub

'=========================================================================
' Methods
'=========================================================================

Public Function OpenComPort(sPort As String, ByVal bPersistent As Boolean) As Long
    Const FUNC_NAME     As String = "OpenComPort"
    
    On Error GoTo EH
    If bPersistent Then
        If LCase$(m_sPort) <> LCase$(sPort) Or m_hComm = 0 Then
            If m_hComm <> 0 And m_bReleased Then
                If m_hComm <> INVALID_HANDLE_VALUE Then
                    Call CloseHandle(m_hComm)
                End If
                m_hComm = 0
            End If
            m_hComm = CreateFile("\\.\" & sPort, GENERIC_READ Or GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0)
            m_sPort = IIf(m_hComm <> INVALID_HANDLE_VALUE, sPort, vbNullString)
        End If
        OpenComPort = m_hComm
        m_bReleased = False
    Else
        If LCase$(m_sPort) = LCase$(sPort) Then
            If m_hComm <> 0 And m_bReleased Then
                If m_hComm <> INVALID_HANDLE_VALUE Then
                    Call CloseHandle(m_hComm)
                End If
                m_hComm = 0
            End If
        End If
        OpenComPort = CreateFile("\\.\" & sPort, GENERIC_READ Or GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0)
    End If
    Exit Function
EH:
    PrintError FUNC_NAME
    Resume Next
End Function

Public Function CloseComPort(ByVal hComm As Long, Optional ByVal ClearPersistent As Boolean) As Long
    Const FUNC_NAME     As String = "CloseComPort"
    Dim vErr            As Variant
    
    vErr = Array(Err.Number, Err.Description, Err.Source)
    If (hComm = 0 Or hComm = INVALID_HANDLE_VALUE) And Not ClearPersistent Then
        Exit Function
    End If
    On Error GoTo EH
    If hComm <> m_hComm Then
        If hComm <> INVALID_HANDLE_VALUE Then
            CloseComPort = CloseHandle(hComm)
        End If
    Else
        m_bReleased = True
    End If
    If ClearPersistent Then
        If m_hComm <> 0 Then
            If m_hComm <> INVALID_HANDLE_VALUE Then
                Call CloseHandle(m_hComm)
            End If
            m_hComm = 0
            m_sPort = vbNullString
        End If
    End If
QH:
    On Error GoTo 0
    Err.Number = vErr(0)
    Err.Description = vErr(1)
    Err.Source = vErr(2)
    Exit Function
EH:
    PrintError FUNC_NAME
    Resume QH
End Function

#If Not ImplUseShared Then

Private Sub FlushDebugLog()

End Sub

#End If

'=========================================================================
' Base class events
'=========================================================================

Private Sub Class_Terminate()
    Const FUNC_NAME     As String = "Class_Terminate"
    Dim vErr            As Variant
    
    vErr = Array(Err.Number, Err.Description, Err.Source)
    On Error GoTo EH
    If m_hComm <> 0 Then
        If m_hComm <> INVALID_HANDLE_VALUE Then
            Call CloseHandle(m_hComm)
        End If
        m_hComm = 0
        m_sPort = vbNullString
    End If
    FlushDebugLog
QH:
    On Error GoTo 0
    Err.Number = vErr(0)
    Err.Description = vErr(1)
    Err.Source = vErr(2)
    Exit Sub
EH:
    PrintError FUNC_NAME
    Resume QH
End Sub
