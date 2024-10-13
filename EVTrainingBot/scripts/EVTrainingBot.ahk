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
global customStrings := true
global configFilePath := ""
global evType := ""
global evTypeDisplayName := ""
global mainGui := ""  ; Initialize as empty
global guiIsClosed := false  ; Initialize the flag

; Set coordinate modes to screen
CoordMode("Pixel", "Screen")
CoordMode("Mouse", "Screen")

; F5 to start the main GUI
F5::main()

; Hotkey to reload the script (F6)
F6::Reload()

F2::testEVTrainingPathing()
F3::testNurseInteraction()

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
    mainGui.AddButton("x120 w200 h40 Center", "HP").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("hp", "HP"))
    mainGui.AddButton("w200 h40 Center", "Attack").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("attack", "Attack"))
    mainGui.AddButton("w200 h40 Center", "Defense").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("defense", "Defense"))
    mainGui.AddButton("w200 h40 Center", "Special Attack").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("specialAtk", "Special Attack"))
    mainGui.AddButton("w200 h40 Center", "Special Defense").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("specialDef", "Special Defense"))
    mainGui.AddButton("w200 h40 Center", "Speed").OnEvent("Click", (CtrlObj, EventInfo) => evTrainingInit("speed", "Speed"))
    
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
}

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

        ; 1. Check for 'outOfPP.png' before casting Sweet Scent
        if (imageExists(commonImageDir . "outOfPP.png")) {
            statusText .= "`nOut of PP detected. Healing and returning."
            updateStatus(statusText)
            healAndReturn()
        }
        ; Need to check to random pokemon encounter here or recommend the smoke ball?
        ; 3. Use Sweet Scent (press '4')
        statusText .= "`nUsing Sweet Scent (pressing '4')."
        updateStatus(statusText)
        sendKey("4")

        ; Wait for the battle to start
        Sleep(6000)

        ; Wait for 'FIGHT' text to appear in battleOptions
        statusText .= "`nChecking for 'FIGHT' and 'horde'."
        updateStatus(statusText)

        hordeFound := false
        fightFound := false
        fightFound := waitForText("FIGHT", "battleOptions", 10)

        if (!fightFound) {
            statusText .= "`nBattle did not start. Restarting loop in 5 seconds."
            updateStatus(statusText)
            randomSleep(4500, 5500)
            ToolTip("Battle did not start. Restarting loop...", 0, yPos, 20)
            continue

        } else if (fightFound) {
            ; Check for shiny and prevent logout if found
            statusText .= "`nFight found, checking for shiny."
            updateStatus(statusText)
            shinyFoundHorde := textExists("Shiny", "enemyHordeHealthBars")
            shinyFoundSingle := textExists("Shiny", "enemyHealthBar")
            if (shinyFoundHorde || shinyFoundSingle){
                statusText .= "`nShiny found! Preventing logout."
                updateStatus(statusText)

                ; Go right, then down, and 'z' to run
                sendKey("right", , 0.3)
                Loop {
                    sendKey("z", , 5)
                    sendKey("x", , 5)
                }
            }
            
            ; Inside your battle loop
            hordeFound := hordeExistsChatBox()
            if (hordeFound) {
                statusText .= "`nNo shiny.. :( but horde battle detected."
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

        ; Battle has started
        statusText .= "`nBattle started."
        updateStatus(statusText)

        ; Select and confirm attack
        statusText .= "`nSelecting and confirming attack."
        updateStatus(statusText)
        sendKey("z")  ; Open attack menu
        randomSleep(150, 500)
        sendKey("z")  ; Confirm attack
        randomSleep(150, 500)
        sendKey("z")  ; Select enemy
        randomSleep(5500, 6500)

        ; Resolve end of battle
        statusText .= "`nWaiting for battle to end..."
        updateStatus(statusText)
        resolveEndofBattle()

        ; Increment battlesCompleted
        battlesCompleted += 1
        statusText .= "`nBattle completed! Total battles completed: " . battlesCompleted . " / " . battlesNeeded
        updateStatus(statusText)    


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

hordeExistsChatBox() {
    global screenAreas

    ; Define the lines from bottom to top
    lines := ["firstLineChat", "secondLineChat", "thirdLineChat", "fourthLineChat", "fifthLineChat", "sixthLineChat", "seventhLineChat"]
    for lineName in lines {
        ; Check if the line has any text
        if (textExists("", lineName)) {
            ; Line has text, now check for "horde"
            if (textExists("horde", lineName)) {
                return true  ; "horde" found in the first line with text
            } else {
                return false  ; "horde" not found in the first line with text
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

    ; Select the city to fly to based on EV type
    if (evType = "specialAtk" || evType = "specialDef") {
        ; Select town map
        sendKey("2")
        sendKey("down", 0.07)
    }
    else if (evType = "speed") {
        ; Select town map
        sendKey("2")
        sendKey("left", 0.07)
    }
    else if (evType = "hp") {
        ; Select town map
        sendKey("2")
        sendKey("left", 0.07, 0.2)
        sendKey("up", 0.07)
    }
    else if (evType = "defense") {
        ; Go down from cave
        sendKey("down", 0.4, 1.5)
        
        ; Select town map
        sendKey("2")
        sendKey("up", 0.07)
    }
    else if (evType = "attack") {
        ; Go down from cave
        sendKey("down", 0.5, 1.5)

        ; Select town map
        sendKey("2")
        sendKey("z", , 2)
    }
    
    ; Confirm the city and wait for the animation
    sendKey("z", , 4.5, , 2.5)
}

nurseInteraction() {
    global evType

    ; Go up into the Pokécenter
    sendKey("up", 0.9, 1)
    
    ; For defense ev training, we need to go right first
    if (evType = "defense") {
        sendKey("right", 0.5, 0)
    }
    ; Go up toward the nurse
    sendKey("up", 1.2)
    ; Talk to the nurse
    sendKey("z", 5.5, , 1.0)

    ; For defense ev training, we need to go left after talking to the nurse
    if (evType = "defense") {
        ; Go left
        sendKey("left", 0.5, 0)

    }
    ; Go back outside of the Pokécenter 
    sendKey("down", 1.4, 1.5)
}


returnToEVTrainingSpot() {
    global evType
    ; Get on bike
    sendKey("1", , 0.2)

    if (evType = "specialAtk") {
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

    } else if (evType = "speed") {
        sendKey("1", , 0.4)
        ; Go left toward stairs
        sendKey("left", 0.5, 0)
        ; Go down to dock
        sendKey("down", 0.47, 0)
        ; Go right to second stairs
        sendKey("right", 1.16, 0)
        ; Go up to grass patch
        sendKey("up", .50, 0)

    } else if (evType = "hp") { 
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

    } else if (evType = "defense") {
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
    } else if (evType = "attack") {
        sendKey("right", .8, .1)
        sendKey("up", .8, 1)
        sendKey("up", 0.08)

    } else if (evType = "specialDef") {
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
    }
}

; This function is used to find the tile above the character (night and day versions should be provided)
findTileAboveCharacter(imageNameDay, imageNameNight := "") {  ; Updated to take two image parameters
    inFrontOfCave := false
    while(!inFrontOfCave) {
        Sleep(Random(200, 700))
        if (imageExists(imageNameDay, screenAreas.aboveCharacter) || imageExists(imageNameNight, screenAreas.aboveCharacter)) {  ; Check both images
            inFrontOfCave := true
        }
        else if (imageExists(imageNameDay, screenAreas.aboveAndLeftofCharacter) || imageExists(imageNameNight, screenAreas.aboveAndLeftofCharacter)) {  ; Check both images
            ; correct by going left one square
            sendKey("left", 0.08, 0)
        }
        else if (imageExists(imageNameDay, screenAreas.aboveAndRightofCharacter) || imageExists(imageNameNight, screenAreas.aboveAndRightofCharacter)) {  ; Check both images
            ; correct by going right one square
            sendKey("right", 0.08, 0)
        }
    }
}

; This function is used to test the nurse interaction for a different EV type
testNurseInteraction() {
    sendKey("up", .7, 1.5)
    ; Go up to the nurse
    sendKey("up", 1.3, .5)
    ; Talk to the nurse
    sendKey("z", 5.8)
    ; Go back outside of the Pokécenter 
    sendKey("down", 1.4, 1.5)
}

; This function is used to test a new pathing for a different EV type
; Replace the evType and the content in the loop to what you need for that type of EV Training
testEVTrainingPathing() {
    global commonImageDir
    global rootDir
    
    ; Set the EV type variables
    global evType := "specialDef"


    ; Define directories based on EV type
    commonImageDir := rootDir "\images\common\"
    evTypeImageDir := rootDir "\images\" . evType . "\"

    Loop(5)
    {
        Sleep(1000)
        
        sendKey("1", , 0.3)
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
        flyToPokecenter()
        testNurseInteraction()
    }
}

