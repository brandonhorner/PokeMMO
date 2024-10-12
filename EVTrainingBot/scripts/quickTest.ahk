; quickTest.ahk - A quick test script for the EV Training Bot
#Requires AutoHotkey v2.0
#Include utilities.ahk
#Include imageAndTextSearch.ahk
#Include "C:\Git\PokeMMO\AHKv2_Screenshot_Tools\lib\Gdip_All.ahk"
#Include "C:\Git\PokeMMO\AHKv2_Screenshot_Tools\lib\Gdip_Screenshot_Tools_Ext.ahk"
CoordMode("Pixel", "Screen")


; Test the checkHorde function
F4::Test()

Test() {
    if (textExists("horde", "firstLineChat")) {
        ToolTip("horde found in first line chat, screen area: " . screenAreas.firstLineChat.x1 . ", " . screenAreas.firstLineChat.y1, 0, 220 + 300, 20)
    } else {
        ToolTip("horde NOT found in first line chat", 0, 220 + 300, 20)
    }
    if (textExists("horde", "secondLineChat")) {
        ToolTip("horde found in second line chat, screen area: " . screenAreas.secondLineChat.x1 . ", " . screenAreas.secondLineChat.y1, 0, 200 + 300, 19)
    } else {
        ToolTip("horde NOT found in second line chat", 0, 200 + 300, 19)
    }
    if (textExists("horde", "thirdLineChat")) {
        ToolTip("horde found in third line chat, screen area: " . screenAreas.thirdLineChat.x1 . ", " . screenAreas.thirdLineChat.y1, 0, 180 + 300, 18)
    } else {
        ToolTip("horde NOT found in third line chat", 0, 180 + 300, 18)
    }
    if (textExists("horde", "fourthLineChat")) {
        ToolTip("horde found in fourth line chat, screen area: " . screenAreas.fourthLineChat.x1 . ", " . screenAreas.fourthLineChat.y1, 0, 160 + 300, 17)
    } else {
        ToolTip("horde NOT found in fourth line chat", 0, 160 + 300, 17)
    }
    if (textExists("horde", "fifthLineChat")) {
        ToolTip("horde found in fifth line chat, screen area: " . screenAreas.fifthLineChat.x1 . ", " . screenAreas.fifthLineChat.y1, 0, 140 + 300, 16)
    } else {
        ToolTip("horde NOT found in fifth line chat", 0, 140 + 300, 16)
    }
    if (textExists("horde", "sixthLineChat")) {
        ToolTip("horde found in sixth line chat, screen area: " . screenAreas.sixthLineChat.x1 . ", " . screenAreas.sixthLineChat.y1, 0, 120 + 300, 15)
    } else {
        ToolTip("horde NOT found in sixth line chat", 0, 120 + 300, 15)
    }
    if (textExists("horde", "seventhLineChat")) {
        ToolTip("horde found in seventh line chat, screen area: " . screenAreas.seventhLineChat.x1 . ", " . screenAreas.seventhLineChat.y1, 0, 100 + 300, 14)
    } else {
        ToolTip("horde NOT found in seventh line chat", 0, 100 + 300, 14)
    }

    ; if (textExists("horde", screenAreas.firstLineChat)) {
    ;     MsgBox("horde found in first line chat")
    ;     hordeFound := true
    ; }
    ; else{
    ;     ToolTip("horde not found in first line chat, starting search", 0, 100, 20)
    ;     newSearchArea := findFirstLineWithText()
    ;     ToolTip("newSearchArea: " . newSearchArea.x1 . ", " . newSearchArea.y1, 0, 120, 19)
    ;     Sleep(5000)
    ;     if (newSearchArea != screenAreas.firstLineChat){
    ;         ToolTip("new search area was not equal to first line, searching the new area", 0, 140, 18)
    ;         hordeFound := textExists("horde", newSearchArea)
    ;         MsgBox("I had to find horde in a new area: " . newSearchArea . "")
    ;     }
    ; }
    ; Sleep(3000)

    ; if (!hordeFound){
    ;     statusText .= "`nFIGHT found, but not a horde battle. Running away."
    ; }
}
