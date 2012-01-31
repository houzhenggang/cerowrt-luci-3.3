--[[
LuCI - Lua Configuration Interface

Copyright 2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local sid = arg[1]
local utl = require "luci.util"

m = Map("babeld", translatef("Babeld - RDNSS"),
	translate("Babeld is a router advertisement daemon for IPv6. " ..
		"It listens to router solicitations and sends router advertisements " ..
		"as described in RFC 4861."))

m.redirect = luci.dispatcher.build_url("admin/network/babeld")

if m.uci:get("babeld", sid) ~= "rdnss" then
	luci.http.redirect(m.redirect)
	return
end


s = m:section(NamedSection, sid, "interface", translate("RDNSS Configuration"))
s.addremove = false


--
-- General
--

o = s:option(Flag, "ignore", translate("Enable"))
o.rmempty = false

function o.cfgvalue(...)
	local v = Flag.cfgvalue(...)
	return v == "1" and "0" or "1"
end

function o.write(self, section, value)
	Flag.write(self, section, value == "1" and "0" or "1")
end


o = s:option(Value, "interface", translate("Interface"),
	translate("Specifies the logical interface name this section belongs to"))

o.template = "cbi/network_netlist"
o.nocreate = true
o.optional = false

function o.formvalue(...)
	return Value.formvalue(...) or "-"
end

function o.validate(self, value)
	if value == "-" then
		return nil, translate("Interface required")
	end
	return value
end

function o.write(self, section, value)
	m.uci:set("babeld", section, "ignore", 0)
	m.uci:set("babeld", section, "interface", value)
end


o = s:option(DynamicList, "addr", translate("Addresses"),
	translate("Advertised IPv6 RDNSS. If empty, the current IPv6 address of the interface is used"))

o.optional    = false
o.rmempty     = true
o.datatype    = "ip6addr"
o.placeholder = translate("default")
function o.cfgvalue(self, section)
	local l = { }
	local v = m.uci:get_list("babeld", section, "addr")
	for v in utl.imatch(v) do
		l[#l+1] = v
	end
	return l
end


o = s:option(Value, "AdvRDNSSLifetime", translate("Lifetime"),
	translate("Specifies the maximum duration how long the RDNSS entries are used for name resolution. Use 0 to specify an infinite lifetime"))

o.datatype = "uinteger"
o.placeholder = 1200

function o.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	if v == "infinity" then
		return 0
	else
		return v
	end
end

function o.write(self, section, value)
	if value == "0" then
		Value.write(self, section, "infinity")
	else
		Value.write(self, section, value)
	end
end


return m
