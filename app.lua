local lapis = require("lapis")

local app = lapis.Application()
app:enable("etlua")

app:get("/", function()
  return { render = "hello" }
end)

return app
