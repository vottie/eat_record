require "test_helper"

# 認可(#69)。未ログインの操作と、他のユーザーのデータへの操作が、拒否されること。
# 基本の経路は eat_records_controller_test.rb にある。ここでは、その網羅と、所有者の書き換えを確認する。
class SecurityAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @record = eat_records(:ramen_1) # alice の記録
  end

  # manifest は、未ログインでも読める必要がある(#74 で別途対応中)ため、ここでは対象にしない
  test "every page and action for records requires signing in" do
    {
      get: [ desc_eat_records_path, "/eat_records/page/1", edit_eat_record_path(@record), edit_user_registration_path ],
      post: [ new_eat_record_path ],
      patch: [ eat_record_path(@record) ],
      put: [ eat_record_path(@record), user_registration_path ],
      delete: [ eat_record_path(@record), user_registration_path ]
    }.each do |verb, paths|
      paths.each do |path|
        public_send(verb, path)
        assert_redirected_to new_user_session_path, "#{verb.upcase} #{path}"
      end
    end
  end

  test "anonymous requests change nothing" do
    assert_no_difference([ "EatRecord.count", "User.count" ]) do
      post new_eat_record_path, params: { eat_record: { shop_name: "Anonymous" } }
      delete eat_record_path(@record)
      delete user_registration_path
    end
    assert_equal "Ramen Taro", @record.reload.shop_name
  end

  test "the owner of a record cannot be changed through update" do
    sign_in @alice
    patch eat_record_path(@record), params: { eat_record: { shop_name: "Mine", user_id: @bob.id } }

    assert_redirected_to eat_record_path(@record)
    assert_equal @alice.id, @record.reload.user_id
    assert_equal "Mine", @record.shop_name
  end

  test "a record is always created for the signed in user" do
    sign_in @alice
    post new_eat_record_path, params: { eat_record: { shop_name: "Forged Owner", user_id: @bob.id } }

    assert_equal @alice.id, EatRecord.find_by!(shop_name: "Forged Owner").user_id
  end

  test "another user's records are not in the index, the page route or the statistics" do
    sign_in @bob
    get eat_records_path
    assert_select "span.eatrec-row1 a", text: "Ramen Taro", count: 0
    assert_select "span.eatrec-row1 a", text: "Sushi Bar", count: 1

    get "/eat_records/page/1"
    assert_select "span.eatrec-row1 a", text: "Ramen Taro", count: 0

    get stat_eat_records_path
    assert_select "ul.list-group li", count: 1
    assert_select ".eatrec-row1", text: "Ramen Taro", count: 0
  end

  test "another user cannot create, update or destroy through a forged id in the body" do
    sign_in @bob
    patch eat_record_path(@record), params: { eat_record: { id: @record.id, shop_name: "Hijacked" } }

    assert_response :not_found
    assert_equal "Ramen Taro", @record.reload.shop_name
  end

  test "signing out ends access to the records" do
    sign_in @alice
    get eat_records_path
    assert_response :success

    get destroy_user_session_path
    get eat_records_path
    assert_redirected_to new_user_session_path
  end
end
