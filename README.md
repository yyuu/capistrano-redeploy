# capistrano-redeploy

A dangerous recipe that overwrites your running application.

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-redeploy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-redeploy

## Usage

*THIS RECIPE MAY CORRUPT YOUR RUNNING APPLICATION. TAKE SPECIAL CARE FOR YOUR CONFIGURATION/OPERATION.*

The `capistrano-redeploy` will try to perform following actions.

1. Deploy application to temporary directory on remote servers
2. Copy sources from temporary directory to running application

To enable `capistrano-redeploy`, add require line in your `config/deploy.rb`.

    # config/deploy.rb
    require "capistrano-redeploy"

Then, you can overwrite running application. By default, files in `public` will be overwritten on redeployment.

    % cap redeploy

There are some options to configure redeployment for your application.

* `:redeploy_path` - The directory to redeploy to. Use `:current_release` by default.
* `:redeploy_children` - The list of directories to redeploy. Use `["public"]` by default.
* `:redeploy_exclusions` - The exclude list for redeployment. Use `["assets", "system"]` by default.
* `:redeploy_variables` - Supplimental variables for redeployment. See [Examples](#examples) for usage.
* `:redeploy_use_assets` - Invoke `assets:precompile` after redeploy. Disabled by default.

## Examples

### Redeploy files from repository

Redeploy files in `public` (except `public/assets` and `public/system`) from external repository.

    # config/deploy.rb
    set :scm, :git
    set :deploy_via, :copy
    set :repository, "git://example.com/example.git"
    set :redeploy_children, ["public"]
    set :redeploy_exclusions, ["assets", "system"]

### Redeploy files from local path

Redeploy files in `public` (except `public/assets` and `public/system`) from current directory.

    # config/deploy.rb
    set :scm, :git
    set :deploy_via, :copy
    set :repository, "git://example.com/example.git"
    set :redeploy_variables, {
      :scm => :none,
      :deploy_via => :copy,
      :repository => ".", # redeploy from current directory
    }
    set :redeploy_children, ["public"]
    set :redeploy_exclusions, ["assets", "system"]

### Redeploy files from local path with different names

Redeploy files in `src/main/webapp` from current directory to `target/webapp/WEB-INF`.

    # config/deploy.rb
    set :scm, :git
    set :deploy_via, :copy
    set :repository, "git://example.com/example.git"
    set :redeploy_variables, {
      :scm => :none,
      :deploy_via => :copy,
      :repository => ".", # redeploy from current directory
      :copy_cache => nil,
    }
    set :redeploy_source, "src/main/webapp"
    set :redeploy_destination, "target/webapp/WEB-INF"
    set :redeploy_children, ["."]
    set :redeploy_exclusions, ["WEB-INF/web.xml"]


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Author

- YAMASHITA Yuu (https://github.com/yyuu)
- Geisha Tokyo Entertainment Inc. (http://www.geishatokyo.com/)

## License

MIT
