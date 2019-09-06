local AshenFarmer = {}
AshenFarmer.UIParent = UIParent

AshenFarmer.btnStart = CreateFrame("Button", "StartButton", AshenFarmer.UIParent, "UIPanelButtonTemplate")
AshenFarmer.btnStart:SetSize(80 ,22) -- width, height
AshenFarmer.btnStart:SetText("Start!")
AshenFarmer.btnStart:SetPoint("CENTER", AshenFarmer.UIParent, "CENTER", 400, 0)
AshenFarmer.btnStart:SetScript("OnClick", function()
    print("I am the start button")
end)

AshenFarmer.btnStop = CreateFrame("Button", "EndButton", AshenFarmer.UIParent, "UIPanelButtonTemplate")
AshenFarmer.btnStop:SetSize(80, 22)
AshenFarmer.btnStop:SetText("End!")
AshenFarmer.btnStop:SetPoint("CENTER", AshenFarmer.UIParent, "CENTER", 400, -25)
AshenFarmer.btnStop:SetScript("OnClick", function()
    print("I am the stop button. Mana percentage: " .. AshenFarmer.getManaPercentage())
    
end
)

AshenFarmer.myframe = CreateFrame("Frame", "MyFrame", AshenFarmer.UIParent)
AshenFarmer.myframe:ClearAllPoints()
AshenFarmer.myframe:SetPoint("CENTER", AshenFarmer.UIParent, "CENTER", 0, 0)
AshenFarmer.myframe:SetWidth(300)
AshenFarmer.myframe:SetHeight(300)
AshenFarmer.mytexture = AshenFarmer.myframe:CreateTexture("MyTexture", "ARTWORK")
AshenFarmer.mytexture:SetWidth(300)
AshenFarmer.mytexture:SetHeight(300)
AshenFarmer.mytexture:ClearAllPoints()
AshenFarmer.mytexture:SetTexture(1, 0, 0, 0)
AshenFarmer.mytexture:SetAllPoints(AshenFarmer.myframe)


function AshenFarmer.colorIt(color)
    AshenFarmer.mytexture:ClearAllPoints()
    AshenFarmer.mytexture:SetTexture(unpack(color))
    AshenFarmer.mytexture:SetAllPoints(AshenFarmer.myframe)
end

AshenFarmer.doingSomething = false
AshenFarmer.switch = true
AshenFarmer.f = CreateFrame("Frame");

function AshenFarmer.f:onUpdate(sinceLastUpdate)
	self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
    if ( self.sinceLastUpdate >= 1 ) then -- in seconds
        --[[ local name, _, _, _, _, _, _, _, _ = UnitCastingInfo("Player")
        if (name ~= nil) then
            print("Casting: " .. name)
        end ]]



        if (AshenFarmer.switch) then            
            AshenFarmer.colorIt({1, 0, 0, 0.5})
        else
            AshenFarmer.colorIt({0, 1, 0, 0.5})
        end
        AshenFarmer.switch = not AshenFarmer.switch
		self.sinceLastUpdate = 0;
	end
end

--AshenFarmer.f:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
AshenFarmer.f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

function AshenFarmer.f_OnEvent(self, event, ...)
    if (event == nil) then return end
    print("Event: ", event, ...)
end

AshenFarmer.f:SetScript("OnEvent", AshenFarmer.f_OnEvent)

function AshenFarmer.getManaPercentage()
    return UnitPower("Player") / UnitManaMax("Player")
end

function AshenFarmer.hasValidTarget()
    return (not UnitIsDead("target") and UnitExists("target") and UnitInRange("target"))
end



AshenFarmer.f:SetScript("OnUpdate", function(self, sinceLastUpdate) AshenFarmer.f:onUpdate(sinceLastUpdate); end);







