require_relative 'lib/nugem/version'

Gem::Specification.new do |spec|
  spec.authors       = ['Igor Jancev', 'Mike Slinn']
  spec.bindir        = 'exe'
  spec.email         = ['igor@masterybits.com', 'mslinn@mslinn.com']
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.files         = Dir['.rubocop.yml', 'LICENSE.*', 'Rakefile', '{lib,spec}/**/*', '*.gemspec', '*.md']
  spec.description   = <<~END_DESC
    Nugem creates a scaffold project for new gems. You can choose between Github and Bitbucket,
    Rubygems or Geminabox, with or without an executable, etc.
  END_DESC
  spec.homepage      = 'https://github.com/mslinn/nugem'
  spec.license       = 'MIT'
  spec.name          = 'nugem'
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.1.0'
  spec.summary       = 'Nugem creates a scaffold project for new gems.'
  spec.version       = Nugem::VERSION

  spec.add_dependency 'rugged'
  spec.add_dependency 'thor'
end