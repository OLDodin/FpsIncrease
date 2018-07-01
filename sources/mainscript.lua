local m_reactions={}
local m_configForm = nil
local m_template = nil
local m_createdCheckBoxes = {}
local m_currentSetName = ""
local m_mySetAddons = {}
local m_unloadedNow = false
local m_updateInfo = {}
m_updateInfo.isNeedUpdate = false
m_updateInfo.updateForIndex = 0
local m_setHeaderWidget = nil

function SaveAddonTable()
	local savedData = {}
	savedData["selectedIndex"] = m_mySetAddons.index
	savedData["savedsets"] = g_addonSetTable
	savedData["dataVersion"] = "3.0"
	
	userMods.SetAvatarConfigSection( "AddonBuilds", savedData )
end

function LoadAddonTable()
	local savedData = userMods.GetAvatarConfigSection( "AddonBuilds" )
	
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

function AddReaction(name, func)
	if not m_reactions then m_reactions={} end
	m_reactions[name]=func
end

function RunReaction(widget)
	local name=getName(widget)
	if not name or not m_reactions or not m_reactions[name] then return end
	m_reactions[name]()
end

function ButtonPressed(params)
	RunReaction(params.widget)
	changeCheckBox(params.widget)
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
	
	onShowList()
	onShowList() 
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
	onShowList() 
	onShowList() 
end

function GetSelectedSet()
	return m_mySetAddons.set
end

function ClosePressed()
	
end

function GameOptionsPressed()
	options.Update()
	local pageIds = options.GetPageIds()
	for pageIndex = 0, GetTableSize( pageIds ) - 1 do
		local pageId = pageIds[pageIndex]
		if pageIndex == 1 or pageIndex == 3 then
			local groupIds = options.GetGroupIds(pageId)
			if groupIds then
				for groupIndex = 0, GetTableSize( groupIds ) - 1 do
					local groupId = groupIds[groupIndex]
					local blockIds = options.GetBlockIds( groupId )
					for blockIndex = 0, GetTableSize( blockIds ) - 1 do
						local blockId = blockIds[blockIndex]
						
						
						local optionIds = options.GetOptionIds( blockId )
						for optionIndex = 0, GetTableSize( optionIds ) - 1 do
							local optionId = optionIds[optionIndex]
							local optionInfo = options.GetOptionInfo( optionId )
							
							--[[
							
								выкл	Сглаживание
								вкл		Низкая детализация поверхности
								выкл	Тени под персонажами
								выкл	Процедурные текстуры
								выкл	Атмосферные эффекты
								выкл	Пост-эффекты
								выкл	Эффект свечения
								выкл	Мягкие частицы
								
								вкл		Скрывать боевые сообщения в логе боя
								вкл		Всегда использовать интерфейс отряда
							]]--
							if (pageIndex == 1 
							and ((blockIndex == 0 and (optionIndex == 1 or optionIndex == 3 or optionIndex == 5 or optionIndex == 6))
							or (blockIndex == 3 and (optionIndex == 0 or optionIndex == 1 or optionIndex == 2 or optionIndex == 5))))
							then
								if optionIndex == 3 then
									options.SetOptionCurrentIndex( optionId, 1 )
								else
									options.SetOptionCurrentIndex( optionId, 0 )							
								end
							end
							if pageIndex == 3 and blockIndex == 0 and (optionIndex == 4 or optionIndex == 1) then 
								options.SetOptionCurrentIndex( optionId, 1 )
							end
						end
					end
				end		
			end
			options.Apply( pageId )
		end
	end
end

function ShowSettingsWnd(aSetName, anIsUpdate, anUpdateIndex)
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
	setText(m_setHeaderWidget, getLocale()["setName"]..aSetName)
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

function CalcShift(aXShift, aYShift)
	aYShift = aYShift + 1 
	if aYShift == 36 then
		aXShift = aXShift + 230
		aYShift = 0
	end
	return aXShift, aYShift
end

function CreateAddonChexbox(aForm, aName, aXShift, aYShift)
	setLocaleText(createWidget(aForm, aName, "TextView", nil, nil, 200, 15, 40+aXShift, 150+aYShift*20), 10)
	local nameOfCheckBox = aName.."_checkbox"
	local currCheckBox = createWidget(aForm, nameOfCheckBox, "CheckBox", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, 15, 15, 22+aXShift, 150+aYShift*20)
	m_createdCheckBoxes[aName] = currCheckBox
	setCheckBox(currCheckBox, false)
end

