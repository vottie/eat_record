require "test_helper"

class EatRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @record = eat_records(:ramen_1)
  end

  test "redirects to sign in when not signed in" do
    [root_path, eat_records_path, stat_eat_records_path, new_eat_record_path, eat_record_path(@record)].each do |path|
      get path
      assert_redirected_to new_user_session_path, "GET #{path}"
    end
  end

  test "index lists only the signed in user's records" do
    sign_in @user
    get eat_records_path

    assert_response :success
    assert_select "span.eatrec-row1", count: 3
    assert_select "span.eatrec-row1 a", text: "Sushi Bar", count: 0
    assert_select "a", text: "alice"
  end

  test "root shows the index" do
    sign_in @user
    get root_path

    assert_response :success
    assert_select "span.eatrec-row1", count: 3
  end

  test "index paginates via the page route" do
    sign_in @user
    get "/eat_records/page/1"

    assert_response :success
  end

  test "show new edit and desc render" do
    sign_in @user

    [eat_record_path(@record), new_eat_record_path, edit_eat_record_path(@record), desc_eat_records_path].each do |path|
      get path
      assert_response :success, "GET #{path}"
    end
  end

  test "create saves the record for the signed in user" do
    sign_in @user

    # アプリのフォームは POST /eat_records/new に送信する(eat_records_path は /eat_records/index を指す)
    assert_difference("EatRecord.where(user_id: #{@user.id}).count", 1) do
      post new_eat_record_path, params: { eat_record: { shop_name: "New Shop", eat_date: "2025-05-01" } }
    end
    assert_redirected_to eat_record_path(EatRecord.order(:id).last)
    assert_equal @user.id, EatRecord.order(:id).last.user_id
  end

  test "update changes the record" do
    sign_in @user
    patch eat_record_path(@record), params: { eat_record: { shop_name: "Renamed" } }

    assert_redirected_to eat_record_path(@record)
    assert_equal "Renamed", @record.reload.shop_name
  end

  test "destroy removes the record" do
    sign_in @user

    assert_difference("EatRecord.count", -1) do
      delete eat_record_path(@record)
    end
    assert_redirected_to root_path
  end

  test "stat counts visits per shop in descending order" do
    sign_in @user
    get stat_eat_records_path

    assert_response :success
    assert_select "ul.list-group li", count: 2
    assert_select "ul.list-group li:first-child .eatrec-row1", text: "Ramen Taro"
    assert_select "ul.list-group li:first-child .eatrec-row2", text: "2"
    assert_select "ul.list-group li:last-child .eatrec-row1", text: "Curry House"
  end

  test "manifest returns json" do
    sign_in @user
    get manifest_eat_records_path

    assert_response :success
    assert_equal "EatLog", response.parsed_body["name"]
  end
end
