require "test_helper"

class TopControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when not signed in" do
    get top_index_path

    assert_redirected_to new_user_session_path
  end

  test "renders when signed in" do
    sign_in users(:alice)
    get top_index_path

    assert_response :success
  end
end
