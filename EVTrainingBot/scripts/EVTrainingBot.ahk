; EVTrainingBot.ahk - Main script to select and start EV training
#Requires AutoHotkey v2.0+
#Include utilities.ahk
#Include utilities_working.ahk
#Include EVTrainingGUI.ahk
#Include imageAndTextSearch.ahk

; Define directories
global scriptDir := A_ScriptDir
global rootDir := scriptDir "\.."
global commonImageDir := rootDir "\images\common\"


; Define game window identifier
global gameWindowIdentifier := "ahk_exe javaw.exe"  ; Adjust as needed

; Initialize global variables
global currentEVs := ""
global hasTrainingLink := false
global battlesNeeded := ""
global overrideBattles := false
global allowEvolutions := true
global customStrings := false
global configFilePath := ""
global evType := ""
global evTypeDisplayName := ""
global mainGui := ""  ; Initialize as empty
global guiIsClosed := false  ; Initialize the flag

global playerName := "Brunchable"

; Set coordinate modes to screen
CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

; F5 to start the main GUI
F5::main()

; Hotkey to reload the script (F6)
F6::Reload()


;F2::testEVTrainingPathing()
;F3::testNurseInteraction()

; Hotkey to exit the script (F9)
F9::ExitApp()


; This function creates the main GUI which has buttons to select the EV type to train
; Selecting the EV type will start the respective EV training GUI
main() {
    global evType, evTypeDisplayName, commonImageDir, evTypeImageDir
    global configFilePath, gameWindowIdentifier, scriptDir, rootDir
    global currentEVs, hasTrainingLink, battlesNeeded, overrideBattles, allowEvolutions, customStrings
    global mainGui
    global guiIsClosed

    ; Create the main GUI
    mainGui := Gui("+Resize +ToolWindow", "EV Training Bot")
    mainGui.SetFont("s12")
    mainGui.MarginX := 20
    mainGui.MarginY := 20

    ; Add a welcome message
    mainGui.AddText("w400 Center", "Welcome to the EV Training Bot")
    mainGui.AddText("w400 Center", "Please select the EV type you want to train:")

    ; Add buttons for each EV type with proper event handlers
    mainGui.AddButton("x120 w200 h40 Center", "HP Kanto").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("hp", "HP (Dunsparce) Kanto"))
    mainGui.AddButton("w200 h40 Center", "Attack Sinnoh").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("attack", "Attack (Rhydon) Sinnoh"))
    mainGui.AddButton("w200 h40 Center", "Defense Kanto").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("defense", "Defense (Sandslash) Kanto"))
    mainGui.AddButton("w200 h40 Center", "Special Attack Kanto").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("specialAtk", "Special Attack (Golduck) Kanto"))
    mainGui.AddButton("w200 h40 Center", "Special Defense Kanto").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("specialDefKanto", "Special Defense (Tentacruel) Kanto"))
    mainGui.AddButton("w200 h40 Center", "Special Defense Hoenn (exp)").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("specialDefHoenn", "Special Defense (Tentacruel) Hoenn"))
    mainGui.AddButton("w200 h40 Center", "Speed Kanto").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("speed", "Speed (Pidgeot) Kanto"))

    ; Show the GUI without invalid options
    mainGui.Show("AutoSize Center")
}

; 0. This function initializes the EV training process for the selected EV type
; The following functions are all part of the flow, and are all dependent on each other
evTrainingInit(evTypeParam, evTypeDisplayNameParam) {
    global evType, evTypeDisplayName, commonImageDir, evTypeImageDir
    global configFilePath, scriptDir, rootDir
    global mainGui

    ; Set the EV type variables
    evType := evTypeParam
    evTypeDisplayName := evTypeDisplayNameParam

    ; Define directories based on EV type
    commonImageDir := rootDir "\images\common\"
    evTypeImageDir := rootDir "\images\" . evType . "\"
    configFilePath := rootDir "\configs\" . evType . "Config.ini"

    ; Load settings (after configFilePath is assigned)
    loadSettings()

    ; Close the main GUI if it's still open (should already be closed due to the flag)
    if (mainGui) {
        mainGui.Destroy()
    }

    ; Start the EV training process
    evTrainingProcess()
}

