--[[
Zelly's JSON Legacy Mod XpSave Lua
Evolve : ZellyEllyBear
Steam  : ZellyElly
Mygamingtalk.com : Zelly
Etlegacy : Zelly
Made for jemstar <3
Feel free to report problems to me
https://github.com/Zelly/ZellyLuas for latest version
Get JSON.lua from http://regex.info/blog/lua/json
Looks for JSON.lua in fs_basepath/fs_game/JSON.lua
xpsave.json saves to fs_homepath/fs_game/xpsave.json
To find fs_basepath , fs_homepath , and fs_game type them in the server console or rcon
Contributors:
 https://github.com/Zelly
 https://github.com/klassifyed
version: 8.4

Dev notes:
 MAKE SURE THE XP VALUES ARE COMPUTED WITH FLOAT VALUES NOT INTS
 Lua 5.3 float values and int's can't really interact because of the whole 64 bit integer
 We need to use float values because g_construcibleengineersharing(Don't recall actual cvar)
 Keep as much stuff local as possible
 I use tostring() a lot in the print statements. The reason for this is, instead of using %d for example, is because
 if the value happens tobe nil for some reason it will print "nil" instead of an error.
 

Command List:
!loadxp   - Loads your xp from file
!savexp   - Saves your xp to file
!resetxp  - Resets your xp
!printxp  - Print your xp levels(mostly for debugging)

!finger <target> - Provides info on a client, if you have referee status

Version: 8.4
 Updated some functions were not local
 Added printxp command
Version: 8.3
 Removed !players command (redundant)
 Added new value to XP["XP_SERVER_RESET"].resetinterval, to crosscheck if admin changed XP_RESET_INTERVAL
 Fixed lines 484, 485 and 493 to correct attempt to concatenate a nil value, added tostring()
 Updated getNextServerReset and added comments on justification
 Updated line 209 clientMessage because it wasn't printing.
  -- position or "print" caused messages not to display (removed "print")
  -- using clientNum or -1 makes no difference if the first parameter in the function is clientNum (removed or -1)
  -- added n\ to ensure line return after message, otherwise the next print goes inline with the previous
Version: 8.1
 Removed unecessary underscores, since everything is local
 Added bit more commenting
 Updated functions to be local again
 Updated XP_RESET_INTERVAL default to unlimited time
 Updated server wide reset function to not delete the entire file, but just reset it in memory and it will overwrite when a save comes around.
Version: 8
 Merged pull request from https://github.com/klassifyed
 Fixed skills lost after map restart
 Fixed Issue of G_XP_set float value
 Added server wide xp reset
 Added resetxp command
 Added loadxp command
 Added players command
Version: 7.1
 Fixed G_XP_Set float error
Version 7
  Added option to disable xpsave for bots
  Added option for max xp
Version 6
 Fixed everything that i added in version 4 and 5 :P
Version 5.1:
 Fixed _saveLog nil i think
Version 5: 
 Fixed: Client saving 0 when client crash
 Added: Seperate log saving
Version 4:
 Added _saveAllXp function that runs every _saveTime seconds
Version 1.0-3.0:
 Xp will not save on shutdown
--]]
local MOD_NAME      = "Zelly's JSON Legacy Mod XpSave Lua" -- Lua Module name (Shown in lua_status and various messages)
local MOD_VERSON    = "8.4" -- Lua Module Version (Shown in lua_status and various messages)
local MOD_SHORTNAME = "ZXPSAVE"

-------------------------
---- Admin Variables ----
-------------------------
local saveTime              = 30    -- Seconds in between each runframe xp will save
local printDebug            = true -- If you want to print to console
local logPrintDebug         = true -- If you want it to log to server log ( Requires printDebug = true )
local logDebug              = true  -- If you want it to log to xpsave.log
local logStream             = true  -- If you want it to update xpsave.log every message, false if just at end of round. ( Requires logDebug = true )
local xpSaveForBots         = false -- If you want to save xp for bots
local XP_RESET_INTERVAL     = "20w"   -- Variable to determine when server wide xp resets
-- XP_RESET_INTERVAL = "5d"  - 5 days
-- XP_RESET_INTERVAL = "36h" - 36 hours
-- XP_RESET_INTERVAL = "2w"  - 2 weeks
-- XP_RESET_INTERVAL = "0"   - 0 or lower will be infinite

-- Only modify what you understand.

local readPath              = string.gsub(et.trap_Cvar_Get("fs_basepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/") --
local writePath             = string.gsub(et.trap_Cvar_Get("fs_homepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/")

local JSON                  = (loadfile(readPath .. "JSON.lua"))() -- JSON 

local XP_FILE               = writePath .. "xpsave.json" -- If you want you can replace writePath with readPath here I think
local XP_LOGFILE            = writePath .. "xpsave.log"
local XP_RESET_COUNTDOWN    = 900 -- ( 60 * 15 ) 15 minutes before reset
local XP_END_ROUND_SAVED    = false

local BATTLESENSE           = 0
local ENGINEERING           = 1
local MEDIC                 = 2
local FIELDOPS              = 3
local LIGHTWEAPONS          = 4
local HEAVYWEAPONS          = 5
local COVERTOPS             = 6

local lastState            = -1
local xpServerReset        = false

local XP                    = { }
local LogFile               = { }

-- DATE CONSTANTS
local DATE_EPOCH            -- Set later
local NEXT_RESET            -- Set later
local SEC_TIMER             -- Set later
local HOUR                  = 3600      -- ( 60 * 60 )
local DAY                   = 86400     -- ( 60 * 60 * 24 )
local WEEK                  = 604800    -- ( 60 * 60 * 24 * 7 )

local resetIntervalNum = string.gsub(XP_RESET_INTERVAL, "[%a%c%p%s]", "") -- determine XP_RESET_INTERVAL

if ( string.match(XP_RESET_INTERVAL, "[hH]") ) then -- multiply by HOUR
    XP_RESET_INTERVAL = (HOUR * tonumber(resetIntervalNum))
elseif ( string.match(XP_RESET_INTERVAL, "[dD]") ) then -- multiply by DAY
    XP_RESET_INTERVAL = (DAY * tonumber(resetIntervalNum))
elseif ( string.match(XP_RESET_INTERVAL, "[wW]") ) then -- multiply by WEEK
    XP_RESET_INTERVAL = (WEEK * tonumber(resetIntervalNum))
else -- Pattern incorrectly set, default to infinite
    XP_RESET_INTERVAL = -1
end

------------------------------
---- Lua Module functions ----
------------------------------
--- saveLog
-- Saves any lines in the LogFile buffer table to XP_LOGFILE
local saveLog = function()
    if ( LogFile ~= nil or next(LogFile) ~= nil ) then
        local FileObject = io.open(XP_LOGFILE, "a")
        for k=1, #LogFile do
            FileObject:write(LogFile[k].."\n")
        end
        FileObject:close()
        LogFile = { }
    end
end

--- Print log message to console & xpsave.log if enabled
-- [msg] message for string format
-- [...] args for string format
local _print = function(msg, ...)
    if msg == nil then return end
    msg = et.Q_CleanStr(string.format(msg,...))
    if msg:len() == 0 then return end
    if logPrintDebug then
        et.G_LogPrint(MOD_SHORTNAME ..": " .. msg .. "\n")
    elseif printDebug then
        et.G_Print(MOD_SHORTNAME ..": " .. msg .. "\n")
    end
    if logDebug then
        LogFile[#LogFile+1] = os.date("[%X]") .. " " .. msg
        if logStream then
            saveLog()
        end
    end
end

--- Write xp to XP_FILE
local writeXp = function()
    _print("writeXp() XP(%s) XP_FILE(%s)", tostring(XP), tostring(XP_FILE))
    local xp_encoded = JSON:encode_pretty(XP)
    local FileObject = io.open(XP_FILE, "w")
    FileObject:write(xp_encoded)
    FileObject:close()
end

--- Read xp from XP_FILE if it exists
-- if doesn't exist then return empty table
local readXp = function()
    _print("readXp() XP(%s) XP_FILE(%s)", tostring(XP), tostring(XP_FILE))
    local status, FileObject = pcall(io.open, XP_FILE, "r")
    _print("readXp() FileObject(%s)", tostring(FileObject))
    if ( status and FileObject ~= nil ) then
        local fileData = { }
        for line in FileObject:lines() do
            if ( line ~= nil and line ~= "" ) then
                fileData[#fileData+1] = line
            end
        end
        FileObject:close()
        _print("readXp() Successfully read %s lines from %s", tostring(#fileData), tostring(XP_FILE))
        return JSON:decode( table.concat(fileData,"\n") )  
    else
        _print("readXp() %s not found. Will be created on next shutdown",  tostring(XP_FILE))
        return { }
    end
end

--- Send a clientMessage
-- [clientNum]
-- [position]  - chat,cp,print, etc..
-- [message]   - message for string format
-- [...]       - Args for string format
local clientMessage = function(clientNum, position, message, ...)
    et.trap_SendServerCommand(tonumber(clientNum), position .. "\"" .. string.format(message, ...) .. "\n\"")
end

--- return client's guid
-- [clientNum]
local getGUID = function(clientNum)
    return et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
end

--- Check if guid is a bot
-- [clientNum]
local isBot = function(clientNum)
    local guid = getGUID(clientNum)
    if string.match(tostring(guid), "OMNIBOT") then
        return true
    else
        return false
    end
end


--- Make sure guid is a valid guid before saving to it
-- Also checks for bot xpsave
-- [clientNum]
-- [guid]
local validateGUID = function(clientNum, guid)
    -- allow only alphanumeric characters in guid
    if ( guid == nil or string.match(guid, "%W") or string.lower(guid) == "no_guid" or string.lower(guid) == "unknown" or string.len(guid) < 32 ) then -- Invalid characters detected.
        _print("validateGUID Client(%s) has an invalid guid(%s) will not store xp for player", tostring(clientNum), tostring(guid))
        clientMessage(clientNum, "cp", "^1WARNING: ^7Your XP won't be saved because you have an invalid cl_guid.")
        return false
    end
    if not xpSaveForBots and isBot(clientNum) then
        _print("validateGUID Client(%s) is a bot and xpSaveForBots is disabled", tostring(clientNum))
        return false
    end
    _print("validateGUID Client(%s) has a valid guid(%s)", tostring(clientNum), tostring(guid))
    return true
end



--- Sets skill points for client in the XP table
-- [clientNum]
-- [guid]
-- [skillNum] - see at top for skill number values
local setSkillPoints = function(clientNum, guid, skillNum)
    local skillPoints = et.gentity_get(clientNum, "sess.skillpoints", skillNum) + 0.0 -- Just in case it is not a float, make it a float for lua 5.3
    if skillPoints > XP[guid].skills[skillNum+1] then -- skillPoints should always be equal to or greater than
        XP[guid].skills[skillNum+1] = skillPoints
    end
end

--- Reset a client's xp to 0.0
-- [clientNum]
local resetXp = function(clientNum)
    local guid = getGUID(clientNum)
    if validateGUID(clientNum, guid) then
        _print("resetXp Client(%s) guid(%s)", tostring(clientNum), tostring(guid))
        for k=BATTLESENSE+1, COVERTOPS+1 do
            XP[guid].skills[k] = 0.0 -- MUST BE 0.0 to work with lua 5.3 float values
        end
        _print("resetXp (%s) %s %s %s %s %s %s %s", tostring(guid), tostring(XP[guid].skills[BATTLESENSE+1]), tostring(XP[guid].skills[ENGINEERING+1]), tostring(XP[guid].skills[MEDIC+1]), tostring(XP[guid].skills[FIELDOPS+1]), tostring(XP[guid].skills[LIGHTWEAPONS+1]), tostring(XP[guid].skills[HEAVYWEAPONS+1]), tostring(XP[guid].skills[COVERTOPS+1]))
        et.G_ResetXP(clientNum)
    end
end

--- Save's client's xp
-- [clientNum]
local saveXp = function(clientNum)
    local guid = getGUID(clientNum)
    if validateGUID(clientNum, guid) then
        _print("saveXp Client(%s) guid(%s)", tostring(clientNum), tostring(guid))
        if ( XP[guid] == nil or next(XP[guid]) == nil ) then
            XP[guid] = { }
            _print("saveXp new xpsave table created for (%s)", tostring(guid))
        end
        if ( XP[guid].skills == nil or next(XP[guid].skills) == nil ) then -- Check Separately just in-case for some reason this doesn't exist.
            XP[guid].skills = { }
        end
        for skillNum=BATTLESENSE, COVERTOPS do
            setSkillPoints(clientNum, guid, skillNum)
        end
        _print("saveXp (%s) %s %s %s %s %s %s %s", tostring(guid), tostring(XP[guid].skills[BATTLESENSE+1]), tostring(XP[guid].skills[ENGINEERING+1]), tostring(XP[guid].skills[MEDIC+1]), tostring(XP[guid].skills[FIELDOPS+1]), tostring(XP[guid].skills[LIGHTWEAPONS+1]), tostring(XP[guid].skills[HEAVYWEAPONS+1]), tostring(XP[guid].skills[COVERTOPS+1]))
        -- Check if player has referee status
        if ( et.gentity_get(clientNum, "sess.referee") == 1 ) then
            XP[guid].referee = true
            _print("saveXp Client(%s,%s) saved referee status", tostring(clientNum), tostring(guid))
        else
            XP[guid].referee = false
        end
        -- Update last seen for player
        XP[guid].lastseen = os.time()
    end
end

--- Loads client's xp
-- [clientNum]
local loadXp = function(clientNum)
    local guid = getGUID(clientNum)
    if validateGUID(clientNum, guid) then
        _print("loadXp Client(%s, %s)", tostring(clientNum), tostring(guid))
        if ( XP[guid] == nil or next(XP[guid]) == nil ) then
            XP[guid] = { }
            _print("loadXp new xpsave table created for (%s)", tostring(guid))
        end
        if ( XP[guid].skills == nil or next(XP[guid].skills) == nil ) then -- Check Separately just in-case for some reason this doesn't exist.
            XP[guid].skills = { }
        end
        for k=BATTLESENSE+1, COVERTOPS+1 do
            if ( XP[guid].skills[k] == nil ) then
                XP[guid].skills[k] = 0.0 -- MUST BE 0.0 for compatibility with lua 5.3
            end
            XP[guid].skills[k] = XP[guid].skills[k] + 0.0 -- This is a backward compatibility check just in case we loading old version
        end
        _print("loadXp (%s) %s %s %s %s %s %s %s", tostring(guid), tostring(XP[guid].skills[BATTLESENSE+1]), tostring(XP[guid].skills[ENGINEERING+1]), tostring(XP[guid].skills[MEDIC+1]), tostring(XP[guid].skills[FIELDOPS+1]), tostring(XP[guid].skills[LIGHTWEAPONS+1]), tostring(XP[guid].skills[HEAVYWEAPONS+1]), tostring(XP[guid].skills[COVERTOPS+1]))
        for k=BATTLESENSE, COVERTOPS do
            et.G_XP_Set(clientNum, XP[guid].skills[k+1], k, 0)
        end
        if XP[guid].referee then
            _print("_loadXp Client(%s, %s) granted referee status", tostring(clientNum), tostring(guid))
            et.gentity_set(clientNum, "sess.referee",1)
        end
    end
end

local printFinger = function(clientNum, targetNum)
    _print("printFinger Client(%s) Target(%s)", tostring(clientNum), tostring(targetNum))
    if et.gentity_get(clientNum, "sess.referee") == 1 then
        local ui        = et.trap_GetUserinfo(targetNum)
        local name      = et.Info_ValueForKey(ui, "name")
        local guid      = et.Info_ValueForKey(ui, "cl_guid")
        local ip        = et.Info_ValueForKey(ui, "ip")
        local etversion = et.Info_ValueForKey(ui, "cg_etVersion")
        local protocol  = et.Info_ValueForKey(ui, "protocol")
        local port      = et.Info_ValueForKey(ui, "qport")
        clientMessage(clientNum, "chat", "^ofinger: ^7Fingered info for %s", tostring(name))
        clientMessage(clientNum, "print", "IP(%s) GUID(%s) QPORT(%s)", tostring(ip), tostring(guid), tostring(port))
        clientMessage(clientNum, "print", "ETVERSION(%s) PROTOCOL(%s)", tostring(etversion), tostring(protocol))
    else
        clientMessage(clientNum, "chat", "^ofinger: ^7You do not have access to this command")
    end
end

--[[
local skillcvars = { "skill_battlesense", "skill_engineer", "skill_medic", "skill_fieldops", "skill_lightweapons", "skill_heavyweapons", "skill_covertops"}
local getServerSkillLevel = function(skillNum)
    local skilltable = et.trap_Cvar_Get(skillcvars[skillNum+1])
    -- Convert "%d %d %d %d" into { x,x,x,x }
    -- can then see what level the client has.
end--]]

local printXp = function(clientNum)
    local guid = getGUID(clientNum)
    -- This is more of a debug function to compare your saved xp with your current xp
    if not XP[guid] or not next(XP[guid]) or not XP[guid].skills then return end
    local printxpvalues = function(skillName, skillNum)
        clientMessage(clientNum, "print", "%s %s || %s", skillName, tostring(XP[guid].skills[skillNum+1]),tostring(et.gentity_get(clientNum,"sess.skillpoints",skillNum)))
    end
    clientMessage(clientNum, "print", "Saved xp || Current xp")
    printxpvalues("BATTLESENSE ", BATTLESENSE)
    printxpvalues("ENGINEERING ", ENGINEERING)
    printxpvalues("MEDIC       ", MEDIC)
    printxpvalues("FIELDOPS    ", FIELDOPS)
    printxpvalues("LIGHTWEAPONS", LIGHTWEAPONS)
    printxpvalues("HEAVYWEAPONS", HEAVYWEAPONS)
    printxpvalues("COVERTOPS   ", COVERTOPS)
end

--- Save xp of everyone online
local saveXpAll = function()
    for clientNum=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
        local connected = et.gentity_get(clientNum, "pers.connected")
        -- 0 = Disconnected
        -- 1 = Connecting  -- Might want to do 1 too which is 'currently connecting' but im not sure if their xp is readable then so maybe not...
        -- 2 = Connected
        if connected == 2 then
            _print("saveXpAll Client(%s) is connected, saving their xp", tostring(clientNum))
            saveXp(clientNum)
        end
    end
end

--- Returns the current mapname
local getMapName = function()
    return tostring(et.trap_Cvar_Get("mapname"))
end

--- Returns current game state
local getGameState = function()
    local gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
    if gs == 0 then
        if lastState == 2 then
            return "warmup end"
        end
        return "game"
    elseif gs == -1 then
        return "game end"
    elseif gs == 2 then
        lastState = 2
        return "warmup"
    elseif gs == 3 then
        return "round end"
    else
        return tostring(gs)
    end
end

--- Gets next server reset time
-- Zelly: don't 100% understand this yet, will look into further
-- Klassifyed: if server admin wants XP reset by XP_RESET_INTERVAL. this function is called 
--   on InitGame to verify admin hasn't changed XP_RESET_INTERVAL and again after a xp server reset
local getNextServerReset = function()
    if ( XP["XP_SERVER_RESET"] == nil or next(XP["XP_SERVER_RESET"]) == nil ) then
        XP["XP_SERVER_RESET"] = { }
        XP["XP_SERVER_RESET"].resetinterval = XP_RESET_INTERVAL
    end
    if not XP_RESET_INTERVAL or XP_RESET_INTERVAL <= 0 then
        XP["XP_SERVER_RESET"].nextreset = -1
    elseif ( xpServerReset or XP["XP_SERVER_RESET"].resetinterval ~= XP_RESET_INTERVAL ) then
        DATE_EPOCH = os.time()
        XP["XP_SERVER_RESET"].resetinterval = XP_RESET_INTERVAL
        XP["XP_SERVER_RESET"].nextreset = DATE_EPOCH + XP_RESET_INTERVAL
    end
    NEXT_RESET = XP["XP_SERVER_RESET"].nextreset
end

--- Reset xp for server
-- Zelly: cleaned this up quite a bit, was doing unecessary tasks
-- Klassifyed: Thank-you, much much nicer
local resetServerXp = function()
    _print("resetServerXp Resetting all connected player xp to zero")
    for clientNum=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do -- First reset everyone on the server.
        resetXp(clientNum)
    end
    for i,v in pairs(XP) do
        if v.skills then
            _print("resetServerXp Resetting %s's xp", i)
            v.skills = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 } -- reset xp table
        end
    end
    getNextServerReset()
    xpServerReset = true
    clientMessage(-1, "print", "^3[SERVER XP RESET] - Complete")
    clientMessage(-1, "cp", "^3[SERVER XP RESET] - Complete")
end

--- countdown timer function from 15 minutes before server xp reset
local checkServerXpReset = function()
    DATE_EPOCH = os.time()
    local time
    if ( NEXT_RESET ~= nil and NEXT_RESET >= 1 and DATE_EPOCH >= (NEXT_RESET - 900) or DATE_EPOCH >= NEXT_RESET ) then
        if ( DATE_EPOCH == (NEXT_RESET - 900) ) then -- Check XP Server Reset 15 minute mark
            time = os.date("%M:%S", 900)
        elseif ( DATE_EPOCH == (NEXT_RESET - 600) ) then -- Check XP Server Reset 10 minute mark
            time = os.date("%M:%S", 600)
        elseif ( DATE_EPOCH == (NEXT_RESET - 300) ) then -- Check XP Server Reset 5 minute mark
            time = os.date("%M:%S", 300)
        elseif ( DATE_EPOCH == (NEXT_RESET - 240) ) then -- Check XP Server Reset 4 minute mark
            time = os.date("%M:%S", 240)
        elseif ( DATE_EPOCH == (NEXT_RESET - 180) ) then -- Check XP Server Reset 3 minute mark
            time = os.date("%M:%S", 180)
        elseif ( DATE_EPOCH == (NEXT_RESET - 120) ) then -- Check XP Server Reset 2 minute mark
            time = os.date("%M:%S", 120)
        elseif ( DATE_EPOCH == (NEXT_RESET - 60) ) then -- Check XP Server Reset 1 minute mark
            time = os.date("%M:%S", 60)
        elseif ( DATE_EPOCH == (NEXT_RESET - 45) ) then -- Check XP Server Reset 45 second mark
            time = os.date("%M:%S", 45)
        elseif ( DATE_EPOCH == (NEXT_RESET - 30) ) then -- Check XP Server Reset 30 second mark
            time = os.date("%M:%S", 30)
        elseif ( DATE_EPOCH == (NEXT_RESET - 15) ) then -- Check XP Server Reset 15 second mark
            time = os.date("%M:%S", 15)
            SEC_TIMER = 14
        elseif ( DATE_EPOCH < NEXT_RESET and SEC_TIMER ~= nil) then -- Check XP Server Reset remaining seconds
            time = os.date("%M:%S", SEC_TIMER)
            SEC_TIMER = SEC_TIMER - 1
        elseif ( DATE_EPOCH >= NEXT_RESET ) then -- Reset Server XP
            resetServerXp()
        end
        if ( time ~= nil ) then
            clientMessage(-1, "print", "^3[SERVER XP RESET] - %s", tostring(time))
            clientMessage(-1, "cp", "^3[SERVER XP RESET] - %s", tostring(time))
        end
    end
end

function et_InitGame (levelTime, randomSeed, restart)
    et.RegisterModname(tostring(MOD_SHORTNAME) .. " " .. tostring(MOD_VERSION))
    _print(MOD_NAME .. " " .. tostring(MOD_VERSION) .. " Init - " .. getGameState() .. " - " .. getMapName())
    _print("Load Path : " .. tostring(readPath))
    _print("Write Path : " .. tostring(writePath))
    XP = readXp()
    getNextServerReset()
end

function et_ShutdownGame (restart)
    _print(tostring(MOD_NAME) .. " " .. tostring(MOD_VERSION) .. " Shutdown - " .. getGameState() .. " - " .. getMapName())
    saveXpAll()
    writeXp()
    saveLog()
end

function et_RunFrame (levelTime)
    if ( (levelTime % 1000) == 0 and not xpServerReset ) then
        checkServerXpReset()
    end

    if getGameState() ~= "round end" then -- gamestate 3 is Timlimit hit or objectives complete
        if  (levelTime % (saveTime  * 1000)) == 0 then
            _print("et_Runframe saving all active clients")
            saveXpAll()
        end
    elseif ( getGameState() == "round end" ) and not ( XP_END_ROUND_SAVED ) then
        _print("et_Runframe round ended saving all active clients")
        saveXpAll()
        XP_END_ROUND_SAVED = true
    end
end

function et_ClientCommand (clientNum, command)
    local Arg0 = string.lower(et.trap_Argv(0))
    local Arg1 = string.lower(et.trap_Argv(1))
    if ( Arg0 == "say" )  then
        if ( Arg1 == "!finger" ) then
            local targetNum = et.ClientNumberFromString(et.trap_Argv(2))
            printFinger(clientNum, targetNum)
            return 1
        elseif ( Arg1 == "!loadxp" ) then
            loadXp(clientNum)
            clientMessage(clientNum, "print", "^oLoadXp: ^7Your xp has been loaded")
            clientMessage(clientNum, "cp", "^oLoadXp: ^7Your xp has been loaded")
            return 1
        elseif ( Arg1 == "!savexp" ) then
            saveXp(clientNum)
            clientMessage(clientNum, "print", "^oSaveXp: ^7Your xp has been saved")
            clientMessage(clientNum, "cp", "^oSaveXp: ^7Your xp has been saved")
            return 1
        elseif ( Arg1 == "!resetxp" ) then
            resetXp(clientNum)
            clientMessage(clientNum, "print", "^oResetXp: ^7Your xp has been reset")
            clientMessage(clientNum, "cp", "^oResetXp: ^7Your xp has been reset")
            return 1
        elseif ( Arg1 == "!printxp" ) then
            printXp(clientNum)
            return 1
        end
    end
end

function et_ClientConnect (clientNum)
    _print("et_ClientConnect Client(%s) connected, loading their xp", tostring(clientNum))
    loadXp(clientNum)
end

function et_ClientBegin (clientNum)
    local name = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")
    clientMessage(clientNum, "cpm", "^3Welcome ^7%s^3! You are playing on an XP save server", tostring(name))
end

function et_ClientDisconnect (clientNum)
    _print("et_ClientDisconnect Client(%s) disconnected, saving their xp", tostring(clientNum))
    saveXp(clientNum)
end
