#Requires AutoHotkey v2.0
#SingleInstance Force

; --- CONFIGURATION: DEFINE YOUR SERVERS & COLORS ---
; You can match by server name, IP address, or any text that appears in the RDP title bar.
; Colors can be words ("Red", "Green", "Blue", "Yellow", "Orange", "Purple") or Hex codes ("FF5500").

ServerColors := Map(
    "10.0.0.50",   "Red",      ; Matches a specific critical IP
    "staging",     "Yellow",   ; Matches if "staging" is in the title
    "dev-box",     "Green"     ; Matches if "dev-box" is in the title
)

DefaultColor := "Blue"         ; Color used for any RDP window not listed above
Thickness    := 2              ; Thickness of the frame in pixels
Interval     := 100            ; How often to check (in milliseconds)
; ---------------------------------------------------

Borders := []
Loop 4 {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    Borders.Push(g)
}

SetTimer(WatchRDP, Interval)

WatchRDP() {
    if WinActive("ahk_exe mstsc.exe") {
        try {
            ; Get the title of the active RDP window
            activeTitle := WinGetTitle("A")
            chosenColor := DefaultColor
            
            ; Loop through your map to see if the title contains any of your keywords
            for keyword, color in ServerColors {
                if InStr(activeTitle, keyword) {
                    chosenColor := color
                    break ; Stop looking once we find a match
                }
            }
            
            ; Get window position
            WinGetPos(&x, &y, &w, &h, "A")
            
            ; Apply the color to the borders
            for g in Borders {
                g.BackColor := chosenColor
            }
            
            ; Draw the frame
            Borders[1].Show(Format("x{} y{} w{} h{} NoActivate", x, y, w, Thickness)) ; Top
            Borders[2].Show(Format("x{} y{} w{} h{} NoActivate", x, y + h - Thickness, w, Thickness)) ; Bottom
            Borders[3].Show(Format("x{} y{} w{} h{} NoActivate", x, y, Thickness, h)) ; Left
            Borders[4].Show(Format("x{} y{} w{} h{} NoActivate", x + w - Thickness, y, Thickness, h)) ; Right
        }
    } else {
        ; Hide borders if RDP is not the active window
        for g in Borders {
            g.Hide()
        }
    }
}