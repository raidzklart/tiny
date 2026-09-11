# tiny

A minimal, runnable, database-backed SaaS starting point in a single Ruby file: Sinatra, Sequel, SQLite, Phlex, HTMX. Clone, bundle, run.

## Requirements

- Ruby 3.1+ and Bundler
- No Node.js, no npm, no frontend build step

## Run it

    git clone https://github.com/raidzklart/tiny.git
    cd tiny
    bundle install
    ruby app.rb

Then open http://localhost:4567.

The SQLite database (`app.sqlite3`) is created in the project root on first boot. It is listed in `.gitignore`.

## Routes

- `/` — a generic SaaS dashboard shell
- `/showcase` — every component with its variants and states
- `/app.css`, `/app.js` — the combined assets (no `public/` directory)

Assets are declared next to the Phlex components that use them and are served as two flat endpoints. There is no asset build step and no `public/` directory.
