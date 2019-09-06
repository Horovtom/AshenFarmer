local AshenFarmer = {}
AshenFarmer.UIParent = UIParent
AshenFarmer.DEBUG = false

-- Whether the app is running
AshenFarmer.running = false
-- Whether we are casting some spell, or drinking
AshenFarmer.casting = false
-- Whether we are sending command to target next enemy
AshenFarmer.targetting = false
-- Whether we are sending command to drink
AshenFarmer.drinking = false
-- We are waiting for a delay-check for drinking buff to appear
AshenFarmer.drinkCheck = nil
AshenFarmer.drinkWaitingTime = 30 -- ~0.5-1 seconds

AshenFarmer.signs = {}
AshenFarmer.signs.target = {1, 0, 0}
AshenFarmer.signs.cast = {0, 1, 0}
AshenFarmer.signs.drink = {0, 0, 1}
AshenFarmer.signs.nop = {0,0,0}

AshenFarmer.btnStart = CreateFrame("Button", "StartButton", AshenFarmer.UIParent, "UIPanelButtonTemplate")
AshenFarmer.btnStart:SetSize(80 ,22) -- width, height
AshenFarmer.btnStart:SetText("Start!")
AshenFarmer.btnStart:SetPoint("CENTER", AshenFarmer.UIParent, "CENTER", 400, 0)
AshenFarmer.btnStart:SetScript("OnClick", function()
    print("Starting the app...")
    AshenFarmer.targetNearestEnemy()
    AshenFarmer.running = true;
end)

AshenFarmer.btnStop = CreateFrame("Button", "EndButton", AshenFarmer.UIParent, "UIPanelButtonTemplate")
AshenFarmer.btnStop:SetSize(80, 22)
AshenFarmer.btnStop:SetText("End!")
AshenFarmer.btnStop:SetPoint("CENTER", AshenFarmer.UIParent, "CENTER", 400, -25)
AshenFarmer.btnStop:SetScript("OnClick", function()
    print("Stopping the app...")
    AshenFarmer.running = false;
    AshenFarmer.casting = false;
    AshenFarmer.targetting = false;
    AshenFarmer.drinking = false;
    AshenFarmer.colorIt(AshenFarmer.signs.nop)
end
)

AshenFarmer.myframe = CreateFrame("Frame", "MyFrame", AshenFarmer.UIParent)
AshenFarmer.myframe:ClearAllPoints()
AshenFarmer.myframe:SetPoint("CENTER", AshenFarmer.UIParent, "CENTER", -300, 0)
AshenFarmer.myframe:SetWidth(200)
AshenFarmer.myframe:SetHeight(200)
AshenFarmer.mytexture = AshenFarmer.myframe:CreateTexture("MyTexture", "ARTWORK")
AshenFarmer.mytexture:SetWidth(200)
AshenFarmer.mytexture:SetHeight(200)
AshenFarmer.mytexture:ClearAllPoints()
AshenFarmer.mytexture:SetTexture(1, 0, 0, 0)
AshenFarmer.mytexture:SetAllPoints(AshenFarmer.myframe)

function AshenFarmer.colorIt(color)
    AshenFarmer.mytexture:ClearAllPoints()
    AshenFarmer.mytexture:SetTexture(unpack(color))
    AshenFarmer.mytexture:SetAllPoints(AshenFarmer.myframe)
end

-- This frame is used for displaying the color AND it is used to run game-loop
AshenFarmer.f = CreateFrame("Frame");
function AshenFarmer.f:onUpdate(sinceLastUpdate)
    -- If the app is not running, we should bail out
    if (not AshenFarmer.running) then return; end

    if (AshenFarmer.drinkCheck ~= nil) then
        -- Drink check is not nil, we have to wait for it
        if (AshenFarmer.drinkCheck <= 0) then
            -- Drink check waiting time expired...
            if (AshenFarmer.isDrinking()) then
                if (AshenFarmer.DEBUG) then print("We are drinking now. Dismissing drinkCheck...") end
                AshenFarmer.drinkCheck = nil
            else
                print("Somehow first drinking command failed! Trying again...")
                AshenFarmer.drink()
            end
        else
            AshenFarmer.drinkCheck = AshenFarmer.drinkCheck - 1
        end
    end
end

AshenFarmer.f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
AshenFarmer.f:RegisterEvent("UNIT_SPELLCAST_FAILED")
AshenFarmer.f:RegisterEvent("PLAYER_TARGET_CHANGED")
AshenFarmer.f:RegisterEvent("UNIT_AURA")

