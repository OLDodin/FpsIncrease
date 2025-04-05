local m_reactions={}
local m_configForm = nil
local m_createdCheckBoxes = {}
local m_currentSetName = ""
local m_mySetAddons = {}
local m_unloadedNow = false
local m_updateInfo = {}
m_updateInfo.isNeedUpdate = false
m_updateInfo.updateForIndex = 0
local m_setHeaderWidget = nil
local IsBtnInAOPanelNow = false

function setLocaleTextWithColor(widget, aColor)
	setLocaleTextEx(widget, nil, aColor)
end

function setLocaleTextFPS(widget, aFontSize, checked)
	setLocaleTextEx(widget, checked, "ColorWhite",  "left", aFontSize)
end

function IsSaveGlobal()
	local saveGlobal = userMods.GetGlobalConfigSection("FpsIncrease_use_global")
	
	return saveGlobal and saveGlobal.value
end

function SetSaveGlobal(aValue)
	if aValue then
		LogToChat(getLocale()["saveGlobal"])
	else
		LogToChat(getLocale()["saveLocal"])
	end
	userMods.SetGlobalConfigSection( "FpsIncrease_use_global", { value = aValue } )
end

function SaveAddonTable()
	local savedData = {}
	savedData["selectedIndex"] = m_mySetAddons.index
	savedData["savedsets"] = g_addonSetTable
	savedData["dataVersion"] = "3.0"
	if (IsSaveGlobal()) then 
		userMods.SetGlobalConfigSection( "AddonBuilds", savedData )
	else
		userMods.SetAvatarConfigSection( "AddonBuilds", savedData )
	end
end

function LoadAddonTable()
	local savedData = nil
	if (IsSaveGlobal()) then 
		savedData = userMods.GetGlobalConfigSection( "AddonBuilds" )
	else
		savedData = userMods.GetAvatarConfigSection( "AddonBuilds" )
	end
	
	if not savedData then
	elseif not savedData["dataVersion"] then
		--ver 1
		if not savedData["current"] then
			local setAddons = {}
			setAddons.flags = savedData
			setAddons.name = "Set 1"
			table.insert( g_addonSetTable, setAddons )
		else
			-- ver 2
			local setAddons = {}
			setAddons.flags = savedData["savedset"]["set1"]
			setAddons.name = "Set 1"
			table.insert( g_addonSetTable, setAddons )
			
			setAddons = {}
			setAddons.flags = savedData["savedset"]["set2"]
			setAddons.name = "Set 2"
			table.insert( g_addonSetTable, setAddons )

			setAddons = {}
			setAddons.flags = savedData["savedset"]["set3"]
			setAddons.name = "Set 3"
			table.insert( g_addonSetTable, setAddons )
			
			if savedData["current"] == "set1" then
				SetActiveByIndex(1)
			elseif savedData["current"] == "set2" then
				SetActiveByIndex(2)
			else
				SetActiveByIndex(3)
			end
		end	
		
		SaveAddonTable()
	else
		g_addonSetTable = savedData["savedsets"]
		SetActiveByIndex(savedData["selectedIndex"])
	end
end 

function RightClick(params)
	local name=getName(params.widget)
	if not name or name ~= "FPSIncreaseButton" then return end
	ChangeSelectedAddons()
end

local function CompareByString(a,b)
    return a.name < b.name
end

function DeselectAll()
	 for name, currCheckBox in pairs( m_createdCheckBoxes ) do
		setCheckBox(currCheckBox, false)
	 end
end

function SelectAll()
	 for name, currCheckBox in pairs( m_createdCheckBoxes ) do
		setCheckBox(currCheckBox, true)
	 end
end

function SetActiveByIndex(anIndex)
	if m_unloadedNow then
		ChangeSelectedAddons()	
	end
	m_mySetAddons = {}
	m_mySetAddons.index = anIndex
	m_mySetAddons.set = g_addonSetTable[anIndex]
	
	SaveAddonTable()
end

