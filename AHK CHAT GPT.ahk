; Basic GUI setup
#Include JSON.ahk
#Include Jxon.ahk
FileEncoding, UTF-8
Menu, Tray, NoStandard
Menu, Tray, Add, Show/Hide, ToggleGuiVisibility
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Add, Show/Hide, ToggleGuiVisibility
global conversationHistory := []
Gui +AlwaysOnTop +ToolWindow +owndialogs
Gui, Add, Edit,  x5 vUserInput w400 h50, Enter your message here...
Gui, Add, Button, gSendToAI, Chat
Gui, Add, Button, x+5 gClearMessages, Clear Messages
Gui, Add, Button, x+5 gCopyLastResponse, Copy Last Response
Gui, Font, s10, Arial Unicode MS
Gui, Add, Edit, x5 vAIResponse w400 h300 ReadOnly
Gui, Add, Text,x5 h15 y400 ,show/hide:
Gui, Add, Hotkey, x+5 y395 h10 vHotkeyInput w50 h25, F8  ; Default hotkey is F8
Gui, add, Button, x+5 y395 gApplyHotkey, Set
Gui, Show, w420 h425, Tom's AI Assistant
Hotkey, IfWinActive, Tom's AI Assistant
Hotkey, Enter, SendtoAI, On
Hotkey, IfWinActive
Hotkey, F8, ToggleGuiVisibility  
return

ApplyHotkey:
    Gui, Submit, NoHide  ; Save the current GUI contents to their associated variables
    Hotkey, %HotkeyInput%, ToggleGuiVisibility  ; Register the hotkey
return

global guiHidden := false

ToggleGuiVisibility:
    if (guiHidden)
    {
        Gui, Show
        guiHidden := false
    }
    else
    {
        Gui, Hide
        guiHidden := true
    }
return

ClearMessages:
    conversationHistory := []  ; Clear conversation history
    GuiControl,, AIResponse,  ; Clear the AIResponse Edit control
return

CopyLastResponse:
    ; Retrieve current content in the AIResponse Edit control
    GuiControlGet, currentContent, , AIResponse

    ; Split the content into lines
    Lines := StrSplit(currentContent, "`n", "`r")

    ; Copy the last line (last response) to the clipboard
    Clipboard := Lines[Lines.MaxIndex()]
return

SendToAI(userInput) {
    global
    url := "https://api.openai.com/v1/chat/completions"  ; Use the correct endpoint
    apiKey := "API_KEY"
    ; Append user input to conversation history
    conversationHistory.Push({"role": "user", "content": userInput})

    ; Create an array to store messages
    messages := []

    ; Construct messages array
    Loop % conversationHistory.MaxIndex() {
        item := conversationHistory[A_Index]
        messages.Push("{""role"": """ . item.role . """, ""content"": """ . item.content . """}")
    }

    ; Construct the JSON payload as a string
    jsonMessages := ""
    Loop % messages.Length() {
        jsonMessages := jsonMessages . messages[A_Index]
        if (A_Index < messages.Length()) {
            jsonMessages := jsonMessages . ","
        }
    }
    jsonMessages := "[" . jsonMessages . "]"
    jsonPayload := "{""model"": ""gpt-3.5-turbo-1106"", ""messages"": " . jsonMessages . "}"

    ; Copy JSON payload to clipboard for debugging
    Clipboard := jsonPayload

    ; Prepare HTTP request
    http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", url, False)
    http.SetRequestHeader("Content-Type", "application/json")
    http.SetRequestHeader("Authorization", "Bearer " . apiKey)
    http.Send(jsonPayload)

    ; Check for response and handle it
    if (http.Status == 200) {
        jsonResponse := http.ResponseText

        ; Copy JSON response to clipboard for debugging
        Clipboard := jsonResponse

        return ExtractContentFromJSON(jsonResponse)
    } else {
        return "Error: " . http.Status . " " . http.ResponseText
    }

}
ExtractContentFromJSON(jsonString) {
    ; Parse the JSON string into an AutoHotkey object
    json := JXON_Load(jsonString)

    ; Ensure the JSON is valid and contains the expected fields
    if (IsObject(json) && json.HasKey("choices") && json.choices.MaxIndex() >= 0) {
        ; Extract the content from the message of the first choice
        messageObj := json.choices[1].message
        if (IsObject(messageObj) && messageObj.HasKey("content")) {
            return messageObj.content
        }
    }

    ; Return an error message if the expected data is not found
    return "Error: Unable to extract content from JSON response."
}
; Button handler
SendToAI:
    Gui, Submit, NoHide
    userInput := UserInput
    ; Escape backslashes in the user's input

    aiResponse := SendToAI(userInput)

    ; Format and display the messages
    DisplayMessages(userInput, aiResponse)

    ; Clear the UserInput field
    GuiControl,, UserInput, 
return

DisplayMessages(userInput, aiResponse) {
    ; Retrieve current content in the AIResponse Edit control
    GuiControlGet, currentContent, , AIResponse

    ; Format the new messages with an extra line break
    formattedText := "Me:`n " userInput "`n`nTom's AI Assistant:`n " aiResponse "`n`n"

    ; Append the formatted text to the existing content
    newContent := currentContent . formattedText

    ; Update the AIResponse control with the new content
    GuiControl,, AIResponse, %newContent%
}




ExitScript:
GuiClose:
    conversationHistory := []  ; Clear conversation history
    ExitApp
    return
