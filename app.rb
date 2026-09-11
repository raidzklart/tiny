# frozen_string_literal: true

# My App — a minimal, runnable, database-backed SaaS starting point.
#
# This one file is the whole application. Read it top to bottom:
#
#   1. Dependencies and database
#   2. Asset registry (CSS and JS declared next to components)
#   3. Global assets: reset, design tokens, utilities
#   4. Icons
#   5. Layout primitives
#   6. Actions, forms, display, overlays, data and feedback, shell
#   7. Page layout
#   8. Pages
#   9. Routes
#
# Run it with:  ruby app.rb   →  http://localhost:4567
#
# Phlex owns structure and component APIs. CSS owns appearance.
# To restyle the app, edit design tokens and component CSS; the Ruby
# component calls stay unchanged. Use /showcase to evaluate the result.

APP_NAME = "My App"

# ---------------------------------------------------------------------------
# 1. Dependencies and database
# ---------------------------------------------------------------------------

require "fileutils"
require "sinatra/base"
require "sequel"
require "phlex"
require "phlex-icons-huge"

# The SQLite database lives in the project root and is created on first boot.
# .gitignore excludes it. v1 creates no tables, models, or migrations.
DATABASE_PATH = File.expand_path("app.sqlite3", __dir__)
FileUtils.touch(DATABASE_PATH)
DB = Sequel.sqlite(DATABASE_PATH)
DB.run "SELECT 1"

# ---------------------------------------------------------------------------
# 2. Asset registry
# ---------------------------------------------------------------------------
# Components declare their CSS (and any JS) next to their class:
#
#   class Button < Component
#     css <<~CSS
#       .button { ... }
#     CSS
#   end
#
# Sinatra concatenates every declaration and serves the result at /app.css
# and /app.js. There is no public/ directory and no build step.

module Assets
  CSS_BLOCKS = []
  JS_BLOCKS = []

  class << self
    def register_css(body) = CSS_BLOCKS << body
    def register_js(body) = JS_BLOCKS << body

    # The combined output served by the routes below.
    def css = CSS_BLOCKS.join("\n\n")
    def js = JS_BLOCKS.join("\n\n")
  end
end

# Base class for every component in this app.
class Component < Phlex::HTML
  # Declare CSS owned by this component. See the registry above.
  def self.css(body) = Assets.register_css(body)

  # Declare a small piece of local JavaScript owned by this component.
  def self.js(body) = Assets.register_js(body)

  private

  def classes(*parts) = parts.compact.join(" ")
end

# ---------------------------------------------------------------------------
# 3. Global assets: reset, design tokens, utilities
# ---------------------------------------------------------------------------
# The single global section of the registry. Tokens are the main design
# interface; a restyle changes these values and component CSS, not Ruby.

Assets.register_css(<<~CSS)
  /* --- Reset --------------------------------------------------------- */
  *, *::before, *::after { box-sizing: border-box; }
  * { margin: 0; }
  html { -webkit-text-size-adjust: 100%; text-size-adjust: 100%; }
  body {
    min-height: 100dvh;
    line-height: var(--leading);
    -webkit-font-smoothing: antialiased;
    font-family: var(--font-sans);
    font-size: var(--text-md);
    color: var(--text);
    background: var(--bg);
  }
  img, svg, video, canvas { display: block; max-width: 100%; }
  input, button, textarea, select { font: inherit; letter-spacing: inherit; color: inherit; }
  button { background: none; border: none; padding: 0; cursor: pointer; }
  ul, ol { list-style: none; margin: 0; padding: 0; }
  a { color: inherit; text-decoration: none; }
  h1, h2, h3, h4, h5, h6 { font-weight: 600; line-height: 1.25; text-wrap: balance; }
  p { text-wrap: pretty; }
  table { border-collapse: collapse; }
  :focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
  :target { scroll-margin-block: var(--space-8); }
  [x-cloak] { display: none !important; }

  /* --- Design tokens -------------------------------------------------- */
  :root {
    color-scheme: light;

    /* Colour. A clean monochrome wireframe plus muted status colours. */
    --bg: #fafafa;
    --surface: #ffffff;
    --surface-muted: #f4f4f5;
    --border: #e4e4e7;
    --border-strong: #c8c8cd;
    --text: #18181b;
    --text-muted: #5f5f68;
    --text-faint: #9c9ca6;
    --accent: #18181b;
    --accent-hover: #3f3f46;
    --on-accent: #ffffff;
    --danger: #a4232c;
    --danger-surface: #fdf1f1;
    --success: #216e4e;
    --success-surface: #eff8f3;
    --warning: #8a5a12;
    --warning-surface: #fdf6e7;
    --info: #33517c;
    --info-surface: #f0f4fa;

    /* Typography */
    --font-sans: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    --font-mono: ui-monospace, SFMono-Regular, Menlo, Consolas, "Liberation Mono", monospace;
    --text-xs: 0.75rem;
    --text-sm: 0.875rem;
    --text-md: 1rem;
    --text-lg: 1.125rem;
    --text-xl: 1.5rem;
    --text-2xl: 2rem;
    --leading: 1.5;

    /* Spacing */
    --space-1: 0.25rem;
    --space-2: 0.5rem;
    --space-3: 0.75rem;
    --space-4: 1rem;
    --space-5: 1.5rem;
    --space-6: 2rem;
    --space-7: 2.5rem;
    --space-8: 3rem;

    /* Radius and shadow */
    --radius-sm: 4px;
    --radius-md: 8px;
    --radius-lg: 12px;
    --radius-full: 999px;
    --shadow-1: 0 1px 2px rgb(0 0 0 / 0.05);
    --shadow-2: 0 4px 16px rgb(0 0 0 / 0.1);

    /* Layout */
    --container: 72rem;
  }

  /* --- Utilities: layout and composition needs only -------------------- */
  .u-hidden { display: none !important; }
  .u-muted { color: var(--text-muted); }
  .u-visually-hidden {
    position: absolute;
    width: 1px;
    height: 1px;
    margin: -1px;
    padding: 0;
    overflow: hidden;
    clip: rect(0 0 0 0);
    white-space: nowrap;
    border: 0;
  }
CSS

# Third-party JavaScript loads from an ESM CDN through this native import map.
# Icons never load this way; they render server-side as inline SVG.
IMPORT_MAP = <<~JSON
  {
    "imports": {
      "htmx.org": "https://esm.sh/htmx.org@2.0.4",
      "alpinejs": "https://esm.sh/alpinejs@3.14.9"
    }
  }
JSON

# The small amount of global JavaScript: boot HTMX and Alpine.
# Behaviour priority elsewhere: native HTML first, CSS, HTMX when the
# server is involved, Alpine for genuine client-side state.
Assets.register_js(<<~JS)
  // Boot third-party libraries through the import map in the page head.
  import "htmx.org";
  import Alpine from "alpinejs";

  window.Alpine = Alpine;
  Alpine.start();
JS

# ---------------------------------------------------------------------------
# 4. Icons
# ---------------------------------------------------------------------------
# Icons render server-side as inline SVG through phlex-icons-huge.
# No client-side icon JavaScript, no CDN requests for icons.

class Icon < Component
  ICONS = {
    home:          PhlexIcons::Huge::Home01,
    dashboard:     PhlexIcons::Huge::DashboardSquare01,
    chart:         PhlexIcons::Huge::Chart01,
    checklist:     PhlexIcons::Huge::CheckList,
    task:          PhlexIcons::Huge::Task01,
    inbox:         PhlexIcons::Huge::Inbox,
    folder:        PhlexIcons::Huge::Folder02,
    file:          PhlexIcons::Huge::File01,
    database:      PhlexIcons::Huge::Database,
    settings:      PhlexIcons::Huge::Settings01,
    search:        PhlexIcons::Huge::Search01,
    bell:          PhlexIcons::Huge::Notification01,
    menu:          PhlexIcons::Huge::Menu01,
    more:          PhlexIcons::Huge::MoreVertical,
    user:          PhlexIcons::Huge::UserCircle,
    people:        PhlexIcons::Huge::UserGroup,
    plus:          PhlexIcons::Huge::Add01,
    check:         PhlexIcons::Huge::Tick01,
    close:         PhlexIcons::Huge::Cancel01,
    alert:         PhlexIcons::Huge::Alert01,
    info:          PhlexIcons::Huge::InformationCircle,
    help:          PhlexIcons::Huge::HelpCircle,
    mail:          PhlexIcons::Huge::Mail01,
    lock:          PhlexIcons::Huge::Lock,
    calendar:      PhlexIcons::Huge::Calendar03,
    clock:         PhlexIcons::Huge::Time01,
    star:          PhlexIcons::Huge::Star,
    tag:           PhlexIcons::Huge::Tag01,
    globe:         PhlexIcons::Huge::Globe02,
    card:          PhlexIcons::Huge::CreditCard,
    coins:         PhlexIcons::Huge::Coins01,
    wallet:        PhlexIcons::Huge::Wallet02,
    edit:          PhlexIcons::Huge::Edit01,
    trash:         PhlexIcons::Huge::Delete01,
    copy:          PhlexIcons::Huge::Copy01,
    link:          PhlexIcons::Huge::Link01,
    download:      PhlexIcons::Huge::Download04,
    refresh:       PhlexIcons::Huge::Refresh,
    archive:       PhlexIcons::Huge::Archive,
    view:          PhlexIcons::Huge::View,
    view_off:      PhlexIcons::Huge::ViewOff,
    logout:        PhlexIcons::Huge::Logout01,
    chevron_down:  PhlexIcons::Huge::ArrowDown01,
  }.freeze

  css <<~CSS
    .icon {
      width: 1.25rem;
      height: 1.25rem;
      flex: none;
    }
    .icon--sm { width: 1rem; height: 1rem; }
    .icon--lg { width: 1.5rem; height: 1.5rem; }
  CSS

  def initialize(name, **attrs)
    @icon = ICONS.fetch(name) { raise ArgumentError, "unknown icon: #{name.inspect}" }
    @attrs = { class: "icon", **attrs }
  end

  def view_template
    render @icon.new(variant: :stroke, **@attrs)
  end
