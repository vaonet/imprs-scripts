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


local xml_if  = xml:new()
local map_if  = map:new()
local snmp_if = snmp:new()
local util_if = util:new()
local evt_if  = evt:new()
local rrd_if  = rrd:new()

 -- GET THE DATA NEEDED FROM THE CONTEXT AND THE PASSED IN ARGUMENTS
xml_if:SetCurrent(xml.CONTEXT_DATA,nil)
local g_readCommunity = xml_if:FindGetData("/data/equipment/readComm")
local g_verbose       = string.upper(xml_if:FindGetData("/data/equipment/verboseLogging")) == "TRUE"
local g_ifIndex       = tonumber(xml_if:FindGetData("/data/target/ifIndex"))
local g_ipAddress     = xml_if:FindGetData("/data/target/ipAddress")
local g_eventName     = argv[0]
local g_severity      = argv[1]
local g_delay         = tonumber(argv[2])
local g_snmpVersion
if argv[3] == "v2c" then
	g_snmpVersion = snmp.VERSION_2C
elseif argv[3] == "v3" then
	g_snmpVersion = snmp.VERSION_3
else
    g_snmpVersion = snmp.VERSION_1
end
local g_port				= tonumber(argv[4])
local g_retries				= tonumber(argv[5])
local g_timeout				= tonumber(argv[6]) * 1000 / 10 -- convert to 10ms increments
local g_linkSpeed			= util_if:StrToUI64(argv[7])
local g_calculation			= argv[8]
local g_inUpperThreshold	= argv[9]
local g_inUpperSamples		= tonumber(argv[10])
local g_inLowerThreshold	= argv[11]
local g_inLowerSamples		= tonumber(argv[12])
local g_outUpperThreshold	= argv[13]
local g_outUpperSamples		= tonumber(argv[14])
local g_outLowerThreshold	= argv[15]
local g_outLowerSamples		= tonumber(argv[16])

local g_iut	= g_inUpperThreshold
local g_ilt = g_inLowerThreshold
local g_out = g_outUpperThreshold
local g_olt = g_outLowerThreshold

local g_percentage		= ""
local g_percentIn		= ""
local g_percentOut		= ""
local g_linkMaxSpeed	= ""
local g_mapKeyPrefix	= g_ipAddress .. g_ifIndex

if g_verbose == true then
	io.write("ALARM DEFINITION: "..g_eventName,"SEVERITY: "..g_severity,"DELAY: "..g_delay,"TARGET: "..g_ipAddress,"IFACE: "..g_ifIndex,
             "COMMUNITY: "..g_readCommunity,"SNMP VER: "..g_snmpVersion,"SNMP PORT: "..g_port,"GET RETRIES: "..g_retries,
             "GET TIMEOUT: "..g_timeout,"LINK SPEED: "..util_if:UI64ToStr(g_linkSpeed),"CALCULATION: "..g_calculation,"IN UP THRSH: "..g_inUpperThreshold,"IN UP SAMP: "..g_inUpperSamples,"IN LW THRSH: "..g_inLowerThreshold,
             "IN LW SAMP: "..g_inLowerSamples,"OUT UP THRSH: "..g_outUpperThreshold,"IN UP SAMP: "..g_outUpperSamples,"OUT LW THRSH: "..g_outLowerThreshold,
             "OUT LW SAMP: "..g_outLowerSamples)
end

function DumpSnmpError(snmp_if,location)
    io.write("SNMP ERROR: ("..snmp_if:GetError()..") "..location.." - "..snmp_if:GetErrorMsg())
end

function DumpError(location,errorMsg)
    io.write("ERROR: "..location.." - "..errorMsg)
end

