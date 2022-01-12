# Rakefile
#
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will be automatically
# available to Rake.

require_relative 'config/application'

# Ensure that ERB asset pre-processing comes before the 'jsbundling-rails' and
# 'cssbundling-rails' enhancements of 'assets:precompile'.
class EmmaRailtie < Rails::Railtie
  rake_tasks do
    load 'lib/tasks/emma_assets.rake'
  end
end

Rails.application.load_tasks
