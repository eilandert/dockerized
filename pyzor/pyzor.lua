local ucl = require "ucl"
local logger = require "rspamd_logger"
local tcp = require "rspamd_tcp"

local N = "pyzor"
local symbol_pyzor = "PYZOR"
local opts = rspamd_config:get_all_opt(N)

-- Default settings
local cfg_host = "localhost"
local cfg_port = 5953

--{"PV": "2.1", "Code": "200", "WL-Count": "0", "Count": "53", "Thread": "53416", "Diag": "OK"}

local function check_pyzor(task)
    local function cb(err, data)
        if err then
            logger.errx(task, "request error: %s", err)
            return
        end
        logger.debugm(N, task, 'data: %s', tostring(data))

        local parser = ucl.parser()
        local ok, err = parser:parse_string(tostring(data))
        if not ok then
            logger.errx(task, "error parsing response: %s", err)
            return
        end

        local resp = parser:get_object()
        local whitelisted = tonumber(resp["WL-Count"])
        local reported = tonumber(resp["Count"])

        logger.infox(task, "count=%s wl=%s", reported, whitelisted)

        -- Make whitelists count a little bit.
        -- Maybe there's a better way to take whitelists into account,
        -- but at least this is something.
        reported = reported - whitelisted

        local weight = 0

        if reported >= 100 then
            weight = 1.5
        elseif reported >= 25 then
            weight = 1.25
        elseif reported >= 5 then
            weight = 1.0
        elseif reported >= 1 and whitelisted == 0 then
            weight = 0.2
        end

        if weight > 0 then
            task:insert_result(symbol_pyzor, weight, string.format("count=%d wl=%d", reported, whitelisted))
        end
    end

    local request = {
        "CHECK\n",
        task:get_content(),
    }

    logger.debugm(N, task, "querying pyzor")

    tcp.request({
        task = task,
        host = cfg_host,
        port = cfg_port,
        shutdown = true,
        data = request,
        callback = cb,
    })
end

if opts then
    if opts.host then
        cfg_host = opts.host
    end
    if opts.port then
        cfg_port = opts.port
    end

    rspamd_config:register_symbol({
        name = symbol_pyzor,
        callback = check_pyzor,
    })
else
    logger.infox("%s module not configured", N)
end
