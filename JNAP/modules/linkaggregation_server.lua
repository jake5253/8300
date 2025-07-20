--
-- 2017 Belkin International, Inc. and/or its affiliates. All rights reserved.
--
-- $Author: hesia $
-- $DateTime: 2017/07/25 17:05:20 $
-- $Id: //depot-irv/olympus_partners/dallas_dev/lego_overlay/proprietary/jnap/modules/linkaggregation/linkaggregation_server.lua#1 $
--
local function GetLinkAggregationSettings(ctx)
    local linkaggregation = require('linkaggregation')

    local sc = ctx:sysctx()
    return 'OK', {
                     isEnabled = linkaggregation.isLinkAggregationEnabled(sc),
                     aggregatedPorts = linkaggregation.getAggregatedPorts(sc)
                 }
end

local function SetLinkAggregationSettings(ctx, input)
    local linkaggregation = require('linkaggregation')

    local sc = ctx:sysctx()
    local error = linkaggregation.setLinkAggregationEnabled(sc, input.isEnabled)
    return error or 'OK'
end

return require('libhdklua').loadmodule('jnap_linkaggregation'), {
    ['http://linksys.com/jnap/linkaggregation/GetLinkAggregationSettings'] = GetLinkAggregationSettings,
    ['http://linksys.com/jnap/linkaggregation/SetLinkAggregationSettings'] = SetLinkAggregationSettings
}
