require_relative 'lib/nugem/version'

Gem::Specification.new do |spec|
  host = 'https://github.com/mslinn/nugem'

  spec.authors               = ['Igor Jancev', 'Mike Slinn']
  spec.bindir                = 'exe'
  spec.description = <<~END_DESC
    Nugem creates a scaffold project for new gems. You can choose between Github and Bitbucket,
    with or without an executable, and options can be specified.
  END_DESC
  spec.email                 = ['igor@masterybits.com', 'mslinn@mslinn.com']
  spec.executables           = %w[nugem]
  spec.files                 = Dir[
                                  '.rubocop.yml',
                                  '.rspec',
                                  '.shellcheckrc',
                                  'Gemfile',
                                  'LICENSE.*',
                                  'Rakefile',
                                  '{exe,lib,spec,templates}/**/*',
                                  'templates/**/.*',
                                  'templates/**/.*/*',
                                  '*.gemspec',
                                  '*.json',
                                  '*.md'
                                ]
  spec.homepage              = 'https://www.mslinn.com/ruby/6800-nugem.html'
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

  spec.add_dependency 'colorize'
  spec.add_dependency 'custom_binding'
  spec.add_dependency 'gem_support'
  spec.add_dependency 'highline'
  spec.add_dependency 'jekyll'
  spec.add_dependency 'logger'
  spec.add_dependency 'optparse'
  spec.add_dependency 'rugged'
  spec.add_dependency 'sod' # See https://rubygems.org/gems/sod
end
