; imageAndTextSearch.ahk -This script contains functions for searching for images and text on the screen.

#Requires AutoHotkey v2.0

#Include utilities.ahk
#Include utilities_working.ahk
#Include "C:\Git\PokeMMO\AHKv2_Screenshot_Tools\lib\Gdip_All.ahk"
#Include "C:\Git\PokeMMO\AHKv2_Screenshot_Tools\lib\Gdip_Screenshot_Tools_Ext.ahk"

global screenAreas := {
    hotkeyBar: {x1: 250, y1: 25, x2: 2310, y2: 80},
    battleScreen: {x1: 382, y1: 74, x2: 2175, y2: 1035},
    battleOptions: {x1: 382, y1: 927, x2: 1010, y2: 1034},
    chat: {x1: 2, y1: 1232, x2: 395, y2: 1362},
    firstLineChat: {x1: 2, y1: 1342, x2: 395, y2: 1359},
    secondLineChat: {x1: 2, y1: 1324, x2: 395, y2: 1341},
    thirdLineChat: {x1: 2, y1: 1306, x2: 395, y2: 1323},
    fourthLineChat: {x1: 2, y1: 1288, x2: 395, y2: 1305},
    fifthLineChat: {x1: 2, y1: 1270, x2: 395, y2: 1287},
    sixthLineChat: {x1: 2, y1: 1252, x2: 395, y2: 1269},
    seventhLineChat: {x1: 2, y1: 1234, x2: 395, y2: 1251},
    myHealthBar: {x1: 1878, y1: 779, x2: 2175, y2: 856},
    enemyHordeHealthBars: {x1: 873, y1: 97, x2: 1663, y2: 187},
    enemyHealthBar: {x1: 381, y1: 143, x2: 689, y2: 198},
    aboveCharacter: {x1: 1238, y1: 549, x2: 1320, y2: 595},
    aboveAndLeftofCharacter: {x1: 1156, y1: 549, x2: 1238, y2: 595},
    aboveAndRightofCharacter: {x1: 1320, y1: 549, x2: 1402, y2: 595}
}

; Function to check if an image exists on the screen
; Updated imageExists function
; Example call: imageExists("EVTrainingBot\images\hp\caveEntrance.png", screenAreas.aboveCharacter)
imageExists(imagePath, searchArea := "") {
    global imageMessage := ""
    
    CoordMode("Pixel", "Screen")
    if (searchArea) {
        x1 := searchArea.x1
        y1 := searchArea.y1
        x2 := searchArea.x2
        y2 := searchArea.y2
    } else {
        x1 := 0
        y1 := 0
        x2 := A_ScreenWidth - 1
        y2 := A_ScreenHeight - 1
    }

    if !FileExist(imagePath) {
        MsgBox("Image file not found: " imagePath)
        return false
    }

    ; Fibonacci sequence for variations
    fibSequence := [1, 1, 2, 3, 5, 8, 13, 21, 34]

    FoundX := 0
    FoundY := 0

    result := false  ; Initialize result as false

    Loop fibSequence.Length {
        variation := fibSequence[A_Index]
        options := "*" variation

        try {
            success := ImageSearch(&FoundX, &FoundY, x1, y1, x2, y2, options " " imagePath)
            if success {
                result := true
                ;imageMessage .= "`nImage " imagePath " found at " FoundX ", " FoundY
                ;ToolTip(imageMessage, 0, yPos2, 20)
                
                break  ; Exit the loop if image is found
            }
        } catch as Exception {
            MsgBox("Error during ImageSearch: " Exception.Message)
            result := false
            break  ; Exit the loop on error
        }
    }   
    if (result = 0) {
        ;imageMessage .= "`nImage not found: " imagePath
        ;yPos2 += 20
        ;ToolTip(imageMessage, 0, 500, 20)
    }
    return result
}

