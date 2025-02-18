# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'globus_client/version'

Gem::Specification.new do |spec|
  spec.name = 'globus_client'
  spec.version = GlobusClient::VERSION
  spec.authors = ['Aaron Collier', 'Laura Wrubel', 'Mike Giarlo']
  spec.email = ['aaron.collier@stanford.edu', 'lwrubel@stanford.edu', 'mjgiarlo@stanford.edu']

  spec.summary = 'Interface for interacting with the Globus API.'
  spec.description = 'This provides API interaction with the Globus API'
  spec.homepage = 'https://github.com/sul-dlss/globus_client'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sul-dlss/globus_client'
  spec.metadata['changelog_uri'] = 'https://github.com/sul-dlss/globus_client/releases'
  spec.metadata['rubygems_mfa_required'] = 'true'

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

  spec.add_dependency 'activesupport', '>= 4.2'
  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday-retry'
  spec.add_dependency 'zeitwerk'
end
