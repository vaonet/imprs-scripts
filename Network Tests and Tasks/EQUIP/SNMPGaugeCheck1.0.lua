--[[
Vaonet Incorporated ("Vaonet") CONFIDENTIAL
Unpublished Copyright (c) 1998-2013 Vaonet Incorporated, All Rights Reserved.

NOTICE:  All information contained herein is, and remains the property of 
Vaonet. The intellectual and technical concepts contained herein are 
proprietary to Vaonet and may be covered by U.S. and Foreign Patents, patents
in process, and are protected by trade secret or copyright law. Dissemination
of this information or reproduction of this material is strictly forbidden 
unless prior written permission is obtained from Vaonet.  Access to the source
code contained herein is hereby forbidden to anyone except current Vaonet 
employees, managers or contractors who have executed Confidentiality and 
Non-disclosure agreements explicitly covering such access.

The copyright notice above does not evidence any actual or intended publication 
or disclosure  of  this source code, which includes information that is 
confidential and/or proprietary, and is a trade secret, of  Vaonet. ANY
REPRODUCTION, MODIFICATION, DISTRIBUTION, PUBLIC  PERFORMANCE, OR PUBLIC 
DISPLAY OF OR THROUGH USE  OF THIS  SOURCE CODE  WITHOUT  THE EXPRESS WRITTEN
CONSENT OF VAONET IS STRICTLY PROHIBITED, AND IN VIOLATION OF APPLICABLE LAWS 
AND INTERNATIONAL TREATIES.  THE RECEIPT OR POSSESSION OF  THIS SOURCE CODE 
AND/OR RELATED INFORMATION DOES NOT CONVEY OR IMPLY ANY RIGHTS TO REPRODUCE, 
DISCLOSE OR DISTRIBUTE ITS CONTENTS, OR TO MANUFACTURE, USE, OR SELL ANYTHING 
THAT IT  MAY DESCRIBE, IN WHOLE OR IN PART.                

--]]


require("xml")
require("evt")
require("snmp")
require("util")
require("rrd")
require("map")
local reflect = require("reflect")

local xml_if  = xml:new()
local map_if  = map:new()
local snmp_if = snmp:new()
local util_if = util:new()
local evt_if  = evt:new()
local rrd_if  = rrd:new()

local g_typeTable = {
    ["BITS"]           = snmp.SYNTAX_BITS,
    ["COUNTER32"]      = snmp.SYNTAX_CNTR32,
    ["COUNTER64"]      = snmp.SYNTAX_CNTR64,
    ["INT/INT32"]      = snmp.SYNTAX_INT,
    ["IPADDR"] 		   = snmp.SYNTAX_IPADDR,
    ["OCTETS"] 		   = snmp.SYNTAX_OCTETS,
    ["OID"] 		   = snmp.SYNTAX_OID,
    ["OPAQUE"]         = snmp.SYNTAX_OPAQUE,
    ["STRING"] 		   = snmp.SYNTAX_OCTETS+128,
    ["TIMETICKS"]      = snmp.SYNTAX_TIMETICKS,
    ["UINT32/GAUGE32"] = snmp.SYNTAX_UINT32,
    [snmp.SYNTAX_BITS]      	= "BITS",
    [snmp.SYNTAX_CNTR32]    	= "COUNTER32",
    [snmp.SYNTAX_CNTR64]    	= "COUNTER64",
    [snmp.SYNTAX_INT]       	= "INT/INT32",
    [snmp.SYNTAX_IPADDR]    	= "IPADDR",
    [snmp.SYNTAX_OCTETS]    	= "OCTETS",
    [snmp.SYNTAX_OID]       	= "OID",
    [snmp.SYNTAX_OPAQUE]    	= "OPAQUE",
    [snmp.SYNTAX_OCTETS+128]	= "STRING",
    [snmp.SYNTAX_TIMETICKS] 	= "TIMETICKS",
    [snmp.SYNTAX_UINT32]    	= "UINT32/GAUGE32"
}

local g_castTable = {
    											   -- Convert to a native Lua string, then to native Lua number (an unsigned 32bit integer will 
                                                   -- fit nicely in a native Lua number (which is a double)), then to an actual unsigned 
    											   -- 32bit integer
    [snmp.SYNTAX_UINT32]    	= function(vb) return ffi.cast("uint32_t",tonumber(vb.val.uintV)) end,

    											   -- Convert to a native Lua string, then to native Lua number (a signed 32bit integer will 
                                                   -- fit nicely in a native Lua number (which is a double)), then to an actual signed 
    											   -- 32bit integer
    [snmp.SYNTAX_INT]       	= function(vb) return ffi.cast("int32_t",tonumber(vb.val.intV)) end
}

