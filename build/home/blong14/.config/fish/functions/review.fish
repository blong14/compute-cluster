function review
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
    
    set message " \
You are a senior software engineer and you need to review the following code
changes. Please review these changes for potential issues, performance problems,
and code quality improvements. We value brevity and simplicity over everything
else. If the change is big or complicated, stop and present the user with an itemized summary
of the changes that are needed and ask for explicit permission to proceed before proceeding.

You should perform these assessments:

1. Idiomaticity: Check if the code follows best practices and conventions for
the programming language used.

2. Performance: Identify any potential performance bottlenecks or inefficiencies
in the code.

3. Security: Look for any security vulnerabilities or risks in the code.

4. Readability: Assess the code for clarity, maintainability, and overall
readability.

Here are the code changes to review:

$diff
"
    aider \
        --no-auto-commits \
        --no-auto-lint \
        --no-gitignore \
        --no-restore-chat-history \
        --env /Users/blong14/Developer/git/compute-cluster/.env \
        $changes \
        -m "$message"
end

