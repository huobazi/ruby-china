require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require 'mina/puma'
require 'mina_sidekiq/tasks'

set :domain, '123.56.126.53' #'community.readface.cn'
set :deploy_to, '/var/www/community.readface.cn'
set :repository,  'git://github.com/rivid/ruby-china.git'
set :branch, 'postgresql'

set :deploy_environment, 'production'
set :code_revision, `git log --pretty=format:%h -n1`.strip

set :rbenv_path, '/home/ubuntu/.rbenv'
set :bundle_gemfile,  "#{deploy_to}/current/Gemfile"


set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'log', 'public/uploads', 'config/puma.rb']

set :user, 'ubuntu'
set :shared_path, 'shared'

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  queue %{export RBENV_ROOT=#{rbenv_path}}
  queue %{export RAKE_ENV=#{deploy_environment}}
  queue %{export RAILS_ENV=#{deploy_environment}}
  queue %{export RAILS_CACHE_ID=#{code_revision}}
  invoke :'rbenv:load'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/tmp/sockets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/sockets"]

  queue! %[mkdir -p "#{deploy_to}/shared/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp/pids"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue! %[touch "#{deploy_to}/#{shared_path}/config/secrets.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml' and 'secrets.yml'."]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  queue  %[echo "-----> Server: #{domain}."]
  queue  %[echo "-----> Path: #{deploy_to}."]
  queue  %[echo "-----> Environment: #{deploy_environment}."]
  queue  %[echo "-----> Branch: #{branch}."]
  to :before_hook do
    # Put things to run locally before ssh
  end

  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'cdn:upload_assets'
    invoke :'deploy:cleanup'

    to :launch do
      invoke :'puma:restart'
    end
  end
end

namespace :cdn do
  task :upload_assets => :environment do
    queue "cd #{current_path}; RAILS_ENV=production bundle exec rake assets:cdn"
  end
end
