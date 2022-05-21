
Global( "g_addonSetTable", {} )
local locale=getLocale()


local BuildsMenu = nil
local ClassMenu = nil


function onSaveBuild( params )
	local wtEdit = params.widget:GetParent():GetChildChecked( "BuildNameEdit", true )
	local text = userMods.FromWString( wtEdit:GetText() )

	if text ~= "" then
		ShowSettingsWnd(text, false)
	end
end


function getBuildIndex( build )
	for i = 1, table.getn( g_addonSetTable ) do
		if g_addonSetTable[i] == build then
			return i
		end
	end
end

function CreateSubMenu(ClassName)
	local SubMenu = {}
	for i, v in ipairs( g_addonSetTable ) do
		local build = g_addonSetTable[i]
		if ClassName == nil or v.class== clTable[ClassName] then
			local MenuName = v.name 
			if GetSelectedSet() == v then 
				MenuName = "*** "..MenuName
			end
			table.insert( SubMenu, {
				name = toWString( MenuName ),
				onActivate = function() 
					SetActiveByIndex(getBuildIndex( build ))
				end,
				submenu = {
					{ name = toWString(locale["rename"]),
						onActivate = function() onRenameBuild( build ) end },
					{ name = toWString(locale["delete"]),
						onActivate = function() 
							DeletePressed(getBuildIndex( build ))
						end },
					{ name = toWString(locale["update"]),
						onActivate = function() 
							ShowSettingsWnd(build.name, true, getBuildIndex( build ))
						end },
				}
			})
		end
	end
	return SubMenu
end

function onShowList( params )
	if DnD:IsDragging() then
		return
	end

	if not ClassMenu or not ClassMenu:IsValid() then
		local menu = {}
		
		menu = CreateSubMenu(nil)

		local desc = mainForm:GetChildChecked( "SaveBuildTemplate", false ):GetWidgetDesc()
		table.insert( menu, { createWidget = function() return mainForm:CreateWidgetByDesc( desc ) end } )

		local listButton = mainForm:GetChildChecked( "FPSIncreaseButton", false )
		if listButton:IsVisible() then
			local pos = listButton:GetPlacementPlain()
			ClassMenu = ShowMenu( { x = pos.posX, y = pos.posY + pos.sizeY }, menu )
		else
			ClassMenu = ShowMenu( { x = 0, y = 32 }, menu )
		end

		RegisterDnd()
		ClassMenu:GetChildChecked( "BuildNameEdit", true ):SetFocus( true )
	else
		DestroyMenu( ClassMenu )
		ClassMenu = nil
	end
end

----------------------------------------------------------------------------------------------------
-- Renaming

local RenameBuildIndex = nil

function GetMenuItems()
	local children = ClassMenu:GetNamedChildren()
	table.sort( children,
		function( a, b )
			if a:GetName() == "ItemEditTemplate" then return false end
			if b:GetName() == "ItemEditTemplate" then return true end
			return a:GetPlacementPlain().posY < b:GetPlacementPlain().posY
		end )
	return children
end

function onRenameBuild( build )
	if RenameBuildIndex then
		onRenameCancel()
	end

	RenameBuildIndex = getBuildIndex( build )

	local item = GetMenuItems()[ RenameBuildIndex ]
	item:Show( false )

	local edit = ClassMenu:GetChildChecked( "ItemEditTemplate", false )
	edit:SetText( toWString( build.name ) )
	edit:SetPlacementPlain( item:GetPlacementPlain() )
	edit:Show( true )
	edit:Enable( true )
	edit:SetFocus( true )
	ClassMenu:GetChildChecked( "BuildNameEdit", true ):SetFocus( false )
end

function onRenameCancel( params )
	local item = GetMenuItems()[ RenameBuildIndex ]
	item:Show( true )

	local edit = ClassMenu:GetChildChecked( "ItemEditTemplate", false )
	edit:Show( false )
	edit:Enable( false )

	ClassMenu:GetChildChecked( "BuildNameEdit", true ):SetFocus( true )
	RenameBuildIndex = nil
end

function onRenameAccept( params )
	local edit = ClassMenu:GetChildChecked( "ItemEditTemplate", false )
	g_addonSetTable[ RenameBuildIndex ].name = userMods.FromWString( edit:GetText() )
	SaveAddonTable()
	RenameBuildIndex = nil

	onShowList()
	onShowList()