function Get32BitCounters(bwv)
    snmp_if:ClearVBs()
    if g_verbose == true then
        io.write("Get low speed counters")
    end
    snmp_if:AddVBEmpty("1.3.6.1.2.1.1.3.0") -- sysUpTime
    snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.10."..g_ifIndex) -- ifInOctets
    snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.16."..g_ifIndex) -- ifOutOctets
    local vblen, vbarr = snmp_if:DoGet()
    if snmp_if:GetError() ~= 0 then 
        DumpSnmpError(snmp_if,"GetBandwidthVars("..g_ipAddress..")/ifInOctets")
        return false 
    end
    bwv.sysUpTime   = vbarr[0].val.uintV / 100ULL
    bwv.ifInOctets  = vbarr[1].val.uintV * 1ULL
    bwv.ifOutOctets = vbarr[2].val.uintV * 1ULL

    return true
end

function Get64BitCounters(bwv)
	if map_if:Exists(g_mapKeyPrefix.."force32BitCounters") == true then 
        return Get32BitCounters(bwv)
    end
    snmp_if:ClearVBs()
    if g_verbose == true then
        io.write("Get high speed counters")
    end
    snmp_if:AddVBEmpty("1.3.6.1.2.1.1.3.0") -- sysUpTime
    snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.6."..g_ifIndex) -- ifHCInOctets
    snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.10."..g_ifIndex) -- ifHCOutOctets
    vblen, vbarr = snmp_if:DoGet()
    if snmp_if:GetError() ~= 0 then 
        if snmp_if:GetError() == 2 then
            if bwv.linkMaxSpeed <= 10000000000ULL then
                if g_verbose == true then
                    io.write("High speed counters do not exist, but link speed is <= 10Gb/s - get 32Bit counters")
                end
                map_if:Set(g_mapKeyPrefix.."force32BitCounters","yes")
                if Get32BitCounters(bwv) == false then 
                    return false 
                end
            else
                DumpError("GetBandwidthVars("..g_ipAddress..")","LINK SPEED TOO HIGH FOR 32BIT COUNTERS")
            end
        else
            DumpSnmpError(snmp_if,"GetBandwidthVars("..g_ipAddress..")/ifHCInOctets")
            return false 
        end
    else
        bwv.sysUpTime   = vbarr[0].val.uintV / 100ULL
        bwv.ifInOctets  = vbarr[1].val.cntr64
        bwv.ifOutOctets = vbarr[2].val.cntr64
    end

    return true
end

function GetPacketStats(bwv)
    snmp_if:ClearVBs()
    if g_verbose == true then
        io.write("Get packet statistics")
    end
