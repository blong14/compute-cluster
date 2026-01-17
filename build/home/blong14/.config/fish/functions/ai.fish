function ai --description 'Pass file context and a message to aider AI'
    # Base options for aider
    set -l aider_opts --yes-always --no-auto-commits --env ~/Developer/git/compute-cluster/.env --architect --watch --no-gitignore --stream --no-restore-chat-history

    # Check for arguments
    if test (count $argv) -eq 0
        echo "Usage: ai [file] <message>" >&2
        return 1
    end

    set -l file_arg
    set -l message_arg

    # Check if the first argument is a file
    if test -f "$argv[1]"
        set file_arg $argv[1]
        # The second argument is the message
        if set -q argv[2]
            set message_arg $argv[2]
        end
    else
        # If not a file, the first argument is the message
        set message_arg $argv[1]
    end

    # A message is always required
    if not set -q message_arg
        echo "Error: A message is required." >&2
        echo "Usage: ai <file> <message>" >&2
        return 1
    end

    # Construct and run the command
    if set -q file_arg
        command aider $aider_opts $file_arg --message "$message_arg"
    else
        command aider $aider_opts --message "$message_arg"
    end
end
