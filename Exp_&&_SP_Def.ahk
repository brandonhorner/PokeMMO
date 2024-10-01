#Requires AutoHotkey v2.0+

; Set the name or identifier of the game window
gameWindowIdentifier := "ahk_exe javaw.exe"  ; Replace with the actual process name or window title

; Set coordinate modes to screen
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"
allowEvolutions := true

F4:: {

}

; Hotkey to start the main loop (e.g., F5)
F5:: {
    ; Start the main loop
    mainLoop()
}

; Optional: Hotkey to reload the script (e.g., F6)
F6::Reload  ; Reloads the script instead of exiting

; Hotkey to exit the script (e.g., F7)
F7::ExitApp

; Function for the main loop
mainLoop() {
    MAX_TOOLTIPS := 20  ; Maximum number of tooltips allowed
    loopCounter := 0

    Loop {
        ; Clear any existing tooltips from previous iterations
        Loop MAX_TOOLTIPS {
            ToolTip("", 0, 0, A_Index)
        }
        loopCounter += 1
        tooltipID := 1    ; Reset tooltipID for each iteration
        tooltipY := 20    ; Starting Y-position for tooltips

                                                                                                                        ; Display the loop iteration number
                                                                                                                        ToolTip("Loop iteration #" loopCounter, 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20

        ; Check if 'outOfPP.png' is visible
        if (imageExists("outOfPP.png")) {
                                                                                                                        ToolTip("Out of PP detected.", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20

            ; Go Heal and return
                                                                                                                        ToolTip("Healing and returning.", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20
            healAndReturn()
        }

        ; Press the '4' key to use Sweet Scent
                                                                                                                        ToolTip("Using Sweet Scent (pressing '4').", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20
        sendKey("4")

        ; Wait for 'inBattle.png' to appear
                                                                                                                        ToolTip("Waiting for 'inBattle.png' to appear.", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20
        if (!waitForImage("fightOption.png", 20)) {
                                                                                                                        ToolTip("Battle did not start. Reloading in 5 seconds.", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20
            Sleep 5000
                                                                                                                        clearTooltips(tooltipID - 1)
            Reload
        }

        Sleep 1500

        ; Battle has started
                                                                                                                        ToolTip("'inBattle.png' detected. Battle started.", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20

        ; Select an attack
                                                                                                                        ToolTip("Selecting attack (pressing 'z').", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20
        sendKey("z")

        ; Confirm the move
                                                                                                                        ToolTip("Confirming move (pressing 'z').", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20
        sendKey("z")

        ; Select the enemy
                                                                                                                        ToolTip("Selecting enemy (pressing 'z').", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20
        sendKey("z")
        Sleep 6000
        ; resolve the end of the battle, checking for new pokemon moves or evolutions happening.
                                                                                                                        ToolTip("Waiting for battle to end...", 0, tooltipY, tooltipID)
                                                                                                                        tooltipID += 1
                                                                                                                        tooltipY += 20
        resolveEndofBattle()

        ; Function to clear tooltips
        clearTooltips(maxID) {
            Loop maxID {
                ToolTip("", 0, 0, A_Index)
            }
        }
    }
}

; Function to resolve the end of battle
resolveEndofBattle()
{
    tooltipY := 800
    tooltipID := 20
    while (imageExists("inBattle.png")) {
        ; Handle new move dialogues
        ToolTip("Checking for new move dialogues.", 0, tooltipY, tooltipID)
        tooltipID -= 1
        tooltipY -= 20
        Loop {
            Sleep 50
            if (!resolveNewMoveDialogue()) {
                break  ; No more dialogues
            }
        }
        if (imageExists("inBattle.png")){
            Sleep 2500
        }
    }
    
    ToolTip("Checking for pokemon evolution... Allow Evolution is set to " (allowEvolutions ? "true. We will be allowing the evolution." : "false. We will be denying the evolution."), 0, tooltipY, tooltipID)
    ; checks to see if there's an evolution screen.
    resolveEvolutionScreen()
}

resolveEvolutionScreen() {
    ; Check if we should allow evolutions
    if (imageExists("evolutionScreen.png")) {
        if (allowEvolutions) {
            ToolTip("Sleeping 15 seconds while evolution completes.", 0, 900, 20)
            Sleep 15000
            ; Check again for new moves or more evolutions.
            resolveEndofBattle()
            return
        }
    }
    ; Check for pokemon evolving
    if (imageExists("evolutionScreen.png")){
        ; Press 'x' to cancel learning the new move
        sendKey("x", .6, .3)

        ; Wait for the confirmation dialogue to appear
        if (!waitForImage("confirmationDialogueEvolution.png", 10)) {
            ToolTip("Evolution confirmation dialogue did not appear.", 0, 900, 20)
            return false
        }

        ; Press 'z' to confirm
        sendKey("z", .6, .3)

        ; Wait for the confirmation dialogue to disappear
        if (!waitForImageDisappear("confirmationDialogueEvolution.png", 10)) {
            ToolTip("Evolution confirmation dialogue did not disappear.", 0, 900, 20)
            return false
        }
        return true
    }
    return false

}

; Function to resolve new move dialogues by pressing 'x' and confirming with 'z'
resolveNewMoveDialogue() {
    ; Check if the new move dialogue is open
    if (!isNewMoveDialogueOpen()) {
        return false  ; No dialogue to resolve
    }

    ; Press 'x' to cancel learning the new move
    sendKey("x", 1, .5)

    ; Wait for the confirmation dialogue to appear
    if (!waitForImage("confirmationDialogue.png", 5)) {
        ToolTip("Cancel new move confirmation dialogue did not appear.", 0, 900, 20)
        return false
    }

    ; Press 'z' to confirm
    sendKey("z", 1, .5)

    ; Wait for the confirmation dialogue to disappear
    if (!waitForImageDisappear("confirmationDialogue.png", 5)) {
        ToolTip("Cancel new move confirmation dialogue did not disappear.", 0, 900, 20)
        return false
    }

    return true  ; Dialogue resolved
}

; Function to check if the new move dialogue is open
isNewMoveDialogueOpen() {
    Sleep 500  ; Wait for the dialogue to fully appear
    return imageExists("newMoveDialogue.png")
}

; Function to heal and return to the original spot
healAndReturn() {
    ; Press the '5' key to use flyOcarina
    sendKey("5")
    sendKey("down", .05)
    ; select the town wait
    sendKey("z", , 4.5)
    ; go up into pokecenter
    sendKey("up", .9, 1)
    ; go up to the nurse
    sendKey("up", 1.5)
    ; talk to the nurse
    sendKey("z", 5.5)
    ; go outside 
    sendKey("down", 1.2, 1.5)
    ; get on bike
    sendKey("1", , .1)
    ; go right to sign
    sendKey("right", .9, .1)
    ; go up to lady
    sendKey("up", .6, .1)
    ; go right to wall
    sendKey("right", .8, .1)
    ; go up the stairs to lake edge
    sendKey("up", 1.6, .1)
    ; press z to initiate surf
    sendKey("z", , 1)
    ; press z to confirm surf
    sendKey("z", 2, 1)
}

; Function to move the character using direction keys and duration in seconds
moveCharacter(key, durationSec) {
    durationMs := durationSec * 1000  ; Convert seconds to milliseconds
    sendKey(key, durationMs)
}

; Function to send a key press with human-like timing
sendKey(key, pressDuration := 0, pauseDuration := .4) {
    global gameWindowIdentifier

    ; Activate the game window
    WinActivate gameWindowIdentifier
    Sleep 50  ; Brief pause to ensure activation

    if (pressDuration > 0) {
        keyDownDuration := pressDuration * 1000
    } else {
        keyDownDuration := Random(75, 75)
    }
    SendInput "{" key " down}"
    Sleep keyDownDuration
    SendInput "{" key " up}"

    Sleep(pauseDuration * 1000)
}

; Function to wait for an image to appear on the screen with total wait time in seconds
waitForImage(imagePath, totalWaitTimeSec := "") {
    elapsedTime := 0
    Loop {
        if (imageExists(imagePath))
            return true
        Sleep 500  ; Wait 0.5 second per attempt
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Function to wait for an image to disappear from the screen with total wait time in seconds
waitForImageDisappear(imagePath, totalWaitTimeSec := "") {
    elapsedTime := 0
    Loop {
        if (!imageExists(imagePath))
            return true
        Sleep 500  ; Wait 0.5 second per attempt
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Updated imageExists function
imageExists(imagePath, searchArea := "") {
    CoordMode "Pixel", "Screen"
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
        MsgBox "Image file not found: " imagePath
        return false
    }

    ; Fibonacci sequence for variations
    fibSequence := [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]

    FoundX := 0
    FoundY := 0

    result := false  ; Initialize result as false

    Loop 10 {
        variation := fibSequence[A_IndeX]
        options := "*" variation

        try {
            success := ImageSearch(&FoundX, &FoundY, x1, y1, x2, y2, options " " imagePath)
            if success {
                result := true
                ;ToolTip("Image found: " imagePath " at " FoundX ", " FoundY " with variation: " variation, 0, 0, 7)
                break  ; Exit the loop if image is found
            } else {
                ; Image not found; continue to next variation
                ; Optional: Display a tooltip or log each attempt
                ; ToolTip("Attempt " A_Index ": Image not found with variation: " variation, , , 6)
            }
        } catch as Exception{
            MsgBox "Error during ImageSearch: " Exception.Message
            result := false
            break  ; Exit the loop on error
        }
    }

    return result
}
