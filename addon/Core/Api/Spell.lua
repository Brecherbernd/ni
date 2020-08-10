local GetSpellCooldown,
	GetTime,
	GetSpellInfo,
	GetNetStats,
	tonumber,
	UnitIsDeadOrGhost,
	UnitCanAttack,
	IsSpellInRange,
	IsSpellKnown,
	UnitClass,
	GetShapeshiftForm,
	UnitCastingInfo,
	UnitChannelInfo,
	tContains,
	random,
	sin,
	cos,
	sqrt,
	tremove,
	tinsert,
	StrafeLeftStart,
	StrafeLeftStop,
	IsPlayerSpell =
	GetSpellCooldown,
	GetTime,
	GetSpellInfo,
	GetNetStats,
	tonumber,
	UnitIsDeadOrGhost,
	UnitCanAttack,
	IsSpellInRange,
	IsSpellKnown,
	UnitClass,
	GetShapeshiftForm,
	UnitCastingInfo,
	UnitChannelInfo,
	tContains,
	random,
	sin,
	cos,
	sqrt,
	tremove,
	tinsert,
	StrafeLeftStart,
	StrafeLeftStop,
	IsPlayerSpell

local _, class = UnitClass("player")
local casts = { };
local los, newz = ni.functions.los, ni.unit.newz;
local all_units = { };
local function getAllAttackable(distance, radius)
	table.wipe(all_units)
	for k, v in pairs(ni.objects) do
		if type(k) ~= "function" and type(v) == "table" then
			if v:canattack() and not UnitIsDeadOrGhost(k) then
				local dist = v:distance("player");
				if dist ~= nil and dist + radius <= distance then
					table.insert(all_units, v);
				end
			end
		end
	end
end

local function getAllAssistable(distance, radius)
	table.wipe(all_units)
	for k, v in pairs(ni.objects) do
		if type(k) ~= "function" and type(v) == "table" then
			if v:canattack() and not UnitIsDeadOrGhost(k) then
				local dist = v:distance("player");
				if dist ~= nil and dist + radius <= distance then
					table.insert(all_units, v);
				end
			end
		end
	end
end

local function distanceBetween(x1, y1, x2, y2)
	local dx = x1 - x2;
	local dy = y1 - y2;
	return math.sqrt(dx * dx + dy * dy);
end

setmetatable(casts,
	{
		__index = function(t, k)
			rawset(t, k, { at = 0 });
			return t[k];
		end
	})
