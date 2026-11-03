local M = {}

-- Reads a token file (first line, trimmed). Keeps secrets out of the process env.
function M.read(path)
  if not path then return nil end
  local f = io.open(vim.fs.normalize(path), "r")
  if not f then return nil end
  local token = vim.trim(f:read("*a"))
  f:close()
  return token ~= "" and token or nil
end

local function token(name)
  return M.read(vim.env[name .. "_FILE"]) or vim.env[name]
end

-- Defaults from env; per project override in <project>/.nvim.lua (exrc, needs :trust once):
--   local atlas = require("atlas_setup")
--   atlas.setup({ providers = { jira = { base_url = "https://foo.atlassian.net", token = atlas.read("~/.secrets/foo-jira") } } })
-- Providers without base_url are dropped so they don't show up half-configured.
function M.setup(overrides)
  local opts = vim.tbl_deep_extend("force", {
    providers = {
      forgejo = { base_url = vim.env.FORGEJO_URL, token = token("FORGEJO_TOKEN") },
      jira = {
        base_url = vim.env.JIRA_URL,
        email = vim.env.JIRA_EMAIL,
        token = token("JIRA_TOKEN"),
        api_type = vim.env.JIRA_API_TYPE,       -- "cloud" (default) | "server"
        auth_method = vim.env.JIRA_AUTH_METHOD, -- "basic" (default) | "bearer"
      },
    },
  }, overrides or {})
  for name, p in pairs(opts.providers) do
    if not p.base_url then opts.providers[name] = nil end
  end
  require("atlas").setup(opts)
end

return M