function LoadByIndex(anIndex)
	DeselectAll()
	for name, v in pairs( g_addonSetTable[anIndex].flags ) do
		setCheckBox(m_createdCheckBoxes[name], true)
	end
end

function SavePressed()
	if m_updateInfo.isNeedUpdate then 
		if m_mySetAddons.set == g_addonSetTable[m_updateInfo.updateForIndex] then 
			if m_unloadedNow then
				ChangeSelectedAddons()	
			end
		end
		g_addonSetTable[m_updateInfo.updateForIndex].flags = {}
		
		for name, currCheckBox in pairs( m_createdCheckBoxes ) do
			if getCheckBoxState(currCheckBox) then
				g_addonSetTable[m_updateInfo.updateForIndex].flags[name] = true
			end
		end
	else
		local setAddons = {}
		setAddons.flags = {}
		for name, currCheckBox in pairs( m_createdCheckBoxes ) do
			if getCheckBoxState(currCheckBox) then
				setAddons.flags[name] = true
			end
		end
		
		setAddons.name = m_currentSetName
		table.insert( g_addonSetTable, setAddons )
	end

	SaveAddonTable()
	HideSettingsWnd()
	
	onShowList(g_lastAoPanelParams)
	onShowList(g_lastAoPanelParams) 
end

function DeletePressed(anIndex)
	if m_mySetAddons.set == g_addonSetTable[anIndex] then
		if m_unloadedNow then
			ChangeSelectedAddons()	
		end
		m_mySetAddons = {}
	end
	table.remove( g_addonSetTable, anIndex )
	SaveAddonTable()
	HideSettingsWnd()
	onShowList(g_lastAoPanelParams) 
	onShowList(g_lastAoPanelParams) 
end

function GetSelectedSet()
	return m_mySetAddons.set
end

function ClosePressed()
	
end

function ShowSettingsWnd(aSetName, anIsUpdate, anUpdateIndex)
	if not m_configForm then
		m_configForm = InitConfigForm()
	end
	m_currentSetName = aSetName
	if anIsUpdate then
		m_updateInfo.isNeedUpdate = true
		m_updateInfo.updateForIndex = anUpdateIndex
		LoadByIndex(anUpdateIndex)
	else
		DeselectAll()
		m_updateInfo.isNeedUpdate = false
		m_updateInfo.updateForIndex = 0
	end
	setText(m_setHeaderWidget, ConcatWString(getLocale()["setName"], toWString(aSetName)))
	show(m_configForm)
end

function HideSettingsWnd()
	hide(m_configForm)
	ClosePressed()
end

function SetPVPSelected()
	SetSelected(g_bgAddonList)
end

function SetPVESelected()
	SetSelected(g_pveAddonList)
end

function SetAstralSelected()
	SetSelected(g_astralAddonList)
end

function SetSelected(anSelectedArr)
	DeselectAll()
	
	for i = 1, GetTableSize( anSelectedArr ) do
		local currCheckBox = m_createdCheckBoxes[anSelectedArr[i]]
		if currCheckBox then
			setCheckBox(currCheckBox, true)
		end
	end
end

function CalcShift(aXShift, aYShift, anAddonsPerColumn)
	aYShift = aYShift + 1 
	if aYShift == anAddonsPerColumn then
		aXShift = aXShift + 230
		aYShift = 0
	end
	return aXShift, aYShift
end

function CreateAddonChexbox(aForm, aName, aXShift, aYShift)
	local checkBoxTxt = createWidget(aForm, aName, "TextView", nil, nil, 200, 15, 30+aXShift, 10+aYShift*20)
	setLocaleTextFPS(checkBoxTxt, 10)
	local nameOfCheckBox = aName.."_checkbox"
	local currCheckBox = createWidget(aForm, nameOfCheckBox, "CheckBox", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, 15, 15, 12+aXShift, 10+aYShift*20)
	m_createdCheckBoxes[aName] = currCheckBox
	setCheckBox(currCheckBox, false)
end