; 1. This function creates the initial GUI for user preferences/settings
; Actions performed here are:
; - Ask if you have a Training Link
; - Ask what your current EVs are
; - Ask if you want to allow evolutions
; - Ask if you are using "CustomStrings"
; - Ask if you want to override the number of EVs and just do a certain number of battles
evTrainingProcess() {
    global battlesCompleted, battlesNeeded, statusText, allowEvolutions, customStrings, gameWindowIdentifier, yPos, currentEVs, hasTrainingLink
    global evType, evTypeDisplayName

    yPos := 0

    ; Create an instance of the GUI class
    evGUI := EVTrainingGUI()

    ; Get the user inputs
    userInputs := evGUI.getUserInputs()

    ; Check if the user canceled
    if (userInputs.canceled) {
        ToolTip("Script canceled by the user.")
        Sleep(2000)
        saveSettings()
        Reload()
    }

    ; ToolTip for feedback
    ToolTip("Extracted variables from user inputs", 0, yPos, 1)

    ; Calculate battlesNeeded if not overridden
    if (!overrideBattles) {
        ToolTip("Calculating battlesNeeded", 0, yPos, 1)

        ; Validate currentEVs
        if !(currentEVs ~= "^\d+$") {
            MsgBox("Invalid EV value entered. Exiting script.")
            saveSettings()
            Reload()
        }

        ; Calculate battles needed
        currentEVs := currentEVs + 0  ; Convert to number
        EVsPerBattle := hasTrainingLink ? 20 : 10
        remainingEVs := 252 - currentEVs

        if (remainingEVs <= 0) {
            MsgBox("You have already reached or exceeded the maximum EVs (252). No battles needed.")
            ExitApp()
        }

        battlesNeeded := Ceil(remainingEVs / EVsPerBattle)
        TrayTip("You need to complete " . battlesNeeded . " battles to reach 252 EVs. Starting..")
        Sleep(1000)
    } else {
        ToolTip("Using overridden battlesNeeded", 0, yPos, 1)
        battlesNeeded := battlesNeeded + 0  ; Convert to number
        TrayTip("You have chosen to override EV calculation. The script will run for " . battlesNeeded . " battles.")
    }

    ; Initialize battlesCompleted
    battlesCompleted := 0
    ToolTip()  ; Hide the tooltip

    ; Start the main loop
    battleLoop()
    return
}

; BRANDO. You have more additions from chatGPT to potentially add.. Your bot needs to be able to handle the case where we aren't in battle, and we are out of pp
; The script doesn't seem to be able to determine if we are out of battle easily. test isInBattle() function maybe it's time to implement the timestamp method. check the current time and compare it to the chat message mentioning "evolving."

