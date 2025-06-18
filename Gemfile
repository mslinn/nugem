source 'https://rubygems.org'

# Runtime gem dependencies are specified in nugem.gemspec
gemspec

gem_support = ENV.fetch('gem_support', nil)
unless gem_support
  puts "Environment variable 'gem_support' is not set. Please set it to the path of the gem_support gem."
  exit 1
end
gem 'gem_support', path: gem_support

group :development do
  gem 'bump'
  gem 'erb_lint'
  gem 'gem-release', require: false
  gem 'rubocop', require: false
  gem 'rubocop-md', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
end

group :test, :development do
  gem 'bundler', require: false
  gem 'debug', '>= 1.0.0', require: false
  gem 'rake', require: false
  gem 'rspec', require: false
end
