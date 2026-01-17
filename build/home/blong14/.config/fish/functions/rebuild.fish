function rebuild
    source (dirname (status --current-filename))/_nomad_helpers.fish

    if not __nomad_parse_args "rebuild" $argv
        return 1
    end

    $nflask

	__nomad_print_header "rebuilding nomad environment" "purple"
    
    git pull
    # Ensure virtual environment is active
    __nomad_ensure_venv

	__nomad_print_header "install dependencies 1/2" "green"
    pip install -r pip-requirements.txt

	__nomad_print_header "install dependencies 2/2" "green"
    pipenv install --dev --system --verbose

	__nomad_print_header "rebuilding containers" "blue"
    make build
end
