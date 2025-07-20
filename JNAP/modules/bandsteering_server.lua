--
-- 2017 Belkin International, Inc. and/or its affiliates. All rights reserved.
--
-- $Author: hesia $
-- $DateTime: 2017/10/26 17:35:39 $
-- $Id: //depot-irv/olympus_partners/dallas_dev/lego_overlay/proprietary/jnap/modules/bandsteering/bandsteering_server.lua#1 $
--
local function GetServiceInfo(ctx)
    return 'OK', {
        serviceInfo = 'Band steering auto channel selection is supported on this device.'
    }
end


return require('libhdklua').loadmodule('jnap_bandsteering'), {
    ['http://linksys.com/jnap/wirelessap/bandsteering/GetServiceInfo'] = GetServiceInfo
}