function InitConfigForm()
	setTemplateWidget(m_template)
	local formWidth = 1366
	local form=createWidget(mainForm, "ConfigForm", "Panel", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, formWidth, 900, 0, 60)
	priority(form, 5500)
	hide(form)
	
	local addons = common.GetStateManagedAddons()
	table.insert(addons, 0, {})
	table.sort(addons, CompareByString) --sorting with [1] position
	
	local btnWidth = 220
	local setBtnPos = formWidth/2-btnWidth/2-150
	
	setLocaleText(createWidget(form, "minimalButton", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, btnWidth, 25, setBtnPos, 35))
	setLocaleText(createWidget(form, "mediumButton", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, btnWidth, 25, setBtnPos, 65))
	setLocaleText(createWidget(form, "allButton", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, btnWidth, 25, setBtnPos, 95))
	
	setLocaleText(createWidget(form, "gameOptions", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, 240, 25, setBtnPos+300, 65))


	setLocaleText(createWidget(form, "saveButton1", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, 140, 25, 90, 872))
	setLocaleText(createWidget(form, "closeBarsButton2", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, 140, 25, 270, 872))
	
	
	setLocaleTextWithColor(createWidget(form, "header", "TextView", nil, nil, 600, 25, formWidth/2-300, 124), "ColorYellow")
	m_setHeaderWidget = createWidget(form, "saveheader", "TextView", nil, nil, 600, 25, formWidth/2-50, 10)

	--local str = ""
	local xShift = 0
	local yShift = 0
	for i = 1, GetTableSize( addons ) - 1 do
		local info = addons[i]
		if not string.find(info.name, "FpsIncrease") 
		and not string.find(info.name, "UserAddon") 
		and not string.find(info.name, "SpectatorTools")
		or info.name == "UserAddonManager"
		then
			CreateAddonChexbox(form, info.name, xShift, yShift)
			--str = str.."Locales[\"rus\"][\""..info.name.."\"]=\"texttext\"\n"	
			--str = str..", \n".."\""..info.name.."\""
			xShift, yShift = CalcShift(xShift, yShift)
		end
	end
	-- add useraddons to the end
	for i = 1, GetTableSize( addons ) - 1 do
		local info = addons[i]
		if not string.find(info.name, "FpsIncrease") 
		and string.find(info.name, "UserAddon") 
		and info.name ~= "UserAddonManager"
		then
			CreateAddonChexbox(form, info.name, xShift, yShift)		
			xShift, yShift = CalcShift(xShift, yShift)
		end
	end
	--LogInfo(str)

	setLocaleText(createWidget(form, "selectAll", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, 160, 25, 1200, 872))
	setLocaleText(createWidget(form, "deseletAll", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, 160, 25, 1030, 872))
	
	setText(createWidget(form, "closeBarsButton", "Button", WIDGET_ALIGN_HIGH, WIDGET_ALIGN_LOW, 20, 20, 20, 20), "x")
	DnD:Init(form, form, true)
	AddReaction("closeBarsButton", function () HideSettingsWnd() end)
	AddReaction("closeBarsButton2", function () HideSettingsWnd() end)
	
	AddReaction("minimalButton", SetPVPSelected)
	AddReaction("mediumButton", SetPVESelected)
	AddReaction("allButton", SetAstralSelected)

	AddReaction("saveButton1", SavePressed)

	AddReaction("gameOptions", GameOptionsPressed)
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
	

	local addons = common.GetStateManagedAddons()

	for i = 0, GetTableSize( addons ) - 1 do
		local info = addons[i]
		if  string.find(info.name, "AOPanelMod") then
			if info.isLoaded then
				common.StateUnloadManagedAddon( info.name )
				common.StateLoadManagedAddon( info.name )
			end
		end
	end
end


local IsAOPanelEnabled = GetConfig( "EnableAOPanel" ) or GetConfig( "EnableAOPanel" ) == nil

function onAOPanelStart( params )
	if IsAOPanelEnabled then
	
		local SetVal = { val = userMods.ToWString( m_unloadedNow and "Boost ON" or "Boost off" ) }
		local params = { header = SetVal, ptype = "button", size = 85 }
		userMods.SendEvent( "AOPANEL_SEND_ADDON",
			{ name = common.GetAddonName(), sysName = common.GetAddonName(), param = params } )

		hide(getChild(mainForm, "FPSIncreaseButton"))
	end
end

function onAOPanelLeftClick( params )
	if params.sender == common.GetAddonName() then
		onShowList()
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
	if params.unloading and params.name == "UserAddon/AOPanelMod" then
		show(getChild(mainForm, "FPSIncreaseButton"))
	end
end

function enableAOPanelIntegration( enable )
	IsAOPanelEnabled = enable
	SetConfig( "EnableAOPanel", enable )

	if enable then
		onAOPanelStart()
	else
		show(getChild(mainForm, "FPSIncreaseButton"))
	end
end


function Init()
	m_template = createWidget(nil, "Template", "Template")
	setTemplateWidget(m_template)
		
	local button=createWidget(mainForm, "FPSIncreaseButton", "Button", WIDGET_ALIGN_LOW, WIDGET_ALIGN_LOW, 100, 25, 300, 20)
	setText(button, "Boost off")
	DnD:Init(button, button, true)
	
	common.RegisterReactionHandler(ButtonPressed, "execute")
	common.RegisterReactionHandler( RightClick, "RIGHT_CLICK" )
	common.RegisterEventHandler( onAOPanelStart, "AOPANEL_START" )
	common.RegisterEventHandler( onAOPanelLeftClick, "AOPANEL_BUTTON_LEFT_CLICK" )
	common.RegisterEventHandler( onAOPanelRightClick, "AOPANEL_BUTTON_RIGHT_CLICK" )
	common.RegisterEventHandler( onAOPanelChange, "EVENT_ADDON_LOAD_STATE_CHANGED" )
	
	m_configForm = InitConfigForm()
	
	AddReaction("FPSIncreaseButton", function () onShowList() end)
	
	LoadAddonTable()
	
	InitMenuSupport()
	
end

if (avatar.IsExist()) then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end