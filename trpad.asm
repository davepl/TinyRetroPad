; --------------------------------------------------------- 
;  _____      _             _____          _ 
; |  __ \    | |           |  __ \        | |
; | |__) |___| |_ _ __ ___ | |__) |_ _  __| |
; |  _  // _ \ __| '__/ _ \|  ___/ _` |/ _` |
; | | \ \  __/ |_| | | (_) | |  | (_| | (_| |
; |_|  \_\___|\__|_|  \___/|_|   \__,_|\__,_|
; T I N Y  X 86   D E S K T O P   E D I T O R                                            
; --------------------------------------------------------- 
; (c) 2026 Plummer's Software, Ltd.
; Based on Dave's Tiny Editor 2.0.9 
;  which was
; Based on Dave Plummer's Tiny App
; ---------------------------------------------------------
; Dave's Tiny Editor (DTE)
; Copyright (c) 2026 Matthew M. Power
; Licensed under the Apache License, Version 2.0.
; See LICENSE and NOTICE files in this repository.
; ---------------------------------------------------------
;
; Growth History:
; Added FILE Menus - 1375 Bytes
; Added EDIT Menus - 1428 Bytes
; Expanded FILE Menus (Open/Save As) - 1517 Bytes
; Added HELP Menus - 1557 Bytes
; Added FILE Save Prompt Flow - 1622 Bytes
; Added EDIT Time/Date - 1668 Bytes
; Added FORMAT Word Wrap - 1694 Bytes
; Added Right-Click Context Menu - 1779 Bytes
; Added FORMAT Font Dialog - 1910 Bytes
; Added EDIT Find/FindNext/Replace - 2143 Bytes
; Added FILE Print - 2476 Bytes
; Added VIEW Status Bar (Ln/Col) - 2476 Bytes
; Added DIALOG based Feature - 2686 Bytes
; Added KEYBOARD accelerators - 2794 Bytes
; Compiler directives and includes:
 
.386                       ; Full 80386 instruction set and mode
.model flat, stdcall       ; All 32-bit and later apps are flat. Used to include "tiny, etc"
option casemap:none        ; Preserve the case of system identifiers but not our own, more or less

; =====================  FEATURE MENU  =====================
; Optional features are gated behind assembly-time switches.
; Set a switch to 1 to compile the feature in, or 0 to leave
; it out entirely.  With every switch 0 the output is byte-
; for-byte the original baseline build (2686 bytes); a feature
; only costs space when it is switched on.
FEAT_LINENUMBERS = 0       ; View > Line Numbers gutter (default OFF)
FEAT_DARKMODE    = 0       ; View > Dark Mode (default OFF)
; ==========================================================

; Include files - headers and libs that we need for
; calling the system dlls like user32, kernel32, etc
include windows.inc        ; Main windows header file (akin to Windows.h in C)
include user32.inc         ; Windows, controls, etc
include kernel32.inc       ; Handles, modules, paths, etc
;include gdi32.inc         ; Removed because no GDI used for editor
                           ; Rich Edit font is set without GDI
                           ; using EM_SETCHARFORMAT

WindowWidth         equ 800        ; window startup size
WindowHeight        equ 640
IDC_EDIT            equ 1001       ; good ole EDIT control from WinAPI
EM_EXLIMITTEXT      equ WM_USER+53 ; Rich Edit: raise user editing text limit
EM_SETCHARFORMAT    equ WM_USER+68 ; Rich Edit: set text format
EM_SETEVENTMASK     equ WM_USER+69 ; Rich Edit: choose which notifications parent gets
EM_SETTARGETDEVICE  equ WM_USER+72 ; Rich Edit: wrapping target width
SCF_ALL             equ 00000004h  ; Rich Edit: apply format to all text
ENM_CHANGE          equ 00000001h  ; Rich Edit: send EN_CHANGE notifications
CFM_FACE            equ 20000000h  ; Rich Edit: use font face name
MAX_CMD_PATH        equ 128        ; holds startup file path from dropped file
MAX_TITLE           equ 128        ; holds window title text (file name and if dirty * )
IDM_SAVE            equ 0E100h     ; Save menu ID (WM_SYSCOMMAND)
IDM_FILE_NEW        equ 0E200h
IDM_FILE_EXIT       equ 0E201h
IDM_FILE_OPEN       equ 0E202h
IDM_FILE_SAVEAS     equ 0E203h
IDM_FILE_PRINT      equ 0E204h
IDM_FILE_PAGESETUP  equ 0E205h
IDM_EDIT_UNDO       equ 0E210h
IDM_EDIT_CUT        equ 0E211h
IDM_EDIT_COPY       equ 0E212h
IDM_EDIT_PASTE      equ 0E213h
IDM_EDIT_DELETE     equ 0E214h
IDM_EDIT_SELALL     equ 0E215h
IDM_EDIT_TIME       equ 0E216h
IDM_EDIT_FIND       equ 0E217h
IDM_EDIT_FINDNEXT   equ 0E218h
IDM_EDIT_REPLACE    equ 0E219h
IDM_EDIT_GOTO       equ 0E21Ah
IDM_FMT_WRAP        equ 0E220h
IDM_FMT_FONT        equ 0E221h
IDM_VIEW_STATUS     equ 0E230h
IDM_HELP_ABOUT      equ 0E240h
IDM_HELP_VIEWHELP   equ 0E241h
IDC_GOEDIT          equ 1000         ; Go To dialog edit field id
EM_FORMATRANGE      equ WM_USER+57   ; Rich Edit: render text to a DC (printing)
SBHEIGHT            equ 20           ; status bar height in pixels

IF FEAT_LINENUMBERS
; ---- constants used only by the Line Numbers gutter feature ----
IFNDEF EM_GETLINECOUNT
EM_GETLINECOUNT  equ 0BAh
ENDIF
IFNDEF EM_GETFIRSTVISIBLELINE
EM_GETFIRSTVISIBLELINE equ 0CEh
ENDIF
IFNDEF EM_POSFROMCHAR
EM_POSFROMCHAR   equ 0D6h
ENDIF
IFNDEF ENM_UPDATE
ENM_UPDATE       equ 2h
ENDIF
IFNDEF ENM_SCROLL
ENM_SCROLL       equ 4h
ENDIF
IFNDEF EN_UPDATE
EN_UPDATE        equ 0400h
ENDIF
IFNDEF EN_VSCROLL
EN_VSCROLL       equ 0602h
ENDIF
IFNDEF TRANSPARENT
TRANSPARENT      equ 1
ENDIF
IFNDEF COLOR_BTNFACE
COLOR_BTNFACE    equ 15
ENDIF
LN_MARGIN_W      equ 44           ; gutter width in pixels
LN_PAD           equ 6            ; left padding of the numbers
IDM_VIEW_LINENUM equ 0E231h       ; View > Line Numbers command id
ENDIF

IF FEAT_DARKMODE
; ---- constants used only by the Dark Mode feature ----
IFNDEF CFM_COLOR
CFM_COLOR        equ 40000000h
ENDIF
IFNDEF CFE_AUTOCOLOR
CFE_AUTOCOLOR    equ 40000000h
ENDIF
EM_SETBKGNDCOLOR equ WM_USER+67   ; Rich Edit: set background color
DARK_BG          equ 001E1E1Eh    ; gutter/edit dark background (00BBGGRR)
DARK_FG          equ 00DCDCDCh    ; light text on dark
IDM_VIEW_DARK    equ 0E232h       ; View > Dark Mode command id
ENDIF

.DATA

EXTERN _imp__CreateWindowExA@48    :PTR ; create main window / EDIT control
EXTERN _imp__GetModuleHandleA@4    :PTR ; get HINSTANCE
EXTERN _imp__LoadLibraryA@4        :PTR ; load modern Rich Edit DLL
EXTERN _imp__RegisterClassA@4      :PTR ; rgstr wndw class (was RegisterClassExA@4)
EXTERN _imp__GetMessageA@16        :PTR ; message loop get
EXTERN _imp__TranslateMessage@4    :PTR ; translate keys
EXTERN _imp__DispatchMessageA@4    :PTR ; dispatch to WndProc
EXTERN _imp__PostQuitMessage@4     :PTR ; exit message loop
EXTERN _imp__DefWindowProcA@16     :PTR ; default window handling
EXTERN _imp__SetWindowPos@28       :PTR ; resize EDIT control
EXTERN _imp__GetCommandLineA@0     :PTR ; get startup file path
EXTERN _imp__CreateFileA@28        :PTR ; open file (read/write)
EXTERN _imp__GetFileSize@8         :PTR ; get file size
EXTERN _imp__GlobalAlloc@8         :PTR ; allocate buffer
EXTERN _imp__GlobalFree@4          :PTR ; free buffer
EXTERN _imp__ReadFile@20           :PTR ; read file into EDIT
EXTERN _imp__WriteFile@20          :PTR ; save EDIT to file
EXTERN _imp__CloseHandle@4         :PTR ; close file handle
EXTERN _imp__SetWindowTextA@8      :PTR ; set title / EDIT text
EXTERN _imp__GetSystemMenu@8       :PTR ; get system menu
EXTERN _imp__AppendMenuA@16        :PTR ; add Save menu item
EXTERN _imp__CreateMenu@0          :PTR ; create main menu bar
EXTERN _imp__CreatePopupMenu@0     :PTR ; create each drop-down menu
EXTERN _imp__SetMenu@8             :PTR ; attach menu bar to main window
EXTERN _imp__DestroyWindow@4       :PTR ; close main window
EXTERN _imp__GetOpenFileNameA@4    :PTR ; common file open dialog
EXTERN _imp__GetSaveFileNameA@4    :PTR ; common file save dialog
EXTERN _imp__GetLocalTime@4        :PTR ; current local time
EXTERN _imp__GetDateFormatA@24     :PTR ; date formatting
EXTERN _imp__GetTimeFormatA@24     :PTR ; time formatting
EXTERN _imp__MessageBoxA@16        :PTR ; simple About dialog
EXTERN _imp__TrackPopupMenu@28     :PTR ; show context popup menu
EXTERN _imp__DestroyMenu@4         :PTR ; free a menu handle
EXTERN _imp__GetMessagePos@0       :PTR ; screen coords of last msg
EXTERN _imp__GetKeyState@4         :PTR ; shortcut modifier state
EXTERN _imp__SendMessageA@16       :PTR ; talk to EDIT control
EXTERN _imp__ChooseFontW@4         :PTR ; common font picker dialog
EXTERN _imp__FindTextA@4           :PTR ; common Find dialog
EXTERN _imp__ReplaceTextA@4        :PTR ; common Replace dialog
EXTERN _imp__RegisterWindowMessageA@4 :PTR ; FINDMSGSTRING message id
EXTERN _imp__IsDialogMessageA@8    :PTR ; route keys to find dialog
EXTERN _imp__PrintDlgA@4           :PTR ; common Print dialog (returns DC)
EXTERN _imp__StartDocA@8           :PTR ; begin print job
EXTERN _imp__StartPage@4           :PTR ; begin a printed page
EXTERN _imp__EndPage@4             :PTR ; finish a printed page
EXTERN _imp__EndDoc@4              :PTR ; finish print job
EXTERN _imp__GetDeviceCaps@8       :PTR ; printer resolution/size
EXTERN _imp__DeleteDC@4            :PTR ; release printer DC
EXTERN _imp__ShowWindow@8          :PTR ; show/hide status bar
EXTERN _imp__GetClientRect@8       :PTR ; client size for relayout
EXTERN _imp__wsprintfA            :PTR ; format Ln/Col string
EXTERN _imp__ShellExecuteA@24      :PTR ; open help URL in browser
EXTERN _imp__PageSetupDlgA@4       :PTR ; common Page Setup dialog
EXTERN _imp__DialogBoxIndirectParamA@20 :PTR ; in-memory Go To dialog
EXTERN _imp__GetDlgItemInt@16      :PTR ; read Go To line number
EXTERN _imp__EndDialog@8           :PTR ; close Go To dialog
EXTERN _imp__SetFocus@4            :PTR ; focus edit control after commands
EXTERN _imp__ExitProcess@4         :PTR ; terminate process cleanly

IF FEAT_LINENUMBERS
EXTERN _imp__BeginPaint@8          :PTR ; begin gutter paint
EXTERN _imp__EndPaint@8            :PTR ; end gutter paint
EXTERN _imp__FillRect@12           :PTR ; fill gutter background
EXTERN _imp__GetSysColorBrush@4    :PTR ; gutter background brush
EXTERN _imp__InvalidateRect@12     :PTR ; force gutter repaint
EXTERN _imp__SetBkMode@8           :PTR ; transparent number text
EXTERN _imp__TextOutA@20           :PTR ; draw the line numbers
ENDIF

IF FEAT_DARKMODE
EXTERN _imp__GetMenu@4             :PTR ; menu bar for the check mark
EXTERN _imp__CheckMenuItem@12      :PTR ; check/uncheck Dark Mode
ENDIF

ClassName   db ".",0                ; save bytes here (seems to work)
RichDll     db "Msftedit",0         ; Rich Edit DLL (no ext saves those bytes)
EditClass   db "RICHEDIT50W",0      ; modern Rich Edit control from WinAPI
SaveText    db "Save",0             ; button added to system menu
EmptyText   db 0

hMain       dd 0                    ; main window handle
hEdit       dd 0                    ; EDIT control handle
CmdFile     db MAX_CMD_PATH dup (0) ; startup file path buffer
TitleBuf    db MAX_TITLE dup    (0) ; window title buffer
BytesRead   dd 0                    ; bytes read from file
fDirty      dd 0                    ; EDIT modified flag
fWrap       dd 1                    ; word wrap state

UntitledText db "Untitled",0
NotepadTail  db " - TinyRetroPad",0

MFile       db "&File",0
MEdit       db "&Edit",0
MFormat     db "F&ormat",0
MView       db "&View",0
MHelp       db "&Help",0

MNew        db "&New",0
MOpen       db "&Open...",0
MSaveMenu   db "&Save",0
MSaveAs     db "Save &As...",0
MPageSetup  db "Page Set&up...",0
MPrint      db "&Print...",0
MExit       db "E&xit",0

MUndo       db "&Undo",0
MCut        db "Cu&t",0
MCopy       db "&Copy",0
MPaste      db "&Paste",0
MDelete     db "De&lete",0
MFind       db "&Find...",0
MFindNext   db "Find &Next",0
MReplace    db "&Replace...",0
MGoTo       db "&Go To...",0
MSelectAll  db "Select &All",0
MTimeDate   db "Time/&Date",0

MWordWrap   db "&Word Wrap",0
MFont       db "&Font...",0

MStatusBar  db "&Status Bar",0

MViewHelp   db "&View Help",0
MAbout      db "&About TinyRetroPad",0
AboutCap    db "TinyRetroPad",0
AboutText   db "TinyRetroPad - tiny notepad-style editor",0
SaveCap     db "TinyRetroPad",0
SaveAskText db "Save changes?",0
SpaceText   db " ",0
DateBuf     db 32 dup (0)
TimeBuf     db 32 dup (0)
FileFilter  db "All Files",0,"*.*",0,0

FindMsgStr  db "commdlg_FindReplace",0
FindWhat    db 128 dup (0)         ; Find What text buffer
ReplaceWith db 128 dup (0)         ; Replace With text buffer
fr          FINDREPLACEA <>        ; shared find/replace request
hFindDlg    dd 0                   ; modeless find/replace dialog HWND
uFindMsg    dd 0                   ; registered FINDMSGSTRING message

StaticClass db "STATIC",0          ; built-in class for status bar pane
DocName     db "TinyRetroPad",0    ; print job document name
LnColFmt    db "  Ln %d, Col %d",0 ; status bar Ln/Col format
StatusBuf   db 48 dup (0)          ; formatted Ln/Col text
hStatus     dd 0                   ; status bar window handle
fStatus     dd 1                   ; status bar visible flag (default ON)

IF FEAT_LINENUMBERS
fLineNum    dd 0                   ; line-number gutter visible flag (default OFF)
LnNumFmt    db "%d",0              ; gutter number format
MLineNum    db "Line &Numbers",0   ; View menu label
ENDIF

IF FEAT_DARKMODE
fDark       dd 0                   ; dark mode flag (default OFF)
MDarkMode   db "Dark &Mode",0      ; View menu label
ENDIF

hInst       dd 0                   ; module handle (for dialogs)
OpenVerb    db "open",0            ; ShellExecute verb
HelpUrl     db "https://github.com/davepl",0

; in-memory Go To dialog template (no font block to stay compact)
ALIGN 4
GoToTmpl LABEL DWORD
    dd  DS_MODALFRAME or WS_POPUP or WS_CAPTION or WS_SYSMENU
    dd  0                          ; exStyle
    dw  2                          ; control count
    dw  0,0,150,46                 ; x,y,cx,cy
    dw  0                          ; no menu
    dw  0                          ; default class
    dw  'G','o',' ','T','o',0      ; caption
    ALIGN 4
    dd  WS_CHILD or WS_VISIBLE or WS_BORDER or ES_NUMBER or WS_TABSTOP
    dd  0
    dw  7,7,136,12                 ; edit rect
    dw  IDC_GOEDIT
    dw  0FFFFh,0081h               ; Edit class atom
    dw  0                          ; no caption
    dw  0                          ; no creation data
    ALIGN 4
    dd  WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON or WS_TABSTOP
    dd  0
    dw  50,26,50,14                ; OK button rect
    dw  IDOK
    dw  0FFFFh,0080h               ; Button class atom
    dw  'O','K',0                  ; caption
    dw  0                          ; no creation data

; Rich Edit default font face: Courier only
RichFont    dd 92                   ; CHARFORMATW size
            dd CFM_FACE             ; only set face name
            dd 0                    ; no effects
            dd 0                    ; no font size change
            dd 0                    ; no offset change
            dd 0                    ; no color change
            db 0                    ; default charset
            db 0                    ; default pitch/family
            dw 'C','o','u','r','i','e','r',0
            dw 24 dup (0)
            dw 0                    ; CHARFORMATW padding


;----------------------------------------------;
.CODE ; Here is where the program itself lives ;
;----------------------------------------------;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; title bar caption from startup file name ;
; add "*" if the buffer has been modified  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BuildTitle proc NEAR    
    lea     edi, TitleBuf
    mov     esi, OFFSET CmdFile

    ; no file argument: use Untitled
    cmp     byte ptr [esi], 0
    jne     FindFileTail
    mov     esi, OFFSET UntitledText
    jmp     CopyBase

    ; strip full path to filename when a file was provided
    FindFileTail:
    mov     ebx, esi

    FindTail:
        mov     al, [esi]
        test    al, al
        je      GotTail
	
        cmp     al, '\'
        je      MarkTail
	
	;; surprised me disabling this works
        ;cmp     al, '/'
        ;je      MarkTail
        ;cmp     al, ':'
        ;je      MarkTail
	
        inc     esi
        jmp     FindTail

    ; record start of next path segment (looking for file name)
    MarkTail:
        mov     ebx, esi
        inc     ebx
        inc     esi
        jmp     FindTail


    ; point to filename (tail of path)
    GotTail:
        mov     esi, ebx

    ; copy the filename into the title buffer
    CopyBase:
    CopyLoop:
        mov     al, [esi]
        test    al, al
        je      CopyEnd
        mov     [edi], al
        inc     edi
        inc     esi
        jmp     CopyLoop

    CopyEnd:
        mov     esi, OFFSET NotepadTail

    ; append " - Notepad"
    CopyTail:
        mov     al, [esi]
        mov     [edi], al
        inc     edi
        inc     esi
        test    al, al
        jne     CopyTail

    ; done
    TitleDone:
        ret
BuildTitle endp ; end BuildTitle proc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; build title and set title bar caption ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ApplyTitle proc NEAR
    call    BuildTitle
    push    OFFSET TitleBuf
    mov     eax, hMain
    push    eax
    call    [_imp__SetWindowTextA@8]
    ret
ApplyTitle endp ;end ApplyTitle proc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; parse command line for the startup file or  ;
; if user drops a file on the app to launch   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ParseStartupFile proc NEAR
    call    [_imp__GetCommandLineA@0]
    mov     esi, eax
    test    esi, esi
    je      NoArg
    cmp     byte ptr [esi], '"'
    jne     SkipExeBare
    inc     esi
 
    ; skip quoted exe path so esi points to first argument
    SkipExeQuoted:
        mov     al, [esi]
        test    al, al
        je      NoArg
        inc     esi
        cmp     al, '"'
        jne     SkipExeQuoted
        jmp     SkipWs

    ; skip unquoted exe path to reach first argument
    SkipExeBare:
        mov     al, [esi]
        test    al, al
        je      NoArg
        cmp     al, ' '
        je      SkipWs
        cmp     al, 9
        je      SkipWs
        inc     esi
        jmp     SkipExeBare

    ; skip spaces/tabs before argument (white spaces)
    SkipWs:
        mov     al, [esi]
        cmp     al, ' '
        je      SkipWsStep
        cmp     al, 9
        je      SkipWsStep
        jmp     ArgStart

    ; advance past whitespace
    SkipWsStep:
        inc     esi
        jmp     SkipWs

    ; start copying first argument (file path), handle quoted
    ArgStart:
        cmp     byte ptr [esi], 0
        je      NoArg

        lea     edi, CmdFile
        mov     ecx, MAX_CMD_PATH-1

        cmp     byte ptr [esi], '"'
        jne     CopyBare
        inc     esi

    ; copy quoted file path into CmdFile (strip quotes)
    CopyQuoted:
        mov     al, [esi]
        test    al, al
        je      CopyDone
        cmp     al, '"'
        je      CopyDone
        mov     [edi], al
        inc     edi
        inc     esi
        dec     ecx
        jz      CopyDone
        jmp     CopyQuoted

    ; copy unquoted file path into CmdFile
    CopyBare:
        mov     al, [esi]
        test    al, al
        je      CopyDone
        cmp     al, ' '
        je      CopyDone
        cmp     al, 9
        je      CopyDone
        mov     [edi], al
        inc     edi
        inc     esi
        dec     ecx
        jz      CopyDone
        jmp     CopyBare

    ; null-terminate CmdFile and return
    CopyDone:
        mov     byte ptr [edi], 0
        ret

    ; no arg: clear CmdFile (no startup file)
    NoArg:
        mov     byte ptr [CmdFile], 0
        ret
ParseStartupFile endp ; end ParseStartupFile proc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start a new empty document                ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NewFile proc NEAR
    mov     byte ptr [CmdFile], 0
    push    OFFSET EmptyText
    mov     eax, hEdit
    push    eax
    call    [_imp__SetWindowTextA@8]
    xor     eax, eax
    mov     fDirty, eax
    call    ApplyTitle
    ret
NewFile endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; open-file dialog into CmdFile buffer       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PickOpenFile proc NEAR
    LOCAL ofn:OPENFILENAMEA

    push    19
    pop     ecx
    xor     eax, eax
    lea     edi, ofn
    rep stosd

    mov     byte ptr [CmdFile], 0
    mov     ofn.lStructSize, SIZEOF OPENFILENAMEA
    mov     eax, hMain
    mov     ofn.hwndOwner, eax
    mov     ofn.lpstrFilter, OFFSET FileFilter
    mov     ofn.lpstrFile, OFFSET CmdFile
    mov     ofn.nMaxFile, MAX_CMD_PATH
    mov     ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_HIDEREADONLY

    lea     eax, ofn
    push    eax
    call    [_imp__GetOpenFileNameA@4]
    ret
PickOpenFile endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; save-file dialog into CmdFile buffer       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PickSaveFile proc NEAR
    LOCAL ofn:OPENFILENAMEA

    push    19
    pop     ecx
    xor     eax, eax
    lea     edi, ofn
    rep stosd

    mov     ofn.lStructSize, SIZEOF OPENFILENAMEA
    mov     eax, hMain
    mov     ofn.hwndOwner, eax
    mov     ofn.lpstrFilter, OFFSET FileFilter
    mov     ofn.lpstrFile, OFFSET CmdFile
    mov     ofn.nMaxFile, MAX_CMD_PATH
    mov     ofn.Flags, OFN_PATHMUSTEXIST or OFN_HIDEREADONLY or OFN_OVERWRITEPROMPT

    lea     eax, ofn
    push    eax
    call    [_imp__GetSaveFileNameA@4]
    ret
PickSaveFile endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ask user whether to save dirty buffer      ;
; returns eax=1 continue / eax=0 cancel      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MaybeSaveChanges proc NEAR
    cmp     fDirty, 0
    jne     AskSave
    push    1
    pop     eax
    ret

    AskSave:
        push    MB_YESNOCANCEL or MB_ICONQUESTION
        push    OFFSET SaveCap
        push    OFFSET SaveAskText
        mov     eax, hMain
        push    eax
        call    [_imp__MessageBoxA@16]

        cmp     eax, IDCANCEL
        jne     NotCancel
        xor     eax, eax
        ret

    NotCancel:
        cmp     eax, IDNO
        jne     NeedSave
        push    1
        pop     eax
        ret

    NeedSave:
        cmp     byte ptr [CmdFile], 0
        jne     SaveNow
        call    PickSaveFile
        test    eax, eax
        jne     SaveNow
        xor     eax, eax
        ret

    SaveNow:
        call    SaveFile
        push    1
        pop     eax
        ret
MaybeSaveChanges endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; insert current date/time at caret          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InsertTimeDate proc NEAR
    LOCAL sysTime:SYSTEMTIME

    lea     eax, sysTime
    push    eax
    call    [_imp__GetLocalTime@4]

    push    32
    push    OFFSET DateBuf
    push    0                       ; lpFormat (use locale default)
    lea     eax, sysTime
    push    eax                     ; lpDate
    push    DATE_SHORTDATE          ; dwFlags
    push    LOCALE_USER_DEFAULT
    call    [_imp__GetDateFormatA@24]

    push    32
    push    OFFSET TimeBuf
    push    0                       ; lpFormat (use locale default)
    lea     eax, sysTime
    push    eax                     ; lpTime
    push    0                       ; dwFlags
    push    LOCALE_USER_DEFAULT
    call    [_imp__GetTimeFormatA@24]

    push    OFFSET DateBuf
    push    TRUE
    push    EM_REPLACESEL
    mov     eax, hEdit
    push    eax
    call    [_imp__SendMessageA@16]

    push    OFFSET SpaceText
    push    TRUE
    push    EM_REPLACESEL
    mov     eax, hEdit
    push    eax
    call    [_imp__SendMessageA@16]

    push    OFFSET TimeBuf
    push    TRUE
    push    EM_REPLACESEL
    mov     eax, hEdit
    push    eax
    call    [_imp__SendMessageA@16]

    ret
InsertTimeDate endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; toggle Rich Edit word-wrap mode             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ToggleWrap proc NEAR
    cmp     fWrap, 0
    je      WrapOn

    ; wrap off: use a very wide target line
    xor     eax, eax
    mov     fWrap, eax
    push    0FFFFFFFFh
    push    0
    push    EM_SETTARGETDEVICE
    mov     eax, hEdit
    push    eax
    call    [_imp__SendMessageA@16]
    ret

    WrapOn:
        push    1
        pop     eax
        mov     fWrap, eax
        push    0
        push    0
        push    EM_SETTARGETDEVICE
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        ret
ToggleWrap endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; pick a font via common dialog, apply to text ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ChooseFontDlg proc NEAR
    LOCAL lf:LOGFONTW
    LOCAL cf:CHOOSEFONTW
    LOCAL fmt:CHARFORMATW

    ; zero CHOOSEFONT and LOGFONT structs
    xor     eax, eax
    lea     edi, cf
    mov     ecx, (SIZEOF CHOOSEFONTW)/4
    rep     stosd
    lea     edi, lf
    mov     ecx, (SIZEOF LOGFONTW)/4
    rep     stosd

    mov     cf.lStructSize, SIZEOF CHOOSEFONTW
    mov     eax, hMain
    mov     cf.hwndOwner, eax
    lea     eax, lf
    mov     cf.lpLogFont, eax
    mov     cf.Flags, CF_SCREENFONTS or CF_EFFECTS

    lea     eax, cf
    push    eax
    call    [_imp__ChooseFontW@4]
    test    eax, eax
    je      FontCancel

    ; build CHARFORMATW from chosen font
    xor     eax, eax
    lea     edi, fmt
    mov     ecx, (SIZEOF CHARFORMATW)/4
    rep     stosd

    mov     fmt.cbSize, SIZEOF CHARFORMATW
    mov     fmt.dwMask, CFM_FACE or CFM_SIZE or CFM_BOLD or CFM_ITALIC

    ; bold/italic effects
    xor     edx, edx
    cmp     lf.lfWeight, 700
    jl      FNoBold
    or      edx, CFE_BOLD
  FNoBold:
    cmp     lf.lfItalic, 0
    je      FNoItal
    or      edx, CFE_ITALIC
  FNoItal:
    mov     fmt.dwEffects, edx

    ; yHeight (twips) = iPointSize (1/10 pt) * 2
    mov     eax, cf.iPointSize
    add     eax, eax
    mov     fmt.yHeight, eax

    ; copy wide face name into CHARFORMATW
    lea     esi, lf.lfFaceName
    lea     edi, fmt.szFaceName
    mov     ecx, LF_FACESIZE
  FCopyFace:
    mov     ax, [esi]
    mov     [edi], ax
    add     esi, 2
    add     edi, 2
    test    ax, ax
    je      FApply
    dec     ecx
    jnz     FCopyFace

  FApply:
    lea     eax, fmt
    push    eax
    push    SCF_ALL
    push    EM_SETCHARFORMAT
    mov     eax, hEdit
    push    eax
    call    [_imp__SendMessageA@16]

  FontCancel:
    ret
ChooseFontDlg endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fill shared FINDREPLACE request struct      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InitFR proc NEAR
    xor     eax, eax
    lea     edi, fr
    mov     ecx, (SIZEOF FINDREPLACEA)/4
    rep     stosd
    mov     fr.lStructSize, SIZEOF FINDREPLACEA
    mov     eax, hMain
    mov     fr.hwndOwner, eax
    mov     fr.lpstrFindWhat, OFFSET FindWhat
    mov     fr.wFindWhatLen, 128
    mov     fr.lpstrReplaceWith, OFFSET ReplaceWith
    mov     fr.wReplaceWithLen, 128
    mov     fr.Flags, FR_DOWN
    ret
InitFR endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; find next match of FindWhat, select it       ;
; returns eax=1 found / eax=0 not found        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DoFindNext proc NEAR
    LOCAL ft:FINDTEXTEXA
    LOCAL cr:CHARRANGE

    ; current selection range
    lea     eax, cr
    push    eax
    push    0
    push    EM_EXGETSEL
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]

    ; search from end of selection to end of text
    mov     eax, cr.cpMax
    mov     ft.chrg.cpMin, eax
    mov     ft.chrg.cpMax, -1
    mov     eax, OFFSET FindWhat
    mov     ft.lpstrText, eax

    mov     eax, fr.Flags
    and     eax, FR_MATCHCASE
    or      eax, FR_DOWN

    lea     edx, ft
    push    edx
    push    eax
    push    EM_FINDTEXTEXA
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]

    cmp     eax, -1
    je      FindMiss

    ; select the match
    lea     edx, ft.chrgText
    push    edx
    push    0
    push    EM_EXSETSEL
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]

    push    0
    push    0
    push    EM_SCROLLCARET
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]

    push    1
    pop     eax
    ret

  FindMiss:
    xor     eax, eax
    ret
