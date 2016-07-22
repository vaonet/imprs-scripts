require("xml")
require("evt")
require ("ctxt")

local local_event = "View Only"
local nbi_event = "Northbound"
local delay = 0
local snb = "yes"
local dsnb = "no"
local found = false

-- create table1 for alarm ID based on alarm extended info. use extended1
local table1 = {"IK4004012", "IK4007026", "IK4007056", "IK4009021", "IK4009037", "IK4009046", "IK4011006", "IK4305071", "IK4306099"}

-- create table2 for alarm ID based on alarm extended info. use extended2
local table2 = {"IK4007056", "IK4009021", "IK4009037", "IK4006253", "IK4011010"}

-- create table3 for alarm ID based on alarm extended info. use extended3
local table3 = {"Partial Resync Problem", "PollerProblem"}

-- create table4 for alarm ID based on alarm extended info. use extended4
--local table4 = {"IK4500009","IK4500028"}
local table4 = {
    			"IK4500009","IK4500010","IK4500011","IK4500012","IK4500013","IK4500014","IK4500015","IK4500016","IK4500017","IK4500018","IK4500019","IK4500020","IK4500021","IK4500022","IK4500023","IK4500024","IK4500025","IK4500026","IK4500027","IK4500028",
    			"IK4306223","IK4306224","IK4306225","IK4306226","IK4306227","IK4306228","IK4306229","IK4306230","IK4306231","IK4306232","IK4306233","IK4306234","IK4306235","IK4306236","IK4306237","IK4306238","IK4306239","IK4306240","IK4306241","IK4306242"
			   }

-- create extended info notification type 1
local extended1 = "This alarm is service affecting.<br>Notify the on-call cell site technician immediately<br><br>Notify RF tech for IK4007026 alarm if NOC cannot remedy.<br>"

-- create extended info notification type 2
local extended2 = "This alarm is not service affecting.<br>Notify the Cell Site Technician assigned to the eNodeB via email, CC the Lead Cell Site Technician and Department Manager<br><br>Acknowledge this alarm but do not Clear.<br>"

-- create extended info notification type 3
local extended3 = "This alarm is not service affecting.<br>Perform \"Resync All MIBS\".<br>If multiple NEs report this alrm in the same approximate timeframe, notify the Lead Cell Site Technician.<br>"

-- create extended info notification type 4
local extended4 = "Use current protocols for same alarms from CDMA sites or telco alarms"


