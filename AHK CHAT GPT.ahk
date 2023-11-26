; Basic GUI setup
#Include JSON.ahk
global conversationHistory := []
Gui, Add, Edit, vUserInput w400 h50, Enter your message here...
Gui, Add, Button, gSendToAI, Chat
Gui, Add, Edit, vAIResponse w400 h200 ReadOnly
Gui, Show, w420 h300, Tom's AI Assistant
return


SendToAI(userInput) {
    global
    url := "https://api.openai.com/v1/chat/completions"  ; Use the correct endpoint
    apiKey := "API_KEY_HERE
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
    ; Define the RegEx pattern to match the "content" field
    pattern := """content""\s*:\s*""([^""]+)"""
    ; Use RegExMatch to find the first match of the pattern
    if (RegExMatch(jsonString, pattern, match)) {
        ; Extract the content from the RegEx match
        content := match1

        return content
    }

    ; Return an empty string if the "content" field is not found
    return ""
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
