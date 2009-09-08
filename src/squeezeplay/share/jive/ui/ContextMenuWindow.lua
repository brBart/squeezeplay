

-- stuff we use
local ipairs, tostring, type = ipairs, tostring, type

local oo              = require("loop.simple")
local Framework       = require("jive.ui.Framework")
local Widget          = require("jive.ui.Widget")
local Window          = require("jive.ui.Window")
local Surface         = require("jive.ui.Surface")

local log             = require("jive.utils.log").logger("squeezeplay.ui")

local EVENT_ACTION    = jive.ui.EVENT_ACTION
local EVENT_KEY_PRESS = jive.ui.EVENT_KEY_PRESS
local ACTION          = jive.ui.ACTION
local EVENT_CONSUME   = jive.ui.EVENT_CONSUME


-- our class
module(...)
oo.class(_M, Window)


function __init(self, title, windowId)
	local obj = oo.rawnew(self, Window("context_menu" , title, _, windowId))

	obj._DEFAULT_SHOW_TRANSITION = Window.transitionFadeInFast
	obj._DEFAULT_HIDE_TRANSITION = Window.transitionNone

	obj:setAllowScreensaver(true)
	obj:setShowFrameworkWidgets(false)
	obj:setContextMenu(true)

	obj:setButtonAction("lbutton", nil)
	obj:setButtonAction("rbutton", "cancel")

	obj:addActionListener("cancel", obj, _cancelContextMenuAction)
	obj:addActionListener("add", obj, _cancelContextMenuAction)

	obj._bg = _capture()

	return obj
end

function _cancelContextMenuAction()
	Window:hideContextMenus()
	return EVENT_CONSUME
end

function draw(self, surface, layer)
	if not Framework.transition then
		--draw snapshot version of previous version because drawing both windows is too cpu-intensive
		self._bg:blit(surface, 0, 0)
	end
	Window.draw(self, surface, layer)
end


function _getTopWindowContextMenu(self)
	local topWindow = Window:getTopNonTransientWindow()

	if topWindow:isContextMenu() then
		return topWindow
	end
end

function show(self)
	local topContextMenuWindow = self:_getTopWindowContextMenu()
	if topContextMenuWindow then
		self._bg = topContextMenuWindow._bg
		Window.show(self, Window.transitionPushLeftStaticTitle)
	else
		Window.show(self)
		self.isTopContextMenu = true
	end

end

function hide(self)

	local stack = Framework.windowStack

	local idx = 1
	local topwindow = stack[idx]
	while topwindow and topwindow.alwaysOnTop do
		idx = idx + 1
		topwindow = stack[idx]
	end

	if stack[idx + 1] and stack[idx + 1]:isContextMenu() then
		Window.hide(self, Window.transitionPushRightStaticTitle)
	else
		Window.hide(self)
	end

end


function _capture()
	local sw, sh = Framework:getScreenSize()
	local img = Surface:newRGB(sw, sh)

	--take snapshot of screen
	Framework:draw(img)

	--apply shading - tried via maskImg, but child CM windows didn't display maksImg correct
	img:filledRectangle(0, 0, sw, sh, 0x00000085)

	return img
end


--function borderLayout(self)
--	Window.borderLayout(self, true)
--end


function __tostring(self)
	return "ContextMenuWindow()"
end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]
