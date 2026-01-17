function pr
    set branch (git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
    if test -z "$branch"
        echo "Failed to detect the mainline Git branch. Please check your Git setup."
        return 1
    end

    set changes (git diff --name-only origin/$branch)
    if test -z "$changes"
        echo "No changes to summarize for pull request."
        return 0
    end
    
    set diff (git diff origin/$branch)
    
    set message \
        "You are a senior software engineer, please help " \
        "me write a concise summary of the following code changes for " \
        "a pull request.\n" \
        "The summary should explain what is being added in this feature.\n" \
        "$diff"
    
    aider \ 
        --no-auto-commits \
        --no-auto-lint \
        --no-gitignore \
        --no-restore-chat-history \
        --env /Users/blong14/Developer/git/compute-cluster/.env \
        $changes \
        -m "$message"
end
