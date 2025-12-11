local M = {}

local marks = {
  "x",
  "<",
  "d",
  "c",
  "k",
  "w",
  "p",
  "b",
  "I",
  "i",
  "-",
  "/",
  "u",
  "*",
  "?",
  "l",
  "f",
  "\""
}
local function index_of(list, value)
  for i, v in ipairs(list) do
    if v == value then return i end
  end
  return 1
end

local function todo_toggle()
  local line = vim.api.nvim_get_current_line()
  line = line:gsub("%- %[(.)%]", function(mark)
    return "- " .. (mark ~= " " and "[ ]" or "[x]")
  end)
  vim.api.nvim_set_current_line(line)
end

local function _todo_next(inc)
  local line = vim.api.nvim_get_current_line()
  line = line:gsub("%- %[(.)%]", function(mark)
    local next = index_of(marks, mark) + inc
    local next = index_of(marks, mark) + inc

    if next < 1 then
      next = #marks
    elseif next > #marks then
      next = 1
    end

    return "- " ..  "[" .. marks[next] .. "]"
  end)
  vim.api.nvim_set_current_line(line)
end
local function todo_next() _todo_next(1) end
local function todo_prev() _todo_next(-1) end

function M.setup()
  if _initialized then return end
  _initialized = true


  vim.api.nvim_create_user_command("TodoToggle", todo_toggle, {})
  vim.api.nvim_create_user_command("TodoNext", todo_next, {})
  vim.api.nvim_create_user_command("TodoPrev", todo_prev, {})

  vim.keymap.set("n", "<leader>tt", "<cmd>TodoToggle<CR>", { desc = "Toggle a TODO", silent = true, noremap = true })
  vim.keymap.set("n", "<C-p>", "<cmd>TodoPrev<CR>", { desc = "Prev a TODO mark", silent = true, noremap = true })
  vim.keymap.set("n", "<C-n>", "<cmd>TodoNext<CR>", { desc = "Next a TODO mark", silent = true, noremap = true })
end
return M

-- [k]
