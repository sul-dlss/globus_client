# frozen_string_literal: true


lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'globus/client/version'

Gem::Specification.new do |spec|
  spec.name = 'globus_client'
  spec.version = Globus::Client::VERSION
  spec.authors = ['Aaron Collier']
  spec.email = ['aaron.collier@stanford.edu']

  spec.summary = 'Interface for interacting with the Globus API.'
  spec.description = 'This provides API interaction with the Globus API'
  spec.homepage = 'https://github.com/sul-dlss/globus_client'
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sul-dlss/globus_client'
  spec.metadata['changelog_uri'] = 'https://github.com/sul-dlss/globus_client/releases'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'activesupport', '>= 4.2', '< 8'
  spec.add_dependency 'config'
  spec.add_dependency 'faraday'
  
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
  spec.add_development_dependency 'webmock'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
