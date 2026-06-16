if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -g fish_greeting

set -gx PATH "$HOME/.local/bin" $PATH

starship init fish | source
zoxide init fish | source

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

abbr -a onedrive "/usr/bin/rclone mount --vfs-cache-mode full onedrive: $HOME/OneDrive --daemon"
abbr -a gdrive "/usr/bin/rclone mount --vfs-cache-mode full gdrive: $HOME/GDrive --daemon"

abbr -a proxy "set -gx http_proxy http://127.0.0.1:7890; set -gx https_proxy http://127.0.0.1:7890; set -gx HTTP_PROXY http://127.0.0.1:7890; set -gx HTTPS_PROXY http://127.0.0.1:7890"

abbr -a mtu "sudo sysctl -w net.ipv4.tcp_mtu_probing=1"
