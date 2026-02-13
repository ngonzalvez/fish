function setenv
    set project $argv[1]
    set environment $argv[2]

    if test -z "$project"
        echo "Usage: setenv <project> [environment]"
        return 1
    end

    if test -z "$environment"
        set environment development
    end

    set repo_root (git rev-parse --show-toplevel 2>/dev/null)
    or begin
        echo "Not inside a git repository"
        return 1
    end

    set source "$HOME/.envs/$project/.env.$environment"
    set target "$PWD/.env.local"

    if not test -f $source
        echo "Source env file not found: $source"
        return 1
    end

    ln -sf $source $target
    echo "Linked $target → $source"
end
