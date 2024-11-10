; utilities.ahk - A collection of utility functions for the EV Training scripts
#Requires AutoHotkey v2.0

; Function to update the main status tooltip
updateStatus(statusText) {
    global yPos
    ToolTip(statusText, 0, yPos, 1)
}

; Function to load settings
loadSettings() {
    global currentEVs, hasTrainingLink, battlesNeeded, overrideBattles, allowEvolutions, customStrings, configFilePath
    if (configFilePath = "") {
        ToolTip("Error: configFilePath is not set in saveSettings().", 0, 500, 20)
        return
    }
    if !FileExist(configFilePath) {
        currentEVs := ""
        hasTrainingLink := false
        allowEvolutions := true
        customStrings := true
        overrideBattles := false
        battlesNeeded := ""
        return
    }

    currentEVs := IniRead(configFilePath, "EVTraining", "currentEVs", "")
    hasTrainingLink := IniRead(configFilePath, "EVTraining", "hasTrainingLink", "0") == "1"
    allowEvolutions := IniRead(configFilePath, "EVTraining", "allowEvolutions", "1") == "1"
    customStrings := IniRead(configFilePath, "EVTraining", "customStrings", "1") == "1"
    overrideBattles := IniRead(configFilePath, "EVTraining", "overrideBattles", "0") == "1"
    battlesNeeded := IniRead(configFilePath, "EVTraining", "battlesNeeded", "")
}

; Function to save settings
saveSettings() {
    global currentEVs, hasTrainingLink, battlesNeeded, overrideBattles, allowEvolutions, customStrings, configFilePath
    if (configFilePath = "") {
        ToolTip("Error: configFilePath is not set in saveSettings().", 0, 500, 20)
        return
    }
    IniWrite(currentEVs, configFilePath, "EVTraining", "currentEVs")
    IniWrite(hasTrainingLink ? "1" : "0", configFilePath, "EVTraining", "hasTrainingLink")
    IniWrite(allowEvolutions ? "1" : "0", configFilePath, "EVTraining", "allowEvolutions")
    IniWrite(customStrings ? "1" : "0", configFilePath, "EVTraining", "customStrings")
    IniWrite(overrideBattles ? "1" : "0", configFilePath, "EVTraining", "overrideBattles")
    IniWrite(battlesNeeded, configFilePath, "EVTraining", "battlesNeeded")
}

; Function to sleep for a random duration between min and max milliseconds
randomSleep(min, max) {
    Sleep(Random(min, max))
}

; Function to send a key press with human-like timing
sendKey(key, pressDuration := 0, pauseDuration := 0.4, customStringsPressDuration := 0, customStringsPauseDuration := 0) {
    global gameWindowIdentifier, customStrings

    ; Activate the game window
    WinActivate(gameWindowIdentifier)
    randomSleep(10, 20)  ; Brief pause to ensure activation

    ; Determine key press duration
    if (customStrings && customStringsPressDuration > 0) {
        keyDownDuration := customStringsPressDuration * 1000
    } else if (pressDuration > 0) {
        keyDownDuration := pressDuration * 1000
    } else {
        keyDownDuration := Random(65, 85)  ; Random duration between 65ms and 85ms
    }

    ; Send the key press
    Send("{" key " down}")
    Sleep(keyDownDuration)
    Send("{" key " up}")

    ; Determine pause duration
    if (customStrings && customStringsPauseDuration > 0) {
        randomSleep(customStringsPauseDuration * 1000 * 0.9, customStringsPauseDuration * 1000 * 1.1)
    } else {
        randomSleep(pauseDuration * 1000 * 0.9, pauseDuration * 1000 * 1.1)
    }
}
