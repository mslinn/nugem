require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'

require_relative 'spec_helper'
require_relative '../lib/nugem'

# TODO: Test GitHub and GitLab
class RepositoryTest
  RSpec.describe Nugem::Repository do
    it 'tests bitbucket' do
      repo = described_class.new(
        host:           :bitbucket,
        private:        true,
        user:           'maxmustermann',
        name:           :testrepo,
        gem_server_url: 'https://gems.mustermann.com'
      )
      expect(repo.origin).to eq('git@bitbucket.org:maxmustermann/testrepo.git')
      expect(repo.private?).to be_truthy
      expect(repo.public?).to be_falsey
      expect(repo.bitbucket?).to be_truthy
      expect(repo.github?).to be_falsey
      expect(repo.gitlab?).to be_falsey
    end

    it 'tests github' do
      repo = described_class.new(
        host:           :github,
        user:           'maxmustermann',
        name:           :testrepo,
        gem_server_url: 'https://rubygems.org'
      )
      expect(repo.origin).to eq('git@github.com:maxmustermann/testrepo.git')
      expect(repo.private?).to be_falsey
      expect(repo.public?).to be_truthy
      expect(repo.bitbucket?).to be_falsey
      expect(repo.github?).to be_truthy
      expect(repo.gitlab?).to be_falsey
    end
  end
end
