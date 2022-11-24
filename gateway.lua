-- vars
local discordia = require("discordia")
local json = require("json")
local http = require("coro-http")
local client = discordia.Client()

local token = "OTk0NjgxNzUxMzk1OTAxNDcw.GrhWoh.svKQnalVlUnB0EDVlhTznWg3FXgMNdOiE0jB1Y"
local time = require("timer")

local latestLogPath = "../latestlog.txt"
local chatGame = "../../workspace/sendMsgToGame.txt"
local gatewayChannel = "1044380012356321290"

local stalkChannel = "1044382306682535986"
local stalkFile = "../stalkInfoForBot.txt"
local stalkFriendsFile = "../stalkFriends.txt"
local favouriteGamesFile = "../stalkFavouriteGames.txt"

-----code
local function getFileContent(p)
    local file = io.open(p, "r")
    local content = file:read()
    file:close()

    return content
end

local function embed(chan, desc, color, img)
    if img ~= "" then
        chan:send{
            embed = {
                description = desc,
                color = discordia.Color.fromRGB(color[1], color[2], color[3]).value,
                image = {
                    url = img
                }
            }
        }
    else
        chan:send{
            embed = {
                description = desc,
                color = discordia.Color.fromRGB(color[1], color[2], color[3]).value,
            }
        }
    end
end

local oldMsg = getFileContent(latestLogPath)
local oldStalk = getFileContent(stalkFile)

client:on("messageCreate", function(message)
    if not message.author.bot then
        if message.channel.id == gatewayChannel then
            --discord to roblox
            local file = io.open(chatGame, "w")
            file:write(message.content)
            file:close()
            message:addReaction("✅")
        end
    end
end)

client:once('ready', function()
    client:setGame("sex!!")
    client:setStatus("sex")

    while true do
        time.sleep(5)
        local newMsg = getFileContent(latestLogPath)
        local newStalk = getFileContent(stalkFile)

        --chatlog
        if newMsg ~= oldMsg then
            print("msg")
            oldMsg = newMsg
            if tostring(newMsg):find("!close!") then
                embed(client:getChannel(gatewayChannel), "`Mode: Close` " .. tostring(newMsg):gsub("!close!", ""), {50, 50, 255}, "")
            elseif tostring(newMsg):find("!default!") then
                embed(client:getChannel(gatewayChannel), "`Mode: Default` " .. tostring(newMsg):gsub("!default!", ""), {50, 255, 50}, "")
            elseif tostring(newMsg):find("!join!") then
                embed(client:getChannel(gatewayChannel), tostring(newMsg):gsub("!join!", ""), {175, 255, 175}, "")
            elseif tostring(newMsg):find("!leave!") then
                embed(client:getChannel(gatewayChannel), tostring(newMsg):gsub("!leave!", "") , {255, 175, 175}, "")
            end
        end

        --stalk log
        if newStalk ~= oldStalk then
            print("stak")
            local temp = newStalk
            local file = io.open(stalkFile, "w")
            file:write("")
            file:close()
            newStalk = getFileContent(stalkFile)
            oldStalk = newStalk

            print(tostring(temp))
            local data = json.decode(tostring(temp))
            local content = {}

            if data then
                --general info
                table.insert(content, "`Name:` **"..data.Name.."**")
                table.insert(content, "`ID:` **"..data.Id.."**")
                table.insert(content, "`Display Name:` **"..data.DisplayName.."**")
                table.insert(content, "[`Game Info:`](https://www.roblox.com/games/"..data.GameId..")\n```Name: "..data.GameName.."\nPlace ID: "..data.GameId.."\nJob ID: "..data.JobId.."```")

                --friends
                print(getFileContent(stalkFriendsFile))
                local friends = json.decode(getFileContent(stalkFriendsFile))
                local friendsRaw = {}
                for i, v in pairs(friends) do
                    if v.IsOnline then
                        table.insert(friendsRaw, ":green_circle: **"..v.Username.."**")
                    else
                        table.insert(friendsRaw, ":red_circle: **"..v.Username.."**")
                    end
                end
    
                if friendsRaw[1] then
                    table.insert(content, "`Friends:`\n"..table.concat(friendsRaw, "\n").."\n`("..#friendsRaw..")`")
                else
                    table.insert(content, "`Friends:`\n```No friends found.```")
                end

                --favourite games
                print(getFileContent(favouriteGamesFile))
                local favouriteGames = json.decode(getFileContent(favouriteGamesFile))
                local favouriteGamesRaw = {}
                local count = 1
                for i, v in pairs(favouriteGames.Data.Items) do
                    if count <= 15 then
                        table.insert(favouriteGamesRaw, ":video_game: **["..v.Item.Name.."]("..v.Item.AbsoluteUrl..")**")
                    else
                        break
                    end
                end

                if favouriteGamesRaw[1] then
                    table.insert(content, "`Favourite Games:`\n"..table.concat(favouriteGamesRaw, "\n").."\n`("..favouriteGames.Data.TotalItems..")`")
                else
                    table.insert(content, "`Favourite Games:`\n```No favourite games found.```")
                end

                --send
                embed(client:getChannel(stalkChannel), "**Stalk - ["..data.Name.."](https://www.roblox.com/users/"..data.Id.."/profile)**\n"..table.concat(content, "\n"), {255, 255, 255}, "https://www.roblox.com/headshot-thumbnail/image?userId="..data.Id.."&width=420&height=420&format=png")
            end
        end
    end
end)

client:run("Bot " .. token)
