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
}
