#Requires AutoHotkey v2.0+

; Set the name of the game window
gameWindowTitle := "PokeMMO"

; Map directions to keys
directions := Map("up", "w", "down", "s", "left", "a", "right", "d")

; Hotkey to start the main loop (e.g., F5)
F5:: {
    ; Activate the game window
    WinActivate gameWindowTitle

    ; Move the character to the desired location using direction keys
    ;moveCharacter("right", 2)
    ;moveCharacter("up", 1.5)
    ; Add more movements as needed

    ; Start the main loop
    mainLoop()
}

; Optional: Hotkey to exit the script (e.g., F6)
F6::ExitApp

; Function for the main loop
mainLoop() {
    Loop {
        if (!imageExists("sweet_scent_out.png"))
        {
            MsgBox "Sweet Scent was out. Exiting script."
            ExitApp   
        }
        ; Use Sweet Scent by pressing '4'
        sendKey("4")
        
        ; Wait for the attack option to appear (max 5 attempts)
        if (!waitForImage("attackOption.png", 5)) {
            MsgBox "Attack option not found. Exiting script."
            ExitApp
        }

        ; Press 'z' to enter the attack option
        sendKey("z")

        ; Wait for the attack options to pop up (max 5 attempts)
        if (!waitForImage("attackOptions.png", 5)) {
            MsgBox "Attack options not found. Exiting script."
            ExitApp
        }

        ; Press 'z' to select the attack
        sendKey("z")

        ; Wait until the battle screen is no longer up (max 20 attempts)
        if (!waitForImageDisappear("battleScreen.png", 20)) {
            MsgBox "Battle screen did not disappear. Exiting script."
            ExitApp
        }

        ; Check if Sweet Scent is out of PP
        if (imageExists("outOfPP.png")) {
            MsgBox "Sweet Scent is out of PP. Script will now exit."
            ExitApp
        }
    }
}

; Function to move the character using direction keys and duration in seconds
moveCharacter(direction, durationSec) {
    global directions
    key := directions[direction]
    if (!key) {
        MsgBox "Invalid direction: " direction
        return
    }
    durationMs := durationSec * 1000  ; Convert seconds to milliseconds
    sendKey(key, durationMs)
}

; Function to send a key press with optional duration (in milliseconds)
sendKey(key, duration := 0) {
    if (duration > 0) {
        SendEvent "{" key " down}"
        Sleep duration
        SendEvent "{" key " up}"
    } else {
        SendEvent "{" key "}"
    }
    Sleep 100  ; Brief pause between actions
}

; Function to wait for an image to appear on the screen with optional retry limit
waitForImage(imagePath, retryLimit := "") {
    attempts := 0
    Loop {
        if (imageExists(imagePath))
            return true
        Sleep 500  ; Check every 500 milliseconds
        attempts += 1
        if (retryLimit && attempts >= retryLimit)
            return false
    }
}

; Function to wait for an image to disappear from the screen with optional retry limit
waitForImageDisappear(imagePath, retryLimit := "") {
    attempts := 0
    Loop {
        if (!imageExists(imagePath))
            return true
        Sleep 500  ; Check every 500 milliseconds
        attempts += 1
        if (retryLimit && attempts >= retryLimit)
            return false
    }
}

; Function to check if an image exists on the screen
imageExists(imagePath) {
    CoordMode "Pixel", "Screen"
    found := ImageSearch(&x, &y, 0, 0, A_ScreenWidth, A_ScreenHeight, imagePath)
    return found = 0
}