end

# ---------------------------------------------------------------------------
# 5. Layout primitives
# ---------------------------------------------------------------------------
# Generic composition tools, not visually styled components.

class Container < Component
  css <<~CSS
    .container {
      width: 100%;
      max-width: var(--container);
      margin-inline: auto;
      padding-inline: var(--space-5);
    }
    .container--narrow { max-width: 48rem; }
    .container--wide { max-width: 96rem; }
  CSS

  def initialize(size: :md, **attrs)
    @size = size
    @attrs = attrs
  end

  def view_template(&)
    div(class: classes("container", ("container--#{@size}" unless @size == :md)), **@attrs, &)
  end
end

class Stack < Component
  css <<~CSS
    .stack { display: flex; flex-direction: column; }
    .stack--sm { gap: var(--space-2); }
    .stack--md { gap: var(--space-4); }
    .stack--lg { gap: var(--space-6); }
    .stack--xl { gap: var(--space-8); }
  CSS

  def initialize(gap: :md, **attrs)
    @gap = gap
    @attrs = attrs
  end

  def view_template(&)
    div(class: classes("stack", "stack--#{@gap}"), **@attrs, &)
  end
end

class Cluster < Component
  css <<~CSS
    .cluster { display: flex; flex-wrap: wrap; align-items: center; }
    .cluster--sm { gap: var(--space-2); }
    .cluster--md { gap: var(--space-4); }
    .cluster--lg { gap: var(--space-6); }
    .cluster--stretch { align-items: stretch; }
  CSS

  def initialize(gap: :md, **attrs)
    @gap = gap
    @attrs = attrs
  end

  def view_template(&)
    div(class: classes("cluster", "cluster--#{@gap}"), **@attrs, &)
  end
end

class Grid < Component
  css <<~CSS
    .grid { display: grid; }
    .grid--sm { gap: var(--space-2); }
    .grid--md { gap: var(--space-4); }
    .grid--lg { gap: var(--space-6); }
    .grid--2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .grid--3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
    .grid--4 { grid-template-columns: repeat(4, minmax(0, 1fr)); }
  CSS

  def initialize(columns: 3, gap: :md, **attrs)
    @columns = columns
    @gap = gap
    @attrs = attrs
  end

  def view_template(&)
    unless [2, 3, 4].include?(@columns)
      raise ArgumentError, "Grid supports columns 2, 3, or 4 (got #{@columns})"
    end

    div(class: classes("grid", "grid--#{@columns}", "grid--#{@gap}"), **@attrs, &)
  end
end

# ---------------------------------------------------------------------------
# 6a. Actions
# ---------------------------------------------------------------------------

class Button < Component
  css <<~CSS
    .button {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: var(--space-2);
      padding: var(--space-2) var(--space-4);
      font-size: var(--text-sm);
      font-weight: 500;
      line-height: 1.25;
      white-space: nowrap;
      border: 1px solid transparent;
      border-radius: var(--radius-md);
      transition: background-color 120ms ease, border-color 120ms ease, color 120ms ease;
    }
    .button--sm { padding: var(--space-1) var(--space-3); font-size: var(--text-xs); }
    .button--lg { padding: var(--space-3) var(--space-5); font-size: var(--text-md); }
    .button--block { width: 100%; }
    .button:disabled { opacity: 0.55; cursor: not-allowed; }
    .button--primary { background: var(--accent); color: var(--on-accent); }
    .button--primary:hover:not(:disabled) { background: var(--accent-hover); }
    .button--secondary { background: var(--surface); border-color: var(--border-strong); }
    .button--secondary:hover:not(:disabled) { background: var(--surface-muted); }
    .button--ghost { background: transparent; color: var(--text); }
    .button--ghost:hover:not(:disabled) { background: var(--surface-muted); }
    .button--danger { background: var(--danger); color: var(--on-accent); }
    .button--danger:hover:not(:disabled) { background: var(--danger); opacity: 0.9; }
    .button .icon--inline { width: 1rem; height: 1rem; }
  CSS

  def initialize(text = nil, variant: :primary, size: :md, disabled: false, icon: nil,
                 href: nil, type: "button", block: false, **attrs)
    @text = text
    @variant = variant
    @size = size
    @disabled = disabled
    @icon = icon
    @href = href
    @type = type
    @block = block
    @attrs = attrs
  end

  def view_template(&)
    klass = classes(
      "button",
      "button--#{@variant}",
      ("button--#{@size}" unless @size == :md),
      ("button--block" if @block),
      @attrs[:class]
    )
    attrs = @attrs.except(:class)

    if @href
      a(href: @href, class: klass, **attrs) { content(&) }
    else
      button(type: @type, class: klass, disabled: @disabled, **attrs) { content(&) }
    end
  end

  private

  def content(&)
    render Icon.new(@icon, class: "icon--inline") if @icon
    if block_given?
      yield
    else
      plain @text
    end
  end
end

class IconButton < Component
  css <<~CSS
    .icon-button {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 2.25rem;
      height: 2.25rem;
      border-radius: var(--radius-md);
      transition: background-color 120ms ease, border-color 120ms ease;
    }
    .icon-button--sm { width: 1.75rem; height: 1.75rem; }
    .icon-button--sm .icon { width: 1rem; height: 1rem; }
    .icon-button--default { background: var(--surface); border: 1px solid var(--border-strong); }
    .icon-button--default:hover:not(:disabled) { background: var(--surface-muted); }
    .icon-button--ghost { background: transparent; }
    .icon-button--ghost:hover:not(:disabled) { background: var(--surface-muted); }
    .icon-button:disabled { opacity: 0.55; cursor: not-allowed; }
  CSS

  def initialize(icon:, label:, variant: :default, size: :md, disabled: false, **attrs)
    @icon = icon
    @label = label
    @variant = variant
    @size = size
    @disabled = disabled
    @attrs = attrs
  end

  def view_template
    button(
      type: "button",
      class: classes("icon-button", "icon-button--#{@variant}",
                     ("icon-button--#{@size}" unless @size == :md)),
      aria_label: @label,
      title: @label,
      disabled: @disabled,
      **@attrs
    ) { render Icon.new(@icon) }
  end
end

# ---------------------------------------------------------------------------
# 6b. Forms
# ---------------------------------------------------------------------------

class Label < Component
  css <<~CSS
    .label {
      display: inline-block;
      font-size: var(--text-sm);
      font-weight: 500;
    }
    .label__required { color: var(--danger); }
  CSS

  def initialize(for_id: nil, required: false, **attrs)
    @for_id = for_id
    @required = required
    @attrs = attrs
  end

  def view_template(&)
    label("for": @for_id, class: @attrs[:class] || "label", **@attrs.except(:class)) do
      yield
      span(class: "label__required") { " *" } if @required
    end
  end
end

class FormField < Component
  css <<~CSS
    .field { display: grid; gap: var(--space-2); }
    .field__hint { font-size: var(--text-xs); color: var(--text-muted); }
    .field__error { font-size: var(--text-xs); font-weight: 500; color: var(--danger); }
  CSS

  # Wrap a control with a label, a hint, and a validation error.
  # Wire aria-describedby on the control to "#{for_id}-hint" or "#{for_id}-error".
  def initialize(label:, for_id:, hint: nil, error: nil, required: false, **attrs)
    @label = label
    @for_id = for_id
    @hint = hint
    @error = error
    @required = required
    @attrs = attrs
  end

  def view_template(&)
    div(class: classes("field", ("field--error" if @error), @attrs[:class]), **@attrs.except(:class)) do
      render Label.new(for_id: @for_id, required: @required) { @label }
      yield
      if @error
        p(class: "field__error", id: "#{@for_id}-error") { @error }
      elsif @hint
        p(class: "field__hint", id: "#{@for_id}-hint") { @hint }
      end
    end
  end
end

class Input < Component
  css <<~CSS
    .input {
      width: 100%;
      padding: var(--space-2) var(--space-3);
      font-size: var(--text-sm);
      background: var(--surface);
      border: 1px solid var(--border-strong);
      border-radius: var(--radius-md);
    }
    .input::placeholder { color: var(--text-faint); }
    .input:focus-visible { outline: 2px solid var(--accent); outline-offset: -1px; }
    .input:disabled { background: var(--surface-muted); color: var(--text-faint); cursor: not-allowed; }
    .input[aria-invalid="true"] { border-color: var(--danger); }
    .input[aria-invalid="true"]:focus-visible { outline-color: var(--danger); }
  CSS

  def initialize(id: nil, name: nil, type: "text", value: nil, placeholder: nil,
                 disabled: false, invalid: false, **attrs)
    @id = id
    @name = name
    @type = type
    @value = value
    @placeholder = placeholder
    @disabled = disabled
    @invalid = invalid
    @attrs = attrs
  end

  def view_template
    input(
      id: @id,
      name: @name,
      type: @type,
      value: @value,
      placeholder: @placeholder,
      disabled: @disabled,
      class: @attrs[:class] || "input textarea",
      aria_invalid: @invalid ? "true" : nil,
      **@attrs.except(:class)
    )
  end
end

class Textarea < Component
  def initialize(id: nil, name: nil, value: nil, rows: 4, placeholder: nil,
                 disabled: false, invalid: false, **attrs)
    @id = id
    @name = name
    @value = value
    @rows = rows
    @placeholder = placeholder
    @disabled = disabled
    @invalid = invalid
    @attrs = attrs
  end

  def view_template
    textarea(
      id: @id,
      name: @name,
      rows: @rows,
      placeholder: @placeholder,
      disabled: @disabled,
      class: @attrs[:class] || "input textarea",
      aria_invalid: @invalid ? "true" : nil,
      **@attrs.except(:class)
    ) { @value }
  end
