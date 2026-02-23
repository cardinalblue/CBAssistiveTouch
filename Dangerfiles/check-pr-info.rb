$PREFIXES = {
    build: "Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)",
    ci: "Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)",
    docs: "Documentation only changes",
    feat: "A new feature",
    fix: "A bug fix",
    perf: "A code change that improves performance",
    refactor: "A code change that neither fixes a bug nor adds a feature",
    style: "Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)",
    test: "Adding missing tests or correcting existing tests",
}

# Returns an error for a title without a proper prefix
def get_title_prefix_error(title)
    matched = title.match(/^([a-z]+): /)
    prefix = matched[1].to_sym unless matched.nil?
    return if $PREFIXES.keys().include?(prefix)

    example = "prefix: title"
    prefix_table = $PREFIXES.map { |k, v| "- `#{k}` - #{v}" }.join("\n")
    return "Please follow the PR title format:
```
#{example}
```
Please find a prefix that best describes your code changes:
#{prefix_table}"
end

def is_potential_umbrella?
    # Get the commit titles on the branch
    base, head = github.base_commit, github.head_commit
    titles = `git log --format='%s' #{base}..#{head}`.split("\n")

    # Count the commit titles that have the PR number suffix
    pr_count = titles.count { |title| title.match(/ \(#\d+\)$/) }
    commit_count = titles.count

    # If most commit titles are associated with PRs, it's possibly an umbrella branch
    return pr_count / commit_count.to_f >= 0.5
end

def umbrella
    "⛱️ umbrella"
end

def is_umbrella?
    github.pr_labels.include?(umbrella)
end

def get_potential_umbrella_warning
    return unless is_potential_umbrella? && is_umbrella? == false

    return "This PR looks like an umbrella PR. Add the umbrella label if it is; ignore the warning if you plan to squash merge this PR."
end

def get_umbrella_warning
    return unless is_umbrella?

    return "This PR is marked as `#{umbrella}` that targets at rebasing onto the main branch.

Keep every single commit informative of ticket IDs or PR numbers.
Please ensure you merge this branch by **REBASE MERGE** to preserve all the commits in the history.
```
d8888b. d88888b d8888b.  .d8b.  .d8888. d88888b     .88b  d88. d88888b d8888b.  d888b  d88888b
88  `8D 88'     88  `8D d8' `8b 88'  YP 88'         88'YbdP`88 88'     88  `8D 88' Y8b 88'
88oobY' 88ooooo 88oooY' 88ooo88 `8bo.   88ooooo     88  88  88 88ooooo 88oobY' 88      88ooooo
88`8b   88~~~~~ 88~~~b. 88~~~88   `Y8b. 88~~~~~ C8D 88  88  88 88~~~~~ 88`8b   88  ooo 88~~~~~
88 `88. 88.     88   8D 88   88 db   8D 88.         88  88  88 88.     88 `88. 88. ~8~ 88.
88   YD Y88888P Y8888P' YP   YP `8888Y' Y88888P     YP  YP  YP Y88888P 88   YD  Y888P  Y88888P
```"
end

# -- main -- #

error = get_title_prefix_error(github.pr_title)
fail(error) unless error.nil?

warning = get_potential_umbrella_warning
warn(warning) unless warning.nil?

warning = get_umbrella_warning
warn(warning) unless warning.nil?
