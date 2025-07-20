--
-- 2017 Belkin International, Inc. and/or its affiliates. All rights reserved.
--
-- $Author: hesia $
-- $DateTime: 2017/07/25 17:05:20 $
-- $Id: //depot-irv/olympus_partners/dallas_dev/lego_overlay/proprietary/jnap/lualib/linkaggregation.lua#1 $
--

-- linkaggregation.lua - library to configure upstream power modem.


local _M = {} -- create the module

--
-- Whether the link aggregation feature is enabled.
--
-- input = CONTEXT
--
-- output = BOOLEAN
--
function _M.isLinkAggregationEnabled(sc)
    sc:readlock()
    local enabled = sc:get_link_aggregation_enabled()
    return (enabled == nil and false or enabled)
end

--
-- Get the current upstream modem DSL settings.
--
-- input = CONTEXT
--
-- output = [INT]
--
function _M.getAggregatedPorts(sc)
    sc:readlock()
    return sc:get_aggregated_ports()
end

--
-- Enable/Disable the link aggregation feature.
--
-- input = CONTEXT, BOOLEAN
--
function _M.setLinkAggregationEnabled(sc, enabled)
    sc:writelock()
    sc:set_link_aggregation_enabled(enabled)
end

return _M -- return the module
