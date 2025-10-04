-- loader.lua (substitua o atual por este)
local HttpService = game:GetService and game:GetService("HttpService")
local GITHUB_RAW = "https://raw.githubusercontent.com/xt-el/my-project/main/"

local function fetch(url)
    if syn and syn.request then
        local r = syn.request({ Url = url, Method = "GET" })
        return r.Body
    elseif request then
        local r = request({ Url = url, Method = "GET" })
        return r.Body
    elseif http and http.request then
        return http.request("GET", url)
    elseif game and game:HttpGet then
        return game:HttpGet(url)
    end
    error("Nenhuma função HTTP disponível no executor. Edite fetch() no loader.")
end

local manifest_raw = fetch(GITHUB_RAW .. "manifest.json")
local ok, manifest = pcall(function() return HttpService:JSONDecode(manifest_raw) end)
if not ok then error("Erro ao decodificar manifest.json: "..tostring(manifest)) end

-- API base que passamos aos módulos
local loader_api = {
    register_command = function(name, fn)
        _G.__MOD_COMMANDS = _G.__MOD_COMMANDS or {}
        _G.__MOD_COMMANDS[name] = fn
    end,
    print = function(...) print("[loader]", ...) end,
    fetch_raw = fetch,
    utils = {},
    Services = {
        TweenService = game:GetService("TweenService"),
        RunService   = game:GetService("RunService"),
        Workspace    = game:GetService("Workspace"),
        Players      = game:GetService("Players"),
        Debris       = game:GetService("Debris")
    }
}

-- carrega módulos em ordem (manifest.modules é um array)
for i, meta in ipairs(manifest.modules or {}) do
    local path = meta.path
    loader_api.print("Baixando módulo:", meta.name or path)
    local body = fetch(GITHUB_RAW .. path)
    if not body then
        warn("Falha ao baixar: "..tostring(path))
    else
        local fn, err = load(body, "="..path)
        if not fn then
            warn("Erro ao compilar "..path..": "..tostring(err))
        else
            local ok, mod = pcall(fn)
            if not ok then
                warn("Erro ao executar módulo "..path..": "..tostring(mod))
            elseif type(mod) == "table" and type(mod.init) == "function" then
                local succ, err2 = pcall(mod.init, loader_api)
                if not succ then warn("Erro em init de "..path..": "..tostring(err2)) end
                loader_api.print("Módulo carregado:", meta.name or path, "v"..(mod.version or meta.version or "?.?.?"))
            else
                warn("Módulo "..path.." não retornou tabela com init(api).")
            end
        end
    end
end

-- helper de debug para comandos registrados
_G.run_command = function(name, ...)
    local cmd = _G.__MOD_COMMANDS and _G.__MOD_COMMANDS[name]
    if cmd then
        local ok, res = pcall(cmd, ...)
        if ok then return res end
        return nil, res
    else
        return nil, "Comando não encontrado"
    end
end

loader_api.print("Loader finalizado.")