function InitConfigForm()
	setTemplateWidget("common")
	local formWidth = 1200
	local form=createWidget(mainForm, "ConfigForm", "Panel", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, formWidth, 900, 0, 60)
	priority(form, 5500)
	hide(form)
	
	local addons = common.GetStateManagedAddons()
	table.sort(addons, CompareByString) --sorting with [1] position
	
	local btnWidth = 220
	local setBtnPos = formWidth/2-btnWidth/2
	
	setLocaleTextFPS(createWidget(form, "minimalButton", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, btnWidth, 25, setBtnPos, 35))
	setLocaleTextFPS(createWidget(form, "mediumButton", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, btnWidth, 25, setBtnPos, 65))
	setLocaleTextFPS(createWidget(form, "allButton", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, btnWidth, 25, setBtnPos, 95))
	

	setLocaleTextFPS(createWidget(form, "saveButton1", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, 140, 25, 90, 872))
	setLocaleTextFPS(createWidget(form, "closeBarsButton2", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, 140, 25, 270, 872))
	
	
	setLocaleTextWithColor(createWidget(form, "header", "TextView", nil, nil, 600, 25, formWidth/2-300, 124), "ColorYellow")
	m_setHeaderWidget = createWidget(form, "saveheader", "TextView", nil, nil, 600, 25, formWidth/2-50, 10)

	local addonsPerColumn = math.ceil(GetTableSize( addons )/5)
	local scroll = createWidget(form, "container", "ScrollableContainer", nil, nil, formWidth-10, 720, 4, 144)
	local panel = createWidget(form, "group1", "Panel", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, formWidth-50, addonsPerColumn*20+20, 0, 0)
	scroll:PushBack(panel)
	--local str = ""
	local xShift = 0
	local yShift = 0
	
	for i = 1, GetTableSize( addons ) do
		local info = addons[i]
		if info then
			if not string.find(info.name, "FpsIncrease") 
			and not string.find(info.name, "UserAddon") 
			and not string.find(info.name, "SpectatorTools")
			or info.name == "UserAddonManager"
			then
				CreateAddonChexbox(panel, info.name, xShift, yShift)
				--str = str.."Locales[\"rus\"][\""..info.name.."\"]=\"texttext\"\n"	
				--str = str..", \n".."\""..info.name.."\""
				xShift, yShift = CalcShift(xShift, yShift, addonsPerColumn)
			end
		end
	end
	-- add useraddons to the end
	for i = 1, GetTableSize( addons ) do
		local info = addons[i]
		if info then
			if not string.find(info.name, "FpsIncrease") 
			and string.find(info.name, "UserAddon") 
			and info.name ~= "UserAddonManager"
			then
				CreateAddonChexbox(panel, info.name, xShift, yShift)		
				xShift, yShift = CalcShift(xShift, yShift, addonsPerColumn)				
			end
		end
	end
	--LogInfo(str)

	setLocaleTextFPS(createWidget(form, "selectAll", "Button", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, 160, 25, 20, 872))
	setLocaleTextFPS(createWidget(form, "deseletAll", "Button", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, 160, 25, 190, 872))
	
	setText(createWidget(form, "closeBarsButton", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, 20, 20, 20, 20), "x")
	DnD.Init(form, form, true)
	AddReaction("closeBarsButton", function () HideSettingsWnd() end)
	AddReaction("closeBarsButton2", function () HideSettingsWnd() end)
	
	AddReaction("minimalButton", SetPVPSelected)
	AddReaction("mediumButton", SetPVESelected)
	AddReaction("allButton", SetAstralSelected)

	AddReaction("saveButton1", SavePressed)

	AddReaction("selectAll", SelectAll)
	AddReaction("deseletAll", DeselectAll)
	return form
end

function ChangeSelectedAddons()
	if not m_mySetAddons.set then
		return
	end
	m_unloadedNow = not m_unloadedNow
	if m_unloadedNow then
		setText(getChild(mainForm, "FPSIncreaseButton"), "Boost ON")
	else
		setText(getChild(mainForm, "FPSIncreaseButton"), "Boost off")
	end
	for name, v in pairs( m_mySetAddons.set.flags ) do
		if m_unloadedNow then
			common.StateUnloadManagedAddon( name )
		else
			common.StateLoadManagedAddon( name )
		end
	end
	
	for _, info in ipairs(common.GetStateManagedAddons()) do
		if info and info.name == "UserAddon/AOPanel" then
			if info.state == ADDON_STATE_LOADED then
				common.StateReloadManagedAddon(info.name)
			end
		end
	end
