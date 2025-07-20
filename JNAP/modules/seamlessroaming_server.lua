--
-- 2016 Belkin International, Inc. and/or its affiliates. All rights reserved.
--
-- $Author$
-- $DateTime$
-- $Id$
--
local function GetServiceInfo(ctx)
    return 'OK', {
        serviceInfo = 'Seamless roaming is supported on this device.'
    }
end


return require('libhdklua').loadmodule('jnap_seamlessroaming'), {
    ['http://linksys.com/jnap/seamlessroaming/GetServiceInfo'] = GetServiceInfo
}
