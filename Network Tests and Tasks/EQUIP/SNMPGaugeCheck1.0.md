# Script Version 

* 1.0 - Released 2016/07/22

# Purpose

## Monitoring

This script monitors a numeric SNMP variable for value or range violations.

The script retrieves the current value for a specified OID and determines if it should generate and alarm. It does this by using an operator to compare the received value with a lower value and possibly an upper value as well. If the comparison evaluates to true, then an alarm is generated.

## Data Collection

This script stores received values and provides graphing of the data.

# IMPRS Portal Version Compatibility 

This script has been tested on the following versions.

9.1 Release
* 9.1 Update-Release 2016/07/22

9.2 Release
* 9.2-10.9

# Test Parameters

* Execution Schedule: An interval of 5 minutes is highly recommended.

## Script Arguments

Alarm Definition
: The alarm definition to use should the script generate an alarm.

Severity
: The severity to assign to the generated alarm.

Notification Delay (mins)
: The delay, in minutes, to wait before notification begins for the generated alarm.

SNMP Version
: Can be *v1* or *v2c*. It is important to ensure this value matches the SNMP version implemented on the equipment the script is communicating with. If there is a mismatch, then the equipment may not respond and cause the script to fail.

Port
: The port on the equipment to send the requests to. Typically, this value is 161.

Retries
: The number of retries to make when requesting the value from the equipment. The script will fail if no response is received after all attempted retries.

Timeout (secs)
: The time, in seconds, to wait for a response from the equipment. If the timeout is reached and depending on the value for *Retries*, the script will either resend the request or fail.

OID to Get
: This is the OID of the value to get. The value's type must either be: Int32, UInt32, or Gauge32, i.e. a 32 bit integral value. Also, ensure that the equipment implements the OID. If either of these are not the case, then the script will fail.

Operator
: Specifies how to compare the received value.
* EQUAL - If received-value is equal to lower-value, then generate an alarm.
* NOT EQUAL - If received-value is not equal to lower-value, then generate an alarm.
* LESS THAN - If received-value is less than lower-value, then generate an alarm.
* LESS THAN OR EQUAL TO - If received-value is less than or equal to lower-value, then generate an alarm.
* GREATER THAN - If received-value is greater than lower-value, then generate an alarm.
* GREATER THAN OR EQUAL TO - If received-value is greater than or equal to lower-value, then generate an alarm.
* BETWEEN - If received-value is greater than or equal to lower-value and less than or equal to upper-value, then generate an alarm.
* NOT BETWEEN - If received-value is less than lower-value or greater than upper-value, then generate an alarm.

Lower Value
: The value to compare against the received value. The type of comparison is specified by the *Operator*.

Upper Value
: The upper value to use when the operator is either BETWEEN or NOT BETWEEN.

Value Label
: When generating an alarm, this label is used to help identify the value's meaning within the alarm's summary.

# Equipment to Test

Ensure the equipment selected implements the OID specified in the Script Arguments. Otherwise, the script will fail when trying to retrieve the value from the equipment.

You can test whether or not equipment implements the OID, by using the MIB Database Browser (Trap Database Browser in IMPRS Portal version 9.1).

# Data Sources

There is a single data source called *rcvdValue* that **must** be of type *GAUGE* in order for the collected values to be stored correctly. The name is referenced in the script and in graph definitions, so if it is changed here, then it must also be changed in those places.

You may need to set the minimum and maximum values by referring to the definition of the OID within its associated MIB. This is especially important, if the collected values can be negative - the minimum value is initially set to zero.

# Archives

All four archives should be selected: Average, Minimum, Maximum, and Last. Each archive is used in the graph definition.

# Graphs

## Value vs. Time

This is a simple graph the plots the received OID value over time. Depending on what is being graphed, you may opt to modify some of the configuration. Out-of-the-box, the graph assumes it is graphing a *unitless* number. There will be no units shown on the graph.