require_relative '../lib/nugem'

require 'coveralls'
Coveralls.wear!

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
