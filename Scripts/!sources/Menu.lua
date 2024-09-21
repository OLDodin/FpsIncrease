-- Functions for menu creation and manipulation
-- A menu is defined by a table of menu items, which can contain the following fields
-- (none are required):
-- {
--	 name = "item",						-- menu item text
--	 onActivate = func,					-- function to be called when the item is clicked
--	 submenu = { }						-- a submenu to be opened on click. If onActivate is also present
--	 									-- then	the arrow must be clicked to open submenu
--	 createWidget = function() CreateWidgetByDesc(desc) end	-- custom menu item, no other fields are used
-- }
--
-- Usage example:
--	local menu = {
--		{ name = "option1", onActivate = function() LogInfo( "", "option1 clicked" ) end }
--		{ name = "option2", onActivate = function() LogInfo( "", "option2 clicked" ) end }
--		{ name = "submenu",
--			submenu = {
--				{ name = "suboption1" }
--				{ name = "suboption2" }
--	} } }
--	ShowMenu( { x = 100, y = 100 }, menu )


local Actions = {} -- maps widget to action executed upon clicking it

local DNDWidgets = {}

-- templates for creating menu parts
local MenuTemplate = mainForm:GetChildChecked( "MenuTemplate", true ):GetWidgetDesc()
local ItemTemplate = mainForm:GetChildChecked( "ItemTemplate", true ):GetWidgetDesc()
local SubmenuTemplate = mainForm:GetChildChecked( "SubmenuTemplate", true ):GetWidgetDesc()
local CombinedTemplate = mainForm:GetChildChecked( "CombinedTemplate", true ):GetWidgetDesc()

function ShowMenu( screenPosition, menu, parent, isSubMenu )
	local menuWidget = mainForm:CreateChildByDesc( MenuTemplate )
	local menuPlacement = menuWidget:GetPlacementPlain()
	local margin = menuPlacement.sizeY / 2
	local width = 0
	local height = margin
	for _, item in ipairs( menu ) do
		
		local itemWidget
		if item.createWidget then
			itemWidget = item.createWidget( menuWidget )
		else
			itemWidget = CreateItemWidget( menuWidget, item )
		end

		local placement = itemWidget:GetPlacementPlain()
		placement.posY = height
		itemWidget:SetPlacementPlain( placement )
		height = height + placement.sizeY
		width = math.max( width, placement.sizeX );

		itemWidget:Show( true )
	end
	
	local menuPlacement = menuWidget:GetPlacementPlain()
	menuPlacement.posX = screenPosition.x
	menuPlacement.posY = screenPosition.y
	menuPlacement.sizeX = width + margin * 2
	menuPlacement.sizeY = height + margin
	MakeVisible( menuPlacement, isSubMenu )
	menuWidget:SetPlacementPlain( menuPlacement )

	SaveAction( menuWidget, { parentMenu = parent and parent:GetInstanceId(), childMenu = nil } )
	menuWidget:Show( true )
	return menuWidget
end

function DestroyMenu( menuWidget )
	local childMenu = Actions[ menuWidget:GetInstanceId() ].childMenu
	if childMenu then
		DestroyMenu( childMenu )
	end

	ClearActions( menuWidget )
	RemoveDnd( menuWidget )
	menuWidget:DestroyWidget()
end

function GetChildMenu(menuWidget)
	return Actions[ menuWidget:GetInstanceId() ].childMenu
end

----------------------------------------------------------------------------------------------------

function SaveAction( widget, action )
	Actions[ widget:GetInstanceId() ] = action
end

function IsMyMenuPicked(srcId)
	if DNDWidgets[srcId] then
		return true
	end
end

function RemoveDnd( widget )
	local children = widget:GetNamedChildren()
	for _, childWdg in pairs( children ) do
		for i, wdg in pairs(DNDWidgets) do
			if wdg and wdg:IsEqual(childWdg) then
				if wdg:DNDGetState() ~= DND_STATE_NOT_REGISTERED then
					wdg:DNDCancelDrag()
					wdg:DNDUnregister()
				end
				DNDWidgets[i] = nil
				break
			end
		end
		RemoveDnd( childWdg )
	end
end