end

function onRenameFocus( params )
	if not params.active then
		onRenameAccept( params )
	end
end

----------------------------------------------------------------------------------------------------
-- DnD support

local BaseDndId = 148754878
local DraggedItem = nil
local DragFrom = nil
local DragTo = nil

function IsDragging()
	return DraggedItem ~= nil
end

function RegisterDnd()
	local children = GetMenuItems()
	for i, child in ipairs(children) do
		local nameWidget = child:GetChildUnchecked( "CombinedItem", false )
		if nameWidget then
			mission.DNDRegister( nameWidget, BaseDndId + i, true )
		end
	end
end

function OnDndPick( params )
	if BaseDndId <= params.srcId and params.srcId <= BaseDndId + table.getn(g_addonSetTable) then
		DraggedItem = params.srcWidget:GetParent()

		local children = GetMenuItems()
		DragFrom = 1
		while children[DragFrom]:GetInstanceId() ~= DraggedItem:GetInstanceId() do
			DragFrom = DragFrom + 1
			if DragFrom > table.getn(g_addonSetTable) then
				return
			end
		end

		if RenameBuildIndex then
			onRenameCancel()
		end

		common.RegisterEventHandler( OnDndDragTo, "EVENT_DND_DRAG_TO" )
		common.RegisterEventHandler( OnDndEnd, "EVENT_DND_DROP_ATTEMPT" )
		common.RegisterEventHandler( OnDndEnd, "EVENT_DND_DRAG_CANCELLED" )
		mission.DNDConfirmPickAttempt()
	end
end

function OnDndDragTo( params )
	local posConverter = widgetsSystem:GetPosConverterParams()
	local cursorY = params.posY * posConverter.fullVirtualSizeY / posConverter.realSizeY
	local cursorY = cursorY - DraggedItem:GetParent():GetPlacementPlain().posY

	local children = GetMenuItems()
	local childrenPos = {}
	local dragIndex = nil

	local height = 16
	for i, w in ipairs( children ) do
		if w:GetInstanceId() == DraggedItem:GetInstanceId() then
			dragIndex = i
		end
		childrenPos[ i ] = w:GetPlacementPlain()
		childrenPos[ i ].posY = height
		height = height + childrenPos[ i ].sizeY
	end

	DragTo = dragIndex
	if cursorY < childrenPos[dragIndex].posY then
		while DragTo > 1 and cursorY < childrenPos[DragTo].posY do
			DragTo = DragTo - 1
		end
	else
		while DragTo < table.getn(g_addonSetTable) and cursorY > childrenPos[DragTo].posY + childrenPos[DragTo].sizeY do
			DragTo = DragTo + 1
		end
	end
	table.insert( children, DragTo, table.remove( children, dragIndex ) )

	for i, w in ipairs( children ) do
		w:PlayMoveEffect( w:GetPlacementPlain(), childrenPos[i], 100, EA_MONOTONOUS_INCREASE )
	end
end

function OnDndEnd( params )
	if DragFrom ~= DragTo then
		table.insert( g_addonSetTable, DragTo, table.remove( g_addonSetTable, DragFrom ) )
		SaveAddonTable()
	end

	DraggedItem = nil
	DragFrom = nil
	DragTo = nil

	common.UnRegisterEventHandler( OnDndDragTo, "EVENT_DND_DRAG_TO" )
	common.UnRegisterEventHandler( OnDndEnd, "EVENT_DND_DROP_ATTEMPT" )
	common.UnRegisterEventHandler( OnDndEnd, "EVENT_DND_DRAG_CANCELLED" )
	mission.DNDConfirmDropAttempt()
end

----------------------------------------------------------------------------------------------------

function InitMenuSupport()


	common.RegisterReactionHandler( onSaveBuild, "SaveBuildReaction" )
	common.RegisterReactionHandler( onShowList, "ShowBuildsReaction" )
	common.RegisterReactionHandler( onRenameCancel, "RenameCancelReaction" )
	common.RegisterReactionHandler( onRenameAccept, "RenameBuildReaction" )
	common.RegisterReactionHandler( onRenameFocus, "RenameFocusChanged" )
	common.RegisterReactionHandler( onShowList, "WikiEscReaction" )

	common.RegisterEventHandler( OnDndPick, "EVENT_DND_PICK_ATTEMPT" )
	


	InitMenu()
end


