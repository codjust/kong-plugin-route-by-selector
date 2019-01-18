local crud = require "kong.api.crud_helpers"
local utils = require "kong.tools.utils"
local response = kong.response

--TODO: check params valid
return {
    ["/route-by-selector/"] = {
        before = function(self, dao_factory, helpers)
            local method = ngx.req.get_method()
            if method == 'GET' then 
                return
            end
            local db_service = kong.db.services
            -- service_id service_name
            local service_id = self.params.service_id
            local service_name = self.params.service_name

            local service
            if service_id and utils.is_valid_uuid(service_id) then
                service, _, err = db_service:select({id = service_id})
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not service then
                if not service_name then
                    return helpers.responses.send_HTTP_NOT_FOUND("Not found params service_id or service_name in body.")
                end
                service, _, err = db_service:select_by_name(service_name)
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not service then
                return helpers.responses.send_HTTP_NOT_FOUND("Not found service.")
            end

            self.params.service_id = service.id
            self.params.service_name = service.name
        end,
        GET = function(self, dao_factory)
            crud.paginated_set(self, dao_factory.route_by_selector)
        end,
        PUT = function(self, dao_factory)
            crud.put(self.params, dao_factory.route_by_selector)
        end,
        POST = function(self, dao_factory)
            local cjson = require("cjson")
            kong.log.debug("POST params: ", cjson.encode(self.params))
            crud.post(self.params, dao_factory.route_by_selector)
        end
    },
    ["/route-by-selector/:selector_id_or_name"] = {
        before = function(self, dao_factory, helpers)
            local selector_id_or_name = self.params.selector_id_or_name

            local selectors, err
            if utils.is_valid_uuid(selector_id_or_name) then
                selectors, err =
                    crud.find_by_id_or_field(
                    dao_factory.route_by_selector,
                    {id = ngx.unescape_uri(self.params.selector_id_or_name)},
                    ngx.unescape_uri(self.params.selector_id_or_name),
                    "id"
                )
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not selectors then
                selectors, err =
                    crud.find_by_id_or_field(
                    dao_factory.route_by_selector,
                    {selector_name = ngx.unescape_uri(self.params.selector_name)},
                    ngx.unescape_uri(self.params.selector_name),
                    "selector_name"
                )
            end

            if err then
                return helpers.yield_error(err)
            elseif next(selectors) == nil then
                return helpers.responses.send_HTTP_NOT_FOUND()
            end

            self.selector = selectors[1]
            self.selector_name = nil

            local method = ngx.req.get_method()
            if method == 'GET' or method == 'DELETE'then 
                return
            end
            local db_service = kong.db.services
            -- service_id service_name
            local service_id = self.params.service_id
            local service_name = self.params.service_name

            local service
            if service_id and utils.is_valid_uuid(service_id) then
                service, _, err = db_service:select({id = service_id})
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not service then
                if not service_name then
                    return helpers.responses.send_HTTP_NOT_FOUND("Not found params service_id or service_name in body.")
                end
                service, _, err = db_service:select_by_name(service_name)
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not service then
                return helpers.responses.send_HTTP_NOT_FOUND("Not found service.")
            end

            self.params.service_id = service.id
            self.params.service_name = service.name
            self.params.selector_id_or_name = nil
        end,
        GET = function(self, dao_factory, helpers)
            return helpers.responses.send_HTTP_OK(self.selector)
        end,
        PATCH = function(self, dao_factory)
            local cjson = require("cjson")
            kong.log.debug("PATCH params: ", cjson.encode(self.params))
            ngx.update_time()
            self.params.op_time = ngx.now()
            crud.patch(self.params, dao_factory.route_by_selector, self.selector)
        end,
        DELETE = function(self, dao_factory)
            crud.delete(self.selector, dao_factory.route_by_selector)
        end
    }
}
