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

local function home_page(self)
  self.current_user = users:find(self.session.current_user_id)
  self.current_user_id = self.session.current_user_id
  self.challenges_to = challenges:select("where to_id = ?", self.session.current_user_id)
  self.challenges_from = challenges:select("where from_id = ?", self.session.current_user_id)
  self.status_message = self.session.status_message
  self.session.status_message = nil
  self.users = users
end

app:get("/home", function(self)
  if not self.session.current_user_id then
    return { redirect_to = "/" }
  else
    home_page(self)
    return { render = "home" }
  end
end)

app:get("/login", function(self)
  self.passwd_error = self.session.passwd_error
  self.session.passwd_error = ""
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
    self.session.passwd_error = "no such user"
    return { redirect_to = "login" }
  else
    local raw = self.params.password
    if not bcrypt.verify(raw, matches[1].password) then
      self.session.passwd_error = "invalid password"
      return { redirect_to = "login" }
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
  local matches = users:select("where id = ?", to)
  if #matches == 0 or not self.session.current_user_id then
    self.session.status_message = "no matching users"
    return { redirect_to = "/home" }
  else
    local user = matches[1].id
    local challenge = challenges:create({
      to_id = user,
      from_id = self.session.current_user_id,
      challenge = challenge
    })
    self.session.status_message = "challenge sent!"
    return { redirect_to = "/home" }
  end
end)

app:post("/complete", function(self)
  local matches = challenges:select("where to_id = ? and challenge = ? limit 1", self.session.current_user_id, self.params.challenge)
  local challenge = matches[1]
  if not challenge then
    self.session.status_message = "challenge not found.  something went very wrong."
    return { redirect_to = "/home" }
  end
  challenge:delete()
  self.session.status_message = "challenge completed!"
  return { redirect_to = "/home" }
end)

app:post("/cancel", function(self)
  local matches = challenges:select("where from_id = ? and challenge = ? limit 1", self.session.current_user_id, self.params.challenge)
  local challenge = matches[1]
  if not challenge then
    self.session.status_message = "challenge not found.  something went very wrong."
    return { redirect_to = "/home" }
  end
  challenge:delete()
  self.session.status_message = "challenge canceled!"
  return { redirect_to = "/home" }
end)

return app
