local DeviceUid = require("kong.plugins.base_plugin"):extend()
local uuid = require("kong.tools.utils").uuid
local ck = require "resty.cookie"

local function cookieTableHeader(cookieTable)
  local t = {}
  for k, v in pairs(cookieTable) do
    table.insert(t, k .. "=" .. v .. "; ")
  end
  return table.concat(t)
end

local function startsWith(str, start)
  return string.sub(str, 1, string.len(start)) == start
end

local function setClientCookie(data, onlyIfMissing)
  local position = nil
  local cookiePrefix = data.key .. "="
  local cookieHeader = ngx.header['Set-Cookie'] or {}
  if type(cookieHeader) == "string" then
    cookieHeader = { cookieHeader }
  end

  for k, v in pairs(cookieHeader) do
    if startsWith(v, cookiePrefix) then
      position = k
      break
    end
  end

  if position ~= nil and onlyIfMissing then
    return
  end

  if position then
    table.remove(cookieHeader, position)
    ngx.header['Set-Cookie'] = cookieHeader
  end

  local cookie, err = ck:new()
  if not cookie then
    ngx.log(ngx.ERR, "Cookie Error " .. err)
    return
  end

  local ok, err = cookie:set(data)
  if not ok then
    ngx.log(ngx.ERR, "cookie:set " .. data.key .. " Error: " .. err)
    return
  end
end

local function shouldCreateDeviceUidCookie (cookieName)
  local cookies, err = ck:new()
  if not cookies then
    ngx.log(ngx.ERR, "Unable to access cookies " .. err)
    return false
  end

  local deviceUidCookie, err = cookies:get(cookieName)
  if deviceUidCookie and deviceUidCookie ~= "" then
    return false
  end

  local allCookies, err = cookies:get_all()
  if err or not allCookies then
    allCookies = {}
  end

  deviceUidCookie = uuid()
  if not deviceUidCookie or deviceUidCookie == "" then
    return false
  end
  allCookies[cookieName] = deviceUidCookie

  -- Rewrite the request Cookie header
  ngx.req.set_header("Cookie", cookieTableHeader(allCookies))

  return true
end

local function setCookies (cookieName)
  if not ngx.var.shouldCreateDeviceUid then
    return
  end

  local cookie, err = ck:new()
  if not cookie then
    ngx.log(ngx.ERR, "Cookie Error " .. err)
    return
  end

  local deviceUidCookie, err = cookie:get(cookieName)
  if err or not deviceUidCookie or deviceUidCookie == "" then
    return
  end

  local cookieDomain
  if ngx.var.http_host == "localhost:80" or ngx.var.http_host == "localhost:8080" then
    cookieDomain = "localhost"
  else
    local extractedDomain = ngx.var.http_host:match("([%w%-_]+%.-%w+)[%:%d+]-$")
    if not extractedDomain then
      ngx.log(ngx.ERR, "Fail 3")
      return
    end
    cookieDomain = "." .. extractedDomain
  end

  setClientCookie({
    key = cookieName,
    value = uuid(),
    path = "/",
    domain = cookieDomain,
    max_age = 31536000
  }, true)
end

function DeviceUid:new()
    DeviceUid.super.new(self, "deviceuid")
end

function DeviceUid:access(config)
  DeviceUid.super.rewrite(self)

  ngx.var.shouldCreateDeviceUid = shouldCreateDeviceUidCookie(config.cookie_name)
end

function DeviceUid:header_filter(config)
  DeviceUid.super.header_filter(self)

  setCookies(config.cookie_name)
end

DeviceUid.PRIORITY = 1001

return DeviceUid
