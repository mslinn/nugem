require 'rspec/expectations'

require_relative '../lib/nugem'

RSpec.configure do |config|
  # See https://relishapp.com/rspec/rspec-core/docs/command-line/only-failures
  config.example_status_persistence_file_path = 'spec/status_persistence.txt'

  # See https://rspec.info/features/3-12/rspec-core/filtering/filter-run-when-matching/
  # and https://github.com/rspec/rspec/issues/221
  config.filter_run_when_matching :focus

  # Other values: :progress, :html, :json, CustomFormatterClass
  config.formatter = :documentation

  # See https://rspec.info/features/3-12/rspec-core/command-line/order/
  config.order = :defined

  # See https://www.rubydoc.info/github/rspec/rspec-core/RSpec%2FCore%2FConfiguration:pending_failure_output
  config.pending_failure_output = :skip
end
