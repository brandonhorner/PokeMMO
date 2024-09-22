This AutoHotkey v2 script automates certain actions in the game PokeMMO (a local sandbox version). It performs movements, initiates battles, and handles in-game interactions to battle hordes of Pokémon using the Sweet Scent ability.

Features
Automated Character Movement:

Moves the character to a specified location using customizable directions and durations.
Directions are mapped to keyboard keys (W, A, S, D) for easy configuration.
Automated Battle Sequence:

Uses Sweet Scent (4 key) to initiate battles.
Navigates through attack options by waiting for specific in-game images to appear.
Executes attacks by simulating key presses (Z key).
Image Recognition with Retry Mechanism:

Waits for certain screens or options to appear/disappear using ImageSearch.
Includes an optional retry limit to prevent infinite waiting.
Hotkey-Controlled Execution:

Start Script: Press F5 to activate the game window, move the character, and start the battle loop.
Exit Script: Press F6 to terminate the script at any time.
Requirements
AutoHotkey Version: This script requires AutoHotkey v2.0 or later.
Operating System: Windows (compatible with versions supported by AutoHotkey v2).
Game Window Title: The script is configured to interact with a window titled PokeMMO.
Setup Instructions
1. Install AutoHotkey v2
If you haven't already, download and install AutoHotkey v2 from the official website.

2. Prepare Image Files
The script relies on image recognition to detect certain in-game screens. You need to provide the following screenshots:

attackOption.png: Screenshot of the attack option appearing after initiating a battle.
attackOptions.png: Screenshot of the attack options menu (usually shows four attack choices).
battleScreen.png: Screenshot of the battle screen when engaged with Pokémon.
outOfPP.png: Screenshot indicating that Sweet Scent is out of PP (Power Points).
Note: Ensure that the screenshots match your game's resolution, graphics settings, and are saved in a supported image format (e.g., PNG).

3. Configure the Script
Image Paths:

Place the image files in the same directory as the script or provide full paths to their locations.
Update the image filenames in the script if they differ from the ones specified.
Character Movements:

Modify the moveCharacter() function calls within the F5 hotkey block to suit your desired path.
autohotkey
Copy code
moveCharacter("right", 2)  ; Move right for 2 seconds
moveCharacter("up", 1.5)   ; Move up for 1.5 seconds
Hotkeys:

Change the hotkeys (F5 to start, F6 to exit) if desired. Refer to the AutoHotkey documentation for hotkey syntax.
Retry Limits:

Adjust the retry limits in the waitForImage() and waitForImageDisappear() function calls to match the game's response times.
4. Run the Script
Save the Script:

Copy the script code into a text editor.
Save the file with a .ahk extension (e.g., PokeMMO_Automation.ahk).
Launch the Script:

Double-click the .ahk file to run it.
An AutoHotkey icon should appear in your system tray indicating that the script is active.
Start the Automation:

Open the PokeMMO game and ensure it's running in a window titled PokeMMO.
Press F5 to start the automation. The script will:
Activate the game window.
Move the character to the specified location.
Begin the battle loop to fight Pokémon using Sweet Scent.
Stop the Automation:

Press F6 at any time to exit the script.
Script Overview
Hotkeys
F5: Starts the main automation sequence.
F6: Exits the script.
Functions
moveCharacter(direction, durationSec):

Moves the character in the specified direction for durationSec seconds.
Directions: "up", "down", "left", "right".
sendKey(key, duration := 0):

Simulates a key press.
If duration is specified, holds the key down for the given duration (in milliseconds).
waitForImage(imagePath, retryLimit := ""):

Waits for an image to appear on the screen.
Optional retryLimit specifies the number of attempts before giving up.
waitForImageDisappear(imagePath, retryLimit := ""):

Waits for an image to disappear from the screen.
Optional retryLimit specifies the number of attempts before giving up.
imageExists(imagePath):

Checks if an image exists on the screen.
Returns true if found, false otherwise.
Main Loop (mainLoop())
Uses Sweet Scent to initiate battles.
Navigates through attack options by waiting for specific images.
Executes attacks and waits for the battle to conclude.
Checks if Sweet Scent is out of PP and exits if so.
Important Notes
Image Matching Accuracy:

For reliable image recognition, ensure that the screenshots are accurate and match the game's current display settings.
Game Policies:

Automating gameplay may violate the game's terms of service. Use this script responsibly and ensure compliance with all applicable policies.
Script Customization:

The script is designed to be flexible. Feel free to modify movement paths, hotkeys, and other parameters to suit your needs.
Disclaimer
This script is provided for educational purposes. The author is not responsible for any consequences resulting from its use. Use the script responsibly and in accordance with the game's terms of service.

Contact
For questions or assistance with the script, please reach out to the script creator or refer to the AutoHotkey documentation.

Enjoy automating your Pokémon battles!
