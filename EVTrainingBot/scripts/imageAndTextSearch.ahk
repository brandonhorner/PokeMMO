; imageAndTextSearch.ahk -This script contains functions for searching for images and text on the screen.

#Requires AutoHotkey v2.0

#Include utilities.ahk
#Include utilities_working.ahk
#Include %A_ScriptDir%\..\..\AHKv2_Screenshot_Tools\lib\Gdip_All.ahk
#Include %A_ScriptDir%\..\..\AHKv2_Screenshot_Tools\lib\Gdip_Screenshot_Tools_Ext.ahk

global screenAreas := {
    hotkeyBar: {x1: 250, y1: 25, x2: 2310, y2: 80},
    battleScreen: {x1: 382, y1: 74, x2: 2175, y2: 1035},
    battleOptions: {x1: 382, y1: 927, x2: 1038, y2: 1035},
    battleOptionsFight: {x1: 396, y1: 934, x2: 590, y2: 972},
    battleOptionsBottomRight: {x1: 1038, y1: 927, x2: 2175, y2: 1035},
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
            WinActivate(gameWindowIdentifier)
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
        WinActivate(gameWindowIdentifier)
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
        WinActivate(gameWindowIdentifier)
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
        WinActivate(gameWindowIdentifier)
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
        WinActivate(gameWindowIdentifier)
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
        WinActivate(gameWindowIdentifier)
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
    global gameWindowIdentifier

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

    maxAttempts := 2

    Loop maxAttempts {
        attempt := A_Index

        ; Create a timestamp for the filename
        timestamp := Format("{:yyyyMMdd_HHmmss}", A_Now)
        
        ; Set the screenshot path
        screenshotDir := A_ScriptDir "\Screenshots"
        if !DirExist(screenshotDir)
            DirCreate(screenshotDir)
        screenshotPath := screenshotDir "\" timestamp "_" (areaName ? areaName : "full") "_screenshot.png"
        
        WinActivate(gameWindowIdentifier)
        Sleep(50)  ; Brief pause to ensure the window is active

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
            result := (InStr(ocrResult, expectedText, , true) > 0)
        }

        ; Optionally delete the screenshot
        FileDelete(screenshotPath)
        if FileExist(screenshotPath)
            MsgBox("Failed to delete screenshot: " screenshotPath)
        WinActivate(gameWindowIdentifier)

        if (result) {
            return true  ; Text found, return true immediately
        }

        Sleep(100)  ; Brief pause between attempts
    }

    return false  ; Text not found after maxAttempts
}



