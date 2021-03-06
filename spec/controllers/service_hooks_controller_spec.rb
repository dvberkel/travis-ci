require 'spec_helper'

describe ServiceHooksController, :webmock => true do
  before(:each) do
    sign_in_user user
  end

  let(:user) { Factory(:user, :github_oauth_token => 'github_oauth_token') }

  describe 'GET :index' do
    it 'should return repositories of current user' do
      get(:index, :format => 'json')

      response.should be_success

      result = json_response
      result.first['name'].should   == 'safemode'
      result.first['owner_name'].should  == 'svenfuchs'
      result.second['name'].should  == 'scriptaculous-sortabletree'
      result.second['owner_name'].should == 'svenfuchs'
    end
  end

  describe 'PUT :update' do
    before(:each) do
      stub_request :post, 'https://api.github.com/hub?access_token=github_oauth_token'
    end

    context 'subscribes to a service hook' do
      it 'creates a repository if it does not exist' do
        put :update, :id => 1, :name => 'minimal', :owner_name => 'svenfuchs', :active => 'true'

        Repository.count.should == 1
        Repository.first.active?.should be_true

        assert_requested(:post, 'https://api.github.com/hub?access_token=github_oauth_token', :times => 1)
      end

      it 'updates an existing repository if it exists' do
        repository = Factory(:repository)

        put :update, :id => 1, :name => 'minimal', :owner_name => 'svenfuchs', :active => 'true'

        Repository.count.should == 1
        Repository.first.active?.should be_true

        assert_requested(:post, 'https://api.github.com/hub?access_token=github_oauth_token', :times => 1)
      end

      it "should not be acceptable if a Travis::GithubApi::ServiceHookError is raised" do
        Repository.any_instance.expects(:service_hook).raises(Travis::GithubApi::ServiceHookError)

        put :update, :id => 1, :name => 'minimal', :owner_name => 'svenfuchs', :active => 'true'

        assert_response :not_acceptable
      end

    end

    context 'unsubscribes from the service hook' do
      it 'updates an existing repository' do
        repository = Factory(:repository)

        put :update, :id => 1, :name => 'minimal', :owner_name => 'svenfuchs', :active => 'false'

        Repository.first.active?.should be_false

        assert_requested(:post, 'https://api.github.com/hub?access_token=github_oauth_token', :times => 1)
      end
    end
  end
end