end

class Select < Component
  css <<~CSS
    .select {
      appearance: none;
      padding-right: var(--space-8);
      background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%2318181b' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E");
      background-repeat: no-repeat;
      background-position: right var(--space-3) center;
      background-size: 1rem;
    }
    .select:disabled { background-color: var(--surface-muted); color: var(--text-faint); cursor: not-allowed; }
  CSS

  # options: array of strings, or [value, label] pairs.
  def initialize(id: nil, name: nil, options: [], selected: nil, disabled: false, **attrs)
    @id = id
    @name = name
    @options = options.map { |o| o.is_a?(Array) ? o : [o, o] }
    @selected = selected
    @disabled = disabled
    @attrs = attrs
  end

  def view_template
    select(
      id: @id,
      name: @name,
      disabled: @disabled,
      class: classes("input", "select", @attrs[:class]),
      **@attrs.except(:class)
    ) do
      @options.each do |value, label|
        option(value: value, selected: value == @selected) { label }
      end
    end
  end
end

class Checkbox < Component
  css <<~CSS
    .checkbox { display: flex; align-items: flex-start; gap: var(--space-2); cursor: pointer; }
    .checkbox input {
      width: 1rem;
      height: 1rem;
      margin-top: 0.1875rem;
      accent-color: var(--accent);
      flex: none;
    }
    .checkbox:has(input:disabled) { color: var(--text-faint); cursor: not-allowed; }
    .checkbox__text { display: grid; gap: 2px; }
    .checkbox__label { font-size: var(--text-sm); }
    .checkbox__description { font-size: var(--text-xs); color: var(--text-muted); }
  CSS

  def initialize(label:, name:, id: nil, value: "1", checked: false, disabled: false,
                 description: nil, **attrs)
    @label = label
    @name = name
    @id = id
    @value = value
    @checked = checked
    @disabled = disabled
    @description = description
    @attrs = attrs
  end

  def view_template
    label(class: classes("checkbox", @attrs[:class]), **@attrs.except(:class)) do
      input(id: @id, name: @name, type: "checkbox", value: @value, checked: @checked,
            disabled: @disabled)
      span(class: "checkbox__text") do
        span(class: "checkbox__label") { @label }
        span(class: "checkbox__description") { @description } if @description
      end
    end
  end
end

class Radio < Component
  css <<~CSS
    .radio { display: flex; align-items: flex-start; gap: var(--space-2); cursor: pointer; }
    .radio input {
      width: 1rem;
      height: 1rem;
      margin-top: 0.1875rem;
      accent-color: var(--accent);
      flex: none;
    }
    .radio:has(input:disabled) { color: var(--text-faint); cursor: not-allowed; }
    .radio__text { display: grid; gap: 2px; }
    .radio__label { font-size: var(--text-sm); }
    .radio__description { font-size: var(--text-xs); color: var(--text-muted); }
  CSS

  def initialize(label:, name:, value:, id: nil, checked: false, disabled: false,
                 description: nil, **attrs)
    @label = label
    @name = name
    @value = value
    @id = id
    @checked = checked
    @disabled = disabled
    @description = description
    @attrs = attrs
  end

  def view_template
    label(class: classes("radio", @attrs[:class]), **@attrs.except(:class)) do
      input(id: @id, name: @name, type: "radio", value: @value, checked: @checked,
            disabled: @disabled)
      span(class: "radio__text") do
        span(class: "radio__label") { @label }
        span(class: "radio__description") { @description } if @description
      end
    end
  end
end

class Switch < Component
  css <<~CSS
    .switch { display: inline-flex; align-items: flex-start; gap: var(--space-3); cursor: pointer; }
    .switch__input { position: absolute; width: 1px; height: 1px; opacity: 0; }
    .switch__track {
      position: relative;
      flex: none;
      width: 2.5rem;
      height: 1.5rem;
      border-radius: var(--radius-full);
      background: var(--surface-muted);
      border: 1px solid var(--border-strong);
      transition: background-color 120ms ease, border-color 120ms ease;
    }
    .switch__thumb {
      position: absolute;
      top: 50%;
      left: 2px;
      translate: 0 -50%;
      width: 1.125rem;
      height: 1.125rem;
      border-radius: var(--radius-full);
      background: var(--surface);
      border: 1px solid var(--border-strong);
      box-shadow: var(--shadow-1);
      transition: left 120ms ease, background-color 120ms ease;
    }
    .switch__input:checked + .switch__track { background: var(--accent); border-color: var(--accent); }
    .switch__input:checked + .switch__track .switch__thumb { left: calc(100% - 1.125rem - 2px); background: var(--on-accent); border-color: transparent; }
    .switch__input:focus-visible + .switch__track { outline: 2px solid var(--accent); outline-offset: 2px; }
    .switch__input:disabled + .switch__track { opacity: 0.5; }
    .switch:has(.switch__input:disabled) { color: var(--text-faint); cursor: not-allowed; }
    .switch__text { display: grid; gap: 2px; }
    .switch__label { font-size: var(--text-sm); }
    .switch__description { font-size: var(--text-xs); color: var(--text-muted); }
  CSS

  def initialize(label:, name:, id: nil, checked: false, disabled: false, description: nil)
    @label = label
    @name = name
    @id = id
    @checked = checked
    @disabled = disabled
    @description = description
  end

  def view_template
    label(class: "switch") do
      input(class: "switch__input", id: @id, name: @name, type: "checkbox",
            role: "switch", checked: @checked, disabled: @disabled)
      span(class: "switch__track") { span(class: "switch__thumb") }
      span(class: "switch__text") do
        span(class: "switch__label") { @label }
        span(class: "switch__description") { @description } if @description
      end
    end
  end
end

# ---------------------------------------------------------------------------
# 6c. Display
# ---------------------------------------------------------------------------

class Card < Component
  css <<~CSS
    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      box-shadow: var(--shadow-1);
    }
    .card__header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: var(--space-4);
      padding: var(--space-4) var(--space-5);
      border-bottom: 1px solid var(--border);
    }
    .card__title { font-size: var(--text-md); }
    .card__content { padding: var(--space-5); }
    .card--flush .card__content { padding: 0; }
  CSS

  def initialize(title: nil, flush: false, **attrs)
    @title = title
    @flush = flush
    @attrs = attrs
  end

  def view_template(&)
    section(class: classes("card", ("card--flush" if @flush), @attrs[:class]), **@attrs.except(:class)) do
      if @title
        header(class: "card__header") { h3(class: "card__title") { @title } }
      end
      div(class: "card__content", &)
    end
  end
end

class Badge < Component
  css <<~CSS
    .badge {
      display: inline-flex;
      align-items: center;
      gap: var(--space-1);
      padding: 0.125rem 0.5rem;
      font-size: var(--text-xs);
      font-weight: 500;
      border: 1px solid transparent;
      border-radius: var(--radius-full);
    }
    .badge--neutral { background: var(--surface-muted); color: var(--text); }
    .badge--outline { border-color: var(--border-strong); color: var(--text-muted); }
    .badge--success { background: var(--success-surface); color: var(--success); }
    .badge--warning { background: var(--warning-surface); color: var(--warning); }
    .badge--danger { background: var(--danger-surface); color: var(--danger); }
    .badge--info { background: var(--info-surface); color: var(--info); }
  CSS

  def initialize(text = nil, variant: :neutral, **attrs)
    @text = text
    @variant = variant
    @attrs = attrs
  end

  def view_template(&)
    span(class: classes("badge", "badge--#{@variant}", @attrs[:class]), **@attrs.except(:class)) do
      if block_given? then yield else plain(@text) end
    end
  end
end

class Avatar < Component
  css <<~CSS
    .avatar {
      display: inline-grid;
      place-items: center;
      width: 2.25rem;
      height: 2.25rem;
      border-radius: var(--radius-full);
      background: var(--surface-muted);
      border: 1px solid var(--border);
      font-size: var(--text-xs);
      font-weight: 600;
      color: var(--text-muted);
    }
    .avatar--sm { width: 1.75rem; height: 1.75rem; }
    .avatar--lg { width: 3rem; height: 3rem; font-size: var(--text-md); }
  CSS

  def initialize(initials:, size: :md, label: nil, **attrs)
    @initials = initials
    @size = size
    @label = label
    @attrs = attrs
  end

  def view_template
    span(
      class: classes("avatar", ("avatar--#{@size}" unless @size == :md), @attrs[:class]),
      title: @label,
      aria_label: @label,
      **@attrs.except(:class)
    ) { @initials }
  end
end

# ---------------------------------------------------------------------------
# 6d. Overlays
# ---------------------------------------------------------------------------
# Dialog and Drawer use the native <dialog> element. Popover uses the native
# popover attribute. Dropdown uses <details>. Tabs uses Alpine, because the
# active tab is genuine client-side state.

class Dialog < Component
  js <<~JS
    // Open a dialog declaratively: <button data-dialog-open="some-id">.
    document.addEventListener("click", (event) => {
      const opener = event.target.closest("[data-dialog-open]");
      if (!opener) return;
      document.getElementById(opener.dataset.dialogOpen)?.showModal();
    });
  JS

  css <<~CSS
    .dialog {
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      background: var(--surface);
      color: var(--text);
      padding: 0;
      width: min(32rem, calc(100vw - 2rem));
      box-shadow: var(--shadow-2);
    }
    .dialog::backdrop { background: rgb(0 0 0 / 0.4); }
    .dialog__header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: var(--space-4);
      padding: var(--space-4) var(--space-5);
      border-bottom: 1px solid var(--border);
    }
    .dialog__title { font-size: var(--text-lg); }
    .dialog__content { padding: var(--space-5); display: grid; gap: var(--space-5); }
  CSS

  # Closing uses the native form method="dialog"; no JavaScript.
  def initialize(id:, title:, **attrs)
    @id = id
    @title = title
    @attrs = attrs
  end

  def view_template(&)
    dialog(id: @id, class: classes("dialog", @attrs[:class]), aria_labelledby: "#{@id}-title",
           **@attrs.except(:class)) do
      header(class: "dialog__header") do
        h2(class: "dialog__title", id: "#{@id}-title") { @title }
        form(method: "dialog", action: "#") do
          render IconButton.new(icon: :close, label: "Close dialog", variant: :ghost,
                                type: "submit")
        end
      end
      div(class: "dialog__content", &)
    end
  end
