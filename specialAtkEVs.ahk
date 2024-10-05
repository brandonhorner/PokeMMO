#Requires AutoHotkey v2.0+
#Include utilities.ahk
#Include EVTrainingGUI.ahk

; Set the name or identifier of the game window
gameWindowIdentifier := "ahk_exe javaw.exe"  ; Replace with the actual process name or window title

; Set coordinate modes to screen
CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

; Hotkey to start the main loop (e.g., F5)
F5:: {
    global battlesCompleted, battlesNeeded, statusText, allowEvolutions, gameWindowIdentifier, yPos := 0

    ; Create an instance of the GUI class
    evGUI := EVTrainingGUI()

    ; Get the user inputs
    userInputs := evGUI.getUserInputs()
    ToolTip("Got user inputs", 0, yPos, 1)

    currentEVs := userInputs.currentEVs
    hasTrainingLink := userInputs.hasTrainingLink
    battlesNeeded := userInputs.battlesNeeded
    overrideBattles := userInputs.overrideBattles
    allowEvolutions := userInputs.allowEvolutions
    ToolTip("Extracted variables from user inputs", 0, yPos, 1)

    ; If overrideBattles is false, calculate battlesNeeded
    if (!overrideBattles)
    {
        ToolTip("Calculating battlesNeeded", 0, yPos, 1)
        
        ; Calculate battles needed
        currentEVs := currentEVs + 0  ; Convert to number
        if (hasTrainingLink)
            EVsPerBattle := 20
        else
            EVsPerBattle := 10

        remainingEVs := 252 - currentEVs
        if (remainingEVs <= 0)
        {
            MsgBox("You have already reached or exceeded the maximum EVs (252). No battles needed.")
            ExitApp()
        }

        battlesNeeded := Ceil(remainingEVs / EVsPerBattle)

        ToolTip("Battles needed calculated: " battlesNeeded, 0, yPos, 1)
        MsgBox("You need to complete " battlesNeeded " battles to reach 252 EVs.")
    }
    else
    {
        ToolTip("Using overridden battlesNeeded", 0, yPos, 1)
        battlesNeeded := battlesNeeded + 0  ; Convert to number
        MsgBox("You have chosen to override EV calculation. The script will run for " battlesNeeded " battles.")
    }
    ; Initialize battlesCompleted
    battlesCompleted := 0
    ; Remove the tooltip that's covering the message
    ToolTip()  ; Hide the tooltip

    ; Start the main loop
    mainLoop()
}

; Optional: Hotkey to reload the script (e.g., F6)
F6::Reload()  ; Reloads the script instead of exiting

; Hotkey to exit the script (e.g., F7)
F9::ExitApp()

; Function for the main loop
mainLoop() {
    global battlesCompleted, battlesNeeded, statusText, allowEvolutions, gameWindowIdentifier, yPos
    startTime := A_TickCount  ; Record the start time
    yPos := 0  ; Reset yPos for tooltips
    ToolTip("Entered mainLoop", 0, yPos, 1)
    loopCounter := 0
    Loop {
        loopCounter += 1

        ToolTip("Loop iteration #" loopCounter, 0, yPos, 1)
        
        statusText := "Loop iteration #" loopCounter "`n" "Battles Completed: " battlesCompleted " / " battlesNeeded

        updateStatus(statusText)  ; Update the main tooltip

        ; Check if 'outOfPP.png' is visible
        if (imageExists("outOfPP.png")) {
            statusText .= "`nOut of PP detected. Healing and returning."
            updateStatus(statusText)
            healAndReturn()
        }

        ; Press the '4' key to use Sweet Scent
        statusText .= "`nUsing Sweet Scent (pressing '4')."
        updateStatus(statusText)
        sendKey("4")

        ; Wait for 'fightOption.png' to appear
        statusText .= "`nWaiting for 'fightOption.png' to appear."
        updateStatus(statusText)
        if (!waitForImage("fightOption.png", 20)) {
            statusText .= "`nBattle did not start. Reloading in 5 seconds."
            updateStatus(statusText)
            randomSleep(4500, 5500)
            Reload()
        }

        randomSleep(1200, 1800)

        ; Battle has started
        statusText .= "`nBattle started."
        updateStatus(statusText)
        
        ; Select an attack
        statusText .= "`nSelecting attack (pressing 'z')."
        updateStatus(statusText)
        sendKey("z")
        randomSleep(350, 450)

        ; Confirm the move
        statusText .= "`nConfirming move (pressing 'z')."
        updateStatus(statusText)
        sendKey("z")
        randomSleep(350, 450)

        ; Select the enemy
        statusText .= "`nSelecting enemy (pressing 'z')."
        updateStatus(statusText)
        sendKey("z")
        randomSleep(5500, 6500)

        ; Resolve the end of the battle, checking for new Pokémon moves or evolutions happening.
        statusText .= "`nWaiting for battle to end..."
        updateStatus(statusText)
        resolveEndofBattle()

        ; Increment battlesCompleted
        battlesCompleted += 1
        statusText .= "`nBattle completed! Total battles completed: " battlesCompleted " / " battlesNeeded
        updateStatus(statusText)

        ; Check if we've reached the required number of battles
        if (battlesCompleted >= battlesNeeded) {
            ToolTip()  ; Hide the tooltip
            elapsedTime := A_TickCount - startTime
            elapsedSeconds := Round(elapsedTime / 1000, 2)
            MsgBox("You have completed the required number of battles (" battlesNeeded ").`nElapsed time: " elapsedSeconds " seconds.`nPlease check your EVs.")
            ExitApp()
        }
    }
}

; Function to update the main status tooltip
updateStatus(statusText) {
    global yPos
    ToolTip(statusText, 0, yPos, 1)
}
