; test_utilities.ahk - Tests for utilities.ahk functions
#Requires AutoHotkey v2.0

#Include "C:\Git\PokeMMO\AHKv2_Screenshot_Tools\lib\AHKv2_Screenshot_Tools.ahk"

; Include the utilities script
#Include "utilities.ahk"

; Hotkey to run the visualization
F8::visualizeScreenAreas()

; Run the test
F7::
{
    searchAreaChat := {
        x1: 2,
        y1: 1232,
        x2: 395,
        y2: 1362
    }
    TrayTip("Starting test", "test_utilities.ahk")
    textExistsTest("horde", searchAreaChat) ? TrayTip("Test passed", "Text 'horde' found in chat area") : TrayTip("Test failed", "Text 'horde' not found in chat area")
}

; Define directories "C:\Git\PokeMMO\AHKv2_Screenshot_Tools\lib\AHKv2_Screenshot_Tools.ahk"
global scriptDir := A_ScriptDir
global rootDir := scriptDir "\.."

; Global variables for testing
global logFilePath := "test_log.txt"
global configFilePath := "test_config.ini"
global gameWindowIdentifier := "ahk_exe javaw.exe"
global commonImageDir := rootDir "\images\common\"
global evTypeDisplayName := "Special Attack"
global evType := "specialAtk"
global yPos := 0

; Function to check if text exists on the screen using OCR
textExistsTest(expectedText, searchArea := "") {
    CoordMode("Pixel", "Screen")
    
    ; Initialize variables with default values
    x1 := 0
    y1 := 0
    x2 := A_ScreenWidth - 1
    y2 := A_ScreenHeight - 1

    ; Override with searchArea if provided
    if (IsObject(searchArea)) {
        x1 := searchArea.x1
        y1 := searchArea.y1
        x2 := searchArea.x2
        y2 := searchArea.y2
    }

    ToolTip("Step 1: Preparing to take screenshot", 0, 0, 1)

    ; Initialize GDI+
    pToken := Gdip_Startup()

    ; Get the handle of the PokeMMO window
    hwnd := WinExist("ahk_exe javaw.exe")

    ; Take the screenshot of the client area
    ToolTip("Step 2: Capturing screenshot", 0, 20, 2)
    pBitmap := Gdip_ClientAreaBitmapFromHWND(hwnd)

    ; Create a timestamp for the filename
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")

    ; Set the screenshot path
    screenshotDir := "C:\Git\PokeMMO\AHKv2_Screenshot_Tools\Screenshots"
    if !DirExist(screenshotDir)
        DirCreate(screenshotDir)
    screenshotPath := screenshotDir "\" timestamp "_screenshot.png"

    ; Save the screenshot
    ToolTip("Step 3: Saving screenshot", 0, 40, 3)
    Gdip_SaveBitmapToFile(pBitmap, screenshotPath)

    ; Clean up
    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)

    ToolTip("Step 4: Screenshot saved successfully", 0, 60, 4)
    Sleep(500)

    ; Run Tesseract OCR on the screenshot
    ToolTip("Step 5: Preparing to run Tesseract OCR", 0, 80, 5)

    tesseractPath := "C:\Program Files\Tesseract-OCR\tesseract.exe"
    tempOutputFile := A_Temp "\tesseract_output.txt"
    tesseractCommand := '"' tesseractPath '" "' screenshotPath '" "' SubStr(tempOutputFile, 1, -4) '"'

    try {
        ToolTip("Step 6: Running Tesseract OCR", 0, 100, 6)
        RunWait(tesseractCommand,, "Hide")
        
        if FileExist(tempOutputFile) {
            ocrResult := FileRead(tempOutputFile)
            FileDelete(tempOutputFile)
            ToolTip("Step 7: OCR completed", 0, 120, 7)
        } else {
            throw Error("OCR output file not found")
        }
    } catch as e {
        ToolTip("Error running Tesseract: " e.Message, 0, 140, 8)
        Sleep(5000)
        ToolTip(,,,8)
        ; Delete the screenshot before returning
        FileDelete(screenshotPath)
        return false
    }

    ; Check if the expected text is in the OCR result
    ToolTip("Step 8: Checking OCR result for expected text", 0, 160, 9)
    result := InStr(ocrResult, expectedText)

    ; Delete the screenshot
    FileDelete(screenshotPath)
    if FileExist(screenshotPath)
        MsgBox("Failed to delete screenshot: " screenshotPath)

    if (result) {
        ToolTip("Text '" expectedText "' found in the search area.", 0, 180, 10)
    } else {
        ToolTip("Text '" expectedText "' not found in the search area.", 0, 180, 10)
    }
    Sleep(2000)
    ToolTip(,,,10)

    return result
}

