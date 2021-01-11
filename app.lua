local lapis = require("lapis")
local app = lapis.Application()

app:get("/", function()
  return "Welcome to Hot Dog Fitness!"
end)

return app