::_32BitPacketStats::
    if bwv.linkMaxSpeed <= 650000000ULL or map_if:Exists(g_mapKeyPrefix.."force32BitPacketStats") == true then
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.11."..g_ifIndex) -- ifInUcastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.12."..g_ifIndex) -- ifInNUcastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.13."..g_ifIndex) -- ifInDiscards
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.12."..g_ifIndex) -- ifInErrors
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.15."..g_ifIndex) -- ifInUnknownProtos
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.17."..g_ifIndex) -- ifOutUcastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.18."..g_ifIndex) -- ifOutNUcastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.19."..g_ifIndex) -- ifOutDiscards
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.20."..g_ifIndex) -- ifOutErrors
        vblen, vbarr = snmp_if:DoGet()
        if snmp_if:GetError() ~= 0 then 
            DumpSnmpError(snmp_if,"GetPacketStats("..g_ipAddress..")/32BitCounters")
            return false 
        else
            bwv.inUcastPkts     = vbarr[0].val.uintV * 1ULL
            bwv.inNUcastPkts    = vbarr[1].val.uintV * 1ULL
            bwv.inDiscards      = vbarr[2].val.uintV * 1ULL
            bwv.inErrors        = vbarr[3].val.uintV * 1ULL
            bwv.inUnknownProtos = vbarr[4].val.uintV * 1ULL
            bwv.outUcastPkts    = vbarr[5].val.uintV * 1ULL
            bwv.outNUcastPkts   = vbarr[6].val.uintV * 1ULL
            bwv.outDiscards     = vbarr[7].val.uintV * 1ULL
            bwv.outErrors       = vbarr[8].val.uintV * 1ULL
        end
    else
        snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.7."..g_ifIndex) -- ifHCInUcastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.8."..g_ifIndex) -- ifHCInMulticastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.9."..g_ifIndex) -- ifHCInBroadcastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.13."..g_ifIndex) -- ifInDiscards
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.12."..g_ifIndex) -- ifInErrors
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.15."..g_ifIndex) -- ifInUnknownProtos
        snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.11."..g_ifIndex) -- ifHCOutUcastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.12."..g_ifIndex) -- ifHCOutMulticastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.13."..g_ifIndex) -- ifHCOutBroadcastPkts
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.19."..g_ifIndex) -- ifOutDiscards
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.20."..g_ifIndex) -- ifOutErrors
        vblen, vbarr = snmp_if:DoGet()
        if snmp_if:GetError() ~= 0 then 
            if snmp_if:GetError() == 2 then
                if bwv.linkMaxSpeed <= 10000000000ULL then
                    if g_verbose == true then
                        io.write("High speed packet counters do not exist, but link speed is <= 10Gb/s - get 32Bit packet counters")
                    end
                    map_if:Set(g_mapKeyPrefix.."force32BitPacketStats","yes")
                    snmp_if:ClearVBs()
                    goto _32BitPacketStats
                else
                    DumpError("GetPacketStats("..g_ipAddress..")","LINK SPEED TOO HIGH FOR 32BIT PACKET COUNTERS")
                end
            else
                DumpSnmpError(snmp_if,"GetPacketStats("..g_ipAddress..")")
                return false 
            end
        else
            bwv.inUcastPkts     = vbarr[0].val.cntr64
            bwv.inNUcastPkts    = vbarr[1].val.cntr64 + vbarr[2].val.cntr64
            bwv.inDiscards      = vbarr[3].val.uintV * 1ULL
            bwv.inErrors        = vbarr[4].val.uintV * 1ULL
            bwv.inUnknownProtos = vbarr[5].val.uintV * 1ULL
            bwv.outUcastPkts    = vbarr[6].val.cntr64
            bwv.outNUcastPkts   = vbarr[7].val.cntr64 + vbarr[8].val.cntr64
            bwv.outDiscards     = vbarr[9].val.uintV * 1ULL
            bwv.outErrors       = vbarr[10].val.uintV * 1ULL
        end
    end

    return true
end

function GetBandwidthVars()

    local vblen,vbarr
    local bwv = {sysUpTime,linkMaxSpeed,ifInOctets,ifOutOctets,inUcastPkts,inNUcastPkts,inDiscards,inErrors,inUnknownProtos,outUcastPkts,outNUcastPkts,outDiscards,outErrors,range}

    snmp_if:MakeGet(g_ipAddress,g_snmpVersion,g_readCommunity,g_port,g_retries,g_timeout)
    if snmp_if:GetError() ~= 0 then 
        DumpSnmpError(snmp_if,"GetBandwidthVars("..g_ipAddress..")/MakeGet")
        return false 
    end

	if map_if:Exists(g_mapKeyPrefix.."ifSpeed") then 
		bwv.linkMaxSpeed = util_if:StrToUI64(map_if:Get(g_mapKeyPrefix.."ifSpeed"))
	else
        if g_linkSpeed > 0 then
            bwv.linkMaxSpeed = g_linkSpeed
        else
            snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.5."..g_ifIndex)
            if g_verbose == true then
                io.write("Get ifSpeed")
            end
            local vblen, vbarr = snmp:DoGet()
            if snmp_if:GetError() ~= 0 then 
                DumpSnmpError(snmp_if,"GetBandwidthVars("..g_ipAddress..")/ifSpeed")
                return false 
            end
            if vbarr[0].val.uintV == 0xFFFFFFFF then
                snmp_if:ClearVBs()
                snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.15."..g_ifIndex)
                if g_verbose == true then
                    io.write("ifSpeed is -1, get ifHighSpeed")
                end
                vblen, vbarr = snmp_if:DoGet()
                if snmp_if:GetError() ~= 0 then 
                    DumpSnmpError(snmp_if,"GetBandwidthVars("..g_ipAddress..")/ifHighSpeed")
                    return false 
                end
                bwv.linkMaxSpeed = vbarr[0].val.uintV * 1000000ULL
            else
                bwv.linkMaxSpeed = vbarr[0].val.uintV * 1ULL
            end
            map_if:Set(g_mapKeyPrefix.."ifSpeed",util_if:UI64ToStr(bwv.linkMaxSpeed))
            io.write("ifSpeed is "..util_if:UI64ToStr(bwv.linkMaxSpeed))
        end
	end

    if bwv.linkMaxSpeed <= 20000000ULL then
    	if g_verbose == true then
        	io.write("Link speed is <= 20Mb/s")
        end
        if Get32BitCounters(bwv) == false then 
            return false 
        end
        bwv.range = 0xFFFFFFFF
    else
        if Get64BitCounters(bwv) == false then
            return false
        end
        if map_if:Exists(g_mapKeyPrefix.."force32BitCounters") == true then 
            bwv.range = 0xFFFFFFFFULL
        else
            bwv.range = 0xFFFFFFFFFFFFFFFFULL
        end
    end

    --GetPacketStats(bwv)

    return bwv
