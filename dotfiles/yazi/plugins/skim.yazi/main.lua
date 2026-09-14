local M = {}

local state = ya.sync(function()
	local selected = {}
	for _, url in pairs(cx.active.selected) do
		selected[#selected + 1] = url
	end
	return cx.active.current.cwd, selected
end)

function M:entry()
	ya.emit("escape", { visual = true })

	local cwd, selected = state()
	if cwd.scheme.is_virtual then
		return ya.notify { title = "Fzf", content = "Not supported under virtual filesystems", timeout = 5, level = "warn" }
	end

	local permit = ui.hide()
	local output, err = M.run_with(cwd, selected)

	permit:drop()
	if not output then
		return ya.notify { title = "Fzf", content = tostring(err), timeout = 5, level = "error" }
	end

	local urls = M.split_urls(cwd, output)
	if #urls == 1 then
		local cha = #selected == 0 and fs.cha(urls[1])
		ya.emit(cha and cha.is_dir and "cd" or "reveal", { urls[1], raw = true })
	elseif #urls > 1 then
		urls.state = #selected > 0 and "off" or "on"
		ya.emit("toggle_all", urls)
	end
end

---@param cwd Url
---@param selected Url[]
---@return string?, Error?
function M.run_with(cwd, selected)
    local cmd = Command("sk")
    
    -- 定义参数列表
    local args = {
        "--multi",
        "--preview", "bat -n --color=always {}",
        "--bind", "ctrl-e:down,ctrl-u:up",
        "--layout", "reverse"
    }

    -- 解决 attempt to call a nil value (method 'args') 错误
    -- 遍历参数表，逐个调用 .arg()
    for _, arg in ipairs(args) do
        cmd:arg(arg)
    end

    if #selected > 0 then
        -- 如果有选中文件，通过管道喂给 sk
        cmd:stdin(Command.PIPED)
    else
        -- 如果没有选中，利用环境变量让 sk 自己启动 fd
        -- 这种方式对 TTY 最友好，能解决新版 skim 界面不显示的问题
        cmd:env("SKIM_DEFAULT_COMMAND", "fd --type f -HL --exclude .git")
           :stdin(Command.INHERIT)
    end

    local child, err = cmd
        :cwd(tostring(cwd))
        :stdout(Command.PIPED)
        :stderr(Command.INHERIT) -- 允许错误输出到终端，防止 UI 渲染被阻塞
        :spawn()

    if not child then
        return nil, Err("Failed to start `sk`, error: %s", err)
    end

    -- 处理选中文件的输入流
    if #selected > 0 then
        for _, u in ipairs(selected) do
            child:write_all(string.format("%s\n", u))
        end
        child:flush()
    end

    local output, err = child:wait_with_output()
    if not output then
        return nil, Err("Cannot read `sk` output, error: %s", err)
    elseif not output.status.success and output.status.code ~= 130 then
        return nil, Err("`sk` exited with error code %s", output.status.code)
    end
    
    return output.stdout, nil
end

function M.split_urls(cwd, output)
	local t = {}
	for line in output:gmatch("[^\r\n]+") do
		local u = Url(line)
		if u.is_absolute then
			t[#t + 1] = u
		else
			t[#t + 1] = cwd:join(u)
		end
	end
	return t
end

return M
