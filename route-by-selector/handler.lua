-- Copyright (C) codjust https://github.com/huchangwei

local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.route-by-selector.access"

local RouteBySelectorHandler = BasePlugin:extend()

-- TODO: setting PRIORITY
RouteBySelectorHandler.PRIORITY = 5001
RouteBySelectorHandler.VERSION = "0.1.0"

function RouteBySelectorHandler:new()
    RouteBySelectorHandler.super.new(self, "route-by-selector")
end

function RouteBySelectorHandler:access(conf)
    RouteBySelectorHandler.super.access(self)
    access.execute(conf)
end


return RouteBySelectorHandler