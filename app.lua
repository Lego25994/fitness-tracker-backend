local bcrypt = require("bcrypt")
local lapis = require("lapis")
local model = require("lapis.db.model").Model
local users = model:extend("users", {
  relations = { {"challenges", has_many = "challenges", key = "from_id"} } })
local challenges = model:extend("challenges", {
  relations = { {"from", belongs_to = "users"}, {"to", belongs_to = "users"} } })

local BCRYPT_DIGEST_CYCLES = 10

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
  self.passwd_error = ""
  return { render = "login" }
end)

app:get("/register", function(self)
  self.register_error = ""
  return { render = "register" }
end)

app:post("/login", function(self)
  local user = self.params.username
  local matches = users:select("where username = ?", user)
  if #matches == 0 then
    self.passwd_error = "no such user"
    return { render = "login" }
  else
    local raw = self.params.password
    if not bcrypt.verify(raw, matches[1].password) then
      self.passwd_error = "invalid password"
      return { render = "login" }
    end
    self.session.current_user_id = matches[1].id
  end
  return { redirect_to = "/home" }
end)

app:post("/register", function(self)
  local user = self.params.username
  local matches = users:select("where username = ?", user)
  if #matches > 0 then
    self.register_error = "user already exists"
    return { render = "register" }
  else
    local hashed = bcrypt.digest(self.params.password, BCRYPT_DIGEST_CYCLES)
    local new = users:create({
      username = user,
      password = hashed,
    })
    self.session.current_user_id = new.id
    return { redirect_to = "/home" }
  end
  return { redirect_to = "/login" }
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
