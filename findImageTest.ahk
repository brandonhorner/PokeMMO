#Requires AutoHotkey v2.0+
#SingleInstance Force

; Debug mode flag
debugMode := true  ; Set to true to enable rectangle drawing

F6::{
    Reload
}

F2::{
    if debugMode == true
    {
        searchArea := {
            x1: 0,
            y1: 0, 
            x2: A_ScreenWidth, 
            y2: A_ScreenHeight}
        DrawRectangle(searchArea)
        Sleep 5000
    }
    else
    {
        MsgBox "Debug mode is disabled."
    }
}

F3::{
    CoordMode "Pixel"  ; Interprets the coordinates below as relative to the screen rather than the active window's client area.
    variation := 50 ; Adjust as needed if you can't find the image
    useTransBlack := false  ; Set to true if the image has transparency
    options := "*" variation
    if useTransBlack == true
    {
        options .= " *TransBlack "
    }
    try
    {
        if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*1 outOfPP.png")
            MsgBox "The icon was found at " FoundX "x" FoundY
        else
            MsgBox "Icon could not be found on the screen."
    }
    catch as exc
        MsgBox "Could not conduct the search due to the following error:`n" exc.Message

}


; Function to draw a rectangle around the search area (optional, for debugging)
DrawRectangle(searchArea) {
    global overlayGUI := ""
    if IsObject(overlayGUI) {
        overlayGUI.Destroy()
    }
    x := searchArea.x1
    y := searchArea.y1
    width := searchArea.x2 - searchArea.x1 + 1
    height := searchArea.y2 - searchArea.y1 + 1

    ; Create a GUI with a border and transparent background
    overlayGUI := Gui("+AlwaysOnTop -Caption +E0x20 +LastFound +ToolWindow +Border")
    overlayGUI.BackColor := "FFFFFF"  ; Set background color to white
    overlayGUI.TransColor := "FFFFFF"  ; Make background transparent
    overlayGUI.Show("x" x " y" y " w" width " h" height)
}


; Function to remove the rectangle overlay
RemoveRectangle() {
    global overlayGUI
    if IsObject(overlayGUI) {
        overlayGUI.Destroy()
        overlayGUI := ""
    }
}