end

class Drawer < Component
  css <<~CSS
    .drawer {
      border: 1px solid var(--border);
      border-radius: 0;
      background: var(--surface);
      color: var(--text);
      padding: 0;
      width: min(24rem, 90vw);
      height: 100%;
      max-height: 100%;
      margin: 0 0 0 auto;
      border-top: none;
      border-bottom: none;
      border-right: none;
      box-shadow: var(--shadow-2);
    }
    .drawer::backdrop { background: rgb(0 0 0 / 0.4); }
    .drawer__header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: var(--space-4);
      padding: var(--space-4) var(--space-5);
      border-bottom: 1px solid var(--border);
    }
    .drawer__title { font-size: var(--text-lg); }
    .drawer__content { padding: var(--space-5); display: grid; gap: var(--space-5); }
  CSS

  # Same native behaviour as Dialog, styled as a side panel.
  def initialize(id:, title:, **attrs)
    @id = id
    @title = title
    @attrs = attrs
  end

  def view_template(&)
    dialog(id: @id, class: classes("drawer", @attrs[:class]), aria_labelledby: "#{@id}-title",
           **@attrs.except(:class)) do
      header(class: "drawer__header") do
        h2(class: "drawer__title", id: "#{@id}-title") { @title }
        form(method: "dialog", action: "#") do
          render IconButton.new(icon: :close, label: "Close drawer", variant: :ghost,
                                type: "submit")
        end
      end
      div(class: "drawer__content", &)
    end
  end
end

class Popover < Component
  css <<~CSS
    .popover {
      border: 1px solid var(--border);
      border-radius: var(--radius-lg);
      background: var(--surface);
      color: var(--text);
      box-shadow: var(--shadow-2);
      padding: var(--space-4);
      width: min(20rem, 90vw);
    }
    .popover__title { font-size: var(--text-sm); font-weight: 600; margin-bottom: var(--space-1); }
    .popover p { font-size: var(--text-sm); color: var(--text-muted); }
  CSS

  # Open it with any button that carries popovertarget: "id".
  # Light dismiss (click outside, Esc) is native; no JavaScript.
  def initialize(id:, title: nil, **attrs)
    @id = id
    @title = title
    @attrs = attrs
  end

  def view_template(&)
    div(id: @id, popover: "", class: classes("popover", @attrs[:class]), **@attrs.except(:class)) do
      h3(class: "popover__title") { @title } if @title
      yield
    end
  end
end

class Dropdown < Component
  js <<~JS
    // Light-dismiss for the native <details> dropdown: close any open
    // dropdown when the click lands outside of it.
    document.addEventListener("click", (event) => {
      document.querySelectorAll("details.dropdown[open]").forEach((dropdown) => {
        if (!dropdown.contains(event.target)) dropdown.removeAttribute("open");
      });
    });
  JS

  css <<~CSS
    .dropdown { position: relative; display: inline-block; }
    .dropdown__summary {
      display: inline-flex;
      align-items: center;
      gap: var(--space-2);
      padding: var(--space-2) var(--space-3);
      font-size: var(--text-sm);
      background: var(--surface);
      border: 1px solid var(--border-strong);
      border-radius: var(--radius-md);
      cursor: pointer;
      list-style: none;
    }
    .dropdown__summary::-webkit-details-marker { display: none; }
    .dropdown__menu {
      position: absolute;
      top: calc(100% + var(--space-1));
      left: 0;
      z-index: 30;
      min-width: 12rem;
      padding: var(--space-1);
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius-md);
      box-shadow: var(--shadow-2);
    }
    .dropdown__item {
      display: flex;
      align-items: center;
      gap: var(--space-2);
      padding: var(--space-2) var(--space-3);
      font-size: var(--text-sm);
      border-radius: var(--radius-sm);
    }
    .dropdown__item .icon { width: 1rem; height: 1rem; color: var(--text-faint); }
    .dropdown__item:hover { background: var(--surface-muted); }
  CSS

  # items: [{ label:, icon: (optional), href: }]
  def initialize(label:, items:, **attrs)
    @label = label
    @items = items
    @attrs = attrs
  end

  def view_template
    details(class: classes("dropdown", @attrs[:class]), **@attrs.except(:class)) do
      summary(class: "dropdown__summary") do
        plain @label
        render Icon.new(:chevron_down, class: "icon--sm")
      end
      div(class: "dropdown__menu") do
        @items.each do |item|
          a(class: "dropdown__item", href: item[:href] || "#") do
            render Icon.new(item[:icon], class: "icon--sm") if item[:icon]
            span { item[:label] }
          end
        end
      end
    end
  end
end

class Tabs < Component
  css <<~CSS
    .tabs { display: grid; gap: var(--space-4); }
    .tabs__list {
      display: flex;
      gap: var(--space-1);
      border-bottom: 1px solid var(--border);
    }
    .tabs__tab {
      padding: var(--space-2) var(--space-3);
      font-size: var(--text-sm);
      font-weight: 500;
      color: var(--text-muted);
      border-bottom: 2px solid transparent;
      margin-bottom: -1px;
    }
    .tabs__tab:hover { color: var(--text); }
    .tabs__tab--active { color: var(--text); border-bottom-color: var(--accent); }
  CSS

  # Wraps TabsTrigger buttons and TabPanel divs. The active tab is genuine
  # client-side state, so this uses Alpine: x-data="{ active: '...' }".
  def initialize(active:)
    @active = active
  end

  def view_template(&)
    div(class: "tabs", "x-data": "{ active: '#{@active}' }", &)
  end
end

class TabsList < Component
  def view_template(&)
    div(class: "tabs__list", role: "tablist", &)
  end
end

class TabsTrigger < Component
  def initialize(label:, id:)
    @label = label
    @id = id
  end

  def view_template
    button(
      class: "tabs__tab",
      type: "button",
      role: "tab",
      "@click": "active = '#{@id}'",
      ":class": "{ 'tabs__tab--active': active === '#{@id}' }",
      ":aria-selected": "active === '#{@id}'",
      ":tabindex": "active === '#{@id}' ? 0 : -1"
    ) { @label }
  end
end

class TabPanel < Component
  def initialize(id:, initial: false)
    @id = id
    @initial = initial
  end

  def view_template(&)
    attrs = { class: "tabs__panel", role: "tabpanel", "x-show" => "active === '#{@id}'" }
    attrs["x-cloak"] = true unless @initial
    div(**attrs, &)
  end
end

# ---------------------------------------------------------------------------
# 6e. Data and feedback
# ---------------------------------------------------------------------------

class Table < Component
  css <<~CSS
    .table { width: 100%; overflow-x: auto; }
    .table table { width: 100%; border-collapse: collapse; }
    .table th {
      padding: var(--space-3) var(--space-4);
      text-align: left;
      font-size: var(--text-xs);
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      color: var(--text-muted);
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
    }
    .table td {
      padding: var(--space-3) var(--space-4);
      font-size: var(--text-sm);
      border-bottom: 1px solid var(--border);
    }
    .table tbody tr:last-child td { border-bottom: none; }
    .table tbody tr:hover { background: var(--surface-muted); }
  CSS

  # rows: array of rows; each row is an array of cells. A cell is a String
  # or another component (e.g. a Badge), rendered inline.
  def initialize(headers:, rows: [])
    @headers = headers
    @rows = rows
  end

  def view_template
    div(class: "table") do
      table do
        thead do
          tr { @headers.each { |header| th(scope: "col") { header } } }
        end
        tbody do
          @rows.each do |row|
            tr { row.each { |cell| td { render_cell(cell) } } }
          end
        end
      end
    end
  end

  private

  def render_cell(cell)
    if cell.is_a?(String) || cell.is_a?(Numeric)
      plain cell.to_s
    else
      render cell
    end
  end
end

class EmptyState < Component
  css <<~CSS
    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      gap: var(--space-3);
      padding: var(--space-8) var(--space-6);
    }
    .empty-state__icon {
      display: grid;
      place-items: center;
      width: 3rem;
      height: 3rem;
      border-radius: var(--radius-full);
      background: var(--surface-muted);
      border: 1px solid var(--border);
      color: var(--text-muted);
    }
    .empty-state__title { font-size: var(--text-lg); }
    .empty-state__description {
      font-size: var(--text-sm);
      color: var(--text-muted);
      max-width: 28rem;
    }
    .empty-state__action { margin-top: var(--space-2); }
  CSS

  def initialize(icon:, title:, description: nil)
    @icon = icon
    @title = title
    @description = description
  end

  def view_template(&)
    div(class: "empty-state") do
      span(class: "empty-state__icon") { render Icon.new(@icon) }
      h3(class: "empty-state__title") { @title }
      p(class: "empty-state__description") { @description } if @description
      div(class: "empty-state__action", &)
    end
  end
end

