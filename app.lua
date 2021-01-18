local lapis = require("lapis")

local app = lapis.Application()
app:enable("etlua")

app:get("/", function()
  return { render = "login" }
end)

app:get("/home", function(self)
  if not self.session.current_user then
    return { redirect_to = "/" }
  else
    return { render = "home" }
  end
end)

app:post("/login", function(self)
  self.session.current_user = self.params.username
  return { redirect_to = "/home" }
end)

return app
