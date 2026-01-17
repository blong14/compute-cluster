function ai --description 'Pass file context and a message to aider AI'
    set -l aider_opts \
        --no-auto-commits \
        --no-auto-lint \
        --no-gitignore \
        --no-restore-chat-history
        --stream \
        --architect \
        --env ~/Developer/git/compute-cluster/.env

    if test (count $argv) -eq 0
        echo "Usage: ai [file] <message>" >&2
        return 1
    end

    set -l file_arg
    set -l message_arg

    if test -f "$argv[1]"
        set file_arg $argv[1]
        if set -q argv[2]
            set message_arg $argv[2]
        end
    else
        set message_arg $argv[1]
    end

    if not set -q message_arg
        echo "Error: A message is required." >&2
        echo "Usage: ai <file> <message>" >&2
        return 1
    end

    if set -q file_arg
        command aider $aider_opts $file_arg --message "$message_arg"
    else
        command aider $aider_opts --message "$message_arg"
    end
end
