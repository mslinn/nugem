source 'https://rubygems.org'

# Runtime gem dependencies are specified in nugem.gemspec
gemspec

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

group :test do
  gem 'rspec-match_ignoring_whitespace'
end
