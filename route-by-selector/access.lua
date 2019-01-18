local cjson = require "cjson"
local judge = require "kong.plugins.route-by-selector.judge.judge"
local response = kong.response
local log = kong.log

local _M = {}

local function load_conf_selectors_into_memory(selector_name)
    local rows, err =
        kong.dao.route_by_selector:find_all {
        selector_name = selector_name,
    }

    if err then
        return nil, tostring(err)
    end

    if #rows > 0 then
        for _, row in ipairs(rows) do
            if selector_name == row.selector_name then
                return row
            end
        end
    end
end


local function load_route_conf_selector(selector_name)
    local selector_name_cache = kong.dao.route_by_selector:cache_key(selector_name)
    local data, err = kong.cache:get(selector_name_cache, nil, load_conf_selectors_into_memory, selector_name)
    if err then
        return nil, err
    end

    local selectors
    if data ~= nil then
        log.debug("data.value: ", data.value)
        selectors = cjson.decode(data.value)
    end
    return selectors, err
end


local function do_route_by_selectors(ctx, selectors)
    local rules = selectors.rules
    if not rules or type(rules) ~= "table" or #rules <= 0 then
        log.debug("judge rules failed, type(rules): ", type(rules))
        return false
    end

    local pass_rule
    for j, rule in ipairs(rules) do
        if rule.enable == true then
            local pass = judge.judge_rule(rule)
            if pass then
                pass_rule = rule
                break
            end
            log.debug("route rules ipairs: ", j)
        end
    end

    if not pass_rule then
        return false
    end

    local upstream_name = pass_rule.upstream_name
    if not upstream_name then
        log.debug("pass_rule upstream_name is nil.")
        return false
    end

    -- route to specified upstream
    ctx.balancer_data.host = upstream_name
    return true
end

local function do_available_selectors(ctx, name)
    local selectors, err = load_route_conf_selector(name)
    if err then
        log.debug("retrieve_conf_available_selectors err: ", err)
        return false
    end
    if not selectors then
        log.debug("no available selectors")
        return false
    end

    local ok = do_route_by_selectors(ctx, selectors)
    if not ok then 
        return false
    end
    return true
end

function _M.execute(conf)
    local ctx = ngx.ctx
    local selectors_conf = conf.selectors
    if not selectors_conf then 
        return 
    end

    for j, name in ipairs(selectors_conf) do
        pass = do_available_selectors(ctx, name)
        if pass then 
            break
        end
    end
end

return _M
