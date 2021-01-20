local lapis = require("lapis")
local model = require("lapis.db.model").Model
local users = model:extend("users", {
  relations = { {"challenges", has_many = "challenges", key = "from_id"} } })
local challenges = model:extend("challenges", {
  relations = { {"from", belongs_to = "users"}, {"to", belongs_to = "users"} } })

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

app:get("/error", function(self)
  return { render = "error" }
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

app:post("/challenge", function(self)
  local to = self.params.to
  local challenge = self.params.challenge
  local matches = users:select("where username = ?", to)
  if #matches == 0 or not self.session.current_user_id then
    return { redirect_to = "/error" }
  else
    local user = matches[1].id
    local challenge = challenges:create({
      from_id = user,
      to_id = self.session.current_user_id,
      challenge = challenge
    })
    return { redirect_to = "/home" }
  end
end)

return app
