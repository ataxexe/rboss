require 'test/unit'
require_relative 'test_helper'

class DeployFolderTest < Test::Unit::TestCase

  def test_folder_inside_deploy
    with :eap, "5.1" do |profile|
      profile.add :deploy_folder, 'rboss-deploy'
      profile.add :deploy_folder, 'rboss/deploy'
    end

    for_assertions do
      assert(File.exists? "#{@jboss.profile}/deploy/rboss-deploy")
      assert(File.exists? "#{@jboss.profile}/deploy/rboss/deploy")
    end
  end

end