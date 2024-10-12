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
    global statusText, commonImageDir
    newMoveDialogues := [
        commonImageDir . "newMoveDialogue.png",
        commonImageDir . "newMoveDialogueCustomStrings.png"
    ]

    ; Check if new move dialogue is open
    if (!isNewMoveDialogueOpen(newMoveDialogues)) {
        return false
    }

    ; Cancel learning the new move
    sendKey("x", 1, 0.5)

    ; Confirmation dialogues
    confirmationDialogues := [
        commonImageDir . "confirmationDialogue.png",
        commonImageDir . "confirmationDialogueCustomStrings.png"
    ]

    ; Wait for confirmation dialogue to appear
    if (!waitForAnyImage(confirmationDialogues, 5)) {
        statusText .= "`nCancel new move confirmation dialogue did not appear."
        updateStatus(statusText)
        return false
    }

    ; Confirm cancellation
    sendKey("z", 1, 0.5)

    ; Wait for confirmation dialogue to disappear
    if (!waitForAnyImageDisappear(confirmationDialogues, 5)) {
        statusText .= "`nCancel new move confirmation dialogue did not disappear."
        updateStatus(statusText)
        return false
    }

    return true
}

; Function to check if the new move dialogue is open
isNewMoveDialogueOpen(newMoveDialogues) {
    randomSleep(450, 550)
    return imageExistsAny(newMoveDialogues)
}

; Function to resolve evolution screens
resolveEvolutionScreen() {
    global statusText, allowEvolutions, commonImageDir
    evolutionScreens := [
        commonImageDir . "evolutionScreen.png",
        commonImageDir . "evolutionScreenCustomStrings.png"
    ]
    confirmationDialoguesEvolution := [
        commonImageDir . "confirmationDialogueEvolution.png",
        commonImageDir . "confirmationDialogueEvolutionCustomStrings.png"
    ]

    if (imageExistsAny(evolutionScreens)) {
        statusText .= "`nEvolution screen detected."
        updateStatus(statusText)
        if (allowEvolutions) {
            statusText .= "`nAllowing evolution. Waiting for evolution to complete."
            updateStatus(statusText)
            randomSleep(14500, 15500)  ; Adjust duration as needed
            ; After evolution, check for new moves or additional evolutions
            resolveEndofBattle()
            return
        } else {
            statusText .= "`nPreventing evolution."
            updateStatus(statusText)
            ; Press 'x' to cancel the evolution
            sendKey("x", 0.6, 0.3)

            ; Wait for the confirmation dialogue to appear
            if (!waitForAnyImage(confirmationDialoguesEvolution, 10)) {
                statusText .= "`nEvolution confirmation dialogue did not appear."
                updateStatus(statusText)
                return false
            }

            ; Press 'z' to confirm
            sendKey("z", 0.6, 0.3)

            ; Wait for the confirmation dialogue to disappear
            if (!waitForAnyImageDisappear(confirmationDialoguesEvolution, 10)) {
                statusText .= "`nEvolution confirmation dialogue did not disappear."
                updateStatus(statusText)
                return false
            }
            return true
        }
    } else {
        statusText .= "`nEvolution screen NOT detected."
        updateStatus(statusText)
    }
    return false
}