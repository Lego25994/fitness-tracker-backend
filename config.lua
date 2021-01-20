local config = require("lapis.config")

function getenv(name, default)
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
    host = getenv("DATABASE_HOST", "127.0.0.1"),
    user = getenv("DATABASE_USER", "postgres"),
    password = getenv("DATABASE_PASSWORD", ""),
    database = getenv("DATABASE_DATABASE", "hot_dog_fitness")
  }
})