class Alert < Component
  css <<~CSS
    .alert {
      display: flex;
      align-items: flex-start;
      gap: var(--space-3);
      padding: var(--space-4);
      border: 1px solid var(--border);
      border-radius: var(--radius-md);
      background: var(--surface);
    }
    .alert__icon { color: var(--text-muted); margin-top: 1px; }
    .alert__title { font-size: var(--text-sm); font-weight: 600; }
    .alert__content { font-size: var(--text-sm); color: var(--text-muted); display: grid; gap: var(--space-1); }
    .alert--info { background: var(--info-surface); border-color: color-mix(in srgb, var(--info) 25%, transparent); }
    .alert--info .alert__icon { color: var(--info); }
    .alert--success { background: var(--success-surface); border-color: color-mix(in srgb, var(--success) 25%, transparent); }
    .alert--success .alert__icon { color: var(--success); }
    .alert--warning { background: var(--warning-surface); border-color: color-mix(in srgb, var(--warning) 25%, transparent); }
    .alert--warning .alert__icon { color: var(--warning); }
    .alert--danger { background: var(--danger-surface); border-color: color-mix(in srgb, var(--danger) 25%, transparent); }
    .alert--danger .alert__icon { color: var(--danger); }
  CSS

  ICON_BY_VARIANT = { info: :info, success: :check, warning: :alert, danger: :alert }.freeze

  def initialize(variant: :info, title: nil, **attrs)
    @variant = variant
    @title = title
    @attrs = attrs
  end

  def view_template(&)
    div(class: classes("alert", "alert--#{@variant}", @attrs[:class]), **@attrs.except(:class)) do
      span(class: "alert__icon") { render Icon.new(ICON_BY_VARIANT.fetch(@variant)) }
      div(class: "alert__content") do
        strong(class: "alert__title") { @title } if @title
        div(&)
      end
    end
  end
end

class Toast < Component
  css <<~CSS
    .toast {
      display: flex;
      align-items: flex-start;
      gap: var(--space-3);
      padding: var(--space-3) var(--space-4);
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius-md);
      box-shadow: var(--shadow-2);
      min-width: 18rem;
      max-width: 24rem;
    }
    .toast__icon { color: var(--text-muted); margin-top: 2px; }
    .toast__content { flex: 1; display: grid; gap: 2px; }
    .toast__title { font-size: var(--text-sm); font-weight: 500; }
    .toast__description { font-size: var(--text-xs); color: var(--text-muted); }
    .toast .icon-button { flex: none; width: 1.75rem; height: 1.75rem; }
    .toast .icon-button .icon { width: 1rem; height: 1rem; }
    .toast--success .toast__icon { color: var(--success); }
    .toast--danger .toast__icon { color: var(--danger); }
    .toast--warning .toast__icon { color: var(--warning); }
    .toast--info .toast__icon { color: var(--info); }
  CSS

  ICON_BY_VARIANT = { info: :info, success: :check, warning: :alert, danger: :alert }.freeze

  def initialize(variant: :info, title:, description: nil, on_close: nil, **attrs)
    @variant = variant
    @title = title
    @description = description
    @on_close = on_close
    @attrs = attrs
  end

  def view_template
    div(class: classes("toast", "toast--#{@variant}", @attrs[:class]), role: "status",
        **@attrs.except(:class)) do
      span(class: "toast__icon") { render Icon.new(ICON_BY_VARIANT.fetch(@variant)) }
      div(class: "toast__content") do
        span(class: "toast__title") { @title }
        span(class: "toast__description") { @description } if @description
      end
      render IconButton.new(icon: :close, label: "Dismiss notification", variant: :ghost,
                             size: :sm, "@click": @on_close)
    end
  end
end

# ---------------------------------------------------------------------------
# 6f. Application shell
# ---------------------------------------------------------------------------

class Navbar < Component
  css <<~CSS
    .navbar {
      background: var(--surface);
      border-bottom: 1px solid var(--border);
    }
    .navbar--sticky { position: sticky; top: 0; z-index: 20; }
    .navbar__inner {
      display: flex;
      align-items: center;
      gap: var(--space-4);
      padding: var(--space-3) var(--space-5);
    }
    .navbar__brand {
      display: inline-flex;
      align-items: center;
      gap: var(--space-2);
      font-size: var(--text-md);
      font-weight: 600;
    }
    .navbar__mark {
      display: grid;
      place-items: center;
      width: 1.5rem;
      height: 1.5rem;
      border-radius: var(--radius-sm);
      background: var(--accent);
      color: var(--on-accent);
      font-size: var(--text-xs);
      font-weight: 700;
    }
    .navbar__links { display: flex; gap: var(--space-1); }
    .navbar__link {
      padding: var(--space-1) var(--space-3);
      border-radius: var(--radius-sm);
      font-size: var(--text-sm);
      color: var(--text-muted);
    }
    .navbar__link:hover { background: var(--surface-muted); color: var(--text); }
    .navbar__link--active { color: var(--text); font-weight: 500; }
    .navbar__actions { display: flex; align-items: center; gap: var(--space-2); margin-left: auto; }
    .navbar__actions .avatar { margin-left: var(--space-1); }
  CSS

  def initialize(brand:, links: [], sticky: true, **attrs)
    @brand = brand
    @links = links
    @sticky = sticky
    @attrs = attrs
  end

  def view_template(&)
    header(class: classes("navbar", ("navbar--sticky" if @sticky), @attrs[:class]),
           **@attrs.except(:class)) do
      div(class: "navbar__inner") do
        a(class: "navbar__brand", href: "/") do
          span(class: "navbar__mark") { @brand[0].to_s.upcase }
          span { @brand }
        end
        nav(class: "navbar__links", aria_label: "Main navigation") do
          @links.each do |label, href|
            a(class: "navbar__link", href: href) { label }
          end
        end
        div(class: "navbar__actions", &)
      end
    end
  end
end

class Sidebar < Component
  css <<~CSS
    .sidebar {
      display: flex;
      flex-direction: column;
      gap: var(--space-5);
      padding: var(--space-4);
    }
    .sidebar__section { display: grid; gap: var(--space-1); }
    .sidebar__section-title {
      padding: 0 var(--space-3);
      font-size: var(--text-xs);
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      color: var(--text-faint);
    }
    .sidebar__item {
      display: flex;
      align-items: center;
      gap: var(--space-2);
      padding: var(--space-2) var(--space-3);
      border-radius: var(--radius-md);
      font-size: var(--text-sm);
      color: var(--text-muted);
    }
    .sidebar__item .icon { width: 1rem; height: 1rem; color: var(--text-faint); }
    .sidebar__item:hover { background: var(--surface-muted); color: var(--text); }
    .sidebar__item--active { background: var(--surface-muted); color: var(--text); font-weight: 500; }
    .sidebar__item--active .icon { color: var(--text); }
  CSS

  # sections: [{ title: (optional), items: [{ label:, icon:, href:, active: }] }]
  def initialize(sections:, **attrs)
    @sections = sections
    @attrs = attrs
  end

  def view_template
    aside(class: classes("sidebar", @attrs[:class]), **@attrs.except(:class)) do
      @sections.each do |section|
        div(class: "sidebar__section") do
          if section[:title]
            div(class: "sidebar__section-title") { section[:title] }
          end
          section[:items].each do |item|
            a(
              class: classes("sidebar__item", ("sidebar__item--active" if item[:active])),
              href: item[:href],
              aria_current: item[:active] ? "page" : nil
            ) do
              render Icon.new(item[:icon]) if item[:icon]
              span { item[:label] }
            end
          end
        end
      end
    end
  end
end

class PageHeader < Component
  css <<~CSS
    .page-header {
      display: flex;
      flex-wrap: wrap;
      align-items: flex-start;
      justify-content: space-between;
      gap: var(--space-4);
    }
    .page-header__title {
      font-size: var(--text-2xl);
      letter-spacing: -0.02em;
    }
    .page-header__description {
      margin-top: var(--space-1);
      font-size: var(--text-sm);
      color: var(--text-muted);
    }
    .page-header__actions { display: flex; align-items: center; gap: var(--space-2); }
  CSS

  # The block, if given, renders into the actions area.
  def initialize(title:, description: nil, **attrs)
    @title = title
    @description = description
    @attrs = attrs
  end

  def view_template(&)
    div(class: classes("page-header", @attrs[:class]), **@attrs.except(:class)) do
      div do
        h1(class: "page-header__title") { @title }
        p(class: "page-header__description") { @description } if @description
      end
      div(class: "page-header__actions", &)
    end
  end
end

class DashboardShell < Component
  css <<~CSS
    .shell { display: flex; flex-direction: column; min-height: 100dvh; }
    .shell__body { display: grid; grid-template-columns: 1fr; flex: 1; align-items: start; }
    .shell__sidebar { border-bottom: 1px solid var(--border); }
    .shell__main {
      display: grid;
      gap: var(--space-6);
      align-content: start;
      padding: var(--space-6) var(--space-5);
      width: 100%;
    }
    @media (min-width: 48rem) {
      .shell__body { grid-template-columns: 15rem 1fr; }
      .shell__sidebar { border-bottom: none; border-right: 1px solid var(--border); }
      .shell__main { padding: var(--space-8); }
    }
  CSS

  # Composition: Navbar on top, Sidebar and main content side by side.
  # The block renders into the main area, under a PageHeader.
  def initialize(brand:, nav_links:, sections:, title:, description: nil, sticky: true)
    @brand = brand
    @nav_links = nav_links
    @sections = sections
    @title = title
    @description = description
    @sticky = sticky
  end

  def view_template(&)
    div(class: "shell") do
      render Navbar.new(brand: @brand, links: @nav_links, sticky: @sticky) do
        render IconButton.new(icon: :search, label: "Search")
        render IconButton.new(icon: :bell, label: "Notifications")
        render Avatar.new(initials: "A", label: "Account")
      end
      div(class: "shell__body") do
        render Sidebar.new(sections: @sections)
        main(class: "shell__main") do
          render PageHeader.new(title: @title, description: @description)
          yield
        end
      end
    end
  end
end

# ---------------------------------------------------------------------------
# 7. Page layout
# ---------------------------------------------------------------------------