; 2. This is the main loop for battling, the following functions are part of this flow.
battleLoop() {
    global battlesCompleted, battlesNeeded, statusText, allowEvolutions, gameWindowIdentifier, yPos
    global evType, evTypeDisplayName, commonImageDir

    startTime := A_TickCount  ; Record the start time
    yPos := 0  ; Reset yPos for tooltips
    loopCounter := 0

    Loop {
        loopCounter += 1
        statusText := "EV Type: " . evTypeDisplayName . "`n" . "Loop iteration #" . loopCounter . "`n" . "Battles Completed: " . battlesCompleted . " / " . battlesNeeded
        updateStatus(statusText)

        ; Check for 'outOfPP.png' before casting Sweet Scent
        if (imageExists(commonImageDir . "outOfPP.png")) {
            statusText .= "`nOut of PP detected. Healing and returning."
            updateStatus(statusText)
            healAndReturn()
        }
        ; Need to check to random pokemon encounter here or recommend the smoke ball?
        ; Use Sweet Scent (press '4')
        statusText .= "`nUsing Sweet Scent (pressing '4')."
        updateStatus(statusText)
        sendKey("4")

        ; Wait for the battle to start
        Sleep(6000)

        ; Wait for 'FIGHT' text to appear in battleOptions
        statusText .= "`nChecking for 'FIGHT'."
        updateStatus(statusText)

        hordeFound := false
        fightFound := false

        fightFound := waitForText("FIGHT", "battleOptions", 6)

        if (!fightFound) {
            statusText .= "`nBattle did not start within 6 seconds. nRestarting loop in 5 seconds."
            updateStatus(statusText)

            randomSleep(800, 1200)
            Loop 3 {
                statusText .= "`n" . (4 - A_Index)
                updateStatus(statusText)
                randomSleep(800, 1200)
            }
            ; Restart the loop
            continue

        } else if (fightFound) {
            hordeFound := hordeExistsChatBox()

            ; Check for shiny and prevent logout if found
            statusText .= "`nFight found, checking for shiny: "
            updateStatus(statusText)
            shinyFoundHorde := false
            shinyFoundSingle := false
            if (hordeFound) 
            {
                shinyFoundHorde := textExists("Shiny", "enemyHordeHealthBars")
            } else {
                shinyFoundSingle := textExists("Shiny", "enemyHealthBar")
            }
            if (shinyFoundHorde || shinyFoundSingle){
                statusText .= "`nShiny found! Preventing logout."
                updateStatus(statusText)

                ; Go right, then down, and 'z' to run
                sendKey("right", , 0.3)
                Loop {
                    sendKey("z", , 5)
                    sendKey("x", , 5)
                }
            } else {
                statusText .= "No shiny.. :("
                updateStatus(statusText)
            }

            if (hordeFound) {
                statusText .= "`nHorde battle detected."
                updateStatus(statusText)
            } else {
                statusText .= "`nFIGHT found, but not a horde battle. Running away."
                updateStatus(statusText)
                ; Go right, then down, and 'z' to run
                sendKey("right", , 0.3)
                sendKey("down", , 0.3)
                sendKey("z", , 5)
                continue
            }

        }
        battleMoveCounter := 0
        ; Battle has started
        statusText .= "`nBattling started."
        updateStatus(statusText)

        ; While we see enemy health bars, we continue to battle
        while (battleMoveCounter = 0 || textExists("L", "enemyHordeHealthBars" || textExists("L", "enemyHealthBar")))
        {
            fightFound := false
            if(battleMoveCounter = 0 || textExists("FIGHT", "battleScreen") || textExists("FIGHT", "battleOptions"))
            {
                fightFound := true
                if (battleMoveCounter >= 1)
                {
                    statusText .= "`nThe battle continues..."
                    updateStatus(statusText)
                }
                battleMoveCounter += 1
                statusText .= "`nBattlemove #" . battleMoveCounter
                updateStatus(statusText)
                
                statusText .= "`nSelecting and confirming attack."
                updateStatus(statusText)
                sendKey("z")  ; Open attack menu
                randomSleep(150, 500)
                sendKey("z")  ; Confirm attack
                randomSleep(150, 500)
                sendKey("z")  ; Select enemy
                randomSleep(5500, 6500)

                ; Resolve end of battle
                statusText .= "`nResolving end of battle."
                updateStatus(statusText)
                resolveEndofBattle()

                ; Increment battlesCompleted
                battlesCompleted += 1
                statusText .= "`nBattle completed! Total battles completed: " . battlesCompleted . " / " . battlesNeeded
                updateStatus(statusText)    
            }
            else
            {
                Sleep(1000)
                statusText .= "`nThe battle has ended! (or I can't find FIGHT..)"
                updateStatus(statusText)
            }
        }
        ; Check if required number of battles is reached
        if (battlesCompleted >= battlesNeeded) {
            ToolTip()  ; Hide the tooltip
            elapsedTime := A_TickCount - startTime
            elapsedSeconds := Floor(elapsedTime / 1000)
            elapsedMinutes := Floor(elapsedSeconds / 60)
            remainingSeconds := Mod(elapsedSeconds, 60)

            MsgBox("You have completed the required number of battles (" . battlesNeeded . ")."
                . "`nElapsed time: " . elapsedMinutes . " minutes and " . remainingSeconds . " seconds."
                . "`nPress OK to reload the script.")
            Reload()
        }
    }
}