DoFindNext endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; replace current match then advance           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DoReplaceOne proc NEAR
    push    OFFSET ReplaceWith
    push    TRUE
    push    EM_REPLACESEL
    mov     eax, hEdit
    push    eax
    call    [_imp__SendMessageA@16]
    call    DoFindNext
    ret
DoReplaceOne endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; replace every match from the top             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DoReplaceAll proc NEAR
    LOCAL cr:CHARRANGE

    ; move caret to start of text
    mov     cr.cpMin, 0
    mov     cr.cpMax, 0
    lea     eax, cr
    push    eax
    push    0
    push    EM_EXSETSEL
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]

  RepLoop:
    call    DoFindNext
    test    eax, eax
    jz      RepDone
    push    OFFSET ReplaceWith
    push    TRUE
    push    EM_REPLACESEL
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]
    jmp     RepLoop

  RepDone:
    ret
DoReplaceAll endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; dispatch a FINDMSGSTRING notification        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OnFindReplaceMsg proc NEAR
    mov     eax, fr.Flags
    test    eax, FR_DIALOGTERM
    jz      NotTerm
    mov     dword ptr hFindDlg, 0
    ret
  NotTerm:
    test    eax, FR_REPLACEALL
    jz      NotRepAll
    call    DoReplaceAll
    ret
  NotRepAll:
    test    eax, FR_REPLACE
    jz      JustFind
    call    DoReplaceOne
    ret
  JustFind:
    call    DoFindNext
    ret
