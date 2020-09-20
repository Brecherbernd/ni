local keypress_events = { };
local packet_sent_events = { };
local packet_received_events = { };
ni.events = { };
function ni.events.registerkeyevent(name, callback)
	if not keypress_events[name] then
		keypress_events[name] = callback;
		return true;
	end
	return false;
end;
function ni.events.registerpacketsendevent(name, callback)
	if not packet_sent_events[name] then
		packet_sent_events[name] = callback;
		return true;
	end
	return false;
end;
function ni.events.registerpacketreceivedevent(name, callback)
	if not packet_received_events[name] then
		packet_received_events[name] = callback;
		return true;
	end
	return false;
end;
function ni.events.unregisterkeyevent(name)
	keypress_events[name] = nil;
end;
function ni.events.unregisterpacketsendevent(name)
	packet_sent_events[name] = nil;
end;
function ni.events.unregisterpacketreceivedevent(name)
	packet_received_events[name] = nil;
end;
local function OnKeyHandler(self, keyType, key)
	for k, v in pairs(keypress_events) do
		v(keyType, key);
	end
end;
local function OnPacketSentHandler(self, opcode)
	for k, v in pairs(packet_sent_events) do
		v(opcode);
	end
end;
local function OnPacketReceivedHandler(self, opcode)
	for k, v in pairs(packet_received_events) do
		v(opcode);
	end
end;
ni.functions.registercallback(ni.events, "OnKey", OnKeyHandler);
ni.functions.registercallback(ni.events, "OnPacketSent", OnPacketSentHandler);
ni.functions.registercallback(ni.events, "OnPacketReceived", OnPacketReceivedHandler);