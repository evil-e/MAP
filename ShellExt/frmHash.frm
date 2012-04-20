VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "mscomctl.ocx"
Begin VB.Form frmHash 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "Directory File Hasher - Right Click on ListView for Menu Options"
   ClientHeight    =   3765
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   9150
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3765
   ScaleWidth      =   9150
   StartUpPosition =   2  'CenterScreen
   Begin MSComctlLib.ListView lv 
      Height          =   3735
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   9105
      _ExtentX        =   16060
      _ExtentY        =   6588
      View            =   3
      LabelEdit       =   1
      MultiSelect     =   -1  'True
      LabelWrap       =   0   'False
      HideSelection   =   0   'False
      OLEDropMode     =   1
      FullRowSelect   =   -1  'True
      GridLines       =   -1  'True
      _Version        =   393217
      ForeColor       =   -2147483640
      BackColor       =   -2147483643
      BorderStyle     =   1
      Appearance      =   1
      OLEDropMode     =   1
      NumItems        =   3
      BeginProperty ColumnHeader(1) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         Text            =   "File"
         Object.Width           =   3528
      EndProperty
      BeginProperty ColumnHeader(2) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   1
         Text            =   "Byte Size"
         Object.Width           =   2647
      EndProperty
      BeginProperty ColumnHeader(3) {BDD1F052-858B-11D1-B16A-00C0F0283628} 
         SubItemIndex    =   2
         Text            =   "md5"
         Object.Width           =   5292
      EndProperty
   End
   Begin VB.Menu mnuPopup 
      Caption         =   "mnuPopup"
      Visible         =   0   'False
      Begin VB.Menu mnuCopyTable 
         Caption         =   "Copy Table"
      End
      Begin VB.Menu mnuCopyHashs 
         Caption         =   "Copy Hashs"
      End
      Begin VB.Menu mnuDiv 
         Caption         =   "-"
      End
      Begin VB.Menu mnuDisplayUnique 
         Caption         =   "Display unique"
      End
      Begin VB.Menu mnuVTAll 
         Caption         =   "Virus Total Lookup On All"
      End
      Begin VB.Menu mnuVTLookupSelected 
         Caption         =   "Virus Total Lookup On Selected"
      End
      Begin VB.Menu mnudivider 
         Caption         =   "-"
      End
      Begin VB.Menu mnuDeleteSelected 
         Caption         =   "Deleted Selected Files"
      End
      Begin VB.Menu mnuDeleteDuplicates 
         Caption         =   "Delete All Duplicates"
      End
   End
End
Attribute VB_Name = "frmHash"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'License: Copyright (C) 2005 David Zimmer <david@idefense.com, dzzie@yahoo.com>
'
'         This program is free software; you can redistribute it and/or modify it
'         under the terms of the GNU General Public License as published by the Free
'         Software Foundation; either version 2 of the License, or (at your option)
'         any later version.
'
'         This program is distributed in the hope that it will be useful, but WITHOUT
'         ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
'         FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
'         more details.
'
'         You should have received a copy of the GNU General Public License along with
'         this program; if not, write to the Free Software Foundation, Inc., 59 Temple
'         Place, Suite 330, Boston, MA 02111-1307 USA

'7-6-05 Added Delete All Duplicates option
'4-19-12 moved buttons to right click menu options, integrated VirusTotal.exe options

Dim path As String


Sub HashDir(dPath As String)
   
    On Error GoTo out
    Dim f() As String, i As Long
    Dim pf As String
    
    'MsgBox "entering hash dir"
    
    path = dPath
    pf = fso.GetParentFolder(path) & "\"
    pf = Replace(path, pf, Empty)
    
    Me.Caption = Me.Caption & "    Folder: " & pf
        
    If Not fso.FolderExists(dPath) Then
        MsgBox "Folder not found: " & dPath
        GoTo done
    End If
        
    'MsgBox "getting files"
     
    f() = fso.GetFolderFiles(dPath)
    
    If AryIsEmpty(f) Then
        MsgBox "No files in this directory", vbInformation
        GoTo done
    End If
     
    'MsgBox "Going to scan " & UBound(f) & " files"
     
    For i = 0 To UBound(f)
         handleFile f(i)
    Next
    
    'MsgBox "ready to show"
     
    On Error Resume Next
    Me.Show 1
   
    Exit Sub
out:
    MsgBox "HashFiles Error: " & Err.Description, vbExclamation
done:
    'Unload Me
    End
End Sub



Function KeyExistsInCollection(c As Collection, val As String) As Boolean
    On Error GoTo nope
    Dim t
    t = c(val)
    KeyExistsInCollection = True
 Exit Function
nope: KeyExistsInCollection = False
End Function

Private Sub lv_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
    If Button = vbRightButton Then PopupMenu mnuPopup
End Sub

Private Sub mnuCopyHashs_Click()
    Dim li As ListItem
    Dim t As String
    
    For Each li In lv.ListItems
        t = t & li.SubItems(2) & vbCrLf
    Next
    
    Clipboard.Clear
    Clipboard.SetText t
    MsgBox "Copy Complete", vbInformation
End Sub