class AppLayout < Component
  def initialize(title:)
    @title = title
  end

  def view_template(&)
    doctype
    html(lang: "en") do
      head do
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width, initial-scale=1")
        title { @title }
        link(rel: "stylesheet", href: "/app.css")
        script(type: "importmap") { raw safe(IMPORT_MAP) }
      end
      body do
        yield
        script(type: "module", src: "/app.js")
      end
    end
  end
end

# ---------------------------------------------------------------------------
# 8. Pages
# ---------------------------------------------------------------------------
# Shared navigation content for the dashboard pages.

NAV_LINKS = [["Dashboard", "/"], ["Showcase", "/showcase"]].freeze

SIDEBAR_SECTIONS = [
  {
    title: "Overview",
    items: [
      { label: "Dashboard", icon: :dashboard, href: "/", active: true },
      { label: "Analytics", icon: :chart, href: "#" }
    ]
  },
  {
    title: "Workspace",
    items: [
      { label: "Projects", icon: :folder, href: "#" },
      { label: "Tasks", icon: :checklist, href: "#" },
      { label: "Inbox", icon: :inbox, href: "#" }
    ]
  },
  {
    title: "Account",
    items: [
      { label: "Settings", icon: :settings, href: "#" },
      { label: "Log out", icon: :logout, href: "#" }
    ]
  }
].freeze

# The home page: a generic SaaS dashboard shell. No fake product content.
class HomePage < Component
  def view_template
    render AppLayout.new(title: "#{APP_NAME} — Dashboard") do
      render DashboardShell.new(
        brand: APP_NAME,
        nav_links: NAV_LINKS,
        sections: SIDEBAR_SECTIONS,
        title: "Dashboard",
        description: "A starting point. Replace this shell with your product."
      ) do
        render Container.new do
          render EmptyState.new(
            icon: :inbox,
            title: "Nothing here yet",
            description: "This dashboard shell is ready for your first feature. " \
                         "Define a route, add a model, and build from here."
          ) do
            render Button.new("Explore the components", variant: :secondary, href: "/showcase")
          end
        end
      end
    end
  end
end

# --- Showcase helpers --------------------------------------------------------

class ShowcaseSection < Component
  css <<~CSS
    .showcase {
      max-width: var(--container);
      margin-inline: auto;
      padding: var(--space-8) var(--space-5) var(--space-16);
      display: grid;
      gap: var(--space-10);
    }
    .showcase__page-title { font-size: var(--text-2xl); letter-spacing: -0.02em; }
    .showcase__intro { margin-top: var(--space-1); font-size: var(--text-sm); color: var(--text-muted); max-width: 46rem; }
    .showcase__toc { display: flex; flex-wrap: wrap; gap: var(--space-2); }
    .showcase__toc a {
      padding: var(--space-1) var(--space-3);
      font-size: var(--text-xs);
      color: var(--text-muted);
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius-full);
    }
    .showcase__toc a:hover { background: var(--surface-muted); color: var(--text); }
    .showcase__section { display: grid; gap: var(--space-4); }
    .showcase__section-title {
      font-size: var(--text-lg);
      padding-bottom: var(--space-2);
      border-bottom: 1px solid var(--border);
    }
    .showcase__demo {
      display: grid;
      gap: var(--space-3);
      padding: var(--space-4);
      border: 1px dashed var(--border-strong);
      border-radius: var(--radius-md);
    }
    .showcase__demo-label {
      font-size: var(--text-xs);
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      color: var(--text-faint);
    }
    .showcase__demo-row { display: flex; flex-wrap: wrap; align-items: center; gap: var(--space-3); }
    .showcase__demo-stack { display: grid; gap: var(--space-4); justify-items: start; }
    .showcase__grid {
      display: grid;
      gap: var(--space-3);
      grid-template-columns: repeat(auto-fill, minmax(11rem, 1fr));
    }
    .showcase__centered { display: grid; place-items: center; padding: var(--space-6); }
    .showcase__narrow { width: min(24rem, 100%); margin-inline: auto; }
    .showcase__toast-anchor { margin-top: var(--space-3); }
  CSS

  def initialize(id:, title:, description: nil)
    @id = id
    @title = title
    @description = description
  end

  def view_template(&)
    section(class: "showcase__section", id: @id) do
      h2(class: "showcase__section-title") { @title }
      p(class: "u-muted") { @description } if @description
      yield
    end
  end
end

class ShowcaseDemo < Component
  def initialize(label: nil)
    @label = label
  end

  def view_template(&)
    div(class: "showcase__demo") do
      div(class: "showcase__demo-label") { @label } if @label
      yield
    end
  end
end

# --- The showcase page -------------------------------------------------------