local g_printTable = {
    [snmp.SYNTAX_UINT32]    	= function(vb) return tostring(vb.val.uintV) end,
    [snmp.SYNTAX_INT]       	= function(vb) return tostring(vb.val.intV) end
}

local g_opAlmString = {
    ["EQUAL"]						= " IS EQUAL TO ",
    ["NOT EQUAL"]					= " IS NOT EQUAL TO ",
    ["LESS THAN"]					= " IS LESS THAN ",
    ["LESS THAN OR EQUAL TO"]		= " IS LESS THAN OR EQUAL TO ",
    ["GREATER THAN"] 				= " IS GREATER THAN ",
    ["GREATER THAN OR EQUAL TO"]	= " IS GREATER THAN OR EQUAL TO ",
    ["BETWEEN"]						= " IS BETWEEN ",
    ["NOT BETWEEN"]					= " IS NOT BETWEEN "
}

-- It is assumed that rcvVal has been ffi.cast to the appropriate type based on the received value's type
--  and the upper and lower values are still in string format as they were when passed in as arguments to the script.
local g_compTable = {
    ["EQUAL"]						= {
        [snmp.SYNTAX_INT]       = function(rcvVal,lowVal,uppVal) return rcvVal == ffi.cast("int32_t",tonumber(lowVal)) end,
        [snmp.SYNTAX_UINT32]    = function(rcvVal,lowVal,uppVal) return rcvVal == ffi.cast("uint32_t",tonumber(lowVal)) end
    },
    ["NOT EQUAL"]					= {
        [snmp.SYNTAX_INT]       = function(rcvVal,lowVal,uppVal) return rcvVal ~= ffi.cast("int32_t",tonumber(lowVal)) end,
        [snmp.SYNTAX_UINT32]    = function(rcvVal,lowVal,uppVal) return rcvVal ~= ffi.cast("uint32_t",tonumber(lowVal)) end
    },
    ["LESS THAN"]					= {
        [snmp.SYNTAX_INT]       = function(rcvVal,lowVal,uppVal) return rcvVal < ffi.cast("int32_t",tonumber(lowVal)) end,
        [snmp.SYNTAX_UINT32]    = function(rcvVal,lowVal,uppVal) return rcvVal < ffi.cast("uint32_t",tonumber(lowVal)) end
    },
    ["LESS THAN OR EQUAL TO"]		= {
        [snmp.SYNTAX_INT]       = function(rcvVal,lowVal,uppVal) return rcvVal <= ffi.cast("int32_t",tonumber(lowVal)) end,
        [snmp.SYNTAX_UINT32]    = function(rcvVal,lowVal,uppVal) return rcvVal <= ffi.cast("uint32_t",tonumber(lowVal)) end
    },
    ["GREATER THAN"] 				= {
        [snmp.SYNTAX_INT]       = function(rcvVal,lowVal,uppVal) return rcvVal > ffi.cast("int32_t",tonumber(lowVal)) end,
        [snmp.SYNTAX_UINT32]    = function(rcvVal,lowVal,uppVal) return rcvVal > ffi.cast("uint32_t",tonumber(lowVal)) end
    },
    ["GREATER THAN OR EQUAL TO"]	= {
        [snmp.SYNTAX_INT]       = function(rcvVal,lowVal,uppVal) return rcvVal >= ffi.cast("int32_t",tonumber(lowVal)) end,
        [snmp.SYNTAX_UINT32]    = function(rcvVal,lowVal,uppVal) return rcvVal >= ffi.cast("uint32_t",tonumber(lowVal)) end
    },
    ["BETWEEN"]						= {
        [snmp.SYNTAX_INT]       = function(rcvVal,lowVal,uppVal) return rcvVal >= ffi.cast("int32_t",tonumber(lowVal)) and rcvVal <= ffi.cast("int32_t",tonumber(uppVal)) end,
        [snmp.SYNTAX_UINT32]    = function(rcvVal,lowVal,uppVal) return rcvVal >= ffi.cast("uint32_t",tonumber(lowVal)) and rcvVal <= ffi.cast("uint32_t",tonumber(uppVal)) end
    },
    ["NOT BETWEEN"]					= {
        [snmp.SYNTAX_INT]       = function(rcvVal,lowVal,uppVal) return rcvVal < ffi.cast("int32_t",tonumber(lowVal)) or rcvVal > ffi.cast("int32_t",tonumber(uppVal)) end,
        [snmp.SYNTAX_UINT32]    = function(rcvVal,lowVal,uppVal) return rcvVal < ffi.cast("uint32_t",tonumber(lowVal)) or rcvVal > ffi.cast("uint32_t",tonumber(uppVal)) end
    }
}

 -- GET THE DATA NEEDED FROM THE CONTEXT AND THE PASSED IN ARGUMENTS
