#Requires AutoHotkey v2.0

; Function to send a key press with human-like timing
sendKey(key, pressDuration := 0, pauseDuration := 0.4) {
    global gameWindowIdentifier

    ; Activate the game window
    WinActivate(gameWindowIdentifier)
    randomSleep(40, 60)  ; Brief pause to ensure activation

    if (pressDuration > 0) {
        keyDownDuration := pressDuration * 1000
    } else {
        keyDownDuration := Random(65, 85)  ; Random duration between 65ms and 85ms
    }
    SendInput("{" key " down}")
    Sleep(keyDownDuration)
    SendInput("{" key " up}")

    randomSleep(pauseDuration * 1000 * 0.9, pauseDuration * 1000 * 1.1)
}

; Function to wait for an image to appear on the screen with total wait time in seconds
waitForImage(imagePath, totalWaitTimeSec := "") {
    elapsedTime := 0
    Loop {
        if (imageExists(imagePath))
            return true
        randomSleep(450, 550)  ; Wait approximately 0.5 second per attempt
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
        randomSleep(450, 550)  ; Wait approximately 0.5 second per attempt
        elapsedTime += 0.5
        if (totalWaitTimeSec && elapsedTime >= totalWaitTimeSec)
            return false
    }
}

; Function to sleep for a random duration between min and max milliseconds
randomSleep(min, max) {
    Sleep(Random(min, max))
}

; Updated imageExists function
imageExists(imagePath, searchArea := "") {
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
    fibSequence := [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]

    FoundX := 0
    FoundY := 0

    result := false  ; Initialize result as false

    Loop 10 {
        variation := fibSequence[A_Index]
        options := "*" variation

        try {
            success := ImageSearch(&FoundX, &FoundY, x1, y1, x2, y2, options " " imagePath)
            if success {
                result := true
                break  ; Exit the loop if image is found
            }
        } catch as Exception {
            MsgBox("Error during ImageSearch: " Exception.Message)
            result := false
            break  ; Exit the loop on error
        }
    }

    return result
}

; Function to resolve the end of battle
resolveEndofBattle() {
    global statusText, allowEvolutions
    while (imageExists("inBattle.png")) {
        ; Handle new move dialogues
        statusText .= "`nChecking for new move dialogues."
        updateStatus(statusText)
        Loop {
            randomSleep(45, 55)
            if (!resolveNewMoveDialogue()) {
                break  ; No more dialogues
            }
        }
        if (imageExists("inBattle.png")) {
            randomSleep(2400, 2600)
        }
    }

    statusText .= "`nChecking for Pokémon evolution..."
    updateStatus(statusText)
    resolveEvolutionScreen()
}

; Function to resolve new move dialogues by pressing 'x' and confirming with 'z'
resolveNewMoveDialogue() {
    global statusText
    ; Check if the new move dialogue is open
    if (!isNewMoveDialogueOpen()) {
        return false  ; No dialogue to resolve
    }

    ; Press 'x' to cancel learning the new move
    sendKey("x", 1, 0.5)

    ; Wait for the confirmation dialogue to appear
    if (!waitForImage("confirmationDialogue.png", 5)) {
        statusText .= "`nCancel new move confirmation dialogue did not appear."
        updateStatus(statusText)
        return false
    }

    ; Press 'z' to confirm
    sendKey("z", 1, 0.5)

    ; Wait for the confirmation dialogue to disappear
    if (!waitForImageDisappear("confirmationDialogue.png", 5)) {
        statusText .= "`nCancel new move confirmation dialogue did not disappear."
        updateStatus(statusText)
        return false
    }

    return true  ; Dialogue resolved
}

; Function to check if the new move dialogue is open
isNewMoveDialogueOpen() {
    randomSleep(450, 550)  ; Wait for the dialogue to fully appear
    return imageExists("newMoveDialogue.png")
}

; Function to resolve evolution screen
resolveEvolutionScreen() {
    global statusText, allowEvolutions
    if (imageExists("evolutionScreen.png")) {
        if (allowEvolutions) {
            statusText .= "`nAllowing evolution. Waiting for evolution to complete."
            updateStatus(statusText)
            randomSleep(14500, 15500)  ; Adjust duration as needed
            ; Check again for new moves or more evolutions.
            resolveEndofBattle()
            return
        } else {
            statusText .= "`nPreventing evolution."
            updateStatus(statusText)
            ; Press 'x' to cancel the evolution
            sendKey("x", 0.6, 0.3)

            ; Wait for the confirmation dialogue to appear
            if (!waitForImage("confirmationDialogueEvolution.png", 10)) {
                statusText .= "`nEvolution confirmation dialogue did not appear."
                updateStatus(statusText)
                return false
            }

            ; Press 'z' to confirm
            sendKey("z", 0.6, 0.3)

            ; Wait for the confirmation dialogue to disappear
            if (!waitForImageDisappear("confirmationDialogueEvolution.png", 10)) {
                statusText .= "`nEvolution confirmation dialogue did not disappear."
                updateStatus(statusText)
                return false
            }
            return true
        }
    }
    return false
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
    sendKey("1", , .2)
    ; go right to sign
    sendKey("right", .9, .2)
    ; go up to lady
    sendKey("up", .6, .2)
    ; go right to wall
    sendKey("right", .8, .2)
    ; go up the stairs to lake edge
    sendKey("up", 1.6, .2)
    ; press z to initiate surf
    sendKey("z", , 1)
    ; press z to confirm surf
    sendKey("z", 2, 1)
}