OnFindReplaceMsg endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; print document via common dialog + Rich Edit ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintDoc proc NEAR
    LOCAL pd:PRINTDLGA
    LOCAL docInf:DOCINFOA
    LOCAL fmt:FORMATRANGE
    LOCAL txtLen:DWORD
    LOCAL hPrnDC:DWORD

    ; show Print dialog, request a printer DC
    xor     eax, eax
    lea     edi, pd
    mov     ecx, SIZEOF PRINTDLGA
    rep     stosb
    mov     pd.lStructSize, SIZEOF PRINTDLGA
    mov     eax, hMain
    mov     pd.hwndOwner, eax
    mov     pd.Flags, PD_RETURNDC or PD_NOPAGENUMS or PD_NOSELECTION
    lea     eax, pd
    push    eax
    call    [_imp__PrintDlgA@4]
    test    eax, eax
    je      PrintCancel
    mov     eax, pd.hDC
    mov     hPrnDC, eax

    ; begin document
    xor     eax, eax
    lea     edi, docInf
    mov     ecx, SIZEOF DOCINFOA
    rep     stosb
    mov     docInf.cbSize, SIZEOF DOCINFOA
    mov     docInf.lpszDocName, OFFSET DocName
    lea     eax, docInf
    push    eax
    push    hPrnDC
    call    [_imp__StartDocA@8]

    ; prepare FORMATRANGE
    xor     eax, eax
    lea     edi, fmt
    mov     ecx, SIZEOF FORMATRANGE
    rep     stosb
    mov     eax, hPrnDC
    mov     fmt.hdc, eax
    mov     fmt.hdcTarget, eax

    ; page width in twips = HORZRES * 1440 / LOGPIXELSX
    push    HORZRES
    push    hPrnDC
    call    [_imp__GetDeviceCaps@8]
    mov     esi, eax
    push    LOGPIXELSX
    push    hPrnDC
    call    [_imp__GetDeviceCaps@8]
    mov     ecx, eax
    mov     eax, esi
    imul    eax, 1440
    xor     edx, edx
    div     ecx
    mov     fmt.rc.right, eax
    mov     fmt.rcPage.right, eax

    ; page height in twips = VERTRES * 1440 / LOGPIXELSY
    push    VERTRES
    push    hPrnDC
    call    [_imp__GetDeviceCaps@8]
    mov     esi, eax
    push    LOGPIXELSY
    push    hPrnDC
    call    [_imp__GetDeviceCaps@8]
    mov     ecx, eax
    mov     eax, esi
    imul    eax, 1440
    xor     edx, edx
    div     ecx
    mov     fmt.rc.bottom, eax
    mov     fmt.rcPage.bottom, eax

    ; render range = whole document
    push    0
    push    0
    push    WM_GETTEXTLENGTH
    mov     eax, hEdit
    push    eax
    call    [_imp__SendMessageA@16]
    mov     txtLen, eax
    mov     fmt.chrg.cpMin, 0
    mov     fmt.chrg.cpMax, eax

  PrintPage:
    push    hPrnDC
    call    [_imp__StartPage@4]

    lea     eax, fmt
    push    eax
    push    TRUE
    push    EM_FORMATRANGE
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]
    mov     fmt.chrg.cpMin, eax     ; next page starts here
    push    eax

    push    hPrnDC
    call    [_imp__EndPage@4]

    pop     eax
    cmp     eax, txtLen
    jl      PrintPage

    ; flush formatting cache, end document, free DC
    push    0
    push    0
    push    EM_FORMATRANGE
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]
    push    hPrnDC
    call    [_imp__EndDoc@4]
    push    hPrnDC
    call    [_imp__DeleteDC@4]

  PrintCancel:
    ret
