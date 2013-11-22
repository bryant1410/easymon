require 'test_helper'

module Easymon
  class ChecksControllerTest < ActionController::TestCase
    
    test "index when no checks are defined" do
      get :index, use_route: :easymon
      assert_response :service_unavailable
      assert_equal "No Checks Defined", response.body
    end
    
    test "index when all checks pass" do
      Easymon::Repository.add("database", Easymon::ActiveRecordCheck.new(ActiveRecord::Base))
      get :index, use_route: :easymon
      assert_response :success, "Expected success, got 503: #{response.body}"
      assert response.body.include?("OK"), "Should include 'OK' in response body"
    end

    test "index when a critical check fails" do
      Easymon::Repository.add("database", Easymon::ActiveRecordCheck.new(ActiveRecord::Base), true)
      ActiveRecord::Base.connection.stubs(:select_value).raises("boom")
      get :index, use_route: :easymon
      assert_response :service_unavailable
      assert response.body.include?("database: Down"), "Should include failure text, got #{response.body}"
    end
    
    test "index when a non-critical check fails" do
      Easymon::Repository.add("database", Easymon::ActiveRecordCheck.new(ActiveRecord::Base), true)
      Easymon::Repository.add("redis", Easymon::RedisCheck.new(YAML.load_file(Rails.root.join("config/redis.yml"))[Rails.env].symbolize_keys))
      Redis.any_instance.stubs(:ping).raises("boom")
      get :index, use_route: :easymon
      assert_response :success
      assert response.body.include?("redis: Down"), "Should include failure text, got #{response.body}"
      assert response.body.include?("OK"), "Should include 'OK' in response body"
    end
    
    test "show when the check passes" do
      Easymon::Repository.add("database", Easymon::ActiveRecordCheck.new(ActiveRecord::Base))
      get :show, use_route: :easymon, check: "database"
      assert_response :success
      assert response.body.include?("Up"), "Response should include message text, got #{response.body}"
    end
    
    test "show when the check fails" do
      Easymon::Repository.add("database", Easymon::ActiveRecordCheck.new(ActiveRecord::Base))
      ActiveRecord::Base.connection.stubs(:select_value).raises("boom")
      
      get :show, use_route: :easymon, check: "database"
      
      assert_response :service_unavailable
      assert response.body.include?("Down"), "Response should include failure text, got #{response.body}"
    end
    
    test "show if the check is not found" do
      Easymon::Repository.names.each {|name| Easymon::Repository.remove(name)}
      
      get :show, use_route: :easymon, check: "database"
      assert_response :not_found
    end
  end
end