Private Sub mnuDeleteDuplicates_Click()
    
    Dim li As ListItem
    Dim hashs As New Collection
    Dim h As String
    Dim f As String
    
    Const msg As String = "Are you sure you want to DELETE all DUPLICATE files?"
    If MsgBox(msg, vbYesNo) = vbNo Then Exit Sub
    
    For Each li In lv.ListItems
        h = li.SubItems(2)
        If KeyExistsInCollection(hashs, h) Then
            li.Tag = "DeleteMe"
        Else
            li.Tag = ""
            hashs.Add h, h
        End If
    Next
        
nextone:
    For Each li In lv.ListItems
        If li.Tag = "DeleteMe" Then
            f = path & "\" & li.Text
            If fso.FileExists(f) Then
                Kill f
            End If
            lv.ListItems.Remove li.Index
            GoTo nextone
        End If
    Next
    
End Sub

Private Sub mnuDisplayUnique_Click()

     Dim li As ListItem
     Dim hashs As New Collection 'to perform unique value lookup and corrolate to ary index
     Dim h() As String 'count per hash    '\_matched arrays
     Dim b() As String 'actual hash value '/
     Dim hash As String
     Dim v As Long
     Dim i As Long
     
     On Error GoTo hell
     
     ReDim h(0) 'we cant use 0 anyway cause collections index start at 1
     ReDim b(0)
     
     For Each li In lv.ListItems
        hash = li.SubItems(2)
        If KeyExistsInCollection(hashs, hash) Then
            i = hashs(hash)
            h(i) = h(i) + 1
        Else
            push h, 1
            push b, hash
            i = UBound(h)
            hashs.Add i, hash
        End If
     Next
     
     Dim tmp() As String
         
     For i = 1 To UBound(h)
        push tmp, h(i) & "   -   " & b(i)
     Next
     
     Dim t As String
     t = Environ("TMP")
     If Len(t) = 0 Then t = Environ("TEMP")
     If Len(t) = 0 Or Not fso.FolderExists(t) Then
            MsgBox Join(tmp, vbCrLf)
            Exit Sub
     End If
     
     t = fso.GetFreeFileName(t)
     fso.WriteFile t, Join(tmp, vbCrLf)
     
     Shell "notepad """ & t & """", vbNormalFocus
     fso.DeleteFile t
     
Exit Sub
hell: MsgBox Err.Description
End Sub

Private Sub mnuDeleteSelected_Click()
    Dim li As ListItem
    Dim f As String
    On Error Resume Next
    
    Const msg As String = "Are you sure you want to delete these files?"
    If MsgBox(msg, vbYesNo + vbInformation) = vbNo Then Exit Sub
    
    
nextone:
    For Each li In lv.ListItems
        If li.Selected Then
            f = path & "\" & li.Text
            If fso.FileExists(f) Then
                Kill f
            End If
            lv.ListItems.Remove li.Index
            GoTo nextone
        End If
    Next
    
End Sub


Private Sub mnuCopyTable_Click()

    Dim li As ListItem
    Dim t As String
    
    For Each li In lv.ListItems
        t = t & li.Text & vbTab & li.SubItems(1) & vbTab & li.SubItems(2) & vbCrLf
    Next
    
    Clipboard.Clear
    Clipboard.SetText t
    MsgBox "Copy Complete", vbInformation
    
End Sub

Sub handleFile(f As String)
    Dim h  As String
    Dim li As ListItem
     
    h = LCase(hash.HashFile(f))
    
    If Len(h) = 0 Then
        'MsgBox "ok had hash error"
        MsgBox "Hash Error: " & hash.error_message
        Err.Raise 1, "HandleFile", "HashError"
    End If
    
    Set li = lv.ListItems.Add(, , fso.FileNameFromPath(f))
    li.SubItems(1) = FileLen(f)
    li.SubItems(2) = h
    li.Tag = f
    
End Sub



Private Sub Form_Load()
    lv.ColumnHeaders(3).Width = lv.Width - lv.ColumnHeaders(3).Left - 100
End Sub

Private Sub Form_Resize()
    On Error Resume Next
    lv.Width = Me.Width - lv.Left - 140
    lv.Height = Me.Height - lv.Top - 140
End Sub

Private Sub mnuVTAll_Click()

    On Error Resume Next
    Dim li As ListItem
    Dim t As String
    
    For Each li In lv.ListItems
        t = t & li.SubItems(2) & vbCrLf
    Next
    
    If Len(t) = 0 Then Exit Sub
    
    Clipboard.Clear
    Clipboard.SetText t
    Shell App.path & "\virustotal.exe /bulk", vbNormalFocus
    
End Sub

Private Sub mnuVTLookupSelected_Click()
    On Error Resume Next
    Dim hashs() As String
    Dim li As ListItem
    Dim h As String
    Dim i As Long
    
    For Each li In lv.ListItems
        If li.Selected Then
            h = li.SubItems(2)
            If Len(h) > 0 Then
                push hashs, li.SubItems(2)
                i = i + 1
            End If
        End If
    Next

    If i = 0 Then
        MsgBox "No items were selected!", vbInformation
        Exit Sub
    End If
    
    If i = 1 Then
        Shell App.path & "\virustotal.exe """ & lv.SelectedItem.Tag & """", vbNormalFocus
    Else
        Clipboard.Clear
        Clipboard.SetText Join(hashs, vbCrLf)
        Shell App.path & "\virustotal.exe /bulk", vbNormalFocus
    End If
    
End Sub