PrintDoc endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; refresh status bar Ln/Col from caret pos    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdateStatus proc NEAR
    LOCAL cr:CHARRANGE
    LOCAL lnNum:DWORD

    cmp     fStatus, 0
    je      UpdDone

    ; current caret character index
    lea     eax, cr
    push    eax
    push    0
    push    EM_EXGETSEL
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]

    ; 0-based line of caret -> 1-based
    push    cr.cpMax
    push    0
    push    EM_EXLINEFROMCHAR
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]
    mov     esi, eax
    inc     eax
    mov     lnNum, eax

    ; first char index of that line
    push    0
    push    esi
    push    EM_LINEINDEX
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]

    ; column = caret - lineStart + 1
    mov     edx, cr.cpMax
    sub     edx, eax
    inc     edx

    ; format and display
    push    edx
    push    lnNum
    push    OFFSET LnColFmt
    push    OFFSET StatusBuf
    call    [_imp__wsprintfA]
    add     esp, 16
    push    OFFSET StatusBuf
    mov     eax, hStatus
    push    eax
    call    [_imp__SetWindowTextA@8]

  UpdDone:
    ret
UpdateStatus endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; re-lay-out edit/status using client size    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RelayoutClient proc NEAR
    LOCAL rc:RECT
    lea     eax, rc
    push    eax
    push    hMain
    call    [_imp__GetClientRect@8]
    mov     ecx, rc.right
    and     ecx, 0FFFFh
    mov     eax, rc.bottom
    shl     eax, 16
    or      eax, ecx
    push    eax
    push    0
    push    WM_SIZE
    push    hMain
    call    [_imp__SendMessageA@16]
    ret
RelayoutClient endp

