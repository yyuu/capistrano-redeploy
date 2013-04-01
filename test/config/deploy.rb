set :application, "capistrano-redeploy"
set :repository, "git@github.com:yyuu/capistrano-redeploy.git"
set :deploy_to do
  File.join("/home", user, application)
end
set :deploy_via, :copy_subdir
set :deploy_subdir, "test/project"
set :scm, :git
set :use_sudo, false
set :user, "vagrant"
set :password, "vagrant"
set :ssh_options, {:user_known_hosts_file => "/dev/null"}

role :web, "192.168.33.10"
role :app, "192.168.33.10"
role :db,  "192.168.33.10", :primary => true

$LOAD_PATH.push(File.expand_path("../../lib", File.dirname(__FILE__)))
require "capistrano/configuration/resources/platform_resources"
require "capistrano-redeploy"
require "pathname"

task(:test_all) {
  find_and_execute_task("test_default")
  find_and_execute_task("test_none")
  find_and_execute_task("test_none_with_rename_path")
}

on(:load) {
  run("rm -rf #{deploy_to.dump}")
  platform.packages.install("rsync") unless platform.packages.installed?("rsync")
  find_and_execute_task("deploy:setup")
  find_and_execute_task("deploy")
  find_and_execute_task("deploy")
}

def reset_all!()
  variables.each_key do |key|
    reset!(key)
  end
end

def _test_redeploy
  public_path = File.join(current_path, "public")
  backup_path = public_path + ".orig"
  # touch currently deployed public contents with old timestamp
  ts = (Time.now - 60*60*24*365).strftime("%Y%m%d%H%M")
  run("touch -t #{ts} #{public_path}/*")
  # copy public as public.orig
  run("rm -rf #{backup_path.dump} && cp -RPp #{public_path.dump} #{backup_path.dump}")
  find_and_execute_task("redeploy")
  run("test #{File.join(backup_path, "index.html").dump} -ot #{File.join(public_path, "index.html").dump}")
ensure
  run("rm -rf #{backup_path.dump}")
end

def _test_redeploy_exclusions
  precompiled_asset = File.join(current_path, "public", "assets", "precompiled")
  run("mkdir -p #{File.dirname(precompiled_asset).dump} && touch #{precompiled_asset.dump}")
  find_and_execute_task("redeploy")
  run("test -f #{precompiled_asset.dump}")
ensure
  run("rm -f #{precompiled_asset.dump}")
end

namespace(:test_default) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_default", "test_default:setup"
  after "test_default", "test_default:teardown"

  task(:setup) {
    set(:redeploy_source, ".")
    set(:redeploy_destination, ".")
    set(:redeploy_children, %w(public))
    set(:redeploy_exclusions, %w(assets system))
    set(:redeploy_variables, {})
    reset_all!
  }

  task(:teardown) {
  }

  task(:test_redeploy) {
    _test_redeploy
  }

  task(:test_redeploy_exclusions) {
    _test_redeploy_exclusions
  }
}

namespace(:test_none) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_none", "test_none:setup"
  after "test_none", "test_none:teardown"

  task(:setup) {
    set(:redeploy_source, ".")
    set(:redeploy_destination, ".")
    set(:redeploy_children, %w(public))
    set(:redeploy_exclusions, %w(assets system))
    set(:redeploy_variables) {{
      :scm => :none, :deploy_via => :copy,
      :repository => File.expand_path("../project", File.dirname(__FILE__)),
    }}
    reset_all!
  }

  task(:teardown) {
  }

  task(:test_redeploy) {
    _test_redeploy
  }

  task(:test_redeploy_exclusions) {
    _test_redeploy_exclusions
  }
}

namespace(:test_none_with_rename_path) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_none_with_rename_path", "test_none_with_rename_path:setup"
  after "test_none_with_rename_path", "test_none_with_rename_path:teardown"

  task(:setup) {
    set(:redeploy_source, "app")
    set(:redeploy_destination, "xxx")
    set(:redeploy_children, %w(controllers models views))
    set(:redeploy_exclusions, %w())
    set(:redeploy_variables) {{
      :scm => :none, :deploy_via => :copy,
      :repository => File.expand_path("../project", File.dirname(__FILE__)),
    }}
    reset_all!
  }

  task(:teardown) {
  }

  task(:test_none_with_rename_path) {
    begin
      src_path = File.join(current_path, redeploy_source)
      dst_path = File.join(current_path, redeploy_destination)
      find_and_execute_task("redeploy")
      redeploy_children.each do |c|
        run("diff -r #{File.join(src_path, c).dump} #{File.join(dst_path, c).dump}")
      end
    ensure
      run("rm -rf #{dst_path.dump}")
    end
  }
}

# vim:set ft=ruby sw=2 ts=2 :