; Global variable to store the visualization GUI
global visualGui := {}

; Function to load screen areas from file
loadScreenAreas() {
    try {
        content := FileRead(A_ScriptDir "\screenAreas.ahk")
        screenAreas := Map()
        lines := StrSplit(content, "`n", "`r")
        for line in lines {
            if (line = "") {
                continue
            }
            parts := StrSplit(line, ":", , 2)
            if (parts.Length < 2) {
                continue
            }
            areaName := Trim(parts[1])
            coords := Trim(parts[2])
            if (RegExMatch(coords, "{x1:\s*(\d+),\s*y1:\s*(\d+),\s*x2:\s*(\d+),\s*y2:\s*(\d+)}", &match)) {
                screenAreas[areaName] := {x1: Integer(match[1]), y1: Integer(match[2]), x2: Integer(match[3]), y2: Integer(match[4])}
            }
        }
        return screenAreas
    } catch as err {
        MsgBox("Error loading screen areas: " . err.Message)
        return Map()
    }
}

; Function to draw colored rectangles for each screen area
visualizeScreenAreas() {
    global visualGui
    
    ; Load the latest screen areas
    screenAreas := loadScreenAreas()
    
    if (screenAreas.Count = 0) {
        MsgBox("No screen areas loaded. Please check your screenAreas.ahk file.")
        return
    }
    
    ; Close existing GUI if it exists
    if (visualGui.HasProp("Hwnd")) {
        visualGui.Destroy()
    }
    
    ; Create a new GUI
    visualGui := Gui("+AlwaysOnTop -Caption +E0x20")
    visualGui.BackColor := "Black"
    visualGui.Opt("+LastFound")
    WinSetTransparent(1)
    
    ; Create a colored rectangle for each area
    for areaName, area in screenAreas {
        color := getColorForArea(areaName)
        visualGui.Add("Progress", 
            Format("x{} y{} w{} h{} Background{}", 
                area.x1, area.y1, area.x2 - area.x1, area.y2 - area.y1, color))
    }
    
    ; Show the GUI
    visualGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight " NoActivate")
    WinSetTransparent(150)
    
    ; Wait for Esc key to close the GUI
    KeyWait "Esc", "D"
    visualGui.Destroy()
}

; Function to get color for each area
getColorForArea(areaName) {
    colors := Map(
        "hotkeyBar", "Red",
        ;battleScreen", "Purple",
        "battleOptions", "ff0000",
        "battleOptionsBottomRight", "4c00ff",
        "chat", "Green",
        "firstLineChat", "Blue",
        "secondLineChat", "Red",
        "thirdLineChat", "Yellow",
        "fourthLineChat", "Blue",
        "fifthLineChat", "Red",
        "sixthLineChat", "Yellow",
        "seventhLineChat", "Blue",
        "myHealthBar", "Red",
        "enemyHordeHealthBars", "Maroon",
        "enemyHealthBar", "Olive",
        "aboveCharacter", "Maroon",
        "aboveAndLeftofCharacter", "Red",
        "aboveAndRightofCharacter", "Red"
    )
    return colors.Has(areaName) ? colors[areaName] : "White"
}


