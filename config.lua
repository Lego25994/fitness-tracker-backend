local config = require("lapis.config")

config("development", {
  session_name = "hot_dog_fitness_session",
  secret = "VERY SECRET KEEP OUT DONT TOUCH",
  postgres = {
    host = "127.0.0.1",
    user = "postgres",
    password = "",
    database = "hot_dog_fitness"
  }
})