end

function ConvertThreshold(threshold,speed)
    if g_calculation == "true" then    
        -- convert everything to native number (double) to perform calculation
        threshold = tonumber(threshold) / 100.0 * tonumber(speed)
        -- convert (back) to unsigned 64 bit integer
        threshold = math.floor(threshold) * 1ULL
    else
        threshold = util_if:StrToUI64(threshold)
    end
    return threshold
end

function GetIfInfo()
    local staleCacheMark = 3600
    if map_if:Exists(g_mapKeyPrefix.."ifInfoCacheTime") ~= true then 
        map_if:Set(g_mapKeyPrefix.."ifInfoCacheTime",tostring(os.time()-staleCacheMark))
    end
    if (os.time() - tonumber(map_if:Get(g_mapKeyPrefix.."ifInfoCacheTime"))) >= staleCacheMark then
        snmp_if:MakeGet(g_ipAddress,g_snmpVersion,g_readCommunity,g_port,g_retries,g_timeout)
        if snmp_if:GetError() ~= 0 then 
            DumpSnmpError(snmp_if,"GetIfInfo("..g_ipAddress..":"..g_ifIndex..")/MakeGet")
            map_if:Remove(g_mapKeyPrefix.."ifInfoCacheTime")
            return false 
        end
        snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.1."..g_ifIndex) -- ifName
        snmp_if:AddVBEmpty("1.3.6.1.2.1.31.1.1.1.18."..g_ifIndex) -- ifAlias
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.2."..g_ifIndex) -- ifDescr
        snmp_if:AddVBEmpty("1.3.6.1.2.1.2.2.1.3."..g_ifIndex) -- ifType
        snmp_if:AddVBEmpty(".1.3.6.1.2.1.2.2.1.6."..g_ifIndex) -- ifPhysAddress
        local vblen, vbarr = snmp_if:DoGet()
        if snmp_if:GetError() ~= 0 then 
            DumpSnmpError(snmp_if,"GetIfInfo("..g_ipAddress..":"..g_ifIndex..")/DoGet")
            map_if:Remove(g_mapKeyPrefix.."ifInfoCacheTime")
            return false 
        end
        map_if:Set(g_mapKeyPrefix.."ifName",       util_if:ToString(vbarr[0].val.octets))
        map_if:Set(g_mapKeyPrefix.."ifAlias",      util_if:ToString(vbarr[1].val.octets))
        map_if:Set(g_mapKeyPrefix.."ifDescr",      util_if:ToString(vbarr[2].val.octets))
        map_if:Set(g_mapKeyPrefix.."ifType",       snmp_if:IANAifTypeStr(vbarr[3].val.intV))
        map_if:Set(g_mapKeyPrefix.."ifPhysAddress",snmp_if:AsHexString(4,":"))
        map_if:Set(g_mapKeyPrefix.."ifInfoCacheTime",tostring(os.time()))
    end
    return true