ni.spell = {
	queue = {},
	id = function(s)
		if s == nil then
			return nil
		end
		local id = ni.functions.getspellid(s)
		return (id ~= 0) and id or nil
	end,
	cd = function(id)
		local start, duration = GetSpellCooldown(id)
		local start2 = GetSpellCooldown(61304)
		if (start > 0 and duration > 0 and start ~= start2) then
			return start + duration - GetTime()
		else
			return 0
		end
	end,
	gcd = function()
		local _, d = GetSpellCooldown(61304)
		return d ~= 0
	end,
	available = function(id, stutter)
		if not stutter then
			if ni.spell.gcd() or ni.vars.combat.casting == true then
				return false
			end
		end

		if tonumber(id) == nil then
			id = ni.spell.id(id)
		end

		local result = false

		if id ~= nil and id ~= 0 and (IsSpellKnown(id) or (ni.vars.build >= 50400 and IsPlayerSpell(id))) then
			local name, _, _, cost, _, powertype = GetSpellInfo(id)

			if ni.stopcastingtracker.shouldstop(id) then
				return false
			end

			if
				name and
					((powertype == -2 and ni.player.hpraw() >= cost) or (powertype >= 0 and ni.player.powerraw(powertype) >= cost)) and
					ni.spell.cd(name) == 0
			 then
				result = true
			end
		end
		return result
	end,
	casttime = function(spell)
		return select(7, GetSpellInfo(spell)) / 1000 + select(3, GetNetStats()) / 1000
	end,
	cast = function(...)
		local i = ...
		if i == nil then
			return
		end
		if #{...} > 1 then
			ni.debug.print(string.format("Casting %s on %s", ...))
		else
			ni.debug.print(string.format("Casting %s", ...))
		end
		ni.functions.cast(...)
	end,
	delaycast = function(spell, target, delay)
		if delay then
			if GetTime() - casts[spell].at < delay then
				return false
			end
		end
		ni.spell.cast(spell, target);
		casts[spell].at = GetTime();
		return true;
	end,
	castspells = function(spells, t)
		local items = ni.utils.splitstring(spells)

		for i = 0, #items do
			local st = items[i]
			if st ~= nil then
				local id = tonumber(st)
				if id ~= nil then
					ni.spell.cast(id, t)
				else
					ni.spell.cast(st, t)
				end
			end
		end
	end,
	castat = function(spell, t, offset)
		if spell then
			if t == "mouse" then
				ni.spell.cast(spell)
				ni.player.clickat("mouse")
			elseif ni.unit.exists(t) then
				local offset = true and offset or random()
				local x, y, z = ni.unit.info(t)
				local r = offset * sqrt(random())
				local theta = random() * 360
				local tx = x + r * cos(theta)
				local ty = y + r * sin(theta)
				ni.spell.cast(spell)
				ni.player.clickat(tx, ty, z)
			end
		end
	end,
	bestaoeloc = function(distance, radius, friendly, minimumcount, inc, zindex_inc)
		return ni.functions.bestaoeloc(distance, radius, friendly, minimumcount, inc, zindex_inc);
	end,
	casthelpfulatbest = function(spell, distance, radius, minimumcount, inc, zindex_inc)
		local x, y, z = ni.spell.bestaoeloc(distance, radius, true, minimumcount, inc, zindex_inc);
		if x and y and z then
			ni.spell.cast(spell);
			ni.player.clickat(x, y, z);
		end
	end,
	castharmfulatbest = function(spell, distance, radius, minimumcount, inc, zindex_inc)
		local x, y, z = ni.spell.bestaoeloc(distance, radius, false, minimumcount, inc, zindex_inc);
		if x and y and z then
			ni.spell.cast(spell);
			ni.player.clickat(x, y, z);
		end
	end,
	castqueue = function(...)
		local id, tar = ...
		if id == nil then
			id = ni.getspellidfromactionbar()
		end
		if id == nil or id == 0 then
			return
		end
		for k, v in pairs(ni.spell.queue) do
			if tContains(v[2], id) then
				ni.frames.spellqueue.update()
				tremove(ni.spell.queue, k)
				return
			end
		end
		tinsert(ni.spell.queue, {ni.spell.cast, {id, tar}})
		ni.frames.spellqueue.update(id, true)
	end,
	castatqueue = function(...)
		local id, tar = ...
		if id == nil then
			id = ni.getspellidfromactionbar()
			tar = "target"
		end
		if id == nil or id == 0 then
			return
		end
		for k, v in pairs(ni.spell.queue) do
			if tContains(v[2], id) then
				ni.frames.spellqueue.update()
				tremove(ni.spell.queue, k)
				return
			end
		end
		if tar ~= nil then
			tinsert(ni.spell.queue, {ni.spell.castat, {id, tar}})
			ni.frames.spellqueue.update(id, true)
		end
	end,
	stopcasting = function()
		ni.functions.stopcasting()
	end,
	stopchanneling = function()
		StrafeLeftStart()
		StrafeLeftStop()
	end,
	valid = function(t, spellid, facing, los, friendly)
		friendly = true and friendly or false
		los = true and los or false
		facing = true and facing or false

		if tonumber(spellid) == nil then
			spellid = ni.spell.id(spellid)
			if spellid == 0 then
				return false
			end
		end

		local unitid = ni.unit.id(t)

		if unitid then
			if (ni.tables.whitelistedlosunits[unitid]) then
				ni.debug.log(tostring(ni.player.isfacing(t)) .. " " .. tostring(ni.player.los(t)))
				return true
			end
		end

		local name, _, _, cost, _, powertype = GetSpellInfo(spellid)

		if
			ni.unit.exists(t) and ((not friendly and (not UnitIsDeadOrGhost(t) and UnitCanAttack("player", t) == 1)) or friendly) and
				IsSpellInRange(name, t) == 1 and
				(IsSpellKnown(spellid) or (ni.vars.build >= 50400 and IsPlayerSpell(spellid))) and
				ni.player.powerraw(powertype) >= cost and
				((facing and ni.player.isfacing(t)) or not facing) and
				((los and ni.player.los(t)) or not los)
		 then
			return true
		end

		return false
	end,
	getinterrupt = function()
		local interruptSpell = 0

		if class == "SHAMAN" then
			interruptSpell = 57994
		elseif class == "WARRIOR" then
			if ni.vars.build >= 40300 then
				interruptSpell = 6552
			else
				if GetShapeshiftForm() == 3 then
					interruptSpell = 6552
				elseif GetShapeshiftForm() == 2 then
					interruptSpell = 72
				end
			end
		elseif class == "PRIEST" then
			interruptSpell = 15487
		elseif class == "DEATHKNIGHT" then
			interruptSpell = 47528
		elseif class == "ROGUE" then
			interruptSpell = 1766
		elseif class == "MAGE" then
			interruptSpell = 2139
		elseif class == "HUNTER" then
			interruptSpell = 34490
		elseif class == "MONK" then
			interruptSpell = 116705
		elseif class == "WARLOCK" and IsSpellKnown(19647, true) then
			interruptSpell = 19647
		end

		return interruptSpell
	end,
	castinterrupt = function(t)
		local interruptSpell = ni.spell.getinterrupt()

		if interruptSpell ~= 0 and ni.spell.cd(interruptSpell) == 0 then
			ni.spell.stopcasting()
			ni.spell.stopchanneling()
			ni.spell.cast(interruptSpell, t)
		end
	end,
	getpercent = function()
		return math.random(40, 60)
	end,
	shouldinterrupt = function(t)
		local InterruptPercent = ni.spell.getpercent()
		local castName, _, _, _, castStartTime, castEndTime, _, _, castinterruptable = UnitCastingInfo(t)
		local channelName, _, _, _, channelStartTime, channelEndTime, _,  channelInterruptable = UnitChannelInfo(t)

		if channelName ~= nil then
			castName = channelName
			castStartTime = channelStartTime
			castEndTime = channelEndTime
			castinterruptable = channelInterruptable
		end

		if castName ~= nil then
			if castinterruptable then
				return false
			end

			if UnitCanAttack("player", t) == nil then
				return false
			end
			local timeSinceStart = (GetTime() * 1000 - castStartTime) / 1000
			local casttime = castEndTime - castStartTime
			local currentpercent = timeSinceStart / casttime * 100000

			if (currentpercent < InterruptPercent) then
				return false
			end

			if ni.vars.interrupt == "wl" then
				if tContains(ni.vars.interrupts.whitelisted, castName) then
					return true
				else
					return false
				end
			else
				if tContains(ni.vars.interrupts.blacklisted, castName) then
					return false
				end
			end
			return true
		end
		return false
	end,
	isinstant = function(spell)
		return select(7, GetSpellInfo(spell)) == 0
	end
}
