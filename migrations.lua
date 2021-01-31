local schema = require("lapis.db.schema")
local types = schema.types

return {
  [1] = function()
    schema.create_table("users", {
      {"id", types.serial},
      {"username", types.varchar},

      "PRIMARY KEY (id)"
    })
  end,
  [2] = function()
    schema.create_table("challenges", {
      {"id", types.serial},
      {"from_id", types.integer},
      {"to_id", types.integer},
      {"challenge", types.varchar},
      
      "PRIMARY KEY (id)"
    })
  end,
  [3] = function()
    schema.add_column("users", "password", "varchar(255) not null default '*'")
  end
}
