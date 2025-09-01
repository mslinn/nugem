require_relative 'spec_helper'
require_relative '../lib/nugem'

# Do not use let to define variables so ArbitraryContextBinding can be constructed properly
RSpec.describe 'Getters' do
  repository = Nugem::Repository.new({
                                       host:    'github',
                                       name:    'my_repo',
                                       private: true,
                                       user:    'Mike Slinn',
                                     })
  acb_nugem_module = ArbitraryContextBinding.new(modules: [Nugem])

  describe 'Nugem getters' do
    it 'reads values from constructed context' do
      result = acb_nugem_module.render('User: <%= repository.user_name %>')
      expect(result).to eq('User: Mike Slinn')

      # result = acb_nugem_module.render('Project Title: <%= @project.title %>')
      # expect(result).to eq('Project Title: TODO')
    end
  end
end
