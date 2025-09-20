-- sqldb.lua
local sqlite3 = _G.sqlite3
local json = _G.json
local client = _G.client
local discordia = _G.discordia

local db_filename = "data.db"
local conn = sqlite3.open(db_filename)

-- Data Tables --

conn:exec([[
  CREATE TABLE IF NOT EXISTS guild_configs (
    guild_id TEXT PRIMARY KEY,
    config TEXT
  );
]])

-- End Data Tables --

local sqldb = {}

local DEFAULT_CONFIG = {
    prefix = "!",
    disabledcommands = {},

    modules = {
        staff_management = {
            enabled = false,
            infraction_types = nil,
            infraction_embed = nil,
            infraction_channel = nil
        },
    }
}

-- Helper Functions --
local function encode_table(data)
  local succ, encoded = pcall(function()
    return json.encode(data)
  end)

  if succ then
    return encoded
  else
    return "{}"
  end
end
local function decode_table(data)
  local succ, decoded = pcall(function()
    return json.decode(data)
  end)

  if succ then
    return decoded
  else
    return {}
  end
end
local function transform_table(input, donotdecode)
  if not input or type(input) ~= "table" then
      return {}
  end

  local result = {}
  local header = input[0]

  if not header then
      return {}
  end

  for i, key in pairs(header) do
      local data_row = input[i]
      
      if data_row and #data_row > 0 then
          for i2, value in pairs(data_row) do
              result[i2] = result[i2] or {}
              result[i2][key] = value
          end
      end
  end

  if not donotdecode then
      for i, table in pairs(result) do
          for key, value in pairs(table) do
              if type(value) == "string" then
                  if value:sub(1, 1) == "[" or value:sub(1, 1) == "{" then
                      local decoded, _, err = json.decode(value)
                      if not err then
                          table[key] = decoded
                      else
                          print("DEBUG: JSON decode failed for", key, "with value:", value)
                      end
                  end
              end
          end
      end
  end

  return result
end
local function deepMerge(defaults, target)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            deepMerge(v, target[k])
        elseif target[k] == nil then
            target[k] = v
        end
    end
end
-- End Helper Functions

-- Guild Config Functions --

function sqldb:set(guild_id, changes_table, reason)
  if not guild_id or type(guild_id) ~= "string" or not tonumber(guild_id) then
    return false, "guild_id was invalid or not provided"
  end

  if not changes_table or type(changes_table) ~= "table" or next(changes_table) == nil then
    return false, "changes_table was invalid or not provided"
  end

  local config = sqldb:get(guild_id) or {}

  for key, value in pairs(changes_table) do
    if value == "nil" then
      config[key] = nil
    else
      config[key] = value
    end
  end

  local json_value = encode_table(config)

  if not json_value then
    return false, "json_value is invalid_1"
  elseif type(json_value) ~= "string" then
    return false, "json_value is not a string"
  end

  if not reason or type(reason) ~= "string" then
    return false, "reason was invalid or not provided"
  end

  local stmt = conn:prepare("INSERT OR REPLACE INTO guild_configs (guild_id, config) VALUES (?, ?)")
  if not stmt then
    return false, "Failed to prepare statement"
  end

  stmt:reset()
  stmt:bind(guild_id, json_value)
  stmt:step()
  
  return true, config
end

function sqldb:get(guild_id)
  if not guild_id or type(guild_id) ~= "string" or not tonumber(guild_id) then
    return false, "guild_id was invalid or not provided"
  end

  local result = conn:exec("SELECT config FROM guild_configs WHERE guild_id = '" .. guild_id .. "';")

  if result and result[1] then
    return decode_table(result[1][1])
  else
    return nil
  end
end

function sqldb:getAllGuildConfigs()
  local result = conn:exec("SELECT guild_id, config FROM guild_configs;")

  if not result then
    return {}, "Failed"
  end

  local rawGuildsConfig = transform_table(result)
  local guildConfigs = {}

  for id, data in pairs(rawGuildsConfig) do
    local config = data.config
    if config then
      guildConfigs[data.guild_id] = config
    else
      print(data.guild_id .. " doesn't have config.")
    end
  end

  return guildConfigs
end

function sqldb:registerGuild(guild_id)
    local config = sqldb:get(guild_id)

    if type(config) ~= "table" then
        config = table.clone(DEFAULT_CONFIG)
        local succ, res = sqldb:set(guild_id, config, "REGISTER_GUILD")
        if succ then
            config = res
        end
    else
        deepMerge(DEFAULT_CONFIG, config)
        sqldb:set(guild_id, config, "MERGE_DEFAULTS")
    end

    return true, config
end

function sqldb:delete(guild_id)
  local start = os.time()
  local query = "DELETE FROM guild_configs WHERE guild_id = '" .. guild_id .. "';"
  local _, result = conn:exec(query)

  if result == 0 then
    return true
  else
    return false, "Error deleting configuration: " .. result
  end
end

-- End Guild Config Functions --

function sqldb:close()
  conn:close()
end

return sqldb