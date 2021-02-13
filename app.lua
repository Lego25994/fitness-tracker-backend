local bcrypt = require("bcrypt")
local lapis = require("lapis")
local db = require("lapis.db")
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
  self.challenges_to = challenges:select(
        "where to_id = ? and completed_at is null and canceled_at is null",
        self.session.current_user_id)
  self.challenges_from = challenges:select(
        "where from_id = ? and completed_at is null and canceled_at is null",
        self.session.current_user_id)
  self.challenges_all = challenges:select()
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

app:get("/leaderboard", function(self)
  if not self.session.current_user_id then
    return { redirect_to = "/" }
  else
    local challenges = challenges:select()
    local map = {}
    self.leaderboard = {}
    local leaderboard = self.leaderboard
    -- 1. step through 'challenges',  assembling a map of users to number of completed
    --    challenges
    -- 2. sort the list based on number of challenges completed
    -- 3. stick the results into another table, in order
    for i, challenge in ipairs(challenges) do
      if challenge.completed_at then
        if not map[challenge.to_id] then
          map[challenge.to_id] = 0
        end
        map[challenge.to_id] = map[challenge.to_id] + 1
      end
    end
    for user, finished in pairs(map) do
      local place = 1
      for i=1, #leaderboard, 1 do
        if leaderboard[i].finished > finished then
          place = place + 1
        end
      end
      table.insert(leaderboard, place, {user = users:select("where id = ?", user)[1].username, finished = finished})
    end
    return { render = "leaderboard" }
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
      challenge = challenge,
      created_at = db.format_date()
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
  challenge.completed_at = db.format_date()
  challenge:update("completed_at")
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
  challenge.canceled_at = db.format_date()
  challenge:update("canceled_at")
  self.session.status_message = "challenge canceled!"
  return { redirect_to = "/home" }
end)

return app