end

function GenerateAlarm(keyPrefix)
    if g_eventName == "NONE" then
        return
	end
    xml_if:SetCurrent(xml.CONTEXT_CFG,nil)
    xml_if:SetCurrent(xml.CONTEXT_DATA,nil)
    local extendedInfo = ""
    local summary = ""
    if GetIfInfo() == true then
        summary = keyPrefix.." threshold exceed. "..map_if:Get(g_mapKeyPrefix.."ifName").." ("..g_ipAddress..":"..g_ifIndex..")"
        extendedInfo = 
    		"ADDRESS: "     ..g_ipAddress.."<br/>"..
            "IFACE: "       ..g_ifIndex.."<br/>"..
            "NAME: "        ..map_if:Get(g_mapKeyPrefix.."ifName").."<br/>"..
            "ALIAS: "       ..map_if:Get(g_mapKeyPrefix.."ifAlias").."<br/>"..
            "DESCR: "       ..map_if:Get(g_mapKeyPrefix.."ifDescr").."<br/>"..
            "TYPE: "        ..map_if:Get(g_mapKeyPrefix.."ifType").."<br/>"..
            "MAC: "         ..map_if:Get(g_mapKeyPrefix.."ifPhysAddress")
    else
        summary = keyPrefix.." threshold exceed. ("..g_ipAddress..":"..g_ifIndex..")"
        extendedInfo = 
            "IP ADDRESS:"  ..g_ipAddress.."<br/>"..
            "INTERFACE:"   ..g_ifIndex
    end

    -- provide additional alarm summary details
    if string.find(keyPrefix,"INCOMING") then
		if string.find(keyPrefix,"LOWER") then
        	g_percentage = g_percentIn.."<br/>Lower Incoming Threshold: "..g_ilt
        elseif string.find(keyPrefix,"UPPER") then
            g_percentage = g_percentIn.."<br/>Upper Incoming Threshold: "..g_iut
        end
	elseif string.find(keyPrefix,"OUTGOING") then
		if string.find(keyPrefix,"LOWER") then
        	g_percentage = g_percentOut.."<br/>Lower Outgoing Threshold: "..g_olt
        elseif string.find(keyPrefix,"UPPER") then
            g_percentage = g_percentOut.."<br/>Upper Outgoing Threshold: "..g_out
        end
	end
    evt_if:Fire(
       	xml_if:FindGetData("/data/equipment/name"),
       	g_eventName,
       	g_severity,
       	summary.."<br/>"..g_percentage.."<br/>".."Max Link Speed: "..g_linkMaxSpeed,
       	extendedInfo.."<br/>"..g_percentage,
       	g_delay*60,
       	keyPrefix..g_ipAddress..tostring(g_ifIndex),
       	map_if:Get(g_mapKeyPrefix.."ifName"),
       	map_if:Get(g_mapKeyPrefix.."ifAlias"),
       	map_if:Get(g_mapKeyPrefix.."ifPhysAddress"),
       	xml_if:FindGetData("/data/equipment/location"),
       	xml_if:FindGetData("/data/equipment/layerTags")
   	)
	g_percentage = "" -- init
    return
end

function TransitionAlarm(keyPrefix)
    if g_eventName == "NONE" then
        return
	end
    xml_if:SetCurrent(xml.CONTEXT_DATA,nil)
    evt_if:Trans(
        "", -- altUid
        xml_if:FindGetData("/data/equipment/name"),
        keyPrefix..g_ipAddress..tostring(g_ifIndex),
        evt.aCLR
    )
end

