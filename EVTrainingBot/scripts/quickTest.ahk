; quickTest.ahk - A quick test script for the EV Training Bot
#Requires AutoHotkey v2.0
#Include utilities.ahk
#Include imageAndTextSearch.ahk
#Include %A_ScriptDir%\..\..\AHKv2_Screenshot_Tools\lib\Gdip_All.ahk
#Include %A_ScriptDir%\..\..\AHKv2_Screenshot_Tools\lib\Gdip_Screenshot_Tools_Ext.ahk

CoordMode("Pixel", "Screen")


; Test the checkHorde function
F4::Test()

Test() {
    MyGui := Gui()
    MyGui.BackColor := "White"
    MyGui.Add("Picture", "x0 y0 h350 w450", A_WinDir "\Web\Wallpaper\Windows\img0.jpg")
    MyBtn := MyGui.Add("Button", "Default xp+20 yp+250", "Start the Bar Moving")
    MyBtn.OnEvent("Click", MoveBar)
    MyProgress := MyGui.Add("Progress", "w416")
    MyText := MyGui.Add("Text", "wp")  ; wp means "use width of previous".
    MyGui.Show()
    
    MoveBar(*)
    {
        Loop Files, A_WinDir "\*.*", "R"
        {
            if (A_Index > 100)
                break
            MyProgress.Value := A_Index
            MyText.Value := A_LoopFileName
            Sleep 50
        }
        MyText.Value := "Bar finished."
    }

}


