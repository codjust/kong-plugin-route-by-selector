local SCHEMA = {
    primary_key = {"id"},
    table = "route_by_selector",
    cache_key = {"selector_name"},
    fields = {
        id = {type = "id", dao_insert_value = true, immutable = true},
        created_at = {type = "timestamp", immutable = true, dao_insert_value = true},
        selector_name  =  {type = "string", required = true, unique = true},
        service_id =  {type = "id",  foreign = "services:id"},
        service_name = {type = "string"},
        value = {type = "string", default = "{}"},
        op_time= {type = "timestamp"}
    },

}

return  {route_by_selector = SCHEMA}