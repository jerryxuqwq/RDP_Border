#Requires AutoHotkey v2.0
#SingleInstance Force

; Define file path
ConfigFile := A_ScriptDir "\rdp_colors.ini"

; Initialize Super-Global Variables
DefaultColor := "Blue"
Thickness    := 6
Interval     := 100
ServerColors := Map()
LastModTime  := ""

; Pre-create the 4 border overlay GUIs
Borders := []
Loop 4 {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    Borders.Push(g)
}

; Perform the initial configuration load
LoadConfig()

; TIMER 1: Tracks the active RDP windows (Runs at your custom interval)
SetTimer(WatchRDP, Interval)

; TIMER 2: Watches the INI file for hard-drive saves (Runs every 1 second)
SetTimer(CheckForFileUpdates, 1000)


CheckForFileUpdates() {
    global ConfigFile, LastModTime
    if FileExist(ConfigFile) {
        currentModTime := FileGetTime(ConfigFile, "M")
        if (currentModTime != LastModTime) {
            LastModTime := currentModTime
            LoadConfig() ; File was saved! Reload everything.
        }
    }
}

LoadConfig() {
    global ConfigFile, DefaultColor, Thickness, Interval, ServerColors, Borders
    
    ; Create file with default values if missing
    ; NOTE: This text is flush left so no empty spaces corrupt the INI formatting.
    if !FileExist(ConfigFile) {
        DefaultConfig := "
(
[Settings]
DefaultColor=Blue
Thickness=2
Interval=100

[Servers]
prod-server=Red
10.0.0.50=Red
staging=Yellow
dev-box=Green
)"
        FileAppend(DefaultConfig, ConfigFile, "UTF-8")
    }
    
    ; Safely read settings (with fallback safety nets if user makes a typo)
    try {
        DefaultColor := IniRead(ConfigFile, "Settings", "DefaultColor", "Blue")
        Thickness    := Integer(IniRead(ConfigFile, "Settings", "Thickness"))
        Interval     := Integer(IniRead(ConfigFile, "Settings", "Interval"))
    } catch {
        ; Fallbacks in case of bad formatting in the INI
        DefaultColor := "Blue"
        Thickness    := 2
        Interval     := 100
        MsgBox "read ini error" 

    }
    
    ; Dynamically adjust the RDP tracking timer speed
    SetTimer(WatchRDP, Interval)
    
    ; Clear and rebuild the server color map
    ServerColors := Map()
    try {
        serverSection := IniRead(ConfigFile, "Servers")
        Loop Parse, serverSection, "`n", "`r" {
            if (A_LoopField == "")
                continue
            pair := StrSplit(A_LoopField, "=", , 2)
            if (pair.Length == 2) {
                ServerColors[Trim(pair[1])] := Trim(pair[2])
            }
        }
    }
    
    ; Briefly hide borders to clear out old scaling artifacts
    for g in Borders {
        g.Hide()
    }
}

WatchRDP() {
    global DefaultColor, Thickness, ServerColors, Borders
    
    if WinActive("ahk_exe mstsc.exe") {
        try {
            activeTitle := WinGetTitle("A")
            chosenColor := DefaultColor
            
            ; Check window title against keywords
            for keyword, color in ServerColors {
                if InStr(activeTitle, keyword) {
                    chosenColor := color
                    break
                }
            }
            
            ; Grab exact active window coordinates
            WinGetPos(&x, &y, &w, &h, "A")
            
            ; Apply color
            for g in Borders {
                g.BackColor := chosenColor
            }
            
            ; Draw the frame using the newly updated Thickness
            Borders[1].Show(Format("x{} y{} w{} h{} NoActivate", x, y, w, Thickness)) ; Top
            Borders[2].Show(Format("x{} y{} w{} h{} NoActivate", x, y + h - Thickness, w, Thickness)) ; Bottom
            Borders[3].Show(Format("x{} y{} w{} h{} NoActivate", x, y, Thickness, h)) ; Left
            Borders[4].Show(Format("x{} y{} w{} h{} NoActivate", x + w - Thickness, y, Thickness, h)) ; Right
        }
    } else {
        ; Hide borders if RDP is not focused
        for g in Borders {
            g.Hide()
        }
    }
}