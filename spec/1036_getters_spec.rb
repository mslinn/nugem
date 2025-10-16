require_relative 'spec_helper'
require_relative '../lib/nugem'

# Do not use let to define variables so CustomBinding can be constructed properly
RSpec.describe 'Getters' do
  repository = Nugem::Repository.new({
                                       host:    'github',
                                       name:    'my_repo',
                                       private: true,
                                       user:    'Mike Slinn',
                                     })
  cb = CustomBinding::CustomBinding.new
  cb.add_object_to_binding_as 'repository', repository

  describe 'Nugem getters' do
    it 'reads values from constructed context' do
      result = cb.result 'User: <%= repository.user_name %>'
      expect(result).to eq('User: Mike Slinn')
    end
  end
end
