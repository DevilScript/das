
-- Load WindUI
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not success then
    warn("Failed to load WindUI: " .. tostring(WindUI))
    return
end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Configuration
local versionOptions = {
    PayloadV1 = { fireBytes = game.PlaceId == 139511259501829 and {74} or {71} },
    PayloadV2 = { fireBytes = game.PlaceId == 139511259501829 and {73} or {63} }
}

-- Predefined payloads from 8.txt
local payloads = {
    Gems = {254, 2, 0, 6, 1, 50, 2, 25, 252}, -- Gems (50) with int16 value
    Coins = {254, 2, 0, 6, 1, 49, 3, 96, 121, 254, 255}, -- Coins (49) with int32 value
    EventCoins = {254, 2, 0, 6, 1, 51, 2, 100, 100}, -- Event Coins (51)
    ChristmasCoins = {254, 2, 0, 6, 1, 53, 2, 100, 100}, -- Christmas Coins (53)
    Rice = {254, 2, 0, 6, 3, 52, 48, 50, 253, 1, 0, 6, 1, 49, 3, 50, 251, 511, 255}, -- Item "02"
    LeopardFruit = {254, 2, 0, 6, 3, 53, 48, 56, 253, 1, 0, 6, 3, 49, 48, 49, 4, 0, 0, 0, 208, 136, 195, 0, 66}, -- Fruit "508"
    LoveHashira = {254, 2, 0, 6, 1, 51, 1, 405}, -- Partner (405)
    BigMom = {254, 2, 0, 6, 3, 49, 48, 51, 48, 49, 4, 0, 0, 0, 100, 100, 100, 0, 66}, -- Monster "boss0301"
    FlyBuff = {254, 2, 0, 6, 3, 57, 57, 57, 57, 57, 57, 4, 0, 0, 0, 100, 100, 100, 0, 66} -- Buff "999999"
}

-- Signal identifiers from 6.txt
local signals = {
    "PCFruitEXPUpdateSignal",
    "MonsterDiedSignal",
    "BossHPInfo",
    "SummonWin",
    "Notify",
    "SpinWin",
    "PlayerEffectUpdate",
    "QuestCompletedHUDSignal",
    "CharMoveSignal"
}

-- Convert buffer to readable string
local function bufferToString(bytes)
    local result = ""
    for _, byte in ipairs(bytes) do
        if byte >= 32 and byte <= 126 then
            result = result .. string.char(byte)
        else
            result = result .. "[0x" .. string.format("%02X", byte) .. "]"
        end
    end
    return result
end