function ClearActions( widget )
	local name = widget:GetInstanceId()
	if Actions[ name ] then
		Actions[ name ] = nil
	end

	local children = widget:GetNamedChildren()
	for _, child in pairs( children ) do
		ClearActions( child )
	end
end

function CreateItemWidget( parent, item )
	local widget
	if item.submenu and item.onActivate then
		widget = parent:CreateChildByDesc( CombinedTemplate )
		local combinedItemWdg = widget:GetChildChecked( "CombinedItem", false )
		combinedItemWdg:SetVal( "button_label", item.name )
		SaveAction( combinedItemWdg, item.onActivate )
		SaveAction( widget:GetChildChecked( "CombinedSubmenu", true ), item.submenu )
		if item.isDNDEnabled then
			if combinedItemWdg:DNDGetState() == DND_STATE_NOT_REGISTERED then
				local id = combinedItemWdg:DNDRegisterGeneric(true)
				DNDWidgets[id] = combinedItemWdg
			end
		end
	elseif item.submenu then
		widget = parent:CreateChildByDesc( SubmenuTemplate )
		widget:SetVal( "button_label", item.name )
		SaveAction( widget, item.submenu )
	else
		widget = parent:CreateChildByDesc( ItemTemplate )
		widget:SetVal( "button_label", item.name )
		if item.onActivate then
			SaveAction( widget, item.onActivate )
		end
	end
	
	item.wdgInstanceId = widget:GetInstanceId()
	
	return widget
end

function GetParentMenu( childWidget )
	local menu = childWidget
	while menu:GetParent():GetInstanceId() ~= mainForm:GetInstanceId() do
		menu = menu:GetParent()
	end
	return menu
end

function MakeVisible( placement, isSubMenu )
	local posConverter = common.GetPosConverterParams()
	if placement.posX + placement.sizeX > posConverter.fullVirtualSizeX then
		placement.posX = posConverter.fullVirtualSizeX - placement.sizeX
		if isSubMenu then
			placement.posY = placement.posY + 18
			placement.posX = placement.posX - 20
		end
	end
	if placement.posY + placement.sizeY > posConverter.fullVirtualSizeY then
		placement.posY = posConverter.fullVirtualSizeY - placement.sizeY
	end
end

----------------------------------------------------------------------------------------------------
-- Reaction handlers

function OnActivate( params )
	if params.active and not IsDragging() then
		local action = Actions[ params.widget:GetInstanceId() ]

		local menu = GetParentMenu( params.widget )
		local parentMenuInfo = Actions[ Actions[ menu:GetInstanceId() ].parentMenu ]
		if parentMenuInfo then
			parentMenuInfo.childMenu = nil
		end
		DestroyMenu( menu )

		if action then
			action(params.widget)
		end
	end
end

function OnOpenSubmenu( params )

	
	if params.active then
		local action = Actions[ params.widget:GetInstanceId() ]
		if action then
			local wt = params.widget
			local pos = { x = wt:GetPlacementPlain().sizeX, y = 0 }
			while wt do
				local placement = wt:GetPlacementPlain()
				pos.x = pos.x + placement.posX
				pos.y = pos.y + placement.posY
				wt = wt:GetParent()
			end

			local menuWidget = GetParentMenu( params.widget )
			local menuInfo = Actions[ menuWidget:GetInstanceId() ]
			if menuInfo.childMenu then
				DestroyMenu( menuInfo.childMenu )
				menuInfo.childMenu = nil
			end
			menuInfo.childMenu = ShowMenu( pos, action, menuWidget, true )
		end
	end
end

function OnCloseSubmenu( params )
	if params.active then
		local menuWidget = GetParentMenu( params.widget )
		local menuInfo = Actions[ menuWidget:GetInstanceId() ]
		if menuInfo.childMenu then
			DestroyMenu( menuInfo.childMenu )
			menuInfo.childMenu = nil
		end
	end
end

----------------------------------------------------------------------------------------------------

function InitMenu()
	common.RegisterReactionHandler( OnActivate, "MenuActivateItemReaction" )
	common.RegisterReactionHandler( OnOpenSubmenu, "MenuOpenSubmenuReaction" )
	common.RegisterReactionHandler( OnOpenSubmenu, "SubmenuMouseOverReaction" )
	common.RegisterReactionHandler( OnCloseSubmenu, "ItemMouseOverReaction" )
end  