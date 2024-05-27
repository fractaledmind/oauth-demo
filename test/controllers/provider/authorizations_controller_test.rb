require "test_helper"

class Provider::AuthorizationsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get provider_authorizations_create_url
    assert_response :success
  end

  test "should get show" do
    get provider_authorizations_show_url
    assert_response :success
  end
end
