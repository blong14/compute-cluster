# This file should be in the same directory as your other fish functions.
# It contains helper functions to reduce duplication.

# Parses common arguments for nomad scripts.
# Usage: __nomad_parse_args "function_name" $argv
function __nomad_parse_args
    argparse --name $argv[1] \
        'h/help' \
        'a/activate-path=' \
        'c/compose-path=' \
        -- $argv[2..-1]
    or return 1

    # Promote local argparse flags to global scope and set defaults.
    # This makes them available to the calling function and other helpers.
    set -g _flag_activate_path (set -q _flag_activate_path; and echo $_flag_activate_path; or echo $nflask/workspace/nomad-flask/bin/activate.fish)
    set -g _flag_compose_path (set -q _flag_compose_path; and echo $_flag_compose_path; or echo $nflask/compose.yaml)
    
    # Display help if requested
    if set -q _flag_help
        __fish_print_help $argv[1]
        return 1
    end

    return 0
end

# Ensures the virtual environment is active by printing the `source` command
# for the caller to evaluate. This works around function scoping issues with `source`.
# Relies on _flag_activate_path being set by __nomad_parse_args.
function __nomad_ensure_venv
    if not test -n "$VIRTUAL_ENV"
		__nomad_print_header "init virtual environment" "blue"
		source $_flag_activate_path
		__nomad_print_header "virtual environment @ $_flag_activate_path" "blue"
	end
end

# Prints a formatted header.
# Usage: __nomad_print_header "My message" "color"
function __nomad_print_header
    echo (set_color $argv[2])\n[+] $argv[1]\n
end
