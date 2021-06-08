
function widget:GetInfo()
	return {
		name = "Limit idle FPS",
		desc = "reduces fps when user is idle" ,
		author = "Floris",
		date = "2020",
		license = "",
		layer = -math.huge,
		enabled = true
	}
end

local idleTime = 0.07	-- not actual idle, just threshold when to decrease fps quickly
local idleFps = 7		-- not instant, slowly lowering to this fps
local idleFrameTimeDelay = 0.033 -- slowing fps increasingly by this much
local sleepTime = 2
local sleepFps = 3
local hibernateTime = 10
local hibernateFps = 1
local offscreenFps = 1

local activeFps = 45
local activeFullspeedFps = 100
local awayTime = 60

local isIdle = false
local isSleep = false
local isHibernate = false
local isAway = false
local lastUserInputTime = os.clock()
local lastMouseX, lastMouseY = Spring.GetMouseState()
local drawAtFullspeed = true
local isOffscreen = false
local nextFrameTime = os.clock()
local frameDelayTime = 0

function widget:Initialize()
	if WG.Chobby and WG.Chobby.Configuration then
		drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed
	end
	WG.keepawake = function()
		lastUserInputTime = os.clock()
	end
	WG.isAway = function()
		return isAway
	end
end

function widget:Shutdown()
	if WG.Chobby and WG.Chobby.Configuration then
		WG.Chobby.Configuration.drawAtFullSpeed = drawAtFullspeed
	end
end

function widget:Update()
	local clock = os.clock()
	local prevIsOffscreen = isOffscreen
	local mouseX, mouseY, lmb, mmb, rmb, mouseOffscreen  = Spring.GetMouseState()
	isOffscreen = mouseOffscreen
	if Spring.GetKeyState(8) then -- backspace pressed
		lastUserInputTime = clock
	end
	if mouseX ~= lastMouseX or mouseY ~= lastMouseY or lmb or mmb or rmb  then
		lastMouseX, lastMouseY = mouseX, mouseY
		lastUserInputTime = clock
	end
	if mouseOffscreen then
		lastUserInputTime = clock - idleTime-1.5
	end

	drawAtFullspeed = WG.Chobby.Configuration.drawAtFullSpeed

	local prevIsAway = isAway
	local prevIsIdle = isIdle
	if clock > 10 then	-- startup graceperiod
		isIdle = (lastUserInputTime < clock - idleTime)
	end
	if isIdle ~= prevIsIdle then
		nextFrameTime = clock-1
	end
	isSleep = (lastUserInputTime < clock - sleepTime)
	isHibernate = (lastUserInputTime < clock - hibernateTime)
	isAway = (lastUserInputTime < clock - awayTime)
	if isAway ~= prevIsAway then
		local lobby = WG.LibLobby.lobby
		if lobby.SetIngameStatus then
			lobby:SetIngameStatus(nil,isAway)
		end
	end
end


function widget:MousePress()	-- doesnt get called
	lastUserInputTime = os.clock()
end

function widget:MouseWheel()
	lastUserInputTime = os.clock()
end

function widget:KeyPress()
	lastUserInputTime = os.clock()
end

function widget:KeyRelease()
	lastUserInputTime = os.clock()
end

function widget:TextInput()
	lastUserInputTime = os.clock()
end

function widget:TextEditing()
	lastUserInputTime = os.clock()
end

function widget:AllowDraw()
	if isIdle then
		if os.clock() > nextFrameTime then
			if isHibernate then
				frameDelayTime = 1/hibernateFps
			elseif isSleep then
				frameDelayTime = 1/sleepFps
			else
				frameDelayTime = math.max(1/idleFps, frameDelayTime + idleFrameTimeDelay)
			end
			nextFrameTime = os.clock()+frameDelayTime
			return true
		end
	elseif os.clock() > nextFrameTime then
		nextFrameTime = os.clock() + (1/(drawAtFullspeed and activeFullspeedFps or activeFps))
		frameDelayTime = 0.025	-- reset
		return true
	end
	return false
end