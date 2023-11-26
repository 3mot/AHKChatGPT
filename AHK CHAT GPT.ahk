; Basic GUI setup
#Include JSON.ahk
#Include Jxon.ahk
FileEncoding, UTF-8
global conversationHistory := []
Gui, Add, Edit, vUserInput w400 h50, Enter your message here...
Gui, Add, Button, gSendToAI, Chat
Gui, Font, s10, Arial Unicode MS
Gui, Add, Edit, vAIResponse w400 h200 ReadOnly

Gui, Show, w420 h300, Tom's AI Assistant
return


SendToAI(userInput) {
    global
    url := "https://api.openai.com/v1/chat/completions"  ; Use the correct endpoint
    apiKey := "API_ID"
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
    jsonPayload := "{""model"": ""gpt-3.5-turbo"", ""messages"": " . jsonMessages . "}"

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
Enter::
SendToAI:
    Gui, Submit, NoHide
    userInput := UserInput
    ; Escape backslashes in the user's input

    aiResponse := SendToAI(userInput)

    ; Escape backslashes in the AI response
    aiResponse := StrReplace(aiResponse, "\\\", "\")

    ; Retrieve current content in the AIResponse Edit control
    GuiControlGet, currentContent, , AIResponse

    ; Append the new response to the existing content
    newContent := currentContent . (StrLen(currentContent) > 0 ? "`n" : "") . aiResponse
    GuiControl,, AIResponse, %newContent%

return

Esc::
GuiClose:
    conversationHistory := []  ; Clear conversation history
    ExitApp
    return