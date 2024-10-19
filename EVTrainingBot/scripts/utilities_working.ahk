; This script contains utility functions for the EVTrainingBot that are typically working.
#Requires AutoHotkey v2.0

#Include utilities.ahk
#Include imageAndTextSearch.ahk
#Include EVTrainingBot.ahk


; Function to update the main status tooltip
updateStatus(statusText) {
    global yPos
    ToolTip(statusText, 0, yPos, 1)
}

; Function to resolve the end of battle
resolveEndofBattle() {
    global statusText, allowEvolutions, commonImageDir
    while (imageExists(commonImageDir . "inBattle.png")) {
        ; Handle new move dialogues
        statusText .= "`nChecking for new move dialogues."
        updateStatus(statusText)
        while true {
            randomSleep(45, 55)
            if (!resolveNewMoveDialogue()) {
                break
            }
        }
        
        if (imageExists(commonImageDir . "inBattle.png")) {
            statusText .= "`nwaiting .4-1.2s.."
            updateStatus(statusText)
            randomSleep(400, 1200)
        }
    }

    ; Handle evolution screens
    statusText .= "`nChecking for Pokémon evolution..."
    updateStatus(statusText)
    resolveEvolutionScreen()
}

; Function to resolve new move dialogues
resolveNewMoveDialogue() {
    global statusText
    statusText .= "`nResolving new move dialogue."
    updateStatus(statusText)
    sendKey("x")
    randomSleep(200, 500)
    sendKey("z")
    randomSleep(200, 500)
}


; Function to check if the new move dialogue is open
isNewMoveDialogueOpen(newMoveDialogues) {
    randomSleep(450, 550)
    return imageExistsAny(newMoveDialogues)
}

; Function to resolve evolution screens
resolveEvolutionScreen() {
    global statusText, allowEvolutions
    if (allowEvolutions) {
        statusText .= "`nAllowing evolution. Waiting for evolution to complete."
        updateStatus(statusText)
        Sleep(15000)  ; Adjust duration as needed
    } else {
        statusText .= "`nPreventing evolution."
        updateStatus(statusText)
        sendKey("x")
        randomSleep(200, 500)
        sendKey("z")
        randomSleep(1500, 2000)
    }
}
