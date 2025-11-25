require_relative "test_helper"

class ApiTest < Minitest::Test
  BID = "buildId"

  def test_join
    assert_equal "/_next/data/#{BID}/_buildManifest.js",
                 Njsparser::Api.join("_next", "data", BID, "_buildManifest.js")
  end

  def test_get_api_path
    assert_equal "/_next/data/#{BID}/test.json",
                 Njsparser::Api.get_api_path(build_id: BID, path: "/test.json")
    assert_equal "/_next/data/#{BID}/test.json",
                 Njsparser::Api.get_api_path(build_id: BID, path: "/test")
    assert_equal "/n/_next/data/#{BID}/test/t.json",
                 Njsparser::Api.get_api_path(build_id: BID, base_path: "/n", path: "/test/t")
  end

  def test_get_index_api_path
    assert_equal "/n/_next/data/#{BID}/index.json",
                 Njsparser::Api.get_index_api_path(build_id: BID, base_path: "/n")
  end

  def test_is_api_exposed_from_response
    assert Njsparser::Api.is_api_exposed_from_response(
      status_code: 200,
      content_type: "application/json",
      text: ""
    )
    assert Njsparser::Api.is_api_exposed_from_response(
      status_code: 404,
      content_type: "application/json",
      text: ""
    )
    assert Njsparser::Api.is_api_exposed_from_response(
      status_code: 200,
      content_type: "text/html",
      text: ""
    )
    refute Njsparser::Api.is_api_exposed_from_response(
      status_code: 404,
      content_type: "text/html",
      text: ""
    )
    assert Njsparser::Api.is_api_exposed_from_response(
      status_code: 404,
      content_type: "text/plain",
      text: '{"notFound":true}'
    )
  end

  def test_list_api_paths
    assert_equal [],
                 Njsparser::Api.list_api_paths(
                   sorted_pages: %w[a b c],
                   build_id: BID,
                   base_path: "",
                   is_api_exposed: false
                 )
    assert_equal [],
                 Njsparser::Api.list_api_paths(
                   sorted_pages: ["/_app", "/404"],
                   build_id: BID,
                   base_path: ""
                 )
    assert_equal ["/n/_next/data/#{BID}/hi.json"],
                 Njsparser::Api.list_api_paths(
                   sorted_pages: ["/hi"],
                   build_id: BID,
                   base_path: "/n"
                 )
  end
end