handleBattle() {
    global statusText, battlesCompleted, allowEvolutions, playerName

    ; Wait for 'FIGHT' to appear
    statusText .= "`nBattle is starting, waiting for 'FIGHT' to appear."
    updateStatus(statusText)
    if (waitForFight()) {
        statusText .= "`n'FIGHT' detected, can attack."
        updateStatus(statusText)
        battleMoveSequence()
    } else {
        statusText .= "`n'FIGHT' not detected within 10 seconds."
        updateStatus(statusText)
        return
    }

    ; Wait and check battle state before deciding battle is over
    battleOver := false
    checkDuration := 10000  ; Total time to wait (in milliseconds)
    checkInterval := 300    ; Time between checks (in milliseconds)
    elapsedTime := 0

    while (elapsedTime < checkDuration) {
        ; Wait for checkInterval
        Sleep(checkInterval)
        elapsedTime += checkInterval

        ; Check if still in battle
        if (isInBattle()) {
            statusText .= "`nStill in battle..."
            updateStatus(statusText)

            ; Handle evolution screen
            if (handleEvolutionScreen()) {
                continue
            }

            ; Handle new move dialogue
            if (handleNewMoveDialogue()) {
                continue
            }

            ; Check if 'FIGHT' appears again
            if (textExists("FIGHT", "battleOptions")) {
                statusText .= "`n'FIGHT' detected again, restarting battle move sequence."
                updateStatus(statusText)
                battleMoveSequence()
                elapsedTime := 0  ; Reset elapsed time since battle continues
                continue
            }
        } else {
            statusText .= "`nBattle appears to be over."
            updateStatus(statusText)
            battleOver := true
            break
        }
    }

    if (!battleOver) {
        ; After waiting, if still in battle, assume battle is over
        statusText .= "`nAssuming battle is over after waiting."
        updateStatus(statusText)
    }

    ; Battle completed
    battlesCompleted += 1
    statusText .= "`nBattle completed! Total battles completed: " . battlesCompleted
    updateStatus(statusText)
}



isInBattle() {
    global screenAreas, commonImageDir

    singleEnemyExists := textExists("L", "enemyHealthBar")
    hordeEnemyExists := textExists("L", "enemyHordeHealthBars")
    playerHealthExists := textExists("L", "myHealthBar")
    evolutionScreenExists := imageExists(commonImageDir . "evolutionScreen.png", screenAreas.battleOptionsBottomRight)
    evolutionScreenCustomStringsExists := imageExists(commonImageDir . "evolutionScreenCustomStrings.png", screenAreas.battleOptionsBottomRight)
    return singleEnemyExists || hordeEnemyExists || playerHealthExists || evolutionScreenExists || evolutionScreenCustomStringsExists
}


isEvolutionScreen() {
    global commonImageDir, screenAreas

    imagePaths := [
        commonImageDir . "evolutionScreen.png",
        commonImageDir . "evolutionScreenCustomStrings.png"
    ]

    ; Search in the specified area
    searchArea := screenAreas.battleOptionsBottomRight

    for imagePath in imagePaths {
        if (imageExists(imagePath, searchArea)) {
            return true
        }
    }
    return false
}


isOutOfPP() {
    global commonImageDir
    return imageExists(commonImageDir . "outOfPP.png")
}

isBattleStarting() {
    global playerName
    return textExists("horde", "battleOptions") || textExists(playerName, "battleOptions")
}

waitForFight() {
    return waitForText("FIGHT", "battleOptions", 3)
}

