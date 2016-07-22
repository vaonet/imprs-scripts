# Script Version 

* 2.2 - Released 2016/07/22
* 2.1 - Released 2016/04/07
* 2.0 - Released 2015/03/03

# Purpose

## Monitoring

This script monitors incoming and outgoing bandwidth on an interface for upper and lower threshold violations. It does so by auto-determining the link speed of the interface (or using a provided linkspeed) and choosing the appropriate counters based on that speed - either the 32 bit low speed or 64 bit high speed counters.

## Data Collection

This script stores the received counter values and provides several graphs of the data.

# IMPRS Portal Version Compatibility 

This script is compatible with the following versions.

* 9.1 Update-Release 2015/03/03 and above
* 9.2 Release 9.2-6.5 and above

# Test Parameters

* Execution Schedule: An interval of 5 minutes is required to ensure correct calculations.

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
: The number of retries to make when requesting values from the equipment. The script will fail if no response is received after all attempted retries.

Timeout (secs)
: The time, in seconds, to wait for a response from the equipment. If the timeout is reached and depending on the value for *Retries*, the script will either resend the request or fail.

Link Speed (bits/sec)
: The script attempts to determine the link speed by interrogating the equipment. If you want to override this attempt, enter the value to use in bits per second.

Percentage
: When calculating threshold violations, use either percent utilization or absolute values. If this checkbox is checked, then the subsequent threshold values should be entered as a percentage (0-100%). Otherwise enter them as values in bits per second.

Incoming Upper Threshold
: If the incoming bandwidth rises above this threshold and stays there for the number of *Samples* given in the next field, then an alarm is generated. To disable the monitoring of this threshold, set the value to 0. If *Percentage* is checked, then the value should be between 0 and 100. If not checked, then the value should less than the link speed or an alarm will never be generated.

Incoming Upper Samples
: If the incoming bandwidth stays above the upper threshold for the number of samples specified here, then an alarm is generated. To disable the monitoring of this threshold, set the value to 0.

Incoming Lower Threshold
: If the incoming bandwidth drops below this threshold and stays there for the number of *Samples* given in the next field, then an alarm is generated. To disable the monitoring of this threshold, set the value to 0. If *Percentage* is checked, then the value should be between 0 and 100. If not checked, then the value should less than the link speed or an alarm will always be generated.

Incoming Lower Samples
: If the incoming bandwidth stays below the lower threshold for the number of samples specified here, then an alarm is generated. To disable the monitoring of this threshold, set the value to 0.

Outgoing Upper Threshold
: If the outgoing bandwidth rises above this threshold and stays there for the number of *Samples* given in the next field, then an alarm is generated. To disable the monitoring of this threshold, set the value to 0. If *Percentage* is checked, then the value should be between 0 and 100. If not checked, then the value should less than the link speed or an alarm will never be generated.

Outgoing Upper Samples
: If the outgoing bandwidth stays above the upper threshold for the number of samples specified here, then an alarm is generated. To disable the monitoring of this threshold, set the value to 0.

Outgoing Lower Threshold
: If the outgoing bandwidth drops below this threshold and stays there for the number of *Samples* given in the next field, then an alarm is generated. To disable the monitoring of this threshold, set the value to 0. If *Percentage* is checked, then the value should be between 0 and 100. If not checked, then the value should less than the link speed or an alarm will always be generated.

Outgoing Lower Samples
: If the outgoing bandwidth stays below the lower threshold for the number of samples specified here, then an alarm is generated. To disable the monitoring of this threshold, set the value to 0.

# Equipment to Test

Ensure the selected equipment implements the IF-MIB. Otherwise, the script will fail when trying to retrieve values from the equipment.

You can check whether or not equipment implements the IF-MIB by referring to the equipment's documentation or using the MIB Database Browser (Trap Database Browser in IMPRS Portal version 9.1).

# Data Sources

There are two data sources called *inOctets* and *outOctets* that **must** be of type *COUNTER* in order for the collected values to be stored correctly. The names are referenced in the script and in graph definitions, so if one is changed here, then it must also be changed in those places.

The minimum and maximum values for each data source should be 0 and 18446744073709551615, respectively.

# Archives

All four archives should be selected: Average, Minimum, Maximum, and Last. Each archive is used in the graph definitions.

# Graphs

## Bandwidth Utilization (In vs Out)

This graph the plots the incoming bandwidth with the outgoing bandwidth overlayed.

## Bandwidth Utilization (In vs Out) with 95th

Same as the above graph but also includes the 95th percentile calculation in the legend.

## Bandwidth Utilization (Out vs In)

This graph the plots the outgoing bandwidth with the incoming bandwidth overlayed.

## Bandwidth Utilization (Out vs In) with 95th

Same as the above graph but also includes the 95th percentile calculation in the legend.
