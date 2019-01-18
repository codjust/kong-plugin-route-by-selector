return {
  {
      name = "2018-1219-151200_init_routebyselector",
      up = [[
          CREATE TABLE IF NOT EXISTS route_by_selector(
          id uuid,
          selector_name text UNIQUE,
          service_id uuid REFERENCES services(id) ON DELETE CASCADE,
          service_name text,
          value text,
          created_at timestamp without time zone default (CURRENT_TIMESTAMP(0) at time zone 'utc'),
          op_time timestamp without time zone default (CURRENT_TIMESTAMP(0) at time zone 'utc'),
          PRIMARY KEY (id)
        );
  
        DO $$
        BEGIN
          IF (SELECT to_regclass('route_by_selector_service_id')) IS NULL THEN
            CREATE INDEX route_by_selector_service_id ON route_by_selector(service_id);
          END IF;
          IF (SELECT to_regclass('route_by_selector_selector_name')) IS NULL THEN
            CREATE INDEX route_by_selector_selector_name ON route_by_selector(selector_name);
          END IF;
        END$$;
  
      ]],
      down = [[
        DROP TABLE route_by_selector;
      ]]
  
  }
  
  
  }