IF FEAT_LINENUMBERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; invalidate the line-number gutter strip     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LnInvalidate proc NEAR hW:DWORD
    LOCAL rc:RECT
    cmp     fLineNum, 0
    je      LnInvDone
    mov     rc.left, 0
    mov     rc.top, 0
    mov     rc.right, LN_MARGIN_W
    mov     rc.bottom, 7FFFh
    push    FALSE
    lea     eax, rc
    push    eax
    push    hW
    call    [_imp__InvalidateRect@12]
  LnInvDone:
    ret
LnInvalidate endp
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; show the common Page Setup dialog            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PageSetup proc NEAR
    LOCAL psd:PAGESETUPDLGA
    xor     eax, eax
    lea     edi, psd
    mov     ecx, SIZEOF PAGESETUPDLGA
    rep     stosb
    mov     psd.lStructSize, SIZEOF PAGESETUPDLGA
    mov     eax, hMain
    mov     psd.hwndOwner, eax
    lea     eax, psd
    push    eax
    call    [_imp__PageSetupDlgA@4]
    ret
PageSetup endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Go To dialog procedure                      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GoToProc proc hDlg:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    mov     eax, uMsg
    cmp     eax, WM_INITDIALOG
    je      GpTrue
    cmp     eax, WM_COMMAND
    jne     GpFalse
    mov     eax, wParam
    and     eax, 0FFFFh
    cmp     eax, IDOK
    je      GpOk
    cmp     eax, IDCANCEL
    jne     GpFalse
    push    0
    push    hDlg
    call    [_imp__EndDialog@8]
    jmp     GpTrue
  GpOk:
    push    FALSE
    push    0
    push    IDC_GOEDIT
    push    hDlg
    call    [_imp__GetDlgItemInt@16]
    push    eax
    push    hDlg
    call    [_imp__EndDialog@8]
  GpTrue:
    push    1
    pop     eax
    ret
  GpFalse:
    xor     eax, eax
    ret
GoToProc endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; prompt for a line number and jump to it     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GoToDlg proc NEAR
    LOCAL cr:CHARRANGE

    push    0
    push    OFFSET GoToProc
    push    hMain
    push    OFFSET GoToTmpl
    push    hInst
    call    [_imp__DialogBoxIndirectParamA@20]

    ; eax = 1-based line, 0 = cancel/invalid
    test    eax, eax
    je      GoDone
    dec     eax

    ; char index of that line's first character
    push    0
    push    eax
    push    EM_LINEINDEX
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]
    cmp     eax, -1
    je      GoDone

    ; move caret there and scroll into view
    mov     cr.cpMin, eax
    mov     cr.cpMax, eax
    lea     edx, cr
    push    edx
    push    0
    push    EM_EXSETSEL
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]
    push    0
    push    0
    push    EM_SCROLLCARET
    mov     edx, hEdit
    push    edx
    call    [_imp__SendMessageA@16]

    ; activate the edit control so the caret shows
    mov     eax, hEdit
    push    eax
    call    [_imp__SetFocus@4]

  GoDone:
    ret
GoToDlg endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; right-click context menu at cursor position ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ShowContextMenu proc NEAR hWndOwner:DWORD
    LOCAL hCtx:DWORD

    call    [_imp__CreatePopupMenu@0]
    mov     hCtx, eax
    push    OFFSET MUndo
    push    IDM_EDIT_UNDO
    push    eax
    call    AppendEnabled
    push    0
    push    hCtx
    call    AppendDisabled
    push    OFFSET MCut
    push    IDM_EDIT_CUT
    push    hCtx
    call    AppendEnabled
    push    OFFSET MCopy
    push    IDM_EDIT_COPY
    push    hCtx
    call    AppendEnabled
    push    OFFSET MPaste
    push    IDM_EDIT_PASTE
    push    hCtx
    call    AppendEnabled
    push    OFFSET MDelete
    push    IDM_EDIT_DELETE
    push    hCtx
    call    AppendEnabled
    push    0
    push    hCtx
    call    AppendDisabled
    push    OFFSET MSelectAll
    push    IDM_EDIT_SELALL
    push    hCtx
    call    AppendEnabled
    call    [_imp__GetMessagePos@0]
    movzx   ecx, ax          ; x = LOWORD
    shr     eax, 16          ; y = HIWORD
    push    NULL             ; prcRect
    push    hWndOwner        ; hWnd
    push    0                ; nReserved
    push    eax              ; y
    push    ecx              ; x
    push    0                ; uFlags
    push    hCtx
    call    [_imp__TrackPopupMenu@28]
    push    hCtx
    call    [_imp__DestroyMenu@4]
    ret
ShowContextMenu endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; append one disabled menu item / separator   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
AppendDisabled proc NEAR hMenu:DWORD, pText:DWORD
    cmp     pText, 0
    je      AddSep

    push    pText
    push    0
    push    MF_STRING or MF_GRAYED
    push    hMenu
    call    [_imp__AppendMenuA@16]
    ret

    AddSep:
        push    0
        push    0
        push    MF_SEPARATOR
        push    hMenu
        call    [_imp__AppendMenuA@16]
        ret
AppendDisabled endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; append one enabled menu item               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
AppendEnabled proc NEAR hMenu:DWORD, uID:DWORD, pText:DWORD
    push    pText
    push    uID
    push    MF_STRING
    push    hMenu
    call    [_imp__AppendMenuA@16]
    ret
AppendEnabled endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; build full top menu bar from menu tables    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CreateNotepadMenus proc NEAR hWnd:DWORD
    LOCAL   hMenuBar:DWORD
    LOCAL   hPopup:DWORD

    call    [_imp__CreateMenu@0]
    test    eax, eax
    je      CreateDone
    mov     hMenuBar, eax

    ; File
    call    [_imp__CreatePopupMenu@0]
    mov     hPopup, eax
    push    OFFSET MNew
    push    IDM_FILE_NEW
    push    eax
    call    AppendEnabled
    push    OFFSET MOpen
    push    IDM_FILE_OPEN
    push    hPopup
    call    AppendEnabled
    push    OFFSET MSaveMenu
    push    IDM_SAVE
    push    hPopup
    call    AppendEnabled
    push    OFFSET MSaveAs
    push    IDM_FILE_SAVEAS
    push    hPopup
    call    AppendEnabled
    push    0
    push    hPopup
    call    AppendDisabled
    push    OFFSET MPageSetup
    push    IDM_FILE_PAGESETUP
    push    hPopup
    call    AppendEnabled
    push    OFFSET MPrint
    push    IDM_FILE_PRINT
    push    hPopup
    call    AppendEnabled
    push    0
    push    hPopup
    call    AppendDisabled
    push    OFFSET MExit
    push    IDM_FILE_EXIT
    push    hPopup
    call    AppendEnabled
    push    OFFSET MFile
    mov     eax, hPopup
    push    eax
    push    MF_POPUP or MF_STRING
    mov     eax, hMenuBar
    push    eax
    call    [_imp__AppendMenuA@16]

    ; Edit
    call    [_imp__CreatePopupMenu@0]
    mov     hPopup, eax
    push    OFFSET MUndo
    push    IDM_EDIT_UNDO
    push    eax
    call    AppendEnabled
    push    0
    push    hPopup
    call    AppendDisabled
    push    OFFSET MCut
    push    IDM_EDIT_CUT
    push    hPopup
    call    AppendEnabled
    push    OFFSET MCopy
    push    IDM_EDIT_COPY
    push    hPopup
    call    AppendEnabled
    push    OFFSET MPaste
    push    IDM_EDIT_PASTE
    push    hPopup
    call    AppendEnabled
    push    OFFSET MDelete
    push    IDM_EDIT_DELETE
    push    hPopup
    call    AppendEnabled
    push    0
    push    hPopup
    call    AppendDisabled
    push    OFFSET MFind
    push    IDM_EDIT_FIND
    push    hPopup
    call    AppendEnabled
    push    OFFSET MFindNext
    push    IDM_EDIT_FINDNEXT
    push    hPopup
    call    AppendEnabled
    push    OFFSET MReplace
    push    IDM_EDIT_REPLACE
    push    hPopup
    call    AppendEnabled
    push    OFFSET MGoTo
    push    IDM_EDIT_GOTO
    push    hPopup
    call    AppendEnabled
    push    0
    push    hPopup
    call    AppendDisabled
    push    OFFSET MSelectAll
    push    IDM_EDIT_SELALL
    push    hPopup
    call    AppendEnabled
    push    OFFSET MTimeDate
    push    IDM_EDIT_TIME
    push    hPopup
    call    AppendEnabled
    push    OFFSET MEdit
    mov     eax, hPopup
    push    eax
    push    MF_POPUP or MF_STRING
    mov     eax, hMenuBar
    push    eax
    call    [_imp__AppendMenuA@16]

    ; Format
    call    [_imp__CreatePopupMenu@0]
    mov     hPopup, eax
    push    OFFSET MWordWrap
    push    IDM_FMT_WRAP
    push    eax
    call    AppendEnabled
    push    OFFSET MFont
    push    IDM_FMT_FONT
    push    hPopup
    call    AppendEnabled
    push    OFFSET MFormat
    mov     eax, hPopup
    push    eax
    push    MF_POPUP or MF_STRING
    mov     eax, hMenuBar
    push    eax
    call    [_imp__AppendMenuA@16]

    ; View
    call    [_imp__CreatePopupMenu@0]
    mov     hPopup, eax
    push    OFFSET MStatusBar
    push    IDM_VIEW_STATUS
    push    eax
    call    AppendEnabled
IF FEAT_LINENUMBERS
    push    OFFSET MLineNum
    push    IDM_VIEW_LINENUM
    push    hPopup
    call    AppendEnabled
ENDIF
IF FEAT_DARKMODE
    push    OFFSET MDarkMode
    push    IDM_VIEW_DARK
    push    hPopup
    call    AppendEnabled
ENDIF
    push    OFFSET MView
    mov     eax, hPopup
    push    eax
    push    MF_POPUP or MF_STRING
    mov     eax, hMenuBar
    push    eax
    call    [_imp__AppendMenuA@16]

    ; Help
    call    [_imp__CreatePopupMenu@0]
    mov     hPopup, eax
    push    OFFSET MViewHelp
    push    IDM_HELP_VIEWHELP
    push    eax
    call    AppendEnabled
    push    0
    push    hPopup
    call    AppendDisabled
    push    OFFSET MAbout
    push    IDM_HELP_ABOUT
    push    hPopup
    call    AppendEnabled
    push    OFFSET MHelp
    mov     eax, hPopup
    push    eax
    push    MF_POPUP or MF_STRING
    mov     eax, hMenuBar
    push    eax
    call    [_imp__AppendMenuA@16]

        mov     eax, hMenuBar
        push    eax
        push    hWnd
        call    [_imp__SetMenu@8]

    CreateDone:
        ret
CreateNotepadMenus endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read startup file and populate EDIT control ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LoadStartupFile proc NEAR
    LOCAL hFile:     DWORD
    LOCAL hMem:      DWORD
    LOCAL dwSize:    DWORD

    ; open CmdFile for reading
    push    NULL
    push    FILE_ATTRIBUTE_NORMAL
    push    OPEN_EXISTING
    push    NULL
    push    FILE_SHARE_READ
    push    GENERIC_READ
    push    OFFSET CmdFile
    call    [_imp__CreateFileA@28]

    ; if opened ok save handle / else skip load
    cmp     eax, INVALID_HANDLE_VALUE
    je      LoadDone
    mov     hFile, eax

    ; get file size (bytes)
    push    NULL
    push    eax
    call    [_imp__GetFileSize@8]
    
    ; INVALID_HANDLE_VALUE file open failed
    cmp     eax, 0FFFFFFFFh 
    je      CloseOnly
    mov     dwSize, eax
    
    ; alloc buffer for file (+1 for null)
    inc     eax
    push    eax
    push    GMEM_FIXED
    call    [_imp__GlobalAlloc@8]
    
    ; if alloc ok, save ptr; else close file
    test    eax, eax
    je      CloseOnly
    mov     hMem, eax
    

    ; read file into buffer
    push    NULL
    lea     eax, BytesRead
    push    eax
    mov     eax, dwSize
    push    eax
    mov     eax, hMem
    push    eax
    mov     eax, hFile
    push    eax
    call    [_imp__ReadFile@20]

    ; if read failed, cleanup and abort
    test    eax, eax
    je      FreeLoadBuffer

    ; null-terminate loaded file data
    mov     eax, hMem
    mov     ecx, BytesRead
    mov     byte ptr [eax+ecx], 0

    ; set EDIT text from buffer
    push    eax
    mov     eax, hEdit
    push    eax
    call    [_imp__SetWindowTextA@8]

    ; set Rich Edit font on loaded text
    push    OFFSET RichFont
    push    SCF_ALL
    push    EM_SETCHARFORMAT
    mov     eax, hEdit
    push    eax
    call    [_imp__SendMessageA@16]

    ; free loaded file buffer
    FreeLoadBuffer:
        mov     eax, hMem
        push    eax
        call    [_imp__GlobalFree@4]

    ; close file handle only (if no buffer to free)
    CloseOnly:
        mov     eax, hFile
        push    eax
        call    [_imp__CloseHandle@4]

    LoadDone:
        ret
LoadStartupFile endp ; end LoadStartupFile proc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; save EDIT contents back to CmdFile ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SaveFile proc    NEAR
    LOCAL hFile: DWORD
    LOCAL hMem:  DWORD
    LOCAL dwSize:DWORD

    ; get EDIT text length
    mov     eax, hEdit
    push    0
    push    0
    push    WM_GETTEXTLENGTH
    push    eax
    call    [_imp__SendMessageA@16]

    ; save size and alloc buffer (+1)
    mov     dwSize, eax
    inc     eax
    push    eax
    push    GMEM_FIXED
    call    [_imp__GlobalAlloc@8]

    ; if alloc ok, save ptr / else abort save
    test    eax, eax
    je      SaveDone
    mov     hMem, eax

    ; get EDIT text into buffer
    mov     edx, dwSize
    inc     edx
    push    eax
    push    edx
    push    WM_GETTEXT
    mov     eax, hEdit
    push    eax
    call    [_imp__SendMessageA@16]

    ; open CmdFile for write (overwrite)
    push    NULL
    push    FILE_ATTRIBUTE_NORMAL
    push    CREATE_ALWAYS
    push    NULL
    push    0
    push    GENERIC_WRITE
    push    OFFSET CmdFile
    call    [_imp__CreateFileA@28]

    ; if open ok, save handle; else free buffer
    cmp     eax, INVALID_HANDLE_VALUE
    je      SaveFree
    mov     hFile, eax

    ; write buffer to file
    push    NULL
    lea     eax, BytesRead
    push    eax
    mov     eax, dwSize
    push    eax
    mov     eax, hMem
    push    eax
    mov     eax, hFile
    push    eax
    call    [_imp__WriteFile@20]

    ; close file
    mov     eax, hFile
    push    eax
    call    [_imp__CloseHandle@4]

    ; clear dirty flag and update title
    xor     eax, eax
    mov     fDirty, eax
    call    ApplyTitle

    ; cleanup - free save buffer
    SaveFree:
        mov     eax, hMem
        push    eax
        call    [_imp__GlobalFree@4]

    SaveDone:
        ret
SaveFile endp ;end SaveFile proc

;;;;;;;;;;;;;;;;;;;;;;;
; program entry point ;
;;;;;;;;;;;;;;;;;;;;;;;
MainEntry proc NEAR

    LOCAL   hInstance: HINSTANCE
    LOCAL   wc:        WNDCLASS
    LOCAL   msg:       MSG

    ; get program HINSTANCE
    push    NULL
    call    [_imp__GetModuleHandleA@4]
    mov     hInstance, eax
    mov     hInst, eax

    ; load modern Rich Edit control library
    push    OFFSET RichDll
    call    [_imp__LoadLibraryA@4]

    ; register the common Find/Replace notification message
    push    OFFSET FindMsgStr
    call    [_imp__RegisterWindowMessageA@4]
    mov     uFindMsg, eax


    push    10
    pop     ecx
    xor     eax, eax
    lea     edi, wc
    rep stosd

    ; initialize WNDCLASSEX
    ;mov     wc.cbSize, SIZEOF WNDCLASSEX
    
    mov     wc.lpfnWndProc, OFFSET WndProc
    mov     eax, hInstance
    mov     wc.hInstance, eax
    mov     wc.lpszClassName, OFFSET ClassName

    ; register window class
    lea     eax, wc
    push    eax
    call    [_imp__RegisterClassA@4]

    ; parse command line for startup file
    call    ParseStartupFile

    ; create main application window
    push    NULL
    push    hInstance
    push    NULL
    push    NULL
    push    WindowHeight
    push    WindowWidth
    push    CW_USEDEFAULT
    push    CW_USEDEFAULT
    push    WS_OVERLAPPEDWINDOW or WS_VISIBLE
    push    OFFSET ClassName
    push    OFFSET ClassName
    push    0
    call    [_imp__CreateWindowExA@48]

    ; if create window ok, save hwnd / else exit
    test    eax, eax
    je      MainRet
    
    mov     hMain, eax

    ; load file and set title
    call    LoadStartupFile
    xor     eax, eax
    mov     fDirty, eax
    call    ApplyTitle

    MessageLoop:

        ; get next message
        push    0
        push    0
        push    NULL
        lea     eax, msg
        push    eax
        call    [_imp__GetMessageA@16]

        ; message WM_QUIT: exit loop
        test    eax, eax
        je      DoneMessages

        ; let an active find/replace dialog handle its own keys
        mov     eax, hFindDlg
        test    eax, eax
        je      NotFindDlg
        lea     edx, msg
        push    edx
        push    eax
        call    [_imp__IsDialogMessageA@8]
        test    eax, eax
        jne     MessageLoop
      NotFindDlg:

        ; manual Notepad-style accelerators not supplied by the EDIT control
        cmp     msg.message, WM_KEYDOWN
        jne     NotAppAccel
        xor     ecx, ecx
        mov     eax, msg.wParam
        cmp     eax, VK_F3
        je      AccelFindNext
        cmp     eax, VK_F5
        je      AccelTime
        push    VK_CONTROL
        call    [_imp__GetKeyState@4]
        test    ah, 80h
        je      NotAppAccel
        mov     eax, msg.wParam
        cmp     eax, 'N'
        je      AccelNew
        cmp     eax, 'O'
        je      AccelOpen
        cmp     eax, 'S'
        je      AccelSave
        cmp     eax, 'P'
        je      AccelPrint
        cmp     eax, 'F'
        je      AccelFind
        cmp     eax, 'H'
        je      AccelReplace
        cmp     eax, 'G'
        je      AccelGoTo
        jmp     NotAppAccel
      AccelNew:
        mov     ecx, IDM_FILE_NEW
        jmp     SendAppAccel
      AccelOpen:
        mov     ecx, IDM_FILE_OPEN
        jmp     SendAppAccel
      AccelSave:
        push    VK_SHIFT
        call    [_imp__GetKeyState@4]
        test    ah, 80h
        mov     ecx, IDM_SAVE
        je      SendAppAccel
        mov     ecx, IDM_FILE_SAVEAS
        jmp     SendAppAccel
      AccelPrint:
        mov     ecx, IDM_FILE_PRINT
        jmp     SendAppAccel
      AccelFind:
        mov     ecx, IDM_EDIT_FIND
        jmp     SendAppAccel
      AccelFindNext:
        mov     ecx, IDM_EDIT_FINDNEXT
        jmp     SendAppAccel
      AccelReplace:
        mov     ecx, IDM_EDIT_REPLACE
        jmp     SendAppAccel
      AccelGoTo:
        mov     ecx, IDM_EDIT_GOTO
        jmp     SendAppAccel
      AccelTime:
        mov     ecx, IDM_EDIT_TIME
      SendAppAccel:
        push    0
        push    ecx
        push    WM_COMMAND
        push    hMain
        call    [_imp__SendMessageA@16]
        jmp     MessageLoop
      NotAppAccel:

        ; translate key input
        lea     eax, msg
        push    eax
        call    [_imp__TranslateMessage@4]

        ; dispatch message to WndProc
        lea     eax, msg
        push    eax
        call    [_imp__DispatchMessageA@4]

        ; loop for next message
        jmp     MessageLoop

    ; get exit code from WM_QUIT
    DoneMessages:
        mov     eax, msg.wParam

    ; final exit point of the program
    MainRet:
        push    eax
        call    [_imp__ExitProcess@4]

MainEntry endp


WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
IF FEAT_LINENUMBERS
    LOCAL   ps:PAINTSTRUCT
    LOCAL   rc:RECT
    LOCAL   pt:POINT
    LOCAL   nbuf[16]:BYTE
ENDIF
IF FEAT_DARKMODE
    LOCAL   dfmt:CHARFORMATW
ENDIF

IF FEAT_LINENUMBERS
    ; line-number gutter: intercept WM_PAINT
    cmp     uMsg, WM_PAINT
    je      LnPaint
ENDIF

    ; check for WM_CREATE
    cmp     uMsg, WM_CREATE
    jne     NotWMCreate

    ; EDIT control (class "RICHEDIT50W")
    mov     eax, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT \
                 or ES_MULTILINE or ES_AUTOVSCROLL or WS_VSCROLL

    ; create EDIT control
    EditStyleReady:
        push    NULL     ; lpParam
        push    NULL     ; no hInstance needed for EDIT control
        
	;push    IDC_EDIT ; hMenu / child ID
	push    NULL
	
        push    hWnd ; parent
        push    0    ; height -- we can get away with setting
        push    0    ; width     these to 0 because REDIT will
        push    0    ; y         auto resize anyway
        push    0    ; x
        push    eax
        push    NULL
        push    OFFSET EditClass ; "RICHEDIT50W"
        push    0
        call    [_imp__CreateWindowExA@48]

        ; add save command to system menu
        mov     hEdit, eax ; save EDIT HWND

        ; Rich Edit needs an event mask for EN_CHANGE notifications
IF FEAT_LINENUMBERS
        push    ENM_CHANGE or ENM_MOUSEEVENTS or ENM_SELCHANGE or ENM_SCROLL or ENM_UPDATE
ELSE
        push    ENM_CHANGE or ENM_MOUSEEVENTS or ENM_SELCHANGE
ENDIF
        push    0
        push    EM_SETEVENTMASK
        push    eax
        call    [_imp__SendMessageA@16]

        ; raise Rich Edit user editing limit
        push    07FFFFFFEh
        push    0
        push    EM_EXLIMITTEXT
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]

        ;; we call this elsewhere anyway ;;
	; set default Rich Edit font
        ;push    OFFSET RichFont
        ;push    0
        ;push    EM_SETCHARFORMAT
        ;mov     eax, hEdit
        ;push    eax
        ;call    [_imp__SendMessageA@16]
	
        push    FALSE
        push    hWnd
        call    [_imp__GetSystemMenu@8]
        push    OFFSET SaveText
        push    IDM_SAVE
        push    MF_STRING
        push    eax
        call    [_imp__AppendMenuA@16]

        ; build Notepad-style menu bar from compact tables
        push    hWnd
        call    CreateNotepadMenus

        ; create status bar pane (hidden until toggled on)
        push    NULL
        push    NULL
        push    NULL
        push    hWnd
        push    0
        push    0
        push    0
        push    0
        push    WS_CHILD or WS_VISIBLE
        push    OFFSET StatusBuf
        push    OFFSET StaticClass
        push    WS_EX_STATICEDGE
        call    [_imp__CreateWindowExA@48]
        mov     hStatus, eax

        ; show initial Ln/Col in the status bar
        call    UpdateStatus

        xor     eax, eax
        ret

IF FEAT_LINENUMBERS
    ; paint the line-number gutter on the left strip
    LnPaint:
        cmp     fLineNum, 0
        je      LnPaintDef
        lea     eax, ps
        push    eax
        push    hWnd
        call    [_imp__BeginPaint@8]
        mov     ebx, eax                 ; ebx = paint HDC
        lea     eax, rc
        push    eax
        push    hWnd
        call    [_imp__GetClientRect@8]
        mov     eax, LN_MARGIN_W
        mov     rc.right, eax            ; strip = {0,0,MARGIN,clientH}
        push    COLOR_BTNFACE
        call    [_imp__GetSysColorBrush@4]
        push    eax
        lea     eax, rc
        push    eax
        push    ebx
        call    [_imp__FillRect@12]
        push    TRANSPARENT
        push    ebx
        call    [_imp__SetBkMode@8]
        push    0
        push    0
        push    EM_GETFIRSTVISIBLELINE
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        mov     esi, eax                 ; esi = current line index
        push    0
        push    0
        push    EM_GETLINECOUNT
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        mov     edi, eax                 ; edi = total line count
      LnLoop:
        cmp     esi, edi
        jge     LnPaintEnd
        push    0
        push    esi
        push    EM_LINEINDEX
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16] ; eax = first char of line
        push    eax
        lea     eax, pt
        push    eax
        push    EM_POSFROMCHAR
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16] ; pt.y = line top (client px)
        mov     eax, pt.y
        cmp     eax, rc.bottom
        jg      LnPaintEnd
        mov     eax, esi
        inc     eax
        push    eax
        push    OFFSET LnNumFmt
        lea     eax, nbuf
        push    eax
        call    [_imp__wsprintfA]
        add     esp, 12
        push    eax                      ; cch = digits written
        lea     eax, nbuf
        push    eax
        push    pt.y
        push    LN_PAD
        push    ebx
        call    [_imp__TextOutA@20]
        inc     esi
        jmp     LnLoop
      LnPaintEnd:
        lea     eax, ps
        push    eax
        push    hWnd
        call    [_imp__EndPaint@8]
        xor     eax, eax
        ret
      LnPaintDef:
        jmp     NotWMDestroy
ENDIF

    ; handle system menu Save
    NotWMCreate:
        mov     eax, uFindMsg
        cmp     uMsg, eax
        jne     NotFindMsg
        call    OnFindReplaceMsg
        xor     eax, eax
        ret

    NotFindMsg:
        cmp     uMsg, WM_SYSCOMMAND
        jne     NotWMSysCommand
        mov     eax, wParam
        cmp     eax, IDM_SAVE
        jne     NotWMSysCommand
        call    SaveFile
        xor     eax, eax
        ret
    
    ;if not the save command
    NotWMSysCommand:
        cmp     uMsg, WM_COMMAND
        jne     NotWMCommand

        ; check for EN_CHANGE from EDIT
	mov     eax, wParam
	shr     eax, 16
	cmp     ax, EN_CHANGE
	
        je      CommandDirty
IF FEAT_LINENUMBERS
        cmp     ax, EN_VSCROLL
        je      LnScrolled
        cmp     ax, EN_UPDATE
        je      LnScrolled
ENDIF

        ; handle top menu commands
        mov     eax, wParam
        and     eax, 0FFFFh
        cmp     eax, IDM_FILE_NEW
        je      CmdFileNew
        cmp     eax, IDM_FILE_OPEN
        je      CmdFileOpen
        cmp     eax, IDM_SAVE
        je      CmdFileSave
        cmp     eax, IDM_FILE_SAVEAS
        je      CmdFileSaveAs
        cmp     eax, IDM_FILE_PRINT
        je      CmdFilePrint
        cmp     eax, IDM_FILE_PAGESETUP
        je      CmdFilePageSetup
        cmp     eax, IDM_FILE_EXIT
        je      CmdFileExit
        cmp     eax, IDM_EDIT_UNDO
        je      CmdEditUndo
        cmp     eax, IDM_EDIT_CUT
        je      CmdEditCut
        cmp     eax, IDM_EDIT_COPY
        je      CmdEditCopy
        cmp     eax, IDM_EDIT_PASTE
        je      CmdEditPaste
        cmp     eax, IDM_EDIT_DELETE
        je      CmdEditDelete
        cmp     eax, IDM_EDIT_SELALL
        je      CmdEditSelAll
        cmp     eax, IDM_EDIT_TIME
        je      CmdEditTime
        cmp     eax, IDM_EDIT_FIND
        je      CmdEditFind
        cmp     eax, IDM_EDIT_FINDNEXT
        je      CmdEditFindNext
        cmp     eax, IDM_EDIT_REPLACE
        je      CmdEditReplace
        cmp     eax, IDM_EDIT_GOTO
        je      CmdEditGoTo
        cmp     eax, IDM_FMT_WRAP
        je      CmdFmtWrap
        cmp     eax, IDM_FMT_FONT
        je      CmdFmtFont
        cmp     eax, IDM_VIEW_STATUS
        je      CmdViewStatus
