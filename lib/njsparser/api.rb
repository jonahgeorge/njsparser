# frozen_string_literal: true

require_relative "utils"

module Njsparser
  # Methods for generating Next.js API paths and checking API exposure.
  module Api
    # Default index JSON filename.
    # @return [String]
    INDEX_JSON = "index.json"

    # Paths that should be excluded from API path generation.
    # @return [Array<String>]
    EXCLUDED_PATHS = ["/404", "/_app", "/_error", "/sitemap.xml", "/_middleware"].freeze

    # Joins URL path segments using Utils.join.
    #
    # @param *args [String, nil] Variable number of path segments.
    # @return [String] The joined path.
    # @see Utils.join
    def self.join(*args)
      Utils.join(*args)
    end

    # Generates a Next.js API path for the given build ID and page path.
    #
    # @param build_id [String] The Next.js build ID.
    # @param base_path [String, nil] The base path of the Next.js application.
    # @param path [String, nil] The page path (defaults to "index.json").
    # @return [String, nil] The generated API path, or nil if the path is excluded.
    #
    # @example
    #   Njsparser::Api.get_api_path(build_id: "abc123", path: "/about")
    #   # => "/_next/data/abc123/about.json"
    def self.get_api_path(build_id:, base_path: nil, path: nil)
      path = INDEX_JSON if path.nil?

      return nil if EXCLUDED_PATHS.include?(path)

      path += ".json" unless path.end_with?(".json")
      path = INDEX_JSON if path.end_with?("/.json")

      join(base_path, "/_next/data/", build_id, path)
    end

    # Generates the index API path for the given build ID.
    #
    # @param build_id [String] The Next.js build ID.
    # @param base_path [String, nil] The base path of the Next.js application.
    # @return [String] The generated index API path.
    #
    # @example
    #   Njsparser::Api.get_index_api_path(build_id: "abc123")
    #   # => "/_next/data/abc123/index.json"
    def self.get_index_api_path(build_id:, base_path: nil)
      get_api_path(build_id: build_id, base_path: base_path, path: INDEX_JSON)
    end

    # Determines if the API is exposed based on HTTP response characteristics.
    #
    # @param status_code [Integer] The HTTP status code.
    # @param content_type [String, nil] The Content-Type header value.
    # @param text [String] The response body text.
    # @return [Boolean] True if the API appears to be exposed.
    #
    # @example
    #   exposed = Njsparser::Api.is_api_exposed_from_response(
    #     status_code: 200,
    #     content_type: "application/json",
    #     text: '{"data": "value"}'
    #   )
    def self.is_api_exposed_from_response(status_code:, content_type:, text:)
      return true if status_code == 200
      return true if content_type&.start_with?("application/json")
      text == '{"notFound":true}'
    end

    # Lists all API paths for the given sorted pages.
    #
    # @param sorted_pages [Array<String>] Array of page paths from the build manifest.
    # @param build_id [String] The Next.js build ID.
    # @param base_path [String] The base path of the Next.js application.
    # @param is_api_exposed [Boolean, nil] Whether the API is exposed (skips generation if false).
    # @return [Array<String>] Array of generated API paths.
    #
    # @example
    #   pages = ["/", "/about", "/contact"]
    #   api_paths = Njsparser::Api.list_api_paths(
    #     sorted_pages: pages,
    #     build_id: "abc123",
    #     base_path: ""
    #   )
    def self.list_api_paths(sorted_pages:, build_id:, base_path:, is_api_exposed: nil)
      result = []

      return result if is_api_exposed == false

      sorted_pages.each do |path|
        api_path = get_api_path(build_id: build_id, base_path: base_path, path: path)
        result << api_path if api_path
      end

      result
    end
  end
end