-- the following table is used to cherry pick the reported alarmtype (//ALA_alarmType)
local alarmtype = { "communicationsAlarm","equipmentAlarm","processingErrorAlarm" }

-- set file scope to portal configuration files
local xml_if = xml:new();
xml_if:SetCurrent(ctxt.cCfg,nil);
local en = xml_if:FindGetData("//name")
local loc = xml_if:FindGetData("//location")
local lyrtg = xml_if:FindGetData("//layerTags")

-- set file scope to incoming data from SAM
xml_if:SetCurrent(ctxt.cData,nil);
local evnt = xml_if:FindGetData("//eventName")

print("event|"..evnt)

--if evnt == "ObjectCreation" then io.write("Context - Data\n"..xml_if:GetDocFormatted()) end


xml_if:ResetPos()

--print("top of the script")

if (evnt == "ObjectCreation" or evnt == "ObjectDeletion") then
    if (xml_if:FindGetData("//ALA_category") == "FAULT") then

        -- search the file linear to create alarm variables for reporting - field are in order
        local at = xml_if:FindGetData("//ALA_alarmType")
        local an = xml_if:FindGetData("//MTOSI_aliasNameList")
        local obj = xml_if:FindGetData("//MTOSI_objectName")
        local pc = xml_if:FindGetData("//MTOSI_probableCause") -- moving in 13.05
        local sev = xml_if:FindGetData("//severity")
        local ack = xml_if:FindGetData("//wasAcknowledged")
        local user = xml_if:FindGetData("//acknowldegedBy")
        local issvc = xml_if:FindGetData("//isServiceAffecting")
        local addtext = xml_if:FindGetData("//additionalText")
        local nn = xml_if:FindGetData("//nodeName")
        local aodn = xml_if:FindGetData("//affectedObjectDisplayedName")
        local ad = xml_if:FindGetData("//applicationDomain")
        local class = xml_if:FindGetData("//displayedClass")
        local act = xml_if:FindGetData("//alarmClassTag")
        local correlate = xml_if:FindGetData("//correlatingAlarm")
        local olc = xml_if:FindGetData("//olcState")
        local t1 = ad
        local t2 = nn
        local t3 = dsnb --default to don't send northbound

if evnt == "ObjectCreation" then
    io.write("Context - Data\n"..xml_if:GetDocFormatted())
    print("at|"..at)
    print("pc|"..pc)
    print("an|"..an)
    print("obj|"..obj)
    print("sev|"..sev)
    print("ack|"..ack)
    print("user|"..user)
    print("issvc|"..issvc)
    print("addtext|"..addtext)
    print("nn|"..nn)
    print("aodn|"..aodn)
    print("ad|"..ad)
    print("class|"..class)
    print("act|"..act)
    print("correlate|"..correlate)
    print("olc|"..olc)
    print("t1|"..t1)
    print("t2|"..t2)
    print("t3|"..t3)
end


        -- create the summary line, transition identity, and extended information
        local lsum = ("local {"..olc.." - "..an.."} "..nn.." "..aodn.." "..act)
        local nsum = ("northbound {"..addtext.." - "..olc.." - "..an.."} "..nn.." "..aodn.." "..act)
--        local id = (ad.." "..nn.." "..aodn.." "..act)
		local id = (obj) -- environmental transition pattern

print("lsum|"..lsum)
print("nsum|"..nsum)
print("id|"..id)

		-- define the severity
        if sev == "critical" then
            evtsev = evt.sCRI
		elseif sev == "major" then
            evtsev = evt.sMAJ
	  	elseif sev == "minor" then
            evtsev = evt.sMIN
	  	elseif sev == "warning" then
            evtsev = evt.sWRN
	  	elseif sev == "info" then
            evtsev = evt.sINF
	  	else
            evtsev = evt.sIND
        end

        -- io.write("** New Message1: "..an.." - "..at.." - "..sev.." - "..nn.."\n");

print(sev.."|"..evtsev)

        if sev ~= "cleared" then
            n=1
            while table1[n] ~= nil do -- loop through the alarmname table1 matching ALA_alarmName
              		-- io.write("** Table1["..n.."] - "..table1[n].."\n");
                if table1[n] == an then
					t3 = snb -- set the northbound flag for reports
            		local evt_if = evt:new();
              		io.write("** New Event found Table1["..n.."] "..an.." - "..id.."\n");
                    if string.match(addtext,"(.-)Alarm Monitored") then
                        nsum = ("northbound {"..string.match(addtext,"(.-)Alarm Monitored").."} - "..nn.." - "..aodn) -- environmental summary
                    end
               		evt_if:Fire(en,nbi_event,evtsev,nsum,extended1,delay,id,t1,t2,t3,loc,lyrtg)
              		found = true
                    break
             	end
                n=n+1
            end
            if found ~= true then
            	n=1
                while table2[n] ~= nil do -- loop through the alarmname table2 matching ALA_alarmName
              		-- io.write("** Table2["..n.."] - "..table2[n].."\n");
                    if table2[n] == an then
						t3 = snb -- set the northbound flag for reports
                        local evt_if = evt:new();
                        io.write("** New Event found Table2["..n.."] "..an.." - "..id.."\n");
                        if string.match(addtext,"(.-)Alarm Monitored") then
        					nsum = ("northbound {"..string.match(addtext,"(.-)Alarm Monitored").."} - "..nn.." - "..aodn) -- environmental summary
        				end
                        evt_if:Fire(en,nbi_event,evtsev,nsum,extended2,delay,id,t1,t2,t3,loc,lyrtg)
						found = true
                        break
                    end
            		n=n+1
            	end
     		end
            if found ~= true then
            	n=1
                while table3[n] ~= nil do -- loop through the alarmname table3 matching ALA_alarmName
              		-- io.write("** Table3["..n.."] - "..table3[n].."\n");
                    if table3[n] == an then
						t3 = snb -- set the northbound flag for reports
                        local evt_if = evt:new();
                        io.write("** New Event found Table3["..n.."] "..an.." - "..id.."\n");
                        if string.match(addtext,"(.-)Alarm Monitored") then
        					nsum = ("northbound {"..string.match(addtext,"(.-)Alarm Monitored").."} - "..nn.." - "..aodn) -- environmental summary
        				end
                        evt_if:Fire(en,nbi_event,evtsev,nsum,extended3,delay,id,t1,t2,t3,loc,lyrtg)
                        found = true
                        break
                    end
                    n=n+1
            	end
     		end
            if found ~= true then
                while table4[n] ~= nil do -- loop through the alarmname table4 matching ALA_alarmName
              		-- io.write("** Table4["..n.."] - "..table4[n].."\n");
                    if table4[n] == an then
						t3 = snb -- set the northbound flag for reports
                        local evt_if = evt:new();
                        io.write("** New Event found Table4["..n.."] "..an.." - "..id.."\n");
                        if string.match(addtext,"(.-)Alarm Monitored") then
        					esum = ("northbound {"..string.match(addtext,"(.-)Alarm Monitored").."} - "..aodn) -- environmental summary
						else
							esum = nsum
        				end
                        evt_if:Fire(en,nbi_event,evtsev,esum,extended4,delay,id,t1,t2,t3,loc,lyrtg)
                        found = true
                        break
                    end
                    n=n+1
            	end
     		end
            if found ~= true then
--            if found ~= true and (evtsev == evt.sCRI or evtsev == evt.sMAJ) then
				t3 = dsnb -- set the local flag for reports
                local evt_if = evt:new();
                io.write("** LOCAL EVENT: "..sev.." - "..an.." - "..id.."\n");
                print("ready to fire|"..en.."|"..local_event.."|"..evtsev.."|"..lsum.."|"..extended1.."|"..delay.."|"..id.."|"..t1.."|"..t2.."|"..t3.."|"..loc.."|"..lyrtg)
                --evt_if:Fire(en,local_event,evtsev,"VAONET "..lsum,"VAONET TEST MESSAGE EXTENDED",delay,"VAONET "..lsum,t1,t2,t3,loc,lyrtg)
                evt_if:Fire(en,local_event,evtsev,lsum,extended1,delay,id,t1,t2,t3,loc,lyrtg)
                --evt_if:GenEvent(nbi_event,en,nsum,extended1,evtsev,delay,id,t1,t2,t3)
            end
    	else
            local evt_if = evt:new();
            if ack == "true" then
                --io.write("** ACK'D TIP: "..id.."\n");
                evt_if:Trans(en,id,evt.aACK)

            elseif ack == "false" then
                --io.write("** CLR'D TIP: "..id.."\n");
                evt_if:Trans(en,id,evt.aCLR)

            end
        end
    end
end
--print("bottom of the script")
