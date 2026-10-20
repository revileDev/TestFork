--[[
    AtomWare Telemetry & Webhook Logger Module
    Dispatches authentication events and execution audits to Discord Webhook
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local WEBHOOK_URL = "https://discord.com/api/webhooks/1553009642370506762/PtcqZVm8UU_rDA4_5CY-38B9dRzxDcTFTnI4IXF-cFvn4xAMQrQbf36AeRy48-obyEvp"

local Telemetry = {}

-- Safely discover executor HTTP request implementation
local function getHttpRequestFn()
    if typeof(syn) == "table" and typeof(syn.request) == "function" then
        return syn.request
    end
    if typeof(http_request) == "function" then
        return http_request
    end
    if typeof(request) == "function" then
        return request
    end
    if typeof(http) == "table" and typeof(http.request) == "function" then
        return http.request
    end
    return nil
end

local function getExecutorName()
    if typeof(identifyexecutor) == "function" then
        return identifyexecutor()
    end
    if typeof(getexecutorname) == "function" then
        return getexecutorname()
    end
    return "Unknown Executor"
end

local function getDeviceType()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile / Touch"
    elseif UserInputService.KeyboardEnabled then
        return "PC / Desktop"
    elseif UserInputService.GamepadEnabled then
        return "Console / Gamepad"
    end
    return "Desktop"
end

function Telemetry:SendAuthLog(gameName, placeId, success, reason)
    task.spawn(function()
        local requestFn = getHttpRequestFn()
        if not requestFn then
            return
        end

        local statusText = success and "AUTHENTICATED" or "FAILED"
        local statusColor = success and 1096065 or 15682852 -- 0x10B981 (Green) or 0xEF4444 (Red)

        local payload = {
            username = "AtomWare Hub Telemetry",
            avatar_url = "https://cdn.discordapp.com/attachments/111111111111111111/atomware_logo.png",
            embeds = {
                {
                    title = "⚡ AtomWare Hub — Auth Audit Log",
                    color = statusColor,
                    fields = {
                        {
                            name = "👤 Player",
                            value = string.format("**%s** (@%s)\nUserId: `%s`\nAge: `%s` days", 
                                tostring(LocalPlayer.DisplayName),
                                tostring(LocalPlayer.Name),
                                tostring(LocalPlayer.UserId),
                                tostring(LocalPlayer.AccountAge)
                            ),
                            inline = true
                        },
                        {
                            name = "🎮 Game Target",
                            value = string.format("**%s**\nPlaceId: `%s`",
                                tostring(gameName or "Unknown"),
                                tostring(placeId or game.PlaceId)
                            ),
                            inline = true
                        },
                        {
                            name = "🛡️ Auth Status",
                            value = string.format("**%s**\n%s", 
                                statusText, 
                                tostring(reason or (success and "Key verified" or "Invalid key submitted"))
                            ),
                            inline = true
                        },
                        {
                            name = "💻 Device & Platform",
                            value = getDeviceType(),
                            inline = true
                        },
                        {
                            name = "⚙️ Executor",
                            value = tostring(getExecutorName()),
                            inline = true
                        },
                        {
                            name = "🌐 Job ID",
                            value = string.format("`%s`", tostring(game.JobId or "SinglePlayer")),
                            inline = true
                        }
                    },
                    footer = {
                        text = "AtomWare Universal Hub System • " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
                    }
                }
            }
        }

        local jsonBody = HttpService:JSONEncode(payload)

        pcall(function()
            requestFn({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonBody
            })
        end)
    end)
end

return Telemetry
