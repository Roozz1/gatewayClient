local stopPerm = false
local prefix = "!"
local ws = syn.websocket.connect("ws://localhost:5000")

local plr = game.Players.LocalPlayer

local closePlayersOnlyMode = false

--chat in game
function chat(msg)
    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
end

--listen for messages
game.ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(object)
    if not stopPerm then
        local msg = object.Message
        local author = game.Players:FindFirstChild(object.FromSpeaker)

        if tostring(author.UserId) == "3462545255" then
            if msg:lower() == prefix.."stop" then
                print("stopped")
                stopPerm = true
                ws:Close()
                writefile(fileName, "!NoContent!")
            end

            if msg:lower() == prefix.."switch" then
                if not closePlayersOnlyMode then
                    closePlayersOnlyMode = true
                    chat("close players only = true")
                else
                    closePlayersOnlyMode = false
                    chat("close players only = false")
                end
            end
        end

        --log chat msg
        if closePlayersOnlyMode then
            local char = author.Character
            local humRoot = char.HumanoidRootPart

            if plr:DistanceFromCharacter(humRoot.Position) < 25 then
                ws:Send("!close!Game: "..game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name.." | "..author.DisplayName.." ("..author.Name..") said: "..msg)
            end
        else
            ws:Send("!default!Game: "..game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name.." | "..author.DisplayName.." ("..author.Name..") said: "..msg)
        end
    else
        return
    end
end)

game.Players.PlayerAdded:Connect(function(plr)
    ws:Send("!join!Game: "..game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name.." | "..author.DisplayName.." ("..author.Name..") joined the game.")
end)

game.Players.PlayerRemoving:Connect(function(plr)
    ws:Send("!leave!Game: "..game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name.." | "..author.DisplayName.." ("..author.Name..") left the game.")
end)

--stop script if socket connection is closed
ws.OnClose:Connect(function()
    stopPerm = true
    print("socket (chatlog) closed, script stopped")
    writefile(fileName, "!NoContent!")
end)

--from discord to game
fileName = "sendMsgToGame.txt"

while true do
    if stopPerm then break end
    local fileContent = readfile(fileName)
    if fileContent ~= "!NoContent!" then
        chat("FROM DISCO: "..fileContent)
        writefile(fileName, "!NoContent!")
    end
    wait(0.5)
end
