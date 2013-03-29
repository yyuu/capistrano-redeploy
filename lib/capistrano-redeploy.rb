require "capistrano-redeploy/version"

module Capistrano
  module ReDeploy
    def self.extended(configuration)
      configuration.load {
        namespace(:redeploy) {
          desc("Redeploy current running application.")
          task(:default, :except => { :no_release => true }) {
            update
          }

          task(:update, :except => { :no_release => true }) {
            transaction do
              update_code
              finalize_update
            end
          }

          _cset(:redeploy_path) { current_release }
          task(:update_code, :except => { :no_release => true }) {
            begin
              tmpdir = capture("mktemp -d /tmp/redeploy.XXXXXXXXXX").strip
              run("rm -rf #{tmpdir.dump} && mkdir -p #{tmpdir}")
              deploy!(tmpdir)
              redeploy!(tmpdir, redeploy_path)
            ensure
              run("rm -rf #{tmpdir.dump}")
            end
          }
          on(:load) {
            if fetch(:redeploy_use_assets, false)
              before "redeploy:finalize_update",   "deploy:assets:symlink"
              after  "redeploy:update_code",       "deploy:assets:precompile"
              before "redeploy:assets:precompile", "deploy:assets:update_asset_mtimes"
            end
          }

          # Return a copy of given object
          # Unlike Object#dup, this also duplicates instance variables.
          def _middle_copy(object)
            o = object.clone
            object.instance_variables.each do |k|
              v = object.instance_variable_get(k)
              o.instance_variable_set(k, v ? v.clone : v)
            end
            o
          end

          _cset(:redeploy_variables, {})
          def deploy!(destination, options={})
            begin
              releases_path = capture("mktemp -d /tmp/releases.XXXXXXXXXX", options).strip
              release_path = File.join(releases_path, release_name)
              run("rm -rf #{releases_path.dump} && mkdir -p #{releases_path.dump}", options)
              c = _middle_copy(top)
              c.instance_eval do
                set(:deploy_to, File.dirname(releases_path))
                set(:releases_path, releases_path)
                set(:release_path, release_path)
                set(:revision) { source.head }
                set(:source) { ::Capistrano::Deploy::SCM.new(scm, self) }
                set(:real_revision) { source.local.query_revision(revision) { |cmd| with_env("LC_ALL", "C") { run_locally(cmd) } } }
                set(:strategy) { ::Capistrano::Deploy::Strategy.new(deploy_via, self) }
                # merge variables
                redeploy_variables.each do |key, val|
                  set(key, val)
                end
                strategy.deploy!
              end
              run("rsync -lrpt #{(release_path + "/").dump} #{destination.dump}", options)
            ensure
              run("rm -rf #{releases_path.dump}", options)
            end
          end

          _cset(:redeploy_children, %w(public))
          _cset(:redeploy_exclusions, %w(assets system))
          _cset(:redeploy_path_map) {
            s = fetch(:redeploy_source, ".").to_s
            d = fetch(:redeploy_destination, ".").to_s
            Hash[redeploy_children.map { |c| [File.join(s, c), File.join(d, c)] }]
          }
          def absolute_path_map(source, destination)
            map = redeploy_path_map.map { |s_subdir, d_subdir|
              [ File.expand_path(File.join(source, s_subdir)), File.expand_path(File.join(destination, d_subdir)) ]
            }
            Hash[map]
          end

          def redeploy!(source, destination, options={})
            exclusions = redeploy_exclusions.map { |e| "--exclude=#{e.dump}" }.join(" ")
            absolute_path_map(source, destination).each do |s, d|
              logger.info("redeploy: #{s} -> #{d}")
              run("mkdir -p #{s.dump} #{d.dump}", options)
              run("rsync -lrpt #{exclusions} #{(s + "/").dump} #{d.dump}", options)
            end
          end

          task(:finalize_update, :except => { :no_release => true }) {
            escaped_release = redeploy_path.to_s.shellescape
            commands = []
            commands << "chmod -R -- g+w #{escaped_release}" if fetch(:group_writable, true)

            # mkdir -p is making sure that the directories are there for some SCM's that don't
            # save empty folders
            shared_children.map do |dir|
              d = dir.shellescape
              if (dir.rindex('/')) then
                commands += ["rm -rf -- #{escaped_release}/#{d}",
                             "mkdir -p -- #{escaped_release}/#{dir.slice(0..(dir.rindex('/'))).shellescape}"]
              else
                commands << "rm -rf -- #{escaped_release}/#{d}"
              end
              commands << "ln -s -- #{shared_path}/#{dir.split('/').last.shellescape} #{escaped_release}/#{d}"
            end

            run commands.join(' && ') if commands.any?

            if fetch(:normalize_asset_timestamps, true)
              stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
              asset_paths = fetch(:public_children, %w(images stylesheets javascripts)).map { |p| "#{escaped_release}/public/#{p}" }
              run("find #{asset_paths.join(" ")} -exec touch -t #{stamp} -- {} ';'; true",
                  :env => { "TZ" => "UTC" }) if asset_paths.any?
            end
          }
        }
      }
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::ReDeploy)
end
