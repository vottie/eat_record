require "test_helper"

# 一覧(並び順・ページング)、統計、説明、manifest、フォームの表示。認可は security_authorization_test.rb にある。
class EatRecordsListingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  def dates_on(page)
    css_select("span.eatrec-row2").map { |node| node.text.strip }
  end

  def create_records(count, shop: "Bulk", start: Date.new(2024, 1, 1))
    count.times do |i|
      EatRecord.create!(shop_name: "#{shop} #{i}", eat_date: start + i, user_id: @user.id)
    end
  end

  test "index lists records from the newest date to the oldest" do
    sign_in @user
    get eat_records_path

    assert_equal %w[2025-03-05 2025-02-20 2025-01-10], dates_on(response)
  end

  test "index shows 25 records per page and the rest on the next page" do
    create_records(30) # fixtures の 3 件と合わせて 33 件
    sign_in @user
    get eat_records_path
    assert_select "span.eatrec-row1", count: 25
    assert_select "nav.pagination, ul.pagination", minimum: 1

    sign_in @user
    get eat_records_path, params: { page: 2 }
    assert_select "span.eatrec-row1", count: 8

    sign_in @user
    get "/eat_records/page/2"
    assert_select "span.eatrec-row1", count: 8
  end

  test "pages are continuous: no record is shown twice or skipped" do
    create_records(30)
    sign_in @user
    get eat_records_path
    first_page = css_select("span.eatrec-row1 a").map { |node| node["href"] }
    sign_in @user
    get eat_records_path, params: { page: 2 }
    second_page = css_select("span.eatrec-row1 a").map { |node| node["href"] }

    assert_equal 33, (first_page + second_page).uniq.size
    assert_empty first_page & second_page
  end

  test "a page beyond the last one is empty, not an error" do
    sign_in @user
    get eat_records_path, params: { page: 99 }

    assert_response :success
    assert_select "span.eatrec-row1", count: 0
  end

  test "index of a user without records is empty and still offers the actions" do
    user = User.create!(email: "empty@example.com", username: "empty", password: "password123")
    sign_in user
    get eat_records_path

    assert_response :success
    assert_select "span.eatrec-row1", count: 0
    assert_select "a[href=?]", new_eat_record_path
    assert_select "a[href=?]", stat_eat_records_path
  end

  test "stat sorts shops by the number of visits, most first" do
    3.times { |i| EatRecord.create!(shop_name: "Curry House", eat_date: Date.new(2025, 4, i + 1), user_id: @user.id) }
    sign_in @user
    get stat_eat_records_path

    shops = css_select("ul.list-group li").map { |li| [ li.at_css(".eatrec-row1").text.strip, li.at_css(".eatrec-row2").text.strip ] }
    assert_equal [ [ "Curry House", "4" ], [ "Ramen Taro", "2" ] ], shops
  end

  test "stat of a user without records is an empty list" do
    user = User.create!(email: "empty@example.com", username: "empty", password: "password123")
    sign_in user
    get stat_eat_records_path

    assert_response :success
    assert_select "ul.list-group li", count: 0
  end

  test "stat counts shops with the same name as one shop" do
    sign_in @user
    get stat_eat_records_path

    assert_select "ul.list-group li", count: 2
  end

  test "desc renders the description" do
    sign_in @user
    get desc_eat_records_path

    assert_response :success
    assert_select "h3", text: "説明"
  end

  test "manifest is json with the app name, display mode and icons" do
    sign_in @user
    get manifest_eat_records_path

    assert_response :success
    assert_match %r{application/json}, response.media_type
    manifest = response.parsed_body
    assert_equal "EatLog", manifest["name"]
    assert_equal "EatLog", manifest["short_name"]
    assert_equal "standalone", manifest["display"]
    assert_predicate manifest["icons"], :present?
    manifest["icons"].each do |icon|
      assert_equal %w[sizes src type], icon.keys.sort
      assert_match(/\A\d+x\d+\z/, icon["sizes"])
    end
  end

  test "the new form has a field for every record attribute and posts to the new path" do
    sign_in @user
    get new_eat_record_path

    assert_select "form[action=?][method=post]", new_eat_record_path do
      %w[shop_name place_name usecase eat_with eat_time eat_menu article].each do |attribute|
        assert_select "[name=?]", "eat_record[#{attribute}]", minimum: 1, message: attribute
      end
      assert_select "select[name^=?]", "eat_record[eat_date"
    end
  end

  test "the edit form is filled with the record's values" do
    record = eat_records(:ramen_1)
    sign_in @user
    get edit_eat_record_path(record)

    assert_select "input[name=?][value=?]", "eat_record[shop_name]", "Ramen Taro"
    assert_select "input[name=?][value=?]", "eat_record[place_name]", "Tokyo"
  end

  test "create keeps every submitted value" do
    sign_in @user
    post new_eat_record_path, params: { eat_record: {
      shop_name: "Full", place_name: "Place", usecase: "店", eat_with: "友達",
      eat_time: "夜", eat_menu: "Menu", article: "Memo", eat_date: "2025-06-01"
    } }
    record = EatRecord.find_by!(shop_name: "Full")

    assert_redirected_to eat_record_path(record)
    assert_equal [ "Place", "店", "友達", "夜", "Menu", "Memo", Date.new(2025, 6, 1) ],
                 [ record.place_name, record.usecase, record.eat_with, record.eat_time, record.eat_menu, record.article, record.eat_date ]
  end
end
