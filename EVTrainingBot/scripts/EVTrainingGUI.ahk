; EVTrainingGUI.ahk - A class for creating a GUI to get user inputs for EV training
#Requires AutoHotkey v2.0
#Include %A_ScriptDir%\utilities.ahk

class EVTrainingGUI {
    ; GUI and control variables
    gui := ""
    guiIsClosed := false
    canceled := false

    ; Control variables
    evInput := ""
    trainingLinkCheckbox := ""
    overrideCheckbox := ""
    battlesInput := ""
    allowEvolutionCheckbox := ""
    denyMovesCheckbox := ""
    customStringsCheckbox := ""
    errorText := ""
    okButton := ""

    ; Get user inputs from GUI
    getUserInputs() {
        global currentEVs, hasTrainingLink, battlesNeeded, overrideBattles, allowEvolutions, customStrings

        this.guiIsClosed := false  ; Reset flag
        this.createGUI()
        this.setupEventHandlers()
        this.gui.Show("AutoSize Center")
        this.validateInputs()

        ; Wait until the GUI is closed
        while !this.guiIsClosed
            Sleep(100)

        ; Return user inputs or canceled status
        if (this.canceled) {
            return { canceled: true }
        } else {
            return {
                canceled: false,
                currentEVs: currentEVs,
                hasTrainingLink: hasTrainingLink,
                battlesNeeded: battlesNeeded,
                overrideBattles: overrideBattles,
                allowEvolutions: allowEvolutions,
                customStrings: customStrings
            }
        }
    }

    createGUI() {
        global currentEVs, hasTrainingLink, overrideBattles, battlesNeeded, allowEvolutions, customStrings
        global evTypeImageDir, evTypeDisplayName

        ; Read settings from the INI file
        loadSettings()

        ; Create the GUI and set properties
        this.gui := Gui(, "EV Training - " . evTypeDisplayName)
        this.gui.SetFont("s11")
        this.gui.MarginX := 10
        this.gui.MarginY := 10
        this.gui.BackColor := "White"

        ; Define layout parameters
        colGap := 20
        col1Width := 1200
        col2Width := 250
        xLeft := 10
        xMiddle := xLeft + col1Width + colGap
        yPos := 10

        ; Column 1: Instructions and image
        this.createLeftColumn(xLeft, yPos, col1Width)

        ; Column 2: Input fields and options
        this.createRightColumn(xMiddle, col2Width)
    }

    createLeftColumn(xLeft, yPos, col1Width) {
        global evTypeImageDir

        ; Step 1: Get into position
        step1Text := this.gui.AddText("x" . xLeft . " y" . yPos . " w" . col1Width . " h50 Center", "Step 1: Get into position")
        step1Text.SetFont("s16 Bold")
        yPos += 35

        ; Load starting location image
        startingLocationImage := evTypeImageDir . "startingLocation.png"
        this.gui.AddPicture("x" . xLeft . " y" . yPos . " w" . col1Width . " h768 Border", startingLocationImage)
    }

    createRightColumn(xMiddle, col2Width) {
        global currentEVs, hasTrainingLink, overrideBattles, battlesNeeded, allowEvolutions, customStrings, evTypeDisplayName

        yPos := 50

        ; Step 2: Enter EV Details
        step2Text := this.gui.AddText("x" . xMiddle . " y" . (yPos + 35) . " w" . col2Width . " h50", "Step 2:`nEnter EV Details")
        step2Text.SetFont("s16 Bold")
        yPos += 90

        ; Current EVs input
        this.gui.AddText("x" . xMiddle . " y" . yPos . " w" . col2Width, "Current " . evTypeDisplayName . " EVs (0 - 251):")
        yPos += 40
        this.evInput := this.gui.AddEdit("x" . xMiddle . " y" . yPos . " w50 Limit3 -WantReturn")
        this.evInput.Value := currentEVs  ; Set saved value
        yPos += 40

        ; Training Link checkbox
        this.trainingLinkCheckbox := this.gui.AddCheckBox("x" . xMiddle . " y" . yPos, "I am holding a Training Link")
        this.trainingLinkCheckbox.Value := hasTrainingLink  ; Set saved value
        yPos += 25

        ; Allow Evolution checkbox
        this.allowEvolutionCheckbox := this.gui.AddCheckBox("x" . xMiddle . " y" . yPos, "Allow Evolution?")
        this.allowEvolutionCheckbox.Value := allowEvolutions  ; Set saved value
        yPos += 25

        ; Custom Strings checkbox
        this.customStringsCheckbox := this.gui.AddCheckBox("x" . xMiddle . " y" . yPos, "Custom Strings")
        this.customStringsCheckbox.Value := customStrings  ; Set saved value
        yPos += 25

        ; Deny Learning New Moves checkbox (disabled for now)
        this.denyMovesCheckbox := this.gui.AddCheckBox("x" . xMiddle . " y" . yPos, "Deny Learning New Moves")
        this.denyMovesCheckbox.Enabled := false
        this.denyMovesCheckbox.Value := true
        yPos += 70

        ; Override EV calculation checkbox
        this.overrideCheckbox := this.gui.AddCheckBox("x" . xMiddle . " y" . yPos, "Override EV calculation")
        this.overrideCheckbox.Value := overrideBattles  ; Set saved value
        yPos += 25

        ; Battles Needed input
        this.battlesInput := this.gui.AddEdit("x" . xMiddle . " y" . yPos . " w100 Limit4 -WantReturn")
        this.battlesInput.Value := battlesNeeded  ; Set saved value
        yPos += 55

        ; Error message text
        this.errorText := this.gui.AddText("x" . xMiddle . " y" . yPos . " w260 h16 cRed", "")
        yPos += 25

        ; START button
        this.okButton := this.gui.AddButton("x" . xMiddle . " y" . yPos . " w250 h365 Center", "START")
        this.okButton.SetFont("s14 Bold")
        this.okButton.Enabled := false  ; Disabled until valid inputs
        this.gui.Default := this.okButton  ; Set as default button
    }

    setupEventHandlers() {
        ; GUI event handlers
        this.gui.OnEvent("Close", this.gui_Close.Bind(this))
        this.gui.OnEvent("Escape", this.gui_Close.Bind(this))

        ; Control event handlers
        this.evInput.OnEvent("Change", this.validateInputs.Bind(this))
        this.battlesInput.OnEvent("Change", this.validateInputs.Bind(this))
        this.overrideCheckbox.OnEvent("Click", this.validateInputs.Bind(this))
        this.okButton.OnEvent("Click", this.okButton_Click.Bind(this))
    }

    gui_Close(guiObj) {
        ; Handle GUI close event
        global currentEVs, hasTrainingLink, overrideBattles, battlesNeeded, allowEvolutions, customStrings
        ; Update global variables with the control values
        currentEVs := this.evInput.Value
        hasTrainingLink := this.trainingLinkCheckbox.Value
        overrideBattles := this.overrideCheckbox.Value
        allowEvolutions := this.allowEvolutionCheckbox.Value
        customStrings := this.customStringsCheckbox.Value
        battlesNeeded := this.battlesInput.Value
        this.canceled := true

        ; Save settings to the INI file
        saveSettings()

        this.guiIsClosed := true
        this.gui.Destroy()
    }

    okButton_Click(ctrlObj := "", eventInfo := "") {
        ; Handle START button click
        global currentEVs, hasTrainingLink, overrideBattles, battlesNeeded, allowEvolutions, customStrings
        ; Update global variables with the control values
        currentEVs := this.evInput.Value
        hasTrainingLink := this.trainingLinkCheckbox.Value
        overrideBattles := this.overrideCheckbox.Value
        allowEvolutions := this.allowEvolutionCheckbox.Value
        customStrings := this.customStringsCheckbox.Value
        battlesNeeded := this.battlesInput.Value
        this.canceled := false

        ; Save settings to the INI file
        saveSettings()

        this.guiIsClosed := true
        this.gui.Destroy()
    }

    validateInputs(ctrlObj := "", eventInfo := "") {
        ; Validate user inputs and enable/disable START button
        validEV := this.isValidEV(this.evInput.Value)
        validBattles := true
        errorMessage := ""

        if (!validEV && !this.overrideCheckbox.Value) {
            errorMessage := "Please enter a valid EV value (0 - 251)."
        }

        if (this.overrideCheckbox.Value) {
            validBattles := this.isValidBattles(this.battlesInput.Value)
            if (!validBattles) {
                errorMessage := "Please enter a valid number of battles."
            }
        }

        ; Enable START button if inputs are valid
        if ((validEV || this.overrideCheckbox.Value) && validBattles) {
            this.okButton.Enabled := true
            this.errorText.Value := ""
        } else {
            this.okButton.Enabled := false
            this.errorText.Value := errorMessage
        }

        ; Enable/disable controls based on override checkbox
        if (this.overrideCheckbox.Value) {
            this.battlesInput.Enabled := true
            this.evInput.Enabled := false
            this.trainingLinkCheckbox.Enabled := false
        } else {
            this.battlesInput.Enabled := false
            this.evInput.Enabled := true
            this.trainingLinkCheckbox.Enabled := true
        }
    }

    isValidEV(value) {
        ; Check if EV value is valid
        if (value == "")
            return false
        if !(value ~= "^\d+$")
            return false
        num := value + 0
        return (num >= 0 && num <= 251)
    }

    isValidBattles(value) {
        ; Check if battles needed value is valid
        if (value == "")
            return false
        if !(value ~= "^\d+$")
            return false
        num := value + 0
        return (num > 0)
    }
}