class ShowcasePage < Component
  COLOR_TOKENS = [
    ["--bg", "Page background"],
    ["--surface", "Surface"],
    ["--surface-muted", "Muted surface"],
    ["--border", "Border"],
    ["--border-strong", "Strong border"],
    ["--text", "Text"],
    ["--text-muted", "Muted text"],
    ["--text-faint", "Faint text"],
    ["--accent", "Accent"],
    ["--success", "Success"],
    ["--warning", "Warning"],
    ["--danger", "Danger"],
    ["--info", "Info"]
  ].freeze

  RADIUS_TOKENS = [
    ["--radius-sm", "sm"],
    ["--radius-md", "md"],
    ["--radius-lg", "lg"],
    ["--radius-full", "full"]
  ].freeze

  SPACING_TOKENS = (1..8).map { |n| ["--space-#{n}", n.to_s] }.freeze

  ICON_SAMPLE = %i[
    home dashboard chart checklist task inbox folder file database settings
    search bell menu user people plus check close edit trash download calendar
    star globe card
  ].freeze

  SECTIONS = [
    ["colour",   "Colour"], ["typography", "Typography"], ["spacing", "Spacing"],
    ["radius",   "Radius"], ["icons", "Icons"], ["layout", "Layout primitives"],
    ["buttons", "Buttons"],
    ["forms",    "Forms"], ["display", "Display"], ["overlays", "Overlays"],
    ["data",     "Data & feedback"], ["shell", "Shell"], ["examples", "Examples"]
  ].freeze

  def view_template
    render AppLayout.new(title: "Component showcase — #{APP_NAME}") do
      div(class: "showcase") do
        header do
          h1(class: "showcase__page-title") { "Component showcase" }
          p(class: "showcase__intro") do
            plain "Every component, its variants and states, on one page. "
            plain "Restyling changes tokens and component CSS only; Ruby component calls stay unchanged."
          end
        end

        nav(class: "showcase__toc", aria_label: "Sections") do
          SECTIONS.each do |id, label|
            a(href: "##{id}") { label }
          end
        end

        colour_section
        typography_section
        spacing_section
        radius_section
        icons_section
        layout_section
        buttons_section
        forms_section
        display_section
        overlays_section
        data_section
        shell_section
        examples_section
      end
    end
  end

  private

  # --- Tokens -------------------------------------------------------------

  def colour_section
    render ShowcaseSection.new(id: "colour", title: "Colour",
                               description: "Monochrome wireframe tokens plus muted status colours.") do
      render ShowcaseDemo.new(label: "Tokens") do
        div(class: "showcase__grid") do
          COLOR_TOKENS.each do |token, label|
            div do
              div(class: "swatch") do
                div(class: "swatch__chip", style: { background: "var(#{token})" })
                code(class: "swatch__token") { token }
                div(class: "swatch__label") { label }
              end
            end
          end
        end
      end
    end
  end

  def typography_section
    render ShowcaseSection.new(id: "typography", title: "Typography") do
      render ShowcaseDemo.new(label: "Scale") do
        div(class: "showcase__demo-stack", style: { "font-size": "inherit" }) do
          h1 { "Display heading — text-2xl" }
          h2 { "Section heading — text-xl" }
          h3 { "Card heading — text-lg" }
          p { "Body text — text-md. The quick brown fox jumps over the lazy dog." }
          p(class: "u-muted") { "Muted body text — text-sm. The quick brown fox jumps over the lazy dog." }
          small { "Small text — text-xs. The quick brown fox jumps over the lazy dog." }
          code { "Monospace — font-mono" }
        end
      end
    end
  end

  def spacing_section
    render ShowcaseSection.new(id: "spacing", title: "Spacing") do
      render ShowcaseDemo.new(label: "Scale") do
        div(class: "showcase__demo-stack") do
          SPACING_TOKENS.each do |token, label|
            div(class: "spec-row") do
              span(class: "spec-label") { token }
              div(class: "spec-bar", style: { width: "var(#{token})" })
              span(class: "swatch__label") { label }
            end
          end
        end
      end
    end
  end

  def radius_section
    render ShowcaseSection.new(id: "radius", title: "Radius") do
      render ShowcaseDemo.new(label: "Tokens") do
        div(class: "showcase__demo-row") do
          RADIUS_TOKENS.each do |token, label|
            div(class: "swatch") do
              div(class: "radius-demo", style: { "border-radius": "var(#{token})" })
              code(class: "swatch__token") { token }
            end
          end
        end
      end
    end
  end

  def icons_section
    render ShowcaseSection.new(
      id: "icons", title: "Icons",
      description: "Rendered server-side as inline SVG by phlex-icons-huge. Icon.new(:name)."
    ) do
      render ShowcaseDemo.new(label: "A sample of the available icons") do
        div(class: "showcase__grid") do
          ICON_SAMPLE.each do |name|
            div(class: "icon-cell") do
              render Icon.new(name, class: "icon--lg")
              code { name.to_s }
            end
          end
        end
      end
    end
  end

  def layout_section
    render ShowcaseSection.new(
      id: "layout", title: "Layout primitives",
      description: "Generic composition tools: Container, Stack, Cluster, Grid."
    ) do
      render ShowcaseDemo.new(label: "Container") do
        render Container.new(size: :narrow) do
          div(class: "u-muted", style: { background: "var(--surface-muted)",
                                          padding: "var(--space-4)",
                                          "border-radius": "var(--radius-md)",
                                          "border": "1px dashed var(--border-strong)" }) do
            plain "Container size: :narrow (max-width: 48rem)"
          end
        end
      end
      render ShowcaseDemo.new(label: "Stack") do
        render Stack.new(gap: :sm) do
          span { "Item one" }
          span { "Item two" }
          span { "Item three" }
        end
      end
      render ShowcaseDemo.new(label: "Cluster") do
        render Cluster.new(gap: :sm) do
          render Badge.new("design")
          render Badge.new("frontend")
          render Badge.new("backend")
          render Badge.new("ops")
        end
      end
      render ShowcaseDemo.new(label: "Grid") do
        render Grid.new(columns: 4, gap: :sm) do
          4.times { |i| div(style: { background: "var(--surface-muted)", padding: "var(--space-3)",
                                     "border-radius": "var(--radius-md)", "text-align": "center" }) { "Cell #{i + 1}" } }
        end
        render Grid.new(columns: 3, gap: :sm) do
          6.times { |i| div(style: { background: "var(--surface-muted)", padding: "var(--space-3)",
                                     "border-radius": "var(--radius-md)", "text-align": "center" }) { "Cell #{i + 1}" } }
        end
      end
    end
  end

  # --- Actions ------------------------------------------------------------

  def buttons_section
    render ShowcaseSection.new(id: "buttons", title: "Buttons") do
      render ShowcaseDemo.new(label: "Variants") do
        div(class: "showcase__demo-row") do
          render Button.new("Primary")
          render Button.new("Secondary", variant: :secondary)
          render Button.new("Ghost", variant: :ghost)
          render Button.new("Danger", variant: :danger)
          render Button.new("Link", href: "/")
        end
      end
      render ShowcaseDemo.new(label: "Sizes") do
        div(class: "showcase__demo-row") do
          render Button.new("Small", size: :sm)
          render Button.new("Medium")
          render Button.new("Large", size: :lg)
        end
      end
      render ShowcaseDemo.new(label: "With icon and disabled") do
        div(class: "showcase__demo-row") do
          render Button.new("Save changes", icon: :check)
          render Button.new("Download", variant: :secondary, icon: :download)
          render Button.new("Disabled", disabled: true)
          render Button.new("Disabled", variant: :secondary, disabled: true)
        end
      end
      render ShowcaseDemo.new(label: "Icon buttons") do
        div(class: "showcase__demo-row") do
          render IconButton.new(icon: :search, label: "Search")
          render IconButton.new(icon: :bell, label: "Notifications", variant: :ghost)
          render IconButton.new(icon: :trash, label: "Delete", variant: :ghost)
          render IconButton.new(icon: :more, label: "More options", disabled: true)
        end
      end
    end
  end

  # --- Forms --------------------------------------------------------------

  def forms_section
    render ShowcaseSection.new(id: "forms", title: "Forms") do
      render ShowcaseDemo.new(label: "Text fields") do
        div(class: "showcase__grid") do
          render FormField.new(label: "Email", for_id: "su-email", hint: "We never share your email.") do
            render Input.new(id: "su-email", name: "email", type: "email",
                             placeholder: "you@example.com", aria_describedby: "su-email-hint")
          end
          render FormField.new(label: "Workspace name", for_id: "su-name") do
            render Input.new(id: "su-name", name: "name", placeholder: "Acme Inc")
          end
          render FormField.new(label: "Workspace ID", for_id: "su-id",
                               error: "This ID is already taken.") do
            render Input.new(id: "su-id", name: "id", value: "acme", invalid: true,
                             aria_describedby: "su-id-error")
          end
          render FormField.new(label: "API key", for_id: "su-key") do
            render Input.new(id: "su-key", name: "key", value: "sk-live-••••••", disabled: true)
          end
        end
      end
      render ShowcaseDemo.new(label: "Textarea and select") do
        div(class: "showcase__grid") do
          render FormField.new(label: "Description", for_id: "su-desc",
                               hint: "Markdown is supported.") do
            render Textarea.new(id: "su-desc", name: "description",
                                placeholder: "Describe your workspace",
                                aria_describedby: "su-desc-hint")
          end
          render FormField.new(label: "Plan", for_id: "su-plan") do
            render Select.new(id: "su-plan", name: "plan",
                              options: [["free", "Free"], ["team", "Team"], ["business", "Business"]],
                              selected: "team")
          end
          render FormField.new(label: "Disabled select", for_id: "su-region") do
            render Select.new(id: "su-region", name: "region",
                              options: ["EU", "US", "APAC"], disabled: true)
          end
        end
      end
      render ShowcaseDemo.new(label: "Checkbox, radio, switch") do
        div(class: "showcase__grid") do
          render Stack.new(gap: :sm) do
            render Checkbox.new(label: "Product updates", name: "updates", checked: true)
            render Checkbox.new(label: "Weekly digest", name: "digest",
                                description: "A summary of activity in your workspace.")
            render Checkbox.new(label: "Marketing emails", name: "marketing", disabled: true)
          end
          render Stack.new(gap: :sm) do
            render Radio.new(label: "Monthly billing", name: "billing", value: "monthly", checked: true)
            render Radio.new(label: "Annual billing", name: "billing", value: "annual",
                             description: "Two months free.")
            render Radio.new(label: "Invoice", name: "billing", value: "invoice", disabled: true)
          end
          render Stack.new(gap: :sm) do
            render Switch.new(label: "Public profile", name: "public", checked: true)
            render Switch.new(label: "Two-factor authentication", name: "mfa",
                              description: "Require a code at sign-in.")
            render Switch.new(label: "Legacy access", name: "legacy", disabled: true)
          end
        end
      end
    end
  end

  # --- Display ------------------------------------------------------------

  def display_section
    render ShowcaseSection.new(id: "display", title: "Display") do
      render ShowcaseDemo.new(label: "Badges") do
        div(class: "showcase__demo-row") do
          render Badge.new("Default")
          render Badge.new("Outline", variant: :outline)
          render Badge.new("Success", variant: :success)
          render Badge.new("Warning", variant: :warning)
          render Badge.new("Danger", variant: :danger)
          render Badge.new("Info", variant: :info)
        end
      end
      render ShowcaseDemo.new(label: "Avatars") do
        div(class: "showcase__demo-row") do
          render Avatar.new(initials: "AB", size: :sm)
          render Avatar.new(initials: "CD")
          render Avatar.new(initials: "EF", size: :lg)
          render Cluster.new(gap: :sm) do
            render Avatar.new(initials: "A", size: :sm)
            render Avatar.new(initials: "B", size: :sm)
            render Avatar.new(initials: "C", size: :sm)
          end
        end
      end
      render ShowcaseDemo.new(label: "Cards") do
        render Grid.new(columns: 2, gap: :lg) do
          render Card.new(title: "With a title") do
            p(class: "u-muted") { "A card groups related content in a surface." }
          end
          render Card.new do
            render Stack.new(gap: :sm) do
              h3(class: "card__title") { "Without a title" }
              p(class: "u-muted") { "Content is yours to compose with Stack, Cluster, and Grid." }
            end
          end
        end
      end
    end
  end

  # --- Overlays -----------------------------------------------------------

  def overlays_section
    render ShowcaseSection.new(
      id: "overlays", title: "Overlays",
      description: "Dialog and Popover ride native browser behaviour. Tabs use Alpine for client-side state."
    ) do
      render ShowcaseDemo.new(label: "Dialog — native <dialog>") do
        div(class: "showcase__demo-row") do
          render Button.new("Open dialog", variant: :secondary, data_dialog_open: "demo-dialog")
          render Dialog.new(id: "demo-dialog", title: "Invite a teammate") do
            render FormField.new(label: "Email address", for_id: "invite-email") do
              render Input.new(id: "invite-email", type: "email", placeholder: "teammate@example.com")
            end
            div(class: "cluster", style: { "justify-content": "flex-end" }) do
              render Button.new("Cancel", variant: :ghost, type: "submit") { plain "Cancel" }
              render Button.new("Send invite", type: "submit", icon: :mail)
            end
          end
        end
      end
      render ShowcaseDemo.new(label: "Drawer — native <dialog>, side panel") do
        div(class: "showcase__demo-row") do
          render Button.new("Open drawer", variant: :secondary, data_dialog_open: "demo-drawer")
          render Drawer.new(id: "demo-drawer", title: "Appearance") do
            render Stack.new(gap: :md) do
              render Switch.new(label: "Compact mode", name: "compact")
              render Switch.new(label: "Show sidebar", name: "sidebar", checked: true)
              render Select.new(name: "theme", options: ["System", "Light", "Dark"], selected: "Light")
            end
            div(class: "cluster", style: { "justify-content": "flex-end" }) do
              render Button.new("Close", variant: :secondary, type: "submit") { plain "Close" }
            end
          end
        end
      end
      render ShowcaseDemo.new(label: "Popover — native popover attribute") do
        div(class: "showcase__demo-row") do
          render Button.new("Open popover", variant: :secondary, popovertarget: "demo-popover")
          render Popover.new(id: "demo-popover", title: "What is this?") do
            p { "A native popover. Click outside or press Esc to dismiss it." }
          end
        end
      end
      render ShowcaseDemo.new(label: "Dropdown") do
        div(class: "showcase__demo-row") do
          render Dropdown.new(label: "Options", items: [
            { label: "Edit", icon: :edit },
            { label: "Duplicate", icon: :copy },
            { label: "Archive", icon: :archive },
            { label: "Delete", icon: :trash }
          ])
          render Dropdown.new(label: "Account", items: [
            { label: "Profile", icon: :user },
            { label: "Billing", icon: :card },
            { label: "Log out", icon: :logout }
          ])
        end
      end
      render ShowcaseDemo.new(label: "Tabs — Alpine for client state") do
        render Tabs.new(active: "overview") do
          render TabsList.new do
            render TabsTrigger.new(label: "Overview", id: "overview")
            render TabsTrigger.new(label: "Members", id: "members")
            render TabsTrigger.new(label: "Settings", id: "tab-settings")
          end
          render TabPanel.new(id: "overview", initial: true) do
            p(class: "u-muted") { "The first panel. Switching tabs is client-side state, so Alpine owns it." }
          end
          render TabPanel.new(id: "members") do
            render Table.new(
              headers: ["Name", "Role"],
              rows: [["Ada Lovelace", "Owner"], ["Grace Hopper", "Admin"], ["Alan Turing", "Member"]]
            )
          end
          render TabPanel.new(id: "tab-settings") do
            render Stack.new(gap: :sm) do
              render Switch.new(label: "Allow invites", name: "invites", checked: true)
              render Switch.new(label: "Require approval", name: "approval")
            end
          end
        end
      end
    end
  end

  # --- Data and feedback --------------------------------------------------

  def data_section
    render ShowcaseSection.new(id: "data", title: "Data and feedback") do
      render ShowcaseDemo.new(label: "Table") do
        render Card.new(flush: true) do
          render Table.new(
            headers: ["Resource", "Status", "Owner", "Updated"],
            rows: [
              ["Landing page", Badge.new("Live", variant: :success), "Ada", "2 days ago"],
              ["Mobile app", Badge.new("In review", variant: :warning), "Grace", "5 hours ago"],
              ["Data import", Badge.new("Failed", variant: :danger), "Alan", "1 week ago"],
              ["API keys", Badge.new("Draft", variant: :outline), "Ada", "3 weeks ago"]
            ]
          )
        end
      end
      render ShowcaseDemo.new(label: "Empty state") do
        render Card.new do
          render EmptyState.new(
            icon: :folder,
            title: "No projects yet",
            description: "Projects group your work. Create your first one to get going."
          ) do
            render Button.new("New project", icon: :plus)
          end
        end
      end
      render ShowcaseDemo.new(label: "Alerts") do
        render Grid.new(columns: 2, gap: :md) do
          render Alert.new(variant: :info, title: "Heads up") { "A new version is available." }
          render Alert.new(variant: :success, title: "Saved") { "Your changes are live." }
          render Alert.new(variant: :warning, title: "Approaching limit") { "You have used 9 of 10 seats." }
          render Alert.new(variant: :danger, title: "Build failed") { "Check the logs, then retry the deploy." }
        end
      end
      render ShowcaseDemo.new(label: "Toasts — live demo with Alpine") do
        div("x-data": "{ visible: false }") do
          render Button.new("Trigger toast", variant: :secondary,
                            "@click": "visible = true; setTimeout(() => visible = false, 4000)")
          div(class: "showcase__toast-anchor", "x-show": "visible", "x-transition": true,
              "x-cloak" => true) do
            render Toast.new(variant: :success, title: "Changes saved",
                             description: "Your settings were updated.",
                             on_close: "visible = false")
          end
        end
        render Stack.new(gap: :sm) do
          render Toast.new(variant: :info, title: "Sync started")
          render Toast.new(variant: :warning, title: "Storage almost full",
                           description: "Delete old exports to free space.")
          render Toast.new(variant: :danger, title: "Connection lost")
        end
      end
    end
  end

  # --- Shell --------------------------------------------------------------

  def shell_section
    render ShowcaseSection.new(
      id: "shell", title: "Application shell",
      description: "PageHeader, Navbar, and Sidebar. The full shell composition appears in Examples."
    ) do
      render ShowcaseDemo.new(label: "PageHeader") do
        render PageHeader.new(title: "Team", description: "Manage members and their roles.") do
          render Button.new("Invite member", variant: :secondary, icon: :plus)
        end
      end
      render ShowcaseDemo.new(label: "Navbar") do
        div(style: { overflow: "hidden", "border-radius": "var(--radius-md)" }) do
          render Navbar.new(brand: "Example", links: [["Home", "#"], ["Docs", "#"], ["Pricing", "#"]],
                            sticky: false) do
            render IconButton.new(icon: :search, label: "Search", variant: :ghost)
            render Button.new("Sign in", variant: :secondary, size: :sm)
          end
        end
      end
      render ShowcaseDemo.new(label: "Sidebar") do
        div(style: { "max-width": "16rem", background: "var(--surface)",
                     "border-radius": "var(--radius-md)" }) do
          render Sidebar.new(sections: [
            { title: "Menu", items: [
              { label: "Dashboard", icon: :dashboard, href: "#", active: true },
              { label: "Analytics", icon: :chart, href: "#" }
            ] },
            { title: "Workspace", items: [
              { label: "Projects", icon: :folder, href: "#" },
              { label: "Settings", icon: :settings, href: "#" }
            ] }
          ])
        end
      end
    end
  end

  # --- Composed examples ----------------------------------------------------

  def examples_section
    render ShowcaseSection.new(
      id: "examples", title: "Composed examples",
      description: "Component compositions on this page only; they are not application features."
    ) do
      render ShowcaseDemo.new(label: "Login form") do
        div(class: "showcase__narrow") do
          render Card.new(title: "Sign in") do
            render Stack.new(gap: :lg) do
              render FormField.new(label: "Email", for_id: "login-email",
                                   error: "Enter a valid email address.") do
                render Input.new(id: "login-email", type: "email", value: "ada@", invalid: true,
                                 aria_describedby: "login-email-error", autocomplete: "email")
              end
              render FormField.new(label: "Password", for_id: "login-password",
                                   hint: "At least 8 characters.") do
                render Input.new(id: "login-password", type: "password",
                                 aria_describedby: "login-password-hint", autocomplete: "current-password")
              end
              render Button.new("Sign in", block: true)
              p(class: "u-muted", style: { "text-align": "center", "font-size": "var(--text-sm)" }) do
                plain "Forgot your password? "
                a(href: "#", style: { "text-decoration": "underline" }) { "Reset it" }
              end
            end
          end
        end
      end
      render ShowcaseDemo.new(label: "Settings page") do
        render Stack.new(gap: :lg) do
          render PageHeader.new(title: "Settings", description: "Manage your workspace.") do
            render Button.new("Cancel", variant: :ghost)
            render Button.new("Save changes", icon: :check)
          end
          render Grid.new(columns: 2, gap: :lg) do
            render Card.new(title: "Profile") do
              render Stack.new(gap: :md) do
                render FormField.new(label: "Name", for_id: "set-name") do
                  render Input.new(id: "set-name", value: "Ada Lovelace")
                end
                render FormField.new(label: "Email", for_id: "set-email") do
                  render Input.new(id: "set-email", type: "email", value: "ada@example.com")
                end
              end
            end
            render Card.new(title: "Notifications") do
              render Stack.new(gap: :md) do
                render Switch.new(label: "Product emails", name: "n-product", checked: true)
                render Switch.new(label: "Security alerts", name: "n-security", checked: true,
                                  description: "Sent to all admins.")
                render Switch.new(label: "Marketing", name: "n-marketing")
              end
            end
            render Card.new(title: "Danger zone") do
              render Stack.new(gap: :md) do
                p(class: "u-muted") { "Deleting the workspace removes all data. This cannot be undone." }
                render Button.new("Delete workspace", variant: :danger, icon: :trash)
              end
            end
          end
        end
      end
      render ShowcaseDemo.new(label: "Dashboard shell") do
        div(style: { "border-radius": "var(--radius-lg)", overflow: "hidden",
                     border: "1px solid var(--border)" }) do
          render DashboardShell.new(
            brand: "Example",
            nav_links: [["Dashboard", "#"], ["Showcase", "/showcase"]],
            sections: [
              { title: "Overview", items: [
                { label: "Dashboard", icon: :dashboard, href: "#", active: true },
                { label: "Analytics", icon: :chart, href: "#" }
              ] },
              { title: "Workspace", items: [
                { label: "Projects", icon: :folder, href: "#" },
                { label: "Settings", icon: :settings, href: "#" }
              ] }
            ],
            title: "Overview",
            description: "A composed dashboard with a data table.",
            sticky: false
          ) do
            render Card.new(title: "Recent activity", flush: true) do
              render Table.new(
                headers: ["Resource", "Status", "Updated"],
                rows: [
                  ["Landing page", Badge.new("Live", variant: :success), "2 days ago"],
                  ["Mobile app", Badge.new("In review", variant: :warning), "5 hours ago"],
                  ["Data import", Badge.new("Failed", variant: :danger), "1 week ago"]
                ]
              )
            end
          end
        end
      end
      render ShowcaseDemo.new(label: "Empty dashboard") do
        div(style: { "border-radius": "var(--radius-lg)", overflow: "hidden",
                     border: "1px solid var(--border)" }) do
          render DashboardShell.new(
            brand: "Example",
            nav_links: [["Dashboard", "#"]],
            sections: [{ title: "Overview", items: [
              { label: "Dashboard", icon: :dashboard, href: "#", active: true }
            ] }],
            title: "Dashboard",
            description: "Same shell, empty state.",
            sticky: false
          ) do
            render EmptyState.new(
              icon: :folder,
              title: "No projects yet",
              description: "This is where your product's first feature will live."
            ) do
              render Button.new("New project", icon: :plus)
            end
          end
        end
      end
    end
  end
end

# ---------------------------------------------------------------------------
# 9. Routes
# ---------------------------------------------------------------------------

class App < Sinatra::Base
  get "/" do
    HomePage.new.call
  end

  get "/showcase" do
    ShowcasePage.new.call
  end

  # Every CSS and JS declaration in this file, combined. No public/ directory.
  get "/app.css" do
    content_type "text/css", charset: "utf-8"
    Assets.css
  end

  get "/app.js" do
    content_type "text/javascript", charset: "utf-8"
    Assets.js
  end
end

App.run! if $PROGRAM_NAME == __FILE__
