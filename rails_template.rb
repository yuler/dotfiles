# refs: https://guides.rubyonrails.org/rails_application_templates.html
# rubocop:disable Layout/HeredocIndentation
gem_file = <<~GEM_FILE
source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.0.0"

# Drivers
gem "sqlite3", ">= 2.1"

# Deployment
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "thruster", require: false
gem "kamal", require: false

# Front-end
gem "propshaft"
gem "jsbundling-rails"
gem "cssbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Job mission
# gem "mission_control-jobs"

# Other
gem "jbuilder"
gem "bcrypt", "~> 3.1.7"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "image_processing", "~> 1.2"
gem "faraday"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "erb_lint", require: false
  gem "dotenv-rails"
end

group :development do
  gem "hotwire-livereload"
  gem "letter_opener"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
GEM_FILE
# rubocop:enable Layout/HeredocIndentation

run "echo '#{gem_file}' > Gemfile"
run "echo '# #{@app_name.titleize}' > README.md"

run "bundle lock --add-platform x86_64-linux"

git :init
git add: "."
git commit: "-a -m 'Initial commit'"

if yes?("Run `rails generate authentication`?")
  generate "authentication"
  rails_command "db:migrate"

  git add: "."
  git commit: "-a -m 'Add authentication'"
end

run <<~COMMANDS
  echo ''
  echo ''
  echo '---'
  echo 'cd #{@app_name}'
  echo './bin/dev'
  echo '---'
COMMANDS
