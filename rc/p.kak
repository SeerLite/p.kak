declare-option -hidden str-list p_plugins_all
declare-option -hidden str-list p_plugins_unloaded
declare-option str p_plugin_dir "%val{config}/plugins"
declare-option bool p_fail_on_missing true

define-command p-plugin -params 1..2 %{
	set-option -add global p_plugins_all %arg{1}
	set-option -add global p_plugins_unloaded %arg{1}
	hook global -group p-kak User "p_plugin_loaded=%arg{1}" %arg{2}
}

define-command p-plugin-mod -params 2..3 %{
	hook global -group p-kak User "p_plugin_loaded=%arg{2}" "require-module %arg{1}"
	p-plugin %arg{2} %arg{3}
}

define-command p-load %{
	evaluate-commands %sh{
		mkdir -p "$kak_opt_p_plugin_dir"
		cd "$kak_opt_p_plugin_dir"
		for plugin_source in $kak_opt_p_plugins_unloaded; do
			plugin_name="${plugin_source##*/}"
			plugin_name="${plugin_name%.git}"

			if [ -d "$plugin_name" ]; then
				plugins_to_load="$plugins_to_load $plugin_name"
				finish_cmd="$finish_cmd; set-option -remove global p_plugins_unloaded $plugin_source"
				finish_cmd="$finish_cmd; trigger-user-hook p_plugin_loaded=$plugin_source"
			else
				if [ "$kak_opt_p_fail_on_missing" = "true" ]; then
					printf "fail \"'%s' not found in '%s'. Install it with p_install first.\"\n" \
						"$plugin_name" "$kak_opt_p_plugin_dir"
					exit
				fi
			fi
		done

		# execute all commands at once
		if [ -n "$plugins_to_load" ]; then
			fd -uu -t f '\.kak$' $plugins_to_load 2> /dev/null | sed "s|.*|source \"$kak_opt_p_plugin_dir/&\"|"
			printf '%s' "$finish_cmd"
		fi
	}
}

# TODO: p_install, p_update, p_clean
define-command p-install %{
	evaluate-commands %sh{
		mkdir -p "$kak_opt_p_plugin_dir"
		cd "$kak_opt_p_plugin_dir"
		for plugin_source in $kak_opt_p_plugins_all; do
			plugin_name="${plugin_source##*/}"
			plugin_name="${plugin_name%.git}"
			git clone "$plugin_source" "$plugin_name"
		done
	}
}