function ProcessAlarm(dir,isUpper,bitRate,threshold,samplesNeeded)
    local keyPrefix = ""
    if isUpper == true then
        keyPrefix = "UPPER "..dir
    else
        keyPrefix = "LOWER "..dir
    end
    if (isUpper == true and bitRate > threshold) or (isUpper == false and bitRate < threshold) then
		print("processAlarm~bitRate|threshold|"..tostring(bitRate).."|"..tostring(threshold))
        -- we are in breach
        local curSample = 1
        if map_if:Exists(g_mapKeyPrefix..keyPrefix.."CurSample") then 
            curSample = tonumber(map_if:Get(g_mapKeyPrefix..keyPrefix.."CurSample"))+1
        end
        if curSample == samplesNeeded then
            -- we have entered the alarm state
            GenerateAlarm(keyPrefix)
            map_if:Set(g_mapKeyPrefix..keyPrefix.."InAlarm","TRUE")
            map_if:Remove(g_mapKeyPrefix..keyPrefix.."CurSample")
        else
            map_if:Set(g_mapKeyPrefix..keyPrefix.."CurSample",tostring(curSample))
        end
    else
        -- we are not in breach (anymore)
        if map_if:Get(g_mapKeyPrefix..keyPrefix.."InAlarm") == "TRUE" then 
            TransitionAlarm(keyPrefix)
            map_if:Remove(g_mapKeyPrefix..keyPrefix.."InAlarm")
        end
    end
end

function SaveSample(bwv)
    map_if:Set(g_mapKeyPrefix.."sysUpTime",util_if:UI64ToStr(bwv.sysUpTime))
    map_if:Set(g_mapKeyPrefix.."ifInOctets",util_if:UI64ToStr(bwv.ifInOctets))
    map_if:Set(g_mapKeyPrefix.."ifOutOctets",util_if:UI64ToStr(bwv.ifOutOctets))
    rrd_if:Update("inOctets:outOctets","N:"..util_if:UI64ToStr(bwv.ifInOctets)..":"..util_if:UI64ToStr(bwv.ifOutOctets))
    --rrd_if:Update("inOctets","N:"..util_if:UI64ToStr(bwv.ifInOctets))
    --rrd_if:Update("outOctets","N:"..util_if:UI64ToStr(bwv.ifOutOctets))
    --rrd_if:Update("inUcastPkts","N:"..util_if:UI64ToStr(bwv.inUcastPkts))
    --rrd_if:Update("inNUcastPkts","N:"..util_if:UI64ToStr(bwv.inNUcastPkts))
    --rrd_if:Update("inDiscards","N:"..util_if:UI64ToStr(bwv.inDiscards))
    --rrd_if:Update("inErrors","N:"..util_if:UI64ToStr(bwv.inErrors))
    --rrd_if:Update("inUnknownProtos","N:"..util_if:UI64ToStr(bwv.inUnknownProtos))
    --rrd_if:Update("outUcastPkts","N:"..util_if:UI64ToStr(bwv.outUcastPkts))
    --rrd_if:Update("outNUcastPkts","N:"..util_if:UI64ToStr(bwv.outNUcastPkts))
    --rrd_if:Update("outDiscards","N:"..util_if:UI64ToStr(bwv.outDiscards))
    --rrd_if:Update("outErrors","N:"..util_if:UI64ToStr(bwv.outErrors))
end

-- DEBUG: Dump the configuration and data contexts
--xml_if:SetCurrent(xml.CONTEXT_CFG,nil)
--io.write("Context - Configuration\n"..xml_if:GetDocFormatted())
--xml_if:SetCurrent(xml.CONTEXT_DATA,nil)
--io.write("Context - Data\n"..xml_if:GetDocFormatted())

function WrappedDiff(last,cur,range)
    if cur >= last then 
        return (cur-last) 
    else 
        return (range - last + cur) 
    end
end

