-- -- git.yazi --------------------------------------------------------
th.git = th.git or {}
th.git.modified_sign = ""
th.git.added_sign = "✚"
th.git.untracked_sign = ""
th.git.ignored_sign = ""
th.git.deleted_sign = ""
require("git"):setup()

-- -- restore.yazi ----------------------------------------------------
require("restore"):setup({
	position = { "center", w = 70, h = 20 }, -- Optional
})