function AshenFarmer.f_OnEvent(self, event, player, ...)
    if (event == nil or not AshenFarmer.running) then return; end
    -- print("Received event: ", event, ...)

    if (event == "UNIT_AURA") then
        -- if (not AshenFarmer.drinking) then return; end
        if (not AshenFarmer.drinking) then return; end

        if (AshenFarmer.isDrinking()) then
            AshenFarmer.colorIt(AshenFarmer.signs.nop)
            AshenFarmer.drinkCheck = nil
        else
            if (AshenFarmer.drinkCheck ~= nil) then return; end
            -- Seems like we finished drinking
            if (AshenFarmer.manaLow()) then
                -- Our mana is not high though, we might have to wait for the buff to appear on the list... 
                print("But our mana is not high! Waiting...")
                AshenFarmer.colorIt(AshenFarmer.signs.nop)
                -- Establish waiting time... 
                AshenFarmer.drinkCheck = AshenFarmer.drinkWaitingTime
                return
            end
            if (AshenFarmer.DEBUG) then print("That means, that we finished drinking!") end
            AshenFarmer.drinkCheck = nil
            AshenFarmer.drinking = false
            AshenFarmer.doingNothing()
        end
        return
    end
    
    if (AshenFarmer.drinking) then return end

    if (event == "UNIT_SPELLCAST_SUCCEEDED") then
        if (player ~= "player") then return; end
        AshenFarmer.casting = false
    elseif (event == "PLAYER_TARGET_CHANGED") then 
        AshenFarmer.targetting = false
        AshenFarmer.casting = false
    elseif (event == "UNIT_SPELLCAST_FAILED") then
        if (player ~= "player" or not AshenFarmer.casting) then return; end
        if (AshenFarmer.manaLow()) then
            if (AshenFarmer.DEBUG) then print("We ran out of mana in the middle of combat!") end
            AshenFarmer.drink()
        elseif (not AshenFarmer.hasValidTarget()) then
            AshenFarmer.targetNearestEnemy()
        end
    end

    -- All the other events (Spellcast succeeded and Target died) are basically saying that we are doing nothing...
    AshenFarmer.doingNothing()
end

AshenFarmer.f:SetScript("OnEvent", AshenFarmer.f_OnEvent)

function AshenFarmer.isDrinking()
    -- Go through the list of buffs and search for a drink buff. 
    local i = 1
    while (true) do
        local name, _, _, _, _, _, _, _, _, _, _ = UnitBuff("player", i)
        if (name == nil) then
            return false
        elseif (name == "Drink") then
            return true
        end
        i = i + 1
    end
end

function AshenFarmer.manaLow() 
    return AshenFarmer.getManaPercentage() < 0.2
end

function AshenFarmer.getManaPercentage()
    return UnitPower("Player") / UnitManaMax("Player")
end

function AshenFarmer.hasValidTarget()
    return (UnitIsDead("target") == nil and UnitExists("target") and IsActionInRange(1) == 1)
end

-- Signs to the clicker, that we want to target next enemy
function AshenFarmer.targetNearestEnemy() 
    if (AshenFarmer.DEBUG) then print("Targetting next enemy...") end
    AshenFarmer.targetting = true
    AshenFarmer.casting = false
    AshenFarmer.drinking = false
    AshenFarmer.colorIt(AshenFarmer.signs.target)
end

-- Signs to the clicker, that we want to drink
function AshenFarmer.drink()
    if (AshenFarmer.DEBUG) then print("Drinking...") end
    AshenFarmer.targetting = false
    AshenFarmer.casting = false
    AshenFarmer.drinking = true

    AshenFarmer.colorIt(AshenFarmer.signs.drink)
end

-- Signs to the clicker, that we want to cast a spell
function AshenFarmer.cast()
    if (AshenFarmer.DEBUG) then print("Casting...") end
    AshenFarmer.targetting = false
    AshenFarmer.casting = true
    AshenFarmer.drinking = false
    AshenFarmer.colorIt(AshenFarmer.signs.cast)
end

function AshenFarmer.doingNothing()
    if (AshenFarmer.drinking or AshenFarmer.casting or AshenFarmer.targetting) then return; end

    if (AshenFarmer.DEBUG) then print("=== Doing nothing ===") end

    if (AshenFarmer.hasValidTarget()) then
        if (AshenFarmer.DEBUG) then print("Our new target is valid, good to kill.") end
        AshenFarmer.cast()
    else
        if (AshenFarmer.drinking) then
            if (AshenFarmer.DEBUG) then print("Detected drinking started!") end
        else
            if (AshenFarmer.DEBUG) then print("Our target is not valid") end
            -- Unit died or we targetted wrong enemy
            if (AshenFarmer.manaLow()) then
                if (AshenFarmer.DEBUG) then print("We have less than twenty-percent of mana!") end
                AshenFarmer.drink()
            else
                AshenFarmer.targetNearestEnemy()
            end
        end
    end
end


AshenFarmer.f:SetScript("OnUpdate", function(self, sinceLastUpdate) AshenFarmer.f:onUpdate(sinceLastUpdate); end);