local bwv = GetBandwidthVars()
if bwv ~= false then
	if g_verbose == true then
        io.write("sysUpTime        = "..util_if:UI64ToStr(bwv.sysUpTime),
                 "linkMaxSpeed     = "..util_if:UI64ToStr(bwv.linkMaxSpeed),
                 "ifInOctets       = "..util_if:UI64ToStr(bwv.ifInOctets),
                 "ifOutOctets      = "..util_if:UI64ToStr(bwv.ifOutOctets)
                 --"inUcastPkts      = "..util_if:UI64ToStr(bwv.inUcastPkts),
                 --"inNUcastPkts     = "..util_if:UI64ToStr(bwv.inNUcastPkts),
                 --"inDiscards       = "..util_if:UI64ToStr(bwv.inDiscards),
                 --"inErrors         = "..util_if:UI64ToStr(bwv.inErrors),
                 --"inUnknownProtos  = "..util_if:UI64ToStr(bwv.inUnknownProtos),
                 --"outUcastPkts     = "..util_if:UI64ToStr(bwv.outUcastPkts),
                 --"outNUcastPkts    = "..util_if:UI64ToStr(bwv.outNUcastPkts),
                 --"outDiscards      = "..util_if:UI64ToStr(bwv.outDiscards),
                 --"outErrors        = "..util_if:UI64ToStr(bwv.outErrors)
        )
	end
	g_linkMaxSpeed = util_if:UI64ToStr(bwv.linkMaxSpeed) -- added for summary line

    local lastSysUpTime
	if map_if:Exists(g_mapKeyPrefix.."sysUpTime") == false then 
        io.write("No previous sample - saving this sample and aborting.")
        SaveSample(bwv)
    else
        lastSysUpTime = util_if:StrToUI64(map_if:Get(g_mapKeyPrefix.."sysUpTime"))
        if lastSysUpTime > bwv.sysUpTime then
            io.write("Target has reset since the last sample - saving this sample and aborting.")
            SaveSample(bwv)
        else
            local lastIfInOctets, lastIfOutOctets
            lastIfInOctets  = util_if:StrToUI64(map_if:Get(g_mapKeyPrefix.."ifInOctets"))
            lastIfOutOctets = util_if:StrToUI64(map_if:Get(g_mapKeyPrefix.."ifOutOctets"))

            if g_verbose == true then
                io.write("lastSysUpTime    = "..util_if:UI64ToStr(lastSysUpTime),
                         "lastIfInOctets   = "..util_if:UI64ToStr(lastIfInOctets),
                         "lastIfOutOctets  = "..util_if:UI64ToStr(lastIfOutOctets))
            end

            -- If we are here, then we have a good current sample and a good previous sample.
            SaveSample(bwv)

            local sysUpTimeDelta,inOctetsDelta,outOctetsDelta
            sysUpTimeDelta = bwv.sysUpTime - lastSysUpTime

            inOctetsDelta  = WrappedDiff(lastIfInOctets,bwv.ifInOctets,bwv.range)
            outOctetsDelta = WrappedDiff(lastIfOutOctets,bwv.ifOutOctets,bwv.range)

            local inBitRate   = 0
            if sysUpTimeDelta ~= 0 then inBitRate = (inOctetsDelta * 8ULL) / sysUpTimeDelta end
            local outBitRate  = 0
            if sysUpTimeDelta ~= 0 then outBitRate = (outOctetsDelta * 8ULL) / sysUpTimeDelta end
            local inUtilPcnt  = snmp_if:Ui64ToDbl(inBitRate) / snmp_if:Ui64ToDbl(bwv.linkMaxSpeed) * 100.0
            local outUtilPcnt = snmp_if:Ui64ToDbl(outBitRate) / snmp_if:Ui64ToDbl(bwv.linkMaxSpeed) * 100.0

            if g_verbose == true then
                io.write("range          = "..util_if:UI64ToStr(bwv.range),
                         "sysUpTimeDelta = "..util_if:UI64ToStr(sysUpTimeDelta),
                         "inOctetsDelta  = "..util_if:UI64ToStr(inOctetsDelta),
                         "inBitRate      = "..util_if:UI64ToStr(inBitRate),
                         "inUtilPcnt     = "..string.format("%.2f",tonumber(inUtilPcnt)).."%",
                         "outOctetsDelta = "..util_if:UI64ToStr(outOctetsDelta),
                         "outBitRate     = "..util_if:UI64ToStr(outBitRate),
                         "outUtilPcnt    = "..string.format("%.2f",tonumber(outUtilPcnt)).."%")
            else
                io.write(g_ipAddress..":"..g_ifIndex.." IN: "..util_if:UI64ToStr(inBitRate).." ("..string.format("%.2f",tonumber(inUtilPcnt)).."%)"..
                                                      " OUT: "..util_if:UI64ToStr(outBitRate).." ("..string.format("%.2f",tonumber(outUtilPcnt)).."%)")
            end

			-- used to add additional information to alarm summary
            g_percentIn = "Incoming Actual: "..util_if:UI64ToStr(inBitRate).." ("..string.format("%.2f",tonumber(inUtilPcnt)).."%)"
            g_percentOut = "Ooutgoing Actual: "..util_if:UI64ToStr(outBitRate).." ("..string.format("%.2f",tonumber(outUtilPcnt)).."%)"

            g_inUpperThreshold  = ConvertThreshold(g_inUpperThreshold,bwv.linkMaxSpeed)
            if g_inUpperThreshold > bwv.linkMaxSpeed and g_verbose == true then
                io.write("WARNING - INCOMING UPPER THRESHOLD ("..tostring(g_inUpperThreshold)..") GREATER THAN LINK SPEED ("..util_if:UI64ToStr(bwv.linkMaxSpeed)..") - UTILIZATION WILL NEVER BREECH")
            end
            g_inLowerThreshold  = ConvertThreshold(g_inLowerThreshold,bwv.linkMaxSpeed)
            if g_inLowerThreshold > bwv.linkMaxSpeed and g_verbose == true then
                io.write("WARNING - INCOMING LOWER THRESHOLD ("..tostring(g_inLowerThreshold)..") GREATER THAN LINK SPEED ("..util_if:UI64ToStr(bwv.linkMaxSpeed)..") - UTILIZATION WILL ALWAYS BREECH")
            end
            g_outUpperThreshold = ConvertThreshold(g_outUpperThreshold,bwv.linkMaxSpeed)
            if g_outUpperThreshold > bwv.linkMaxSpeed and g_verbose == true then
                io.write("WARNING - OUTGOING UPPER THRESHOLD ("..tostring(g_outUpperThreshold)..") GREATER THAN LINK SPEED ("..util_if:UI64ToStr(bwv.linkMaxSpeed)..") - UTILIZATION WILL NEVER BREECH")
            end
            g_outLowerThreshold = ConvertThreshold(g_outLowerThreshold,bwv.linkMaxSpeed)
            if g_outLowerThreshold > bwv.linkMaxSpeed and g_verbose == true then
                io.write("WARNING - OUTGOING LOWER THRESHOLD ("..tostring(g_outLowerThreshold)..") GREATER THAN LINK SPEED ("..util_if:UI64ToStr(bwv.linkMaxSpeed)..") - UTILIZATION WILL ALWAYS BREECH")
            end

            ProcessAlarm("INCOMING",true,inBitRate,g_inUpperThreshold,g_inUpperSamples)
            ProcessAlarm("INCOMING",false,inBitRate,g_inLowerThreshold,g_inLowerSamples)
            ProcessAlarm("OUTGOING",true,outBitRate,g_outUpperThreshold,g_outUpperSamples)
            ProcessAlarm("OUTGOING",false,outBitRate,g_outLowerThreshold,g_outLowerSamples)
        end
    end

    io.write("END SCRIPT ("..g_ipAddress..":"..g_ifIndex..")")
end
