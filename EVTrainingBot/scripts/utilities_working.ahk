; This script contains utility functions for the EVTrainingBot that are typically working.
#Requires AutoHotkey v2.0

#Include utilities.ahk
#Include imageAndTextSearch.ahk
#Include EVTrainingBot.ahk

; Function to resolve the end of battle
resolveEndofBattle() {
    global statusText, allowEvolutions, commonImageDir

    ; Handle evolution screens
    statusText .= "`nChecking for Pokémon evolution..."
    updateStatus(statusText)
    resolveEvolutionScreen()

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
}

; Function to resolve new move dialogues
resolveNewMoveDialogue() {
    global statusText, commonImageDir
    newMoveDialogues := [
        commonImageDir . "newMoveDialogue.png",
        commonImageDir . "newMoveDialogueCustomStrings.png"
    ]
    statusText .= "`nChecking for new move dialogues."
    updateStatus(statusText)
    randomSleep(75, 150)
    ; Check if new move dialogue is open
    if (!isNewMoveDialogueOpen(newMoveDialogues)) {
        statusText .= "`nNew move dialogue NOT detected."
        updateStatus(statusText)
        return false
    }

    ; Cancel learning the new move
    sendKey("x", 1, 0.5)

    ; Confirm cancellation
    sendKey("z", 1, 0.5)

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

    if (imageExistsAny(evolutionScreens)) {
        statusText .= "`nEvolution screen detected."
        updateStatus(statusText)
        if (allowEvolutions) {
            statusText .= "`nAllowing evolution. Waiting for evolution to complete. ~15 seconds."
            updateStatus(statusText)
            randomSleep(14500, 15500)  ; Adjust duration as needed
            ; After evolution, check for new moves or additional evolutions
            resolveEndofBattle()
            return
        } else {
            statusText .= "`nPreventing evolution."
            updateStatus(statusText)
            ; Press 'x' to cancel the evolution
            sendKey("x", 0.6)

            ; Press 'z' to confirm
            sendKey("z", 0.6, 0.7)
            resolveEndofBattle()

        }
    } else {
        statusText .= "`nEvolution screen NOT detected."
        updateStatus(statusText)
    }
    return false
}

; This function is used to find the tile above the character (night and day versions should be provided)
findTileAboveCharacter(imageNameDay, imageNameNight := "") {  ; Updated to take two image parameters
    inFrontOfCave := false
    while(!inFrontOfCave) {
        WinActivate(gameWindowIdentifier)
        Sleep(Random(200, 700))
        if (imageExists(imageNameDay, screenAreas.aboveCharacter) || imageExists(imageNameNight, screenAreas.aboveCharacter)) {  ; Check both images
            inFrontOfCave := true
        }
        else if (imageExists(imageNameDay, screenAreas.aboveAndLeftofCharacter) || imageExists(imageNameNight, screenAreas.aboveAndLeftofCharacter)) {  ; Check both images
            ; correct by going left one square
            sendKey("left", 0.05, 0)
        }
        else if (imageExists(imageNameDay, screenAreas.aboveAndRightofCharacter) || imageExists(imageNameNight, screenAreas.aboveAndRightofCharacter)) {  ; Check both images
            ; correct by going right one square
            sendKey("right", 0.05, 0)
        }
    }
}
