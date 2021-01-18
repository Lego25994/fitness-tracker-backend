local lapis = require("lapis")
local model = require("lapis.db.model").Model
local users = model:extend("users")

local app = lapis.Application()
app:enable("etlua")

app:get("/", function()
  return { render = "login" }
end)

app:get("/home", function(self)
  if not self.session.current_user_id then
    return { redirect_to = "/" }
  else
    self.current_user = users:find(self.session.current_user_id)
    return { render = "home" }
  end
end)

app:post("/login", function(self)
  local user = self.params.username
  local matches = users:select("where username = ?", user)
  if #matches == 0 then
    local new = users:create({
      username = user
    })
    self.session.current_user_id = new.id
  else
    self.session.current_user_id = matches[1].id
  end
  return { redirect_to = "/home" }
end)

return app
