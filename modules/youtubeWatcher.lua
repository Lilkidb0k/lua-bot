local youtubeWatcher = {
    name = "YouTubeWatcher",
    description = "Watches a YouTube channel for new uploads and announces them in Discord."
}

local Clock = discordia.Clock()
Clock:start()

local CHANNEL_ID = "UCbAw6Ka_R1YAbJyxU0Pngiw"
local DISCORD_CHANNEL_ID = "1426210622990712953"
local CHECK_INTERVAL = 30
local API_KEY = _G.SECRETS.youtube_api_key

local connection = nil
local lastVideoId = nil
local lastCheck = 0
local active = false

local function getUploadsPlaylistId()
    local url = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails&id=" .. CHANNEL_ID .. "&key=" .. API_KEY
    local res, body = http.request("GET", url)
    if res.code ~= 200 then return nil end
    local data = json.decode(body)
    return data.items[1].contentDetails.relatedPlaylists.uploads
end

local function checkYouTube()
    local playlistId = getUploadsPlaylistId()
    if not playlistId then
        print("[YouTubeWatcher] Failed to get uploads playlist.")
        return
    end

    local url = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=" .. playlistId .. "&maxResults=1&key=" .. API_KEY
    local res, body = http.request("GET", url)
    if res.code ~= 200 then
        print("[YouTubeWatcher] Failed to fetch latest video.")
        return
    end

    local data = json.decode(body)
    local item = data.items[1]
    local videoId = item.snippet.resourceId.videoId
    local title = item.snippet.title

    if videoId and videoId ~= lastVideoId then
        lastVideoId = videoId
        local videoUrl = "https://www.youtube.com/watch?v=" .. videoId

        local channel = client:getChannel(DISCORD_CHANNEL_ID)
        if channel then
            channel:send("**New Video Uploaded!**\n**" .. title .. "**\n" .. videoUrl)
            print("[YouTubeWatcher] Announced new video:", title)
        end
    end
end

youtubeWatcher.Start = function()
    if connection then return end

    connection = Clock:on("sec", function()
        coroutine.wrap(function()
            if active or (os.time() - lastCheck) < CHECK_INTERVAL then return end
            active = true
            lastCheck = os.time()
            pcall(checkYouTube)
            active = false
        end)()
    end)
end

youtubeWatcher.Stop = function()
    if not connection then return end
    Clock:removeListener("sec", connection)
    connection = nil
end

return youtubeWatcher