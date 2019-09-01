# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capybara/paparazzi/version'

Gem::Specification.new do |spec|
  spec.name          = "capybara-paparazzi"
  spec.version       = Capybara::Paparazzi::VERSION
  spec.authors       = ["Steven Bull"]
  spec.email         = ["steven@thebulls.us"]
  spec.description = <<DESCRIPTION
Capybara::Paparazzi automatically takes screenshots of all of your pages,
in a variety of different window sizes. It clearly indicates where the
initial view of the page cuts off (the "fold"), and is easily configurable.
DESCRIPTION
  spec.summary       = 'Take responsive screenshots of your site.'
  spec.homepage      = 'https://github.com/sbull/capybara-paparazzi'
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency 'capybara', '>= 2.0'
end