battleMoveSequence() {
    global statusText
    statusText .= "`nPerforming battle move sequence."
    updateStatus(statusText)
    ; Press 'z' 3 times with delays
    sendKey("z")
    randomSleep(100, 400)
    sendKey("z")
    randomSleep(100, 400)
    sendKey("z")
    randomSleep(100, 400)
    ; Wait for action to complete
    Sleep(3000)
    statusText .= "`nBattle move sequence completed."
    updateStatus(statusText)
}


handleEvolutionScreen() {
    global statusText, allowEvolutions, commonImageDir, screenAreas
    if (textExists("evolving", "battleOptionsBottomRight") || imageExists(commonImageDir . "evolutionScreen.png", screenAreas.battleOptionsBottomRight)) {
        statusText .= "`nEvolution screen detected."
        updateStatus(statusText)
        resolveEvolutionScreen()
        return true
    }
    return false
}

handleNewMoveDialogue() {
    global statusText
    if (textExists("Which", "battleOptions") || textExists("ancel", "battleOptions")) {
        statusText .= "`nNew move dialogue detected."
        updateStatus(statusText)
        resolveNewMoveDialogue()
        return true
    }
    return false
}


hordeExistsChatBox() {
    global screenAreas
    global playerName

    ; Define the lines from bottom to top
    chatLines := ["firstLineChat", "secondLineChat", "thirdLineChat", "fourthLineChat", "fifthLineChat", "sixthLineChat", "seventhLineChat"]

    ; Iterate through the chatLines using an index
    for i, lineNumber in chatLines {
        ; Check if the line has any text
        if (textExists("", lineNumber)) {
            ; Line has text, now check if "horde" exists in this line
            if (textExists("horde", lineNumber)) {
                return true  ; "horde" found in the first line with text
            } else if (textExists(playerName, lineNumber)) {
                ; Now check if 'horde' exists in the next line above (i + 1)
                if (i < chatLines.Length) {
                    nextLineName := chatLines[i + 1]
                    if (textExists("horde", nextLineName)) {
                        return true  ; 'horde' found in the next line
                    } else {
                        return false  ; 'horde' not found in next line
                    }
                } else {
                    ; There is no next line above
                    return false
                }
            } else {
                return false  ; Neither 'horde' nor 'playerName' found in this line
            }
        }
    }
    ; No text found in any line
    return false
}


; Function to heal and return to the original spot
; This function is split into 3 parts, the only one that changes
;   is the flyToPokecenter function and the returnToEVTrainingSpot function
healAndReturn() {
    global evType
    ; Fly to the Pokécenter based on EV type
    flyToPokecenter()
    ; Talk to the nurse (also based on EV type)
    nurseInteraction()
    ; Return to the EV training spot (you guessed it, based on EV type)
    returnToEVTrainingSpot()
}

; Step 1 in healing is to fly to the Pokécenter based on EV type
; In game requirements: Town Map in slot 2 on hotkey bar (or change the key)
flyToPokecenter() {
    global evType
    WinActivate(gameWindowIdentifier)
    Sleep(1000)
    ; Select the city to fly to based on EV type
    if (evType == "specialAtk" || evType == "specialDefKanto") {
        ; Select town map
        sendKey("2")
        sendKey("down", 0.07)
    }
    else if (evType == "speed") {
        ; Select town map
        sendKey("2")
        sendKey("left", 0.07)
    }
    else if (evType == "hp") {
        ; Select town map
        sendKey("2")
        sendKey("left", 0.07, 0.2)
        sendKey("up", 0.07)
    }
    else if (evType == "defense") {
        ; Go down from cave
        sendKey("down", 0.4, 1.5)
        
        ; Select town map
        sendKey("2")
        sendKey("up", 0.07)
    }
    else if (evType == "attack") {
        ; Go down from cave
        sendKey("down", 0.5, 1.5)

        ; Select town map
        sendKey("2")
    }
    else if (evType == "specialDefHoenn") {
        ; Select town map
        sendKey("2", , 0.5)
    }
    ; Confirm the city and wait for the animation
    sendKey("z", , 4.5, , 4.5)
}

