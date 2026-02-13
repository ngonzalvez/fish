# Git Worktree Management Functions
# =================================
# These functions manage git worktrees for parallel development on multiple branches.
# Worktrees are created as sibling directories to the main repo (e.g., ../feature-branch).
# They share node_modules and docs via symlinks to avoid duplicate installs.

# Opens an existing worktree in Cursor.
# Fails if the worktree doesn't exist - use `wt` for auto-create behavior.
function open-wt
    if test (count $argv) -lt 1
        echo "Usage: open-wt <branch-name>"
        return 1
    end

    set branch $argv[1]
    set root (git rev-parse --show-toplevel 2>/dev/null)

    if test -z "$root"
        echo "Not inside a git repository"
        return 1
    end

    set path $root/../$branch

    if not test -e $path
        echo "Worktree does not exist: $path"
        return 1
    end

    cd $path
    cursor $path &> /dev/null
end

# Creates a new worktree and sets up the development environment.
# - Pulls latest main first
# - Creates worktree at ../<branch-name> relative to repo root
# - If branch doesn't exist locally, fetches from origin
# - If branch doesn't exist on origin either, creates it via `gt create`
# - Symlinks node_modules from main repo (avoids re-installing deps)
# - Symlinks .docs directory
# - Runs setenv to configure environment variables
# - Opens Cursor in the new worktree
function create-wt
    if test (count $argv) -lt 1
        echo "Usage: create-wt <branch-name>"
        return 1
    end

    set branch $argv[1]
    set root (git rev-parse --show-toplevel 2>/dev/null)

    git checkout main
    git fetch
    git pull origin main


    if test -z "$root"
        echo "Not inside a git repository"
        return 1
    end

    set path $root/../$branch

    if test -e $path
        echo "Worktree already exists: $path"
        return 1
    end

    # If the branch doesn't exist locally or on origin, create it with Graphite
    if not git show-ref --verify --quiet refs/heads/$branch
        if not git show-ref --verify --quiet refs/remotes/origin/$branch
            echo "Branch not found locally or on origin, creating with gt..."
            gt create $branch; or return 1
            # Switch back to main so the branch isn't "in use" in this worktree
            git checkout main
        end
    end

    git worktree add $path $branch; or return 1

    # Symlink shared directories to avoid duplicate dependencies
    rm -rf $path/.docs
    ln -s $root/.docs $path/.docs

    cd $path
    set repo_name (basename $root)

    if -d $path/apps/web
        cd $path/apps/web
        setenv $repo_name development
        cd ../../
    else
        setenv $repo_name development
    end

    setenv $repo_name development

    # Install dependencies
    if grep -q '"install:deps"' package.json 2>/dev/null
        bun run install:deps
    else
        bun install
    end

    cursor $path &> /dev/null
end

# Main worktree command - opens existing or creates new.
# This is the recommended entry point for daily use.
# Example: `wt feature-auth` will open the worktree if it exists,
# or create it with full setup if it doesn't.
function wt
    if test (count $argv) -lt 1
        echo "Usage: wt <branch-name>"
        return 1
    end

    set branch $argv[1]
    set root (git rev-parse --show-toplevel 2>/dev/null)

    if test -z "$root"
        echo "Not inside a git repository"
        return 1
    end

    set path $root/../$branch

    if test -e $path
        open-wt $branch
    else
        create-wt $branch
    end

    cd $root && git checkout main
end
