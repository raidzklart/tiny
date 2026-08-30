# tiny

A Ruby bootstrapper that generates a minimal, runnable, database-backed SaaS starting point: Sinatra, Sequel, SQLite, Phlex, HTMX. One command: `tiny new myapp`.

## Requirements

- Ruby 3.1+ and Bundler
- No Node.js, no npm, no frontend build step

## Install

tiny is a plain executable plus the templates beside it; there is no gem to install.

    git clone https://github.com/raidzklart/tiny.git
    export PATH="$PWD/tiny/exe:$PATH"   # or symlink exe/tiny into your PATH

## Usage

    tiny new myapp

Creates `myapp/` containing exactly three files: `app.rb`, `Gemfile`, `.gitignore`.
Then it runs `bundle install`, `git init`, and one initial commit, and prints the
start command.

    cd myapp && ruby app.rb    # → http://localhost:4567

- `/` — a generic SaaS dashboard shell
- `/showcase` — every component with its variants and states
- `/app.css`, `/app.js` — the combined assets (no `public/` directory)

The SQLite database (`app.sqlite3`) is created inside the project on first boot.

### Flags

- `--skip-install` — skip `bundle install`
- `--skip-git` — skip `git init` and the initial commit

### Other commands

- `tiny help` / `tiny --help` — show usage

## Repository layout

    exe/tiny       the bootstrapper
    templates/     the three files it copies (gitignore is written as .gitignore)