xml_if:SetCurrent(xml.CONTEXT_DATA,nil)
local g_readCommunity = xml_if:FindGetData("/data/equipment/readComm")
local g_verbose       = string.upper(xml_if:FindGetData("/data/equipment/verboseLogging")) == "TRUE"
local g_ipAddress     = xml_if:FindGetData("/data/target/ipAddress")
local g_eventName     = argv[0]
local g_severity      = argv[1]
local g_delay         = tonumber(argv[2])
local g_snmpVersion
if argv[3] == "v2c" then
	g_snmpVersion = snmp.VERSION_2C
else
    g_snmpVersion = snmp.VERSION_1
end
local g_port              = tonumber(argv[4])
local g_retries           = tonumber(argv[5])
local g_timeout           = tonumber(argv[6]) * 1000 / 10 -- convert to 10ms increments
local g_oid				  = argv[7]
local g_operator          = argv[8]
local g_lowerValue        = argv[9]
local g_upperValue        = argv[10] or ""
local g_label             = argv[11] or ""

local g_mapKeyPrefix = g_ipAddress..g_oid..g_operator..g_lowerValue..g_upperValue

local g_rcvdValue = {sysUpTime,valueType,rawValue,castValue,printValue}

if g_verbose == true then
	io.write("ALARM DEFINITION: "..g_eventName,"SEVERITY: "..g_severity,"DELAY: "..g_delay,"TARGET: "..g_ipAddress,
             "COMMUNITY: "..g_readCommunity,"SNMP VER: "..g_snmpVersion,"SNMP PORT: "..g_port,"GET RETRIES: "..g_retries,
             "GET TIMEOUT: "..g_timeout,"OID: "..g_oid,"OPERATOR: "..g_operator,"LOWER VALUE: "..g_lowerValue,"UPPER VALUE: "..g_upperValue)
end

function DumpSnmpError(snmp_if,location)
    io.write("SNMP ERROR: ("..snmp_if:GetError()..") "..location.." - "..snmp_if:GetErrorMsg())
end

function DumpError(location,errorMsg)
    io.write("ERROR: "..location.." - "..errorMsg)
end

function GetSNMPValue()
    local vblen,vbarr
    snmp_if:MakeGet(g_ipAddress,g_snmpVersion,g_readCommunity,g_port,g_retries,g_timeout)
    if snmp_if:GetError() ~= 0 then 
        DumpSnmpError(snmp_if,"GetSNMPValue("..g_ipAddress..")/MakeGet")
        return false
    end
    snmp_if:AddVBEmpty(g_oid)
    snmp_if:AddVBEmpty("1.3.6.1.2.1.1.3.0") -- sysUpTime
    local vblen, vbarr = snmp:DoGet()
    if snmp_if:GetError() ~= 0 then 
        DumpSnmpError(snmp_if,"GetSNMPValue("..g_ipAddress..")/"..g_oid)
        return false
    end
    if vbarr[0].type == 0 then
        DumpError("GetSNMPValue("..g_ipAddress..")/"..g_oid,"RECEIVED VALUE TYPE: "..vbarr[0].type.." - IT IS LIKELY THAT THIS EQUIPMENT DOES NOT IMPLEMENT THE REQUESTED OID")
        return false
    end
	if vbarr[0].type ~= snmp.SYNTAX_INT and vbarr[0].type ~= snmp.SYNTAX_UINT32 then
        DumpError("GetSNMPValue("..g_ipAddress..")/"..g_oid,"RECEIVED VALUE TYPE: "..vbarr[0].type.." ("..g_typeTable[vbarr[0].type]..") DOES NOT MATCH EXPECTED VALUE TYPE: INT/INT32 or UINT32/GAUGE32")
        return false
    end
	if g_verbose == true then
    end

    g_rcvdValue.sysUpTime  = vbarr[1].val.uintV / 100ULL
	if vbarr[0].type == snmp.SYNTAX_INT then
        g_rcvdValue.rawValue   = vbarr[0].val.intV
    else
        g_rcvdValue.rawValue   = vbarr[0].val.uintV
    end
    g_rcvdValue.castValue  = g_castTable[vbarr[0].type](vbarr[0])
    g_rcvdValue.valueType  = vbarr[0].type
    g_rcvdValue.printValue = g_printTable[vbarr[0].type](vbarr[0])
    
    return true
end 

function GenerateAlarm()
    local value, extendedInfo, equipName, layerTags, location
    
    if g_label == "" then
    	value = g_rcvdValue.printValue
    else
        value = g_label.." ("..g_rcvdValue.printValue..") "
    end

	xml_if:SetCurrent(xml.CONTEXT_CFG,nil)
    local summary = xml_if:FindGetData("/data/test/name").." - "
	if g_operator == "BETWEEN" or g_operator == "NOT BETWEEN" then
        summary = summary..value..g_opAlmString[g_operator]..g_lowerValue.." AND "..g_upperValue
    else
        summary = summary..value..g_opAlmString[g_operator]..g_lowerValue
    end

    extendedInfo =
          "ADDRESS:     "..g_ipAddress.."<br/>"..
          "OID:         "..g_oid.."<br/>"..
          "OPERATOR:    "..g_operator.."<br/>"..
          "LOWER VALUE: "..g_lowerValue.."<br/>"..
          "UPPER VALUE: "..g_upperValue.."<br/>"..
          "RECVD VALUE: ("..g_typeTable[g_rcvdValue.valueType]..") "..g_rcvdValue.printValue
          
    xml_if:SetCurrent(xml.CONTEXT_DATA,nil)
    layerTags = xml_if:FindGetData("/data/equipment/layerTags")
    location  = xml_if:FindGetData("/data/equipment/location")
    equipName = xml_if:FindGetData("/data/equipment/name")
          
    if g_verbose == true then
		io.write("FIRE ALARM "..g_eventName.. " FOR "..equipName)
    end
    
    evt_if:Fire(
        equipName,
        g_eventName,
        g_severity,
        summary,
        extendedInfo,
        g_delay*60,
        g_mapKeyPrefix,
        g_rcvdValue.printValue,
        "",
        "",
        location,
        layerTags
    )
    return
end

function TransitionAlarm()
    xml_if:SetCurrent(xml.CONTEXT_DATA,nil)
    local equipName = xml_if:FindGetData("/data/equipment/name")
    if g_verbose == true then
		io.write("CLEAR ALARM "..g_eventName.. " FOR "..equipName)
    end
    evt_if:Trans(
        equipName,
        g_mapKeyPrefix,
        evt.aCLR
    )
    return
end

function ProcessAlarm(result)
    if result == true then
        GenerateAlarm()
    else
        TransitionAlarm()
    end
end

function SaveSample()
    map_if:Set(g_mapKeyPrefix.."sysUpTime",tostring(g_rcvdValue.sysUpTime))
    map_if:Set(g_mapKeyPrefix.."rcvdValue",tostring(g_rcvdValue.rawValue))
    rrd_if:Update("rcvdValue","N:"..tostring(g_rcvdValue.rawValue))
end

if string.len(g_lowerValue) == 0 then
    DumpError("Main("..g_ipAddress..")/"..g_oid,g_operator.." OPERATOR REQUIRES LOWER VALUE");
    return
end
if (g_operator == "BETWEEN" or g_operator == "NOT BETWEEN") and string.len(g_upperValue) == 0 then
    DumpError("Main("..g_ipAddress..")/"..g_oid,g_operator.." OPERATOR REQUIRES UPPER VALUE");
    return
end

local rc = GetSNMPValue()
if rc == false then 
	io.write("FAILED TO GET SNMP VALUE - ABORTING")
    return 
end

if g_verbose == true then
    io.write("RAW VALUE:      "..g_rcvdValue.rawValue)
    io.write("CAST VALUE:     "..tostring(g_rcvdValue.castValue))
    io.write("RECEIVED TYPE:  "..g_rcvdValue.valueType.." ("..g_typeTable[g_rcvdValue.valueType]..")")
    io.write("RECEIVED VALUE: "..g_rcvdValue.printValue)
end

SaveSample()

rc = g_compTable[g_operator][g_rcvdValue.valueType](g_rcvdValue.castValue,g_lowerValue,g_upperValue)
if g_verbose == true then
	io.write("COMPARISON: "..string.format("%s", tostring(rc)))
end
ProcessAlarm(rc)
