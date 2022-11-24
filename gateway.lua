local stopPerm = false
local prefix = "!"
local ws = syn.websocket.connect("ws://localhost:5000")
local stalkWs = syn.websocket.connect("ws://localhost:5500")

local currentGame = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

local lPlr = game.Players.LocalPlayer

local closePlayersOnlyMode = false
local allowDiscord = true

local filter = false
local filterUserId = ""

--chat in game
function chat(msg)
    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
end

--search player
function searchPlr(name)
    for i, v in pairs(game.Players:GetChildren()) do
        if v.Name:lower():gsub(" ", ""):find(name:lower():gsub(" ", "")) then
            return v
        end

        if v.DisplayName:lower():gsub(" ", ""):find(name:lower():gsub(" ", "")) then
            return v
        end
    end

    return false
end

--split
function split (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
  
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
  
    return t
end

--listen for messages
game.ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(object)
    if not stopPerm then
        local msg = object.Message
        local author = game.Players:FindFirstChild(object.FromSpeaker)
        local isSplit = false
        local args
        if msg:find(" ") then
            isSplit = true
            args = split(msg)
        end

        if tostring(author.UserId) == tostring(lPlr.UserId) then
            if msg:lower() == prefix.."stop" then
                print("stopped")
                stopPerm = true
                ws:Close()
                stalkWs:Close()
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

            if msg:lower() == prefix.."allow" then
                if not allowDiscord then
                    allowDiscord = true
                    chat("allow disco = true")
                else
                    allowDiscord = false
                    chat("allow disco = false")
                end
            end

            if isSplit then
                if args[1]:lower() == prefix.."filter" then
                    if args[2] then
                        if args[3] then
                            if args[3] == "hide" then
                                if args[2] == "off" then
                                    filter = false
                                    filterUserId = ""
                                else
                                    local plr = searchPlr(args[2])
                                    if plr then
                                        filter = true
                                        filterUserId = plr.UserId
                                    end
                                end
                            end
                        else
                            if args[2] == "off" then
                                chat("filter off")
                                filter = false
                                filterUserId = ""
                            else
                                local plr = searchPlr(args[2])
                                if plr then
                                    filter = true
                                    filterUserId = tostring(plr.UserId)
                                    chat("filter on - "..plr.Name)
                                end
                            end
                        end
                    end
                end

                if args[1]:lower() == prefix.."s" then
                    if args[2] then
                        local plr = searchPlr(args[2])
                        if plr then
                            local content = {
                                ["Name"] = plr.Name,
                                ["Id"] = plr.UserId,
                                ["DisplayName"] = plr.DisplayName,
                                ["JobId"] = game.JobId,
                                ["GameName"] = currentGame,
                                ["GameId"] = game.PlaceId
                            }

                            local jsonFormat = game:GetService("HttpService"):JSONEncode(content)
                            stalkWs:Send(jsonFormat)
                        end
                    end
                end
            end
        end

        --log chat msg
        if closePlayersOnlyMode then
            local char = author.Character
            local humRoot = char.HumanoidRootPart

            if lPlr:DistanceFromCharacter(humRoot.Position) < 25 then
                if filter then
                    if filterUserId == tostring(author.UserId) then
                        ws:Send("!close!**Game: "..currentGame.." | "..author.DisplayName.." ("..author.Name..") said:** "..msg)
                    end
                else
                    ws:Send("!close!**Game: "..currentGame.." | "..author.DisplayName.." ("..author.Name..") said:** "..msg)
                end
            end
        else
            if filter then
                if filterUserId == tostring(author.UserId) then
                    ws:Send("!default!**Game: "..currentGame.." | "..author.DisplayName.." ("..author.Name..") said:** "..msg)
                end
            else
                ws:Send("!default!**Game: "..currentGame.." | "..author.DisplayName.." ("..author.Name..") said:** "..msg)
            end
        end
    else
        return
    end
end)

game.Players.PlayerAdded:Connect(function(plr)
    if filter then
        if filterUserId == tostring(plr.UserId) then
            ws:Send("!join!`Game: "..currentGame.." | "..plr.DisplayName.." ("..plr.Name..") joined the game.`")
        end
    else
        ws:Send("!join!`Game: "..currentGame.." | "..plr.DisplayName.." ("..plr.Name..") joined the game.`")
    end
end)

game.Players.PlayerRemoving:Connect(function(plr)
    if filter then
        if filterUserId == tostring(plr.UserId) then
            ws:Send("!leave!`Game: "..currentGame.." | "..plr.DisplayName.." ("..plr.Name..") left the game.`")
        end
    else
        ws:Send("!leave!`Game: "..currentGame.." | "..plr.DisplayName.." ("..plr.Name..") left the game.`")
    end
end)

--stop script if socket connection is closed
ws.OnClose:Connect(function()
    stopPerm = true
    stalkWs:Stop()
    print("socket (chatlog) closed, script stopped")
    writefile(fileName, "!NoContent!")
end)

stalkWs.OnClose:Connect(function()
    print("stalk websocket disconnected, script will still continue running")
end)

--from discord to game
fileName = "sendMsgToGame.txt"

while true do
    if stopPerm then break end
    if allowDiscord then
        local fileContent = readfile(fileName)
        if fileContent ~= "!NoContent!" then
            chat("FROM DISCO: "..fileContent)
            writefile(fileName, "!NoContent!")
        end
    end
    wait(0.1)
end
