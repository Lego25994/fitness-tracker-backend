local config = require("lapis.config")

function cfg_getenv(name, default)
  local val = os.getenv(name)
  if not val then
    return default
  else
    return val
  end
end

config("development", {
  session_name = "hot_dog_fitness_session",
  secret = "VERY SECRET KEEP OUT DONT TOUCH",
  postgres = {
    host = cfg_getenv("DATABASE_HOST", "127.0.0.1"),
    user = cfg_getenv("DATABASE_USER", "postgres"),
    password = cfg_getenv("DATABASE_PASSWORD", ""),
    database = cfg_getenv("DATABASE_DATABASE", "hot_dog_fitness")
  }
})
