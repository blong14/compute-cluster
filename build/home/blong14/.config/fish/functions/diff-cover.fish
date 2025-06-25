function diff-cover --description "Run diff-cover in the nomad environment"
    source (dirname (status --current-filename))/_nomad_helpers.fish

    if not __nomad_parse_args "diff-cover" $argv
        return 1
    end

    $nflask

    __nomad_print_header "starting nomad environment for diff-cover" "purple"

    __nomad_ensure_venv

	dc -f $_flag_compose_path run --rm -v $nflask/workspace/diff-cover.sh:/app/workspace/diff-cover.sh --entrypoint=/app/workspace/diff-cover.sh web 

	__nomad_print_header "stopping nomad environment" "green"
end
