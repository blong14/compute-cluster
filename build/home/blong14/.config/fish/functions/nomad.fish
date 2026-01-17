function nomad
    source (dirname (status --current-filename))/_nomad_helpers.fish

    if not __nomad_parse_args "nomad" $argv
        return 1
    end

	$nflask

	__nomad_print_header "starting nomad environment" "purple"

    __nomad_ensure_venv

	dc -f $_flag_compose_path run --rm -it web /bin/bash --rcfile /nomad_app/.bashrc -i

	__nomad_print_header "stopping nomad environment" "green"
end
