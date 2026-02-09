function setenv
    set environment $argv[1]

    if test -z "$environment"
	set environment development
    end

    set repo_root (git rev-parse --show-toplevel 2>/dev/null)
    or begin
        echo "Not inside a git repository"
        return 1
    end

    set repo_name (basename $repo_root)
    set source "$HOME/.envs/$repo_name/.env.$environment"
    set target "$PWD/.env.local"

    if not test -f $source
        echo "Source env file not found: $source"
        return 1
    end

    ln -sf $source $target
    echo "Linked $target → $source"
end