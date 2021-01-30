local lapis = require("lapis")
local model = require("lapis.db.model").Model
local users = model:extend("users", {
  relations = { {"challenges", has_many = "challenges", key = "from_id"} } })
local challenges = model:extend("challenges", {
  relations = { {"from", belongs_to = "users"}, {"to", belongs_to = "users"} } })

local app = lapis.Application()
app:enable("etlua")

app:get("/", function(self)
  if not self.session.current_user_id then
    return { redirect_to = "login" }
  else
    return { redirect_to = "home" }
  end
end)

app:get("/home", function(self)
  if not self.session.current_user_id then
    return { redirect_to = "/" }
  else
    self.current_user = users:find(self.session.current_user_id)
    self.current_user_id = self.session.current_user_id
    self.challenges = challenges:select("where to_id = ?", self.session.current_user_id)
    return { render = "home" }
  end
end)

app:get("/error", function(self)
  return { render = "error" }
end)

app:get("/login", function(self)
  return { render = "login" }
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
  local challenge = self.params.to
  local to = self.params.challenge
  local matches = users:select("where username = ?", to)
  if #matches == 0 or not self.session.current_user_id then
    return { redirect_to = "/error" }
  else
    local user = matches[1].id
    local challenge = challenges:create({
      to_id = user,
      from_id = self.session.current_user_id,
      challenge = challenge
    })
    return { redirect_to = "/home" }
  end
  return { redirect_to = "/home" }
end)

app:post("/complete", function(self)
  local challenges = challenges:select("where to_id = ?", self.session.current_user_id)
  local challenge = challenges:find(self.params.challenge)
  if not challenge then
    return { redirect_to = "/error" }
  end
  challenge:delete()
  return { redirect_to = "/home" }
end)

return app