-- Fire RemoteEvent function
local function fire(byte, payload)
    local Event = game.PlaceId == 139511259501829 and ReplicatedStorage:FindFirstChild("TestConfiguration") and ReplicatedStorage.TestConfiguration:FindFirstChild("Try")
        or ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Okay")
    
    if not Event then
        WindUI:Notify({
            Title = "Error",
            Content = "Event Not Found",
            Icon = "rbxassetid://17368208554",
            Duration = 5
        })
        return false
    end

    local success, err = pcall(function()
        Event:FireServer(
            (function(bytes)
                local b = buffer.create(#bytes)
                for i = 1, #bytes do
                    buffer.writeu8(b, i - 1, bytes[i])
                end
                return b
            end)({byte}),
            (function(bytes)
                local b = buffer.create(#bytes)
                for i = 1, #bytes do
                    buffer.writeu8(b, i - 1, bytes[i])
                end
                return b
            end)(payload)
        )
    end)

    if not success then
        WindUI:Notify({
            Title = "Error",
            Content = "Failed to Fire Event: " .. tostring(err),
            Icon = "rbxassetid://17368208554",
            Duration = 5
        })
        return false
    end
    return true
end

-- Fire Signal function
local function fireSignal(signalName, payload)
    local Signal = require(game.ReplicatedStorage.Warp.Index.Signal)(signalName)
    local success, err = pcall(function()
        Signal:Fire(payload)
    end)
    if not success then
        WindUI:Notify({
            Title = "Error",
            Content = "Failed to Fire Signal: " .. tostring(err),
            Icon = "rbxassetid://17368208554",
            Duration = 5
        })
        return false
    end
    return true
end

-- Create buffer from table using pack (from 4.txt)
local function createBufferFromTable(data)
    local Buffer = require(game.ReplicatedStorage.Warp.Index.Util.Buffer.Dedicated)()
    Buffer:pack(data)
    return Buffer:buildAndRemove()
end

-- Wait for game to load
repeat task.wait(1) until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

-- Create WindUI Window
local Window
local success, err = pcall(function()
    Window = WindUI:CreateWindow({
        Title = "AnimeFruit Buffer Test V7",
        Icon = "rbxassetid://8572550197",
        Author = "Advanced Buffer & Signal Test",
        Folder = "AnimeFruitBufferTestV7",
        Size = UDim2.fromOffset(600, 500),
        Theme = "Dark"
    })
end)
if not success then
    warn("Failed to create WindUI window: " .. tostring(err))
    return
end

-- Create tabs
local Tabs = {}
Tabs.Test = Window:Section({ Title = "Buffer & Signal Test", Opened = true })
Tabs.Buffer = Tabs.Test:Tab({ Title = "Buffer", Icon = "rbxassetid://17368089841", Desc = "Test Buffer Payloads" })
Tabs.Signal = Tabs.Test:Tab({ Title = "Signal", Icon = "rbxassetid://17368089841", Desc = "Test Signal Payloads" })

-- Variables to store Dropdown and Textbox values
local selectedVersion = "PayloadV1"
local selectedPayload = "Gems"
local selectedSignal = signals[1]
local customPayload = ""
local tablePayload = ""
local fireByte = versionOptions[selectedVersion].fireBytes[1]

-- Version Dropdown
Tabs.Buffer:Dropdown({
    Title = "Select Version",
    Values = { "PayloadV1", "PayloadV2" },
    Value = selectedVersion,
    Callback = function(v)
        selectedVersion = v
        fireByte = versionOptions[selectedVersion].fireBytes[1]
        WindUI:Notify({
            Title = "Success",
            Content = "Now using " .. v,
            Icon = "rbxassetid://17368190066",
            Duration = 3
        })
    end
})

Tabs.Buffer:Divider()

-- Payload Dropdown
Tabs.Buffer:Dropdown({
    Title = "Select Payload",
    Values = { "Gems", "Coins", "EventCoins", "ChristmasCoins", "Rice", "LeopardFruit", "LoveHashira", "BigMom", "FlyBuff" },
    Value = selectedPayload,
    Callback = function(v)
        selectedPayload = v
        local payload = payloads[v]
        local readable = bufferToString(payload)
        WindUI:Notify({
            Title = "Payload Selected",
            Content = "Payload: " .. table.concat(payload, ", ") .. "\nASCII: " .. readable,
            Icon = "rbxassetid://17368190066",
            Duration = 5
        })
    end
})

Tabs.Buffer:Button({
    Title = "Send Selected Payload",
    Callback = function()
        if isProcessing or os.time() - lastClickTime < clickCooldown then return end
        isProcessing = true
        lastClickTime = os.time()
        task.delay(clickCooldown, function() isProcessing = false end)

        local payload = payloads[selectedPayload]
        if fire(fireByte, payload) then
            WindUI:Notify({
                Title = "Success",
                Content = "Payload Sent: " .. table.concat(payload, ",") .. "\nASCII: " .. bufferToString(payload),
                Icon = "rbxassetid://17368190066",
                Duration = 5
            })
        end
    end
})

Tabs.Buffer:Divider()

-- Custom Payload Input
Tabs.Buffer:Textbox({
    Title = "Enter Custom Payload",
    Desc = "Comma-separated bytes (e.g., 254,2,0,6,1,50,2,25,252)",
    Callback = function(value)
        if isProcessing or os.time() - lastClickTime < clickCooldown then return end
        isProcessing = true
        lastClickTime = os.time()
        task.delay(clickCooldown, function() isProcessing = false end)

        customPayload = value
        local bytes = {}
        for num in string.gmatch(value, "%d+") do
            local n = tonumber(num)
            if n and n >= 0 and n <= 255 then
                table.insert(bytes, n)
            end
        end
        if #bytes == 0 then
            WindUI:Notify({
                Title = "Error",
                Content = "Invalid Payload",
                Icon = "rbxassetid://17368208554",
                Duration = 3
            })
            return
        end

        local readable = bufferToString(bytes)
        WindUI:Notify({
            Title = "Buffer Decoded",
            Content = "ASCII: " .. readable,
            Icon = "rbxassetid://17368190066",
            Duration = 5
        })

        if fire(fireByte, bytes) then
            WindUI:Notify({
                Title = "Success",
                Content = "Custom Payload Sent: " .. table.concat(bytes, ",") .. "\nASCII: " .. readable,
                Icon = "rbxassetid://17368190066",
                Duration = 5
            })
        end
    end
})

Tabs.Buffer:Textbox({
    Title = "Enter Fire Byte",
    Desc = "Single byte for RemoteEvent (e.g., 73, 74)",
    Callback = function(value)
        local byte = tonumber(value)
        if not byte or byte < 0 or byte > 255 then
            WindUI:Notify({
                Title = "Error",
                Content = "Invalid Fire Byte (0-255)",
                Icon = "rbxassetid://17368208554",
                Duration = 3
            })
            return
        end
        fireByte = byte
        WindUI:Notify({
            Title = "Success",
            Content = "Fire Byte Set: " .. byte,
            Icon = "rbxassetid://17368190066",
            Duration = 3
        })
    end
})

Tabs.Buffer:Divider()

-- Table-based Payload Input
Tabs.Buffer:Textbox({
    Title = "Enter Table Payload",
    Desc = "Table in JSON format (e.g., {type='fruit',id='501',level=100})",
    Callback = function(value)
        if isProcessing or os.time() - lastClickTime < clickCooldown then return end
        isProcessing = true
        lastClickTime = os.time()
        task.delay(clickCooldown, function() isProcessing = false end)

        tablePayload = value
        local success, data = pcall(function()
            return loadstring("return " .. value)()
        end)
        if not success or type(data) ~= "table" then
            WindUI:Notify({
                Title = "Error",
                Content = "Invalid Table Format",
                Icon = "rbxassetid://17368208554",
                Duration = 3
            })
            return
        end

        local buffer = createBufferFromTable(data)
        local bytes = {}
        for i = 0, buffer.len(buffer) - 1 do
            table.insert(bytes, buffer.readu8(buffer, i))
        end
        local readable = bufferToString(bytes)

        WindUI:Notify({
            Title = "Table Payload Decoded",
            Content = "ASCII: " .. readable,
            Icon = "rbxassetid://17368190066",
            Duration = 5
        })

        if fire(fireByte, bytes) then
            WindUI:Notify({
                Title = "Success",
                Content = "Table Payload Sent: " .. table.concat(bytes, ",") .. "\nASCII: " .. readable,
                Icon = "rbxassetid://17368190066",
                Duration = 5
            })
        end
    end
})

Tabs.Signal:Divider()

-- Signal Dropdown
Tabs.Signal:Dropdown({
    Title = "Select Signal",
    Values = signals,
    Value = selectedSignal,
    Callback = function(v)
        selectedSignal = v
        WindUI:Notify({
            Title = "Signal Selected",
            Content = "Signal: " .. v,
            Icon = "rbxassetid://17368190066",
            Duration = 3
        })
    end
})

Tabs.Signal:Button({
    Title = "Send Selected Payload via Signal",
    Callback = function()
        if isProcessing or os.time() - lastClickTime < clickCooldown then return end
        isProcessing = true
        lastClickTime = os.time()
        task.delay(clickCooldown, function() isProcessing = false end)

        local payload = payloads[selectedPayload]
        if fireSignal(selectedSignal, payload) then
            WindUI:Notify({
                Title = "Success",
                Content = "Payload Sent via Signal: " .. selectedSignal .. "\nPayload: " .. table.concat(payload, ",") .. "\nASCII: " .. bufferToString(payload),
                Icon = "rbxassetid://17368190066",
                Duration = 5
            })
        end
    end
})

Tabs.Signal:Button({
    Title = "Send Table Payload via Signal",
    Callback = function()
        if isProcessing or os.time() - lastClickTime < clickCooldown then return end
        isProcessing = true
        lastClickTime = os.time()
        task.delay(clickCooldown, function() isProcessing = false end)

        local success, data = pcall(function()
            return loadstring("return " .. tablePayload)()
        end)
        if not success or type(data) ~= "table" then
            WindUI:Notify({
                Title = "Error",
                Content = "Invalid Table Format",
                Icon = "rbxassetid://17368208554",
                Duration = 3
            })
            return
        end

        local buffer = createBufferFromTable(data)
        local bytes = {}
        for i = 0, buffer.len(buffer) - 1 do
            table.insert(bytes, buffer.readu8(buffer, i))
        end
        local readable = bufferToString(bytes)

        if fireSignal(selectedSignal, bytes) then
            WindUI:Notify({
                Title = "Success",
                Content = "Table Payload Sent via Signal: " .. selectedSignal .. "\nPayload: " .. table.concat(bytes, ",") .. "\nASCII: " .. readable,
                Icon = "rbxassetid://17368190066",
                Duration = 5
            })
        end
    end
})

-- Variables for click cooldown
local clickCooldown = 0.5
local lastClickTime = 0
local isProcessing = false
