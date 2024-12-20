require_relative 'lib/nugem/version'

Gem::Specification.new do |spec|
  host = 'https://github.com/mslinn/nugem'

  spec.authors               = ['Igor Jancev', 'Mike Slinn']
  spec.bindir                = 'exe'
  spec.description = <<~END_DESC
    Nugem creates a scaffold project for new gems. You can choose between Github and Bitbucket,
    Rubygems or Geminabox, with or without an executable, etc.
  END_DESC
  spec.email                 = ['igor@masterybits.com', 'mslinn@mslinn.com']
  spec.executables           = %w[nugem]
  spec.files                 = Dir[
                                  '.rubocop.yml',
                                  'Gemfile',
                                  'LICENSE.*',
                                  'Rakefile',
                                  '{lib,spec,templates}/**/*',
                                  'templates/**/.*',
                                  'templates/**/.*/*',
                                  '*.gemspec',
                                  '*.md'
                                ]
  spec.homepage              = 'https://github.com/mslinn/nugem'
  spec.license               = 'MIT'
  spec.metadata = {
    'allowed_push_host' => 'https://rubygems.org',
    'bug_tracker_uri'   => "#{host}/issues",
    'changelog_uri'     => "#{host}/CHANGELOG.md",
    'homepage_uri'      => spec.homepage,
    'source_code_uri'   => host,
  }
  spec.name                  = 'nugem'
  spec.platform              = Gem::Platform::RUBY
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 3.1.0'
  spec.summary               = 'Nugem creates a scaffold project for new gems.'
  spec.version               = Nugem::VERSION

  spec.add_dependency 'jekyll'
  spec.add_dependency 'rugged'
  spec.add_dependency 'thor'
end