; Function to wait for text to appear on the screen
waitForText(expectedText, areaName := "", totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        WinActivate(gameWindowIdentifier)
        if (textExists(expectedText, areaName))
            return true
        randomSleep(0, 50)  ; Wait approximately 0.5 second per attempt
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Function to wait for any text in the array to appear
waitForAnyText(expectedTexts, areaName := "", totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        WinActivate(gameWindowIdentifier)
        for expectedText in expectedTexts {
            if (textExists(expectedText, areaName))
                return true
        }
        randomSleep(0, 50)
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Function to wait for text to disappear from the screen
waitForTextDisappear(expectedText, areaName := "", totalWaitTimeSec := "") {
    elapsedTime := 0
    while true {
        WinActivate(gameWindowIdentifier)
        if (!textExists(expectedText, areaName))
            return true
        randomSleep(0, 50)
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

F2::{
    global yPos := 50
    textAreaPairs := [
        {expectedText: "FIGHT", areaName: "battleScreen"},
        {expectedText: "FIGHT", areaName: "battleOptions"},
        {expectedText: "FIGHT", areaName: "battleOptionsFight"}
    ]
    counters := [0, 0, 0]
    totalRuns := 0

    loop 10 {    
        totalRuns++
        returnedObj := checkMultiTextExists(textAreaPairs)
        if (returnedObj) {
            loop 3 {
                if (returnedObj[A_Index].found)
                    counters[A_Index]++
            }
            statusText := "Run: " . totalRuns . "`n"
            loop 3 {
                statusText .= "Text: " . returnedObj[A_Index].expectedText . 
                              " Area: " . returnedObj[A_Index].areaName . 
                              " Found: " . (returnedObj[A_Index].found ? "Yes" : "No") . 
                              " Count: " . counters[A_Index] . "`n"
            }
            updateStatus(statusText)
        } else {
            MsgBox("No results returned.")
        }
        Sleep(100)  ; Add a small delay between iterations
    }

    ; After the loop, display final results
    finalStatus := "Final Results (Total Runs: " . totalRuns . "):`n"
    loop 3 {
        finalStatus .= "Text " . A_Index . " Count: " . counters[A_Index] . "`n"
    }
    updateStatus(finalStatus)
}


checkMultiTextExists(textAreaPairs) {
    global screenAreas
    global gameWindowIdentifier

    ; Prepare a result array and initialize 'found' to false
    results := []
    for index, pair in textAreaPairs {
        results.Push({areaName: pair.areaName, expectedText: pair.expectedText, found: false})
    }

    maxAttempts := 5

    ; Indices of pairs that are not yet found
    remainingIndices := []
    for index, _ in results {
        remainingIndices.Push(index)
    }

    Loop maxAttempts {
        attempt := A_Index

        ; If all texts are found, exit early
        if (remainingIndices.Length = 0) {
            break
        }

        ; Start GDI+ once per attempt
        pToken := Gdip_Startup()
        if (!pToken) {
            MsgBox("GDI+ failed to start.")
            return false
        }

        ; Activate the game window
        WinActivate(gameWindowIdentifier)
        Sleep(50)  ; Brief pause to ensure the window is active

        ; Get the handle of the game window
        hwnd := WinExist(gameWindowIdentifier)
        if (!hwnd) {
            MsgBox("Game window not found.")
            Gdip_Shutdown(pToken)
            return false
        }

        ; Capture the client area of the game window
        pScreenBitmap := Gdip_BitmapFromHWND(hwnd)
        if (!pScreenBitmap) {
            MsgBox("Failed to capture bitmap from game window.")
            Gdip_Shutdown(pToken)
            return false
        }

        ; Iterate over remaining pairs
        for idx in remainingIndices.Clone() {  ; Use Clone() to avoid modifying the list while iterating
            pair := textAreaPairs[idx]
            expectedText := pair.expectedText
            areaName := pair.areaName

            if (!screenAreas.%areaName%) {
                MsgBox("Area '" areaName "' not found in screenAreas.")
                continue
            }

            area := screenAreas.%areaName%

            ; Crop the area from pScreenBitmap
            x := area.x1
            y := area.y1
            width := area.x2 - area.x1
            height := area.y2 - area.y1

            pCropBitmap := Gdip_CropBitmap(pScreenBitmap, x, y, width, height)
            if (!pCropBitmap) {
                MsgBox("Failed to crop area '" areaName "'.")
                continue
            }

            ; Run OCR on the cropped bitmap
            ocrResult := runOCROnBitmap(pCropBitmap)

            Gdip_DisposeImage(pCropBitmap)

            if (ocrResult != "") {
                found := (InStr(ocrResult, expectedText, , true) > 0)
                if (found) {
                    results[idx].found := true
                    ; Remove idx from remainingIndices

                    ; Find the position of idx in remainingIndices
                    position := -1
                    for i, v in remainingIndices {
                        if (v = idx) {
                            position := i
                            break
                        }
                    }
                    if (position != -1) {
                        remainingIndices.RemoveAt(position)
                    }
                }
            }
        }

        ; Dispose of the screen bitmap
        Gdip_DisposeImage(pScreenBitmap)
        ; Shutdown GDI+
        Gdip_Shutdown(pToken)

        Sleep(100)  ; Brief pause between attempts
    }

    ; Return the results
    return results
}


runOCROnBitmap(pBitmap) {
    ; Set up directories
    tempDir := A_Temp
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")

    ; Save the bitmap to a temporary file
    tempImagePath := tempDir "\temp_image_" timestamp ".png"
    Gdip_SaveBitmapToFile(pBitmap, tempImagePath)

    ; Run Tesseract OCR on the image
    tesseractPath := "C:\Program Files\Tesseract-OCR\tesseract.exe"
    tempOutputFile := tempDir "\tesseract_output_" timestamp ".txt"
    tesseractCommand := '"' tesseractPath '" "' tempImagePath '" "' SubStr(tempOutputFile, 1, -4) '"'

    try {
        RunWait(tesseractCommand,, "Hide")
        if FileExist(tempOutputFile) {
            ocrResult := FileRead(tempOutputFile) 
            FileDelete(tempOutputFile)
        } else {
            throw Error("OCR output file not found.")
        }
    } catch as e {
        MsgBox("Error running OCR: " e.Message)
        ocrResult := ""
    }

    ; Delete the temporary image file
    FileDelete(tempImagePath)

    return ocrResult
}

Gdip_CropBitmap(pBitmap, x, y, width, height) {
    pBitmapCropped := Gdip_CreateBitmap(width, height)
    G := Gdip_GraphicsFromImage(pBitmapCropped)
    Gdip_SetInterpolationMode(G, 7)
    Gdip_DrawImage(G, pBitmap, 0, 0, width, height, x, y, width, height)
    Gdip_DeleteGraphics(G)
    return pBitmapCropped
}