end


local IsAOPanelEnabled = true

function onAOPanelStart( params )
	if IsAOPanelEnabled then
	
		local SetVal = { val = userMods.ToWString( m_unloadedNow and "Boost ON" or "Boost off" ) }
		local params = { header = SetVal, ptype = "button", size = 85 }
		userMods.SendEvent( "AOPANEL_SEND_ADDON",
			{ name = common.GetAddonName(), sysName = common.GetAddonName(), param = params } )

		hide(getChild(mainForm, "FPSIncreaseButton"))
		IsBtnInAOPanelNow = true
	end
end

function onAOPanelLeftClick( params )
	if params.sender == common.GetAddonName() then
		g_lastAoPanelParams = params
		onShowList(params)
	else
		HideMainMenu()
	end
end

function onAOPanelRightClick( params )
	if params.sender == common.GetAddonName() then
		local SetVal = { val = userMods.ToWString( m_unloadedNow and "Boost ON" or "Boost off" )}
		userMods.SendEvent( "AOPANEL_UPDATE_ADDON", { sysName = common.GetAddonName(), header = SetVal } )
		ChangeSelectedAddons()
	end
	
end

function onAOPanelChange( params )
	if params.state == ADDON_STATE_NOT_LOADED and string.find(params.name, "AOPanel") then
		DnD.ShowWdg(getChild(mainForm, "FPSIncreaseButton"))
		IsBtnInAOPanelNow = false
	end
end


local function OnSlashCommand(aParams)
	local text = userMods.FromWString(aParams.text)
	if text == "/fpssaveglobal" or text == "\\fpssaveglobal" then
		SetSaveGlobal(true)
		common.StateReloadManagedAddon(common.GetAddonSysName())
	end
	if text == "/fpssaveavatar" or text == "\\fpssaveavatar" then
		SetSaveGlobal(false)
		common.StateReloadManagedAddon(common.GetAddonSysName())
	end
end

local function onInterfaceToggle(aParams)
	if aParams.toggleTarget == ENUM_InterfaceToggle_Target_All then
		if not IsBtnInAOPanelNow then
			ListButton:Show( not aParams.hide )
		end
	end
end


function Init()
	setTemplateWidget("common")
		
	local button=createWidget(mainForm, "FPSIncreaseButton", "Button", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, 100, 32, 300, 20)
	setText(button, "Boost off")
	DnD.Init(button, button, true)
	
	common.RegisterReactionHandler(ButtonPressed, "execute")
	common.RegisterReactionHandler( RightClick, "executeRightClick" )
	common.RegisterReactionHandler(CheckBoxChangedOn, "CheckBoxChangedOn")
	common.RegisterReactionHandler(CheckBoxChangedOff, "CheckBoxChangedOff")
	common.RegisterEventHandler( onAOPanelStart, "AOPANEL_START" )
	common.RegisterEventHandler( onAOPanelLeftClick, "AOPANEL_BUTTON_LEFT_CLICK" )
	common.RegisterEventHandler( onAOPanelRightClick, "AOPANEL_BUTTON_RIGHT_CLICK" )
	common.RegisterEventHandler( onAOPanelChange, "EVENT_ADDON_LOAD_STATE_CHANGED" )
	
	common.RegisterEventHandler( onInterfaceToggle, "EVENT_INTERFACE_TOGGLE" )
	common.RegisterEventHandler( OnSlashCommand, "EVENT_UNKNOWN_SLASH_COMMAND" )
	
	AddReaction("FPSIncreaseButton", function () onShowList() end)
	
	LoadAddonTable()
	
	InitMenuSupport()
	
end

if (avatar.IsExist()) then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end