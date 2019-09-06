local AshenFarmer = {}
AshenFarmer.UIParent = UIParent

-- Whether the app is running
AshenFarmer.running = false
-- Whether we are casting some spell, or drinking
AshenFarmer.casting = false
-- Whether we are sending command to target next enemy
AshenFarmer.targetting = false
-- Whether we are sending command to drink
AshenFarmer.drinking = false

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
end

AshenFarmer.f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
AshenFarmer.f:RegisterEvent("PLAYER_TARGET_CHANGED")
AshenFarmer.f:RegisterEvent("UNIT_AURA")

function AshenFarmer.f_OnEvent(self, event, ...)
    if (event == nil or not AshenFarmer.running) then return end
    -- print("Received event: ", event, ...)

    if (event == "UNIT_AURA") then
        -- if (not AshenFarmer.drinking) then return; end
        if (not AshenFarmer.drinking) then return end

        -- Go through the list of buffs and search for a drink buff. If it is there, we are still drinking.
        -- If it is not, we just finished drinking!
        local i = 1
        while (true) do
            local name, _, _, _, _, _, _, _, _, _, _ = UnitBuff("player", i)
            if (name == nil) then
                print("We reached the end of buff list, but did not find any drink!")
                print("That means, that we finished drinking!")
                AshenFarmer.drinking = false
                AshenFarmer.doingNothing()
                return
            elseif (name == "Drink") then
                print("Found a drink at pos: " .. i .. " so we are still drinking...")
                return
            end
            i = i + 1
        end
        return
    elseif (event == "UNIT_SPELLCAST_SUCCEEDED") then
        AshenFarmer.casting = false
    elseif (event == "PLAYER_TARGET_CHANGED") then 
        AshenFarmer.targetting = false
        AshenFarmer.casting = false
    end

    -- All the other events (Spellcast succeeded and Target died) are basically saying that we are doing nothing...
    AshenFarmer.doingNothing()
end

AshenFarmer.f:SetScript("OnEvent", AshenFarmer.f_OnEvent)

function AshenFarmer.getManaPercentage()
    return UnitPower("Player") / UnitManaMax("Player")
end

function AshenFarmer.hasValidTarget()
    return (UnitIsDead("target") == nil and UnitExists("target") and IsActionInRange(1) == 1)
end

-- Signs to the clicker, that we want to target next enemy
function AshenFarmer.targetNearestEnemy() 
    print("Targetting next enemy...")
    AshenFarmer.targetting = true
    AshenFarmer.casting = false
    AshenFarmer.drinking = false
    AshenFarmer.colorIt(AshenFarmer.signs.target)
end

-- Signs to the clicker, that we want to drink
function AshenFarmer.drink()
    print("Drinking...")
    AshenFarmer.targetting = false
    AshenFarmer.casting = false
    AshenFarmer.drinking = true

    AshenFarmer.colorIt(AshenFarmer.signs.drink)
end

-- Signs to the clicker, that we want to cast a spell
function AshenFarmer.cast()
    print("Casting...")
    AshenFarmer.targetting = false
    AshenFarmer.casting = true
    AshenFarmer.drinking = false
    AshenFarmer.colorIt(AshenFarmer.signs.cast)
end

function AshenFarmer.doingNothing()
    if (AshenFarmer.drinking or AshenFarmer.casting or AshenFarmer.targetting) then 
        print("We got to doingNothing even though we are doing SOMETHING!")
        return 
    end

    print("=== Doing nothing ===")

    if (AshenFarmer.hasValidTarget()) then
        print("Our new target is valid, good to kill.")
        AshenFarmer.cast()
    else
        if (AshenFarmer.drinking) then
            print("Detected drinking started!")
        else
            print("Our target is not valid")
            -- Unit died or we targetted wrong enemy
            if (AshenFarmer.getManaPercentage() < 0.2) then
                print("We have less than twenty-percent of mana!")
                AshenFarmer.drink()
            else
                AshenFarmer.targetNearestEnemy()
            end
        end
    end
end


AshenFarmer.f:SetScript("OnUpdate", function(self, sinceLastUpdate) AshenFarmer.f:onUpdate(sinceLastUpdate); end);