nurseInteraction() {
    global evType
    WinActivate(gameWindowIdentifier)

    ; Go up into the Pokécenter
    sendKey("up", 0.9, 1)
    
    ; For defense ev training, we need to go right first
    if (evType == "defense") {
        sendKey("right", 0.5, 0)
    }
    ; Go up toward the nurse
    sendKey("up", 1.3, 0.5)
;    findTileAboveCharacter(commonImageDir . "inFrontOfNurse.png")

    if (evType == "attack") {
        ; Talk to the nurse longer in sinnoh
        sendKey("z", 5.5, , 5)
    }
    else {
        ; Talk to the nurse
        sendKey("z", 5.5, , 1.0)
    }

    ; For defense ev training, we need to go left after talking to the nurse
    if (evType == "defense") {
        ; Go left
        sendKey("left", 0.5, 0)
    }

    ; Go back outside of the Pokécenter 
    sendKey("down", 1.4, 1.5)
}


returnToEVTrainingSpot() {
    global evType
    WinActivate(gameWindowIdentifier)
    ; Get on bike
    sendKey("1", , 0.2)

    if (evType == "specialAtk") {
        ; Go right to sign
        sendKey("right", 0.8, 0)
        ; Go up to lady
        sendKey("up", 0.6, 0)
        ; Go right to wall
        sendKey("right", 0.7, 0)
        ; Go up the stairs to lake edge
        sendKey("up", 1.1, 0)
        ; Press 'z' to initiate surf
        sendKey("z", , 0.3)
        ; Press 'z' to confirm surf
        sendKey("z", 2, 1, 1, .5)

    } else if (evType == "speed") {
        sendKey("1", , 0.4)
        ; Go left toward stairs
        sendKey("left", 0.5, 0)
        ; Go down to dock
        sendKey("down", 0.47, 0)
        ; Go right to second stairs
        sendKey("right", 1.16, 0)
        ; Go up to grass patch
        sendKey("up", .50, 0)

    } else if (evType == "hp") { 
        ; Go down from pokecenter
        sendKey("down", 0.45, 0)
        ; Go left past corner
        sendKey("left", 0.1, 0)
        ; Go down past next corner
        sendKey("down", .96, 0.1)
        ; Go right to cave entrance
        sendKey("right", 0.357, 0.1)
        ; Wiggle to the cave entrance
        findTileAboveCharacter(commonImageDir . "caveEntrance.png", commonImageDir . "caveEntranceNight.png")
        ; Go into cave
        sendKey("up", 0.2, 1)
        ; Go up a square
        sendKey("up", 0.2, 0)
        ; Go right through the cave
        sendKey("right", 1.35, 0)
        ; Go up to the next floor
        sendKey("up", 0.2, 0)
        ; Go right to end of cave
        sendKey("right", 0.4, 0)
        ; Go down to the lake
        sendKey("down", 0.5, 1)
        ; Go left to grass patch
        sendKey("left", 0.2, 1)

    } else if (evType == "defense") {
        ; Go down from pokecenter
        sendKey("down", 1.2, 0)
        ; Go right
        sendKey("right", 0.3, 0)
        ; Find the pathingHelp.png tile above the character 
        findTileAboveCharacter(evTypeImageDir . "pathingHelp.png", evTypeImageDir . "pathingHelpNight.png")
        ; Go down
        sendKey("down", 0.8, 0)
        ; Go left
        sendKey("left", 0.2, 0)
        ; Go down
        sendKey("down", 0.7, 0)
        ; Go right
        sendKey("right", 0.6, 0)
        ; Go down
        sendKey("down", 0.8, 0)
        ; Go left
        sendKey("left", 0.2, 0)
        ; Find the caveEntrance.png tile above the character
        findTileAboveCharacter(commonImageDir . "caveEntrance.png", commonImageDir . "caveEntranceNight.png")
        ; Go up
        sendKey("up", 0.3, 1.5)
    } else if (evType == "attack") {
        sendKey("right", .8, .1)
        sendKey("up", .8, 1)
        sendKey("up", 0.08)

    } else if (evType == "specialDefKanto") {
        ; Go left from pokecenter
        sendKey("left", 0.4, 0.05)
        ; Go up to fence
        sendKey("up", 1.45, 0.05)
        ; Go left to wall
        sendKey("left", 0.3, 0.05)
        ; Go down the stairs
        sendKey("down", 0.4, 0.05)
        ; Go left onto beach
        sendKey("left", 0.4, 0.05)
        ; Go up to the water
        sendKey("up", 0.8, 0.05)
        ; Press 'z' to initiate surf
        sendKey("z", , 0.3)
        ; Press 'z' to confirm surf
        sendKey("z", 2, 1, 1, .5)

    } else if (evType == "specialDefHoenn") {
        ; Press 'down' to go down from the pokecenter
        sendKey("down", 0.2, 0.05)
        ; Press 'right' to go to towards the water
        sendKey("right", 1.7, 0.05)
        ; Press 'down' to go to the treeline
        sendKey("down", 0.3, 0.05)
        ; Press 'right' to go to towards the water
        sendKey("right", 1.6, 0.05)
        ; Press 'down' to go to the water
        sendKey("down", 0.3, 0.05)
        ; Press 'z' to initiate surf
        sendKey("z", , 0.3)
        ; Press 'z' to confirm surf
        sendKey("z", 2, 1)
    }
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

; F3::testNurseInteraction()
; This function is used to test the nurse interaction for a different EV type
testNurseInteraction() {
    global evType := "defense"
    WinActivate(gameWindowIdentifier)
    ; Go up into the Pokécenter
    sendKey("up", 0.9, 1)
    
    ; For defense ev training, we need to go right first
    if (evType == "defense") {
        sendKey("right", 0.5, 0)
    }
    ; Go up toward the nurse
    sendKey("up", 1.2)
    ;findTileAboveCharacter("C:\Git\PokeMMO\EVTrainingBot\images\common\inFrontOfNurse.png")
    ; Talk to the nurse
    sendKey("z", 5.5, , 1.0)

    ; For defense ev training, we need to go left after talking to the nurse
    if (evType == "defense") {
        ; Go left
        sendKey("left", 0.5, 0)
    }

    ; Go back outside of the Pokécenter 
    sendKey("down", 1.4, 1.5)
}

; This function is used to test a new pathing for a different EV type
; Replace the evType and the content in the loop to what you need for that type of EV Training
testEVTrainingPathing() {
    global commonImageDir
    global rootDir
    
    ; Set the EV type variables
    global evType := "specialDefHoenn"

    WinActivate(gameWindowIdentifier)
    ; Define directories based on EV type
    commonImageDir := rootDir "\images\common\"
    evTypeImageDir := rootDir "\images\" . evType . "\"

    Loop(5)
    {
        Sleep(1000)
        
        sendKey("1", , 0.3)
        ; Press 'down' to go down from the pokecenter
        sendKey("down", 0.2, 0.05)
        ; Press 'right' to go to towards the water
        sendKey("right", 1.7, 0.05)
        ; Press 'down' to go to the treeline
        sendKey("down", 0.3, 0.05)
        ; Press 'right' to go to towards the water
        sendKey("right", 1.3, 0.05)
        ; Press 'down' to go to the water
        sendKey("down", 0.3, 0.05)
        ; Press 'z' to initiate surf
        sendKey("z", , 0.3)
        ; Press 'z' to confirm surf
        sendKey("z", 2, 1)
        ; Wait for 10 seconds
        Sleep(2000)
        ToolTip("Flying to pokecenter... evType: " . evType, 0, 0, 20)
        flyToPokecenter()
        Sleep(2000)
        ToolTip("Interacting with nurse... evType: " . evType, 0, 0, 20)
        testNurseInteraction()
    }
}