; Function to wait for an image to appear on the screen
waitForImage(imagePath, totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        if (imageExists(imagePath))
            return true
        randomSleep(450, 550)  ; Wait approximately 0.5 second per attempt
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Function to wait for an image to disappear from the screen
waitForImageDisappear(imagePath, totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        if (!imageExists(imagePath))
            return true
        randomSleep(450, 550)  ; Wait approximately 0.5 second per attempt
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Function to check if any image in the array exists
imageExistsAny(imagePaths, searchArea := "") {
    for imagePath in imagePaths {
        if (imageExists(imagePath, searchArea)) {
            return true
        }
    }
    return false
}

; Function to wait for any image in the array to appear
waitForAnyImage(imagePaths, totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        if (imageExistsAny(imagePaths))
            return true
        randomSleep(450, 550)
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Function to wait for any image in the array to disappear
waitForAnyImageDisappear(imagePaths, totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        if (!imageExistsAny(imagePaths))
            return true
        randomSleep(450, 550)
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

textExists(expectedText, areaName := "") {
    global screenAreas

    if (areaName) {
        searchArea := screenAreas.%areaName%
    } else {
        searchArea := ""
    }

    ; Initialize variables with default values or use the specified search area
    x1 := searchArea ? searchArea.x1 : 0
    y1 := searchArea ? searchArea.y1 : 0
    width := searchArea ? (searchArea.x2 - searchArea.x1) : A_ScreenWidth
    height := searchArea ? (searchArea.y2 - searchArea.y1) : A_ScreenHeight

    ; Create a timestamp for the filename
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")

    ; Set the screenshot path
    screenshotDir := A_ScriptDir "\Screenshots"
    if !DirExist(screenshotDir)
        DirCreate(screenshotDir)
    screenshotPath := screenshotDir "\" timestamp "_" (areaName ? areaName : "full") "_screenshot.png"

    ; Take a screenshot of the specified area
    try {
        pToken := Gdip_Startup()
        if (!pToken) {
            MsgBox("GDI+ failed to start.")
            return false
        }
        ; Capture the specified screen area directly
        pBitmap := Gdip_BitmapFromScreen(x1 "|" y1 "|" width "|" height)
        if (!pBitmap) {
            MsgBox("Failed to capture bitmap from screen.")
            Gdip_Shutdown(pToken)
            return false
        }

        Gdip_SaveBitmapToFile(pBitmap, screenshotPath)
        Gdip_DisposeImage(pBitmap)
        Gdip_Shutdown(pToken)
    } catch as e {
        MsgBox("Error capturing screenshot: " e.Message)
        return false
    }

    ; Run Tesseract OCR on the screenshot
    tesseractPath := "C:\Program Files\Tesseract-OCR\tesseract.exe"
    tempOutputFile := A_Temp "\tesseract_output.txt"
    tesseractCommand := '"' tesseractPath '" "' screenshotPath '" "' SubStr(tempOutputFile, 1, -4) '"'

    try {
        RunWait(tesseractCommand,, "Hide")
        
        if FileExist(tempOutputFile) {
            ocrResult := FileRead(tempOutputFile)
            FileDelete(tempOutputFile)
        } else {
            throw Error("OCR output file not found")
        }
    } catch as e {
        MsgBox("Error running OCR: " e.Message)
        FileDelete(screenshotPath)
        return false
    }

    ; Check if the expected text is in the OCR result
    if (expectedText = "") {
        result := (ocrResult != "") 
    } else {
        result := InStr(ocrResult, expectedText, , 1)
    }

    ; Optionally delete the screenshot
    FileDelete(screenshotPath)
    if FileExist(screenshotPath)
        MsgBox("Failed to delete screenshot: " screenshotPath)

    return result
}


; Function to wait for text to appear on the screen
waitForText(expectedText, areaName := "", totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        if (textExists(expectedText, areaName))
            return true
        randomSleep(0, 50)  ; Wait approximately 0.05 second per attempt
        elapsedTime += 0.05
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Function to wait for any text in the array to appear
waitForAnyText(expectedTexts, areaName := "", totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        for expectedText in expectedTexts {
            if (textExists(expectedText, areaName))
                return true
        }
        randomSleep(0, 50)
        elapsedTime += 0.05
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Function to wait for text to disappear from the screen
waitForTextDisappear(expectedText, areaName := "", totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        if (!textExists(expectedText, areaName))
            return true
        randomSleep(0, 50)
        elapsedTime += 0.05
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}
