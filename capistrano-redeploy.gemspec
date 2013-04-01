# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano-redeploy/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-redeploy"
  spec.version       = Capistrano::ReDeploy::VERSION
  spec.authors       = ["Yamashita Yuu"]
  spec.email         = ["yamashita@geishatokyo.com"]
  spec.description   = %q{A dangerous recipe that overwrites your running application.}
  spec.summary       = %q{A dangerous recipe that overwrites your running application.}
  spec.homepage      = "https://github.com/yyuu/capistrano-redeploy"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "capistrano"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "capistrano-copy-subdir", ">= 0.1.0"
  spec.add_development_dependency "capistrano-platform-resources", ">= 0.1.0"
  spec.add_development_dependency "net-scp", "~> 1.0.4"
  spec.add_development_dependency "net-ssh", "~> 2.2.2"
  spec.add_development_dependency "vagrant", "~> 1.0.6"
end
