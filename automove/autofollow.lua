--- This requires the Ashita library; So include with another addon ---
--- Not standalone! ---

autoFollow = {
	baseAddress = 0,	-- When intitiated, set starting address 
	running = false,
	delay = 0.10,
	timer = 0
};

---------------------------------------------------------------------------------
-- Include the following to set the baseAddress when loading the addon
--ashita.memory.read_int32(ashita.memory.find("FFXiMain.dll", 0, "F6C4447A42D905????????D81D????????", 7, 0))
---------------------------------------------------------------------------------

----- Auto follow memory items
	-- unknown_ptr = 0,		-- float
    -- TargetIndex = 0,		-- unsigned int
    -- TargetID = 0,		-- unsigned int
    -- DirectionX = 0,		-- float	(F6C4447A42D905????????D81D????????, 7)
    -- DirectionY = 0,		-- float
    -- DirectionZ = 0,		-- float
    -- unknown_float = 0,	-- float; (1) Deals with collision (CXiCollisionActor)
	-- unknown_ptr2 = 0,	-- float	
    -- FollowIndex = 0,		-- unsigned int
    -- FollowID = 0,		-- unsigned int
    -- CameraMode = 0,		-- unsigned char; 0 = third-person - 1 = first-person	(8A5C2408B9????????881D????????E8????????85C0, 7)
    -- AutoRun = 0			-- unsigned char
-----------------------------------------------------

-----------------------------------------------------
--- Direction is -1 to 1 (float) for each direction
--- X: -1 to 1 for South to North
--- Y: Always 0 (Game sets it when auto-following a player or NPC)
--- Z: -1 to 1 for West to East
-----------------------------------------------------

----------------------------------------------------------
-- Returns a table of the current direction values
----------------------------------------------------------
function autoFollow:getDirection()
	local direction = {
		x = ashita.memory.read_float(self.baseAddress),
		y = ashita.memory.read_float(self.baseAddress + 4),
		z = ashita.memory.read_float(self.baseAddress + 8)
	};
	
	return direction;
end;

----------------------------------------------------------
-- Returns a string output of the current direction values
----------------------------------------------------------
function autoFollow:getDirectionString()
	local x = ashita.memory.read_float(self.baseAddress);
	local y = ashita.memory.read_float(self.baseAddress + 4);
	local z = ashita.memory.read_float(self.baseAddress + 8);
	local outDirection = string.format("x: %.3f; y: %.3f; z: %.3f", x, y, z);
	return outDirection;
end;

----------------------------------------------------------
-- Write the direction values
----------------------------------------------------------
function autoFollow:setDirection(x1, z1, x2, z2)
	if (x1 == nil) then	x1 = 0; end;
	if (z1 == nil) then	z1 = 0;	end;
	if (x2 == nil) then	x2 = 0;	end;
	if (z2 == nil) then	z2 = 0;	end;
	local normalized = math.sqrt(math.pow((x1 - x2), 2.0) + math.pow((z1 - z2), 2.0));
	local goToX = (x2 - x1) / normalized;
	local goToZ = (z2 - z1) / normalized;
	
	if (goToX >= -1 and goToX <= 1) then
		ashita.memory.write_float(self.baseAddress, goToX);
	end;
	if (goToZ >= -1 and goToZ <= 1) then		
		ashita.memory.write_float(self.baseAddress + 8, goToZ);
	end;
end;

function autoFollow:runTowards(x1, z1, x2, z2)
	if (x1 == nil) then	x1 = 0; end;
	if (z1 == nil) then	z1 = 0;	end;
	if (x2 == nil) then	x2 = 0;	end;
	if (z2 == nil) then	z2 = 0;	end;
	self:setDirection(x1, z1, x2, z2);
	if (self:getAutoRun() == false) then
		self:setAutoRun(true);
	end;
end;

----------------------------------------------------------
-- Write the camera mode (0 or 1)
----------------------------------------------------------
function autoFollow:setCameraMode(val)
	if (val == 0) then
		ashita.memory.write_int8(self.baseAddress + 28, 0);
	elseif (val == 1) then
		ashita.memory.write_int8(self.baseAddress + 28, 0);
	end;
end;

----------------------------------------------------------
-- Write the autorun (0 or 1); Accepts true or false
----------------------------------------------------------
function autoFollow:setAutoRun(val)
	if (val) then
		ashita.memory.write_int8(self.baseAddress + 29, 1);
	else
		ashita.memory.write_int8(self.baseAddress + 29, 0);
	end;
end;

function autoFollow:getAutoRun()
	local currVal = ashita.memory.read_int8(self.baseAddress + 29);
	if (currVal == 0) then
		return false;
	else
		return true;
	end;
end;