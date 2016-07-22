<IMPRS_Resource_Configuration tag="object">
    <NETMAH tag="object">
        <uuid tag="field" type="literal"></uuid>
        <name tag="field" type="literal">SNMP Gauge Check 1</name>
        <phonetic tag="field" type="literal">SNMP Gauge Check</phonetic>
        <description tag="field" type="literal">Checks an SNMP variable that operates as a gauge for value equality and range violations.</description>
        <testType tag="field" type="literal">EQUIP</testType>
        <scriptPath tag="field" type="literal">Vaonet/Network Tests/EQUIP/snmpgaugecheck1.0.lua</scriptPath>
        <scriptArgs tag="field" type="literal">NONE CRITICAL 15 v2c 161 1 1 "" EQUAL "" "" VALUE</scriptArgs>
        <scriptTO tag="field" type="ulong">30</scriptTO>
        <period tag="field" type="ulong">0</period>
        <dayOf tag="field" type="ulong">0</dayOf>
        <offset tag="field" type="ulong">300</offset>
        <rraAvg tag="field" type="string">true</rraAvg>
        <rraMin tag="field" type="string">true</rraMin>
        <rraMax tag="field" type="string">true</rraMax>
        <rraLst tag="field" type="string">true</rraLst>
        <rraABD tag="field" type="string">false</rraABD>
        <abdAlpha tag="field" type="float">0.00000</abdAlpha>
        <abdBeta tag="field" type="float">0.00000</abdBeta>
        <abdNumPDPs tag="field" type="ulong">0</abdNumPDPs>
        <abdNumRows tag="field" type="ulong">0</abdNumRows>
        <DS tag="object">
            <name tag="field" type="literal">rcvdValue</name>
            <type tag="field" type="literal">GAUGE</type>
            <min tag="field" type="literal">0</min>
            <max tag="field" type="literal">4294967295</max>
        </DS>
        <Graph tag="object">
            <name tag="field" type="literal">Value vs. Time</name>
            <jsonCfg tag="field" type="literal">{"options":{"doTitle":true,"title":"&amp;lt;equipName/&amp;gt; : &amp;lt;ipAddress/&amp;gt;","doVLabel":true,"vLabel":"Range","doUpperLimit":false,"doLowerLimit":false,"doRigid":true,"doAutoscale":true,"doAutoscaleMin":false,"doAutoscaleMax":false,"doNoGridFit":false,"doColorBack":true,"colorBack":"#E4E9E4","doColorCanvas":true,"colorCanvas":"#E4E9E4","doColorShadeA":false,"colorShadeA":"","doColorShadeB":false,"colorShadeB":"","doColorGrid":false,"colorGrid":"","doColorMGrid":false,"colorMGrid":"","doColorFont":false,"colorFont":"","doColorAxis":false,"colorAxis":"","doColorFrame":false,"colorFrame":"","doColorArrow":false,"colorArrow":"","doFontDefault":false,"fontDefault":"","doFontTitle":false,"fontTitle":"","doFontAxis":false,"fontAxis":"","doFontUnit":false,"fontUnit":"","doFontLegend":false,"fontLegend":"","doFontWatermark":false,"fontWatermark":"","doNoXGrid":false,"doNoYGrid":false,"doAltYGrid":false,"doLogarithmic":false,"doUnitsExponent":false,"unitsExponent":"","doUnitsLength":false,"unitsLength":"","doUnits":false,"units":"","doRightAxis":false,"rightAxis":"","doRightAxisLabel":false,"rightAxisLabel":"","doRightAxisFormat":false,"rightAxisFormat":"","doNoLegend":false,"doForceRulesLegend":false,"doLegendPosition":false,"legendPosition":"south","doLegendDirection":false,"legendDirection":"topdown","doGridDash":false,"gridDash":"1:1","doBorder":true,"border":"0","doDynamicLabels":false,"doZoom":false,"zoom":"","doFontRenderMode":false,"fontRenderMode":"normal","doFontSmoothingThreshold":false,"fontSmoothingThreshold":"","doPangoMarkup":false,"doGraphRenderMode":false,"graphRenderMode":"normal","doSlopeMode":true,"doInterlaced":false,"doTabWidth":false,"tabWidth":"","doBase":false,"base":"","doWatermark":false,"watermark":""},"instructions":[{"instruction":{"type":"DEF","vname":"rxavg","rrdFile":"&amp;lt;rrdFile/&amp;gt;","ds":"rcvdValue","cf":"AVERAGE","doStep":false,"doStart":false,"doEnd":false,"doReduce":false}},{"instruction":{"type":"DEF","vname":"rxmin","rrdFile":"&amp;lt;rrdFile/&amp;gt;","ds":"rcvdValue","cf":"MIN","doStep":false,"doStart":false,"doEnd":false,"doReduce":false}},{"instruction":{"type":"DEF","vname":"rxmax","rrdFile":"&amp;lt;rrdFile/&amp;gt;","ds":"rcvdValue","cf":"MAX","doStep":false,"doStart":false,"doEnd":false,"doReduce":false}},{"instruction":{"type":"DEF","vname":"rxlst","rrdFile":"&amp;lt;rrdFile/&amp;gt;","ds":"rcvdValue","cf":"LAST","doStep":false,"doStart":false,"doEnd":false,"doReduce":false}},{"instruction":{"type":"VDEF","vname":"avg","rpn":"rxavg,AVERAGE"}},{"instruction":{"type":"VDEF","vname":"min","rpn":"rxmin,MINIMUM"}},{"instruction":{"type":"VDEF","vname":"max","rpn":"rxmax,MAXIMUM"}},{"instruction":{"type":"VDEF","vname":"last","rpn":"rxlst,LAST"}},{"instruction":{"type":"AREA","vname":"rxavg","doColor":true,"color":"#9FEE00","doLegend":true,"legend":"Stats","doStack":false,"doSkipScale":false}},{"instruction":{"type":"GPRINT","vname":"last","format":"Last\\: %.2lf"}},{"instruction":{"type":"GPRINT","vname":"avg","format":"Average\\: %.2lf"}},{"instruction":{"type":"GPRINT","vname":"max","format":"Maximum\\: %.2lf"}},{"instruction":{"type":"GPRINT","vname":"min","format":"Minimum\\: %.2lf\\l"}}]}</jsonCfg>
        </Graph>
    </NETMAH>
</IMPRS_Resource_Configuration>
