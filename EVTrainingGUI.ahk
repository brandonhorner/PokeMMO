#Requires AutoHotkey v2.0+

; Define the EVTrainingGUI class
class EVTrainingGUI {
    currentEVs := ""
    hasTrainingLink := false
    battlesNeeded := ""
    overrideBattles := false
    allowEvolutions := true  ; Default to true

    gui := ""
    guiIsClosed := false

    evInput := ""
    trainingLinkCheckbox := ""
    overrideCheckbox := ""
    battlesInput := ""
    allowEvolutionCheckbox := ""
    denyMovesCheckbox := ""
    errorText := ""
    okButton := ""

    getUserInputs() {
        this.guiIsClosed := false  ; Initialize the flag
        this.gui := Gui(, "Special Attack EV Training")
        this.gui.SetFont("s11")
        this.gui.MarginX := 10
        this.gui.MarginY := 10

        colGap := 20
        col1Width := 1024
        col2Width := 250

        xLeft := 10
        xMiddle := xLeft + col1Width + colGap
        yPos := 10

        ; Column 1: Step 1 - Get into position
        step1Text := this.gui.AddText("x" xLeft " y" yPos " w" col1Width " h50 Center", "Step 1: Get into position")
        step1Text.SetFont("s16 Bold")  ; Make the text bold
        yPos += 35
        this.gui.AddPicture("x" xLeft " y" yPos " w" col1Width " h768 Border", "startingLocation.png")  ; Adjust size as needed

        ; Column 2: Value entry
        yPosMiddle := 50
        step2Text := this.gui.AddText("x" xMiddle " y" yPosMiddle + 35 " w" col2Width " h50", "Step 2:`nEnter EV Details")
        step2Text.SetFont("s16 Bold")  ; Make the text bold
        yPosMiddle += 90
        this.gui.AddText("x" xMiddle " y" yPosMiddle " w" col2Width, "Current Special Attack EVs (0 - 251):")
        yPosMiddle += 20
        this.evInput := this.gui.AddEdit("x" xMiddle " y" yPosMiddle " w50 Limit3")
        yPosMiddle += 40
        this.trainingLinkCheckbox := this.gui.AddCheckBox("x" xMiddle " y" yPosMiddle, "I am holding a Training Link")
        yPosMiddle += 25
        this.allowEvolutionCheckbox := this.gui.AddCheckBox("x" xMiddle " y" yPosMiddle, "Allow Evolution?")
        this.allowEvolutionCheckbox.Value := true  ; Default to checked
        yPosMiddle += 25
        this.denyMovesCheckbox := this.gui.AddCheckBox("x" xMiddle " y" yPosMiddle, "Deny Learning New Moves")
        this.denyMovesCheckbox.Enabled := false  ; Grey out initially since it's not yet implemented
        this.denyMovesCheckbox.Value := true ; Default to checked
        yPosMiddle += 70
        this.overrideCheckbox := this.gui.AddCheckBox("x" xMiddle " y" yPosMiddle, "Override EV calculation")
        yPosMiddle += 25
        this.battlesInput := this.gui.AddEdit("x" xMiddle " y" yPosMiddle " w100 Disabled Limit4")
        yPosMiddle += 80
        this.errorText := this.gui.AddText("x" xMiddle " y" yPosMiddle " w260 h16 cRed", "")

        ; Start button below value entry section
        yPosMiddle += 25  ; Add space before the Start button
        this.okButton := this.gui.AddButton("x" xMiddle " y" yPosMiddle " w250 h365 Center", "START")
        this.okButton.SetFont("s14 Bold")
        this.okButton.Enabled := false  ; Initially disabled

        ; Set up event handlers
        this.gui.OnEvent("Close", this.gui_Close.Bind(this))
        this.gui.OnEvent("Escape", this.gui_Close.Bind(this))

        this.evInput.OnEvent("Change", this.validateInputs.Bind(this))
        this.battlesInput.OnEvent("Change", this.validateInputs.Bind(this))
        this.overrideCheckbox.OnEvent("Click", this.validateInputs.Bind(this))

        this.okButton.OnEvent("Click", this.okButton_Click.Bind(this))

        this.gui.Show("AutoSize Center")

        this.validateInputs()

        ; Wait until the GUI is destroyed
        while !this.guiIsClosed
            Sleep(100)

        return {
            currentEVs: this.currentEVs, 
            hasTrainingLink: this.hasTrainingLink, 
            battlesNeeded: this.battlesNeeded, 
            overrideBattles: this.overrideBattles,
            allowEvolutions: this.allowEvolutions
        }
    }

    gui_Close(guiObj) {
        this.guiIsClosed := true  ; Set the flag to true
        this.gui.Destroy()
    }

    okButton_Click(ctrlObj, eventInfo := "") {
        this.currentEVs := this.evInput.Value
        this.hasTrainingLink := this.trainingLinkCheckbox.Value
        this.overrideBattles := this.overrideCheckbox.Value
        this.allowEvolutions := this.allowEvolutionCheckbox.Value
        this.battlesNeeded := this.battlesInput.Value
        this.guiIsClosed := true  ; Set the flag to true
        this.gui.Destroy()
    }
    
    validateInputs(ctrlObj := "", eventInfo := "") {
        evText := this.evInput.Value
        battlesText := this.battlesInput.Value
        validEV := this.isValidEV(evText)
        validBattles := true
        errorMessage := ""

        if (!validEV && !this.overrideCheckbox.Value) {
            errorMessage := "Please enter a valid EV value (0 - 251)."
        }

        if (this.overrideCheckbox.Value) {
            validBattles := this.isValidBattles(battlesText)
            if (!validBattles) {
                errorMessage := "Please enter a valid number of battles."
            }
        }

        ; Enable START button if valid inputs are provided or override is checked
        if ((validEV || this.overrideCheckbox.Value) && validBattles) {
            this.okButton.Enabled := true
            this.errorText.Value := ""
        } else {
            this.okButton.Enabled := false
            this.errorText.Value := errorMessage
        }

        ; Enable or disable input fields based on overrideCheckbox
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
        if (value == "")
            return false
        if !(value ~= "^\d+$")  ; Checks if value contains only digits
            return false
        num := value + 0
        return (num >= 0 && num <= 251)
    }

    isValidBattles(value) {
        if (value == "")
            return false
        if !(value ~= "^\d+$")
            return false
        num := value + 0
        return (num > 0)
    }
}