IF FEAT_LINENUMBERS
        cmp     eax, IDM_VIEW_LINENUM
        je      CmdViewLineNum
ENDIF
IF FEAT_DARKMODE
        cmp     eax, IDM_VIEW_DARK
        je      CmdViewDark
ENDIF
        cmp     eax, IDM_HELP_ABOUT
        je      CmdHelpAbout
        cmp     eax, IDM_HELP_VIEWHELP
        je      CmdHelpView
        jmp     CommandDone

    CmdFileNew:
        call    MaybeSaveChanges
        test    eax, eax
        je      CommandDone
        call    NewFile
        xor     eax, eax
        ret

    CmdFileOpen:
        call    MaybeSaveChanges
        test    eax, eax
        je      CommandDone
        call    PickOpenFile
        test    eax, eax
        je      CommandDone
        call    LoadStartupFile
        xor     eax, eax
        mov     fDirty, eax
        call    ApplyTitle
        xor     eax, eax
        ret

    CmdFileSave:
        cmp     byte ptr [CmdFile], 0
        je      CmdFileSaveAs
        call    SaveFile
        xor     eax, eax
        ret

    CmdFileSaveAs:
        call    PickSaveFile
        test    eax, eax
        je      CommandDone
        call    SaveFile
        xor     eax, eax
        ret

    CmdFilePrint:
        call    PrintDoc
        xor     eax, eax
        ret

    CmdFilePageSetup:
        call    PageSetup
        xor     eax, eax
        ret

    CmdFileExit:
        call    MaybeSaveChanges
        test    eax, eax
        je      CommandDone
        push    hWnd
        call    [_imp__DestroyWindow@4]
        xor     eax, eax
        ret

    CmdEditUndo:
        push    0
        push    0
        push    WM_UNDO
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        xor     eax, eax
        ret

    CmdEditCut:
        push    0
        push    0
        push    WM_CUT
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        xor     eax, eax
        ret

    CmdEditCopy:
        push    0
        push    0
        push    WM_COPY
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        xor     eax, eax
        ret

    CmdEditPaste:
        push    0
        push    0
        push    WM_PASTE
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        xor     eax, eax
        ret

    CmdEditDelete:
        push    0
        push    0
        push    WM_CLEAR
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        xor     eax, eax
        ret

    CmdEditSelAll:
        mov     eax, hEdit
        push    eax
        call    [_imp__SetFocus@4]
        push    0FFFFFFFFh
        push    0
        push    EM_SETSEL
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        xor     eax, eax
        ret

    CmdEditTime:
        mov     eax, hEdit
        push    eax
        call    [_imp__SetFocus@4]
        call    InsertTimeDate
        xor     eax, eax
        ret

    CmdEditFind:
        call    InitFR
        lea     eax, fr
        push    eax
        call    [_imp__FindTextA@4]
        mov     hFindDlg, eax
        xor     eax, eax
        ret

    CmdEditFindNext:
        call    DoFindNext
        xor     eax, eax
        ret

    CmdEditReplace:
        call    InitFR
        lea     eax, fr
        push    eax
        call    [_imp__ReplaceTextA@4]
        mov     hFindDlg, eax
        xor     eax, eax
        ret

    CmdEditGoTo:
        call    GoToDlg
        xor     eax, eax
        ret

    CmdFmtWrap:
        call    ToggleWrap
        xor     eax, eax
        ret

    CmdFmtFont:
        call    ChooseFontDlg
        xor     eax, eax
        ret

    CmdViewStatus:
        xor     eax, eax
        cmp     fStatus, eax
        jne     StatusOff
        inc     eax
        mov     fStatus, eax
        push    SW_SHOW
        jmp     StatusApply
    StatusOff:
        mov     fStatus, eax
        push    SW_HIDE
    StatusApply:
        mov     eax, hStatus
        push    eax
        call    [_imp__ShowWindow@8]
        call    RelayoutClient
        call    UpdateStatus
        xor     eax, eax
        ret

IF FEAT_LINENUMBERS
    CmdViewLineNum:
        mov     eax, fLineNum
        xor     eax, 1
        mov     fLineNum, eax
        call    RelayoutClient
        push    hWnd
        call    LnInvalidate
        xor     eax, eax
        ret

    LnScrolled:
        push    hWnd
        call    LnInvalidate
        xor     eax, eax
        ret
ENDIF

IF FEAT_DARKMODE
    ; toggle dark mode: recolor the Rich Edit, check the menu item
    CmdViewDark:
        mov     eax, fDark
        xor     eax, 1
        mov     fDark, eax

        ; clear the CHARFORMATW we are about to send
        xor     eax, eax
        lea     edi, dfmt
        mov     ecx, (SIZEOF CHARFORMATW)/4
        rep     stosd
        mov     dfmt.cbSize, SIZEOF CHARFORMATW
        mov     dfmt.dwMask, CFM_COLOR

        cmp     fDark, 0
        je      DarkOff

        ; dark on: dark background + light text
        push    DARK_BG
        push    0                      ; wParam 0 = use given color
        push    EM_SETBKGNDCOLOR
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        mov     dfmt.crTextColor, DARK_FG
        jmp     DarkApply

    DarkOff:
        ; dark off: system background + auto (default) text color
        push    0
        push    1                      ; wParam 1 = system window color
        push    EM_SETBKGNDCOLOR
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]
        mov     dfmt.dwEffects, CFE_AUTOCOLOR

    DarkApply:
        lea     eax, dfmt
        push    eax
        push    SCF_ALL
        push    EM_SETCHARFORMAT
        mov     eax, hEdit
        push    eax
        call    [_imp__SendMessageA@16]

        ; reflect the new state with a check mark in the View menu
        mov     edx, MF_BYCOMMAND
        cmp     fDark, 0
        je      DarkChkReady
        or      edx, MF_CHECKED
    DarkChkReady:
        push    edx                    ; uCheck
        push    IDM_VIEW_DARK          ; uIDCheckItem
        push    hWnd
        call    [_imp__GetMenu@4]      ; eax = menu bar handle
        push    eax
        call    [_imp__CheckMenuItem@12]
        xor     eax, eax
        ret
ENDIF

    CmdHelpAbout:
        push    MB_OK or MB_ICONINFORMATION
        push    OFFSET AboutCap
        push    OFFSET AboutText
        push    hWnd
        call    [_imp__MessageBoxA@16]
        xor     eax, eax
        ret

    CmdHelpView:
        push    SW_SHOWNORMAL
        push    0
        push    0
        push    OFFSET HelpUrl
        push    OFFSET OpenVerb
        push    0
        call    [_imp__ShellExecuteA@24]
        xor     eax, eax
        ret

    CommandDirty:

        ; already dirty: ignore
        cmp     fDirty, 0
        jne     CommandDone

        ; mark dirty and update title
        push    1
        pop     eax
        mov     fDirty, eax
        call    ApplyTitle

    ; message handled, return 0
    CommandDone:
        xor     eax, eax
        ret

    ; check for a resize message
    NotWMCommand:
        cmp     uMsg, WM_NOTIFY
        jne     NotWMNotify
        mov     edx, lParam
        mov     eax, [edx+8]               ; NMHDR.code
        cmp     eax, EN_SELCHANGE          ; caret/selection moved
        jne     NotSelChange
        call    UpdateStatus
        jmp     NotifyDone
    NotSelChange:
        cmp     eax, 0700h                 ; EN_MSGFILTER
        jne     NotifyDone
        cmp     dword ptr [edx+12], 0205h  ; WM_RBUTTONUP
        jne     NotifyDone
        push    hWnd
        call    ShowContextMenu
        push    1
        pop     eax
        ret
    NotifyDone:
        xor     eax, eax
        ret
    NotWMNotify:
        cmp     uMsg, WM_SIZE
        jne     NotWMSize

        ; unpack width/height from WM_SIZE lParam
        mov     edx, lParam ; packed w/h
        movzx   esi, dx     ; esi = width
        shr     edx, 16     ; full client height
        mov     edi, edx    ; edi = edit height

        ; if status bar shown, reserve space and place it
        cmp     fStatus, 0
        je      SizeEdit
        sub     edi, SBHEIGHT
        push    SWP_NOZORDER
        push    SBHEIGHT
        push    esi
        push    edi
        push    0
        push    NULL
        push    hStatus
        call    [_imp__SetWindowPos@28]

    ; resize EDIT to fill remaining area
    SizeEdit:
IF FEAT_LINENUMBERS
        ; shift the edit right by the gutter when line numbers are on
        xor     ebx, ebx
        cmp     fLineNum, 0
        je      LnNoShift
        mov     ebx, LN_MARGIN_W
        sub     esi, LN_MARGIN_W
      LnNoShift:
        push    SWP_NOZORDER
        push    edi
        push    esi
        push    0
        push    ebx
        push    NULL
        mov     eax, hEdit
        push    eax
        call    [_imp__SetWindowPos@28]
        push    hWnd
        call    LnInvalidate
ELSE
        push    SWP_NOZORDER
        push    edi
        push    esi
        push    0
        push    0
        push    NULL
        mov     eax, hEdit
        push    eax
        call    [_imp__SetWindowPos@28]
ENDIF

    ; resize handled, return 0
    SizeDone:
        xor     eax, eax
        ret

    ; check for WM_DESTROY
    NotWMSize:
        cmp     uMsg, WM_DESTROY
        jne     NotWMDestroy

        ; post quit message and exit
        push    0
        call    [_imp__PostQuitMessage@4]
        xor     eax, eax
        ret

    ; default message handling
    NotWMDestroy:
        push    lParam
        push    wParam
        push    uMsg
        push    hWnd
        call    [_imp__DefWindowProcA@16]
        ret

WndProc endp ; end WndProc

END MainEntry
