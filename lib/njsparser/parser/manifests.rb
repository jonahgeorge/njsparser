# frozen_string_literal: true

require "json"
require_relative "../utils"

module Njsparser
  module Parser
    # Methods for parsing Next.js build manifests.
    module Manifests
      # Build manifest filename.
      # @return [String]
      BUILD_MANIFEST_NAME = "_buildManifest.js"

      # SSG manifest filename.
      # @return [String]
      SSG_MANIFEST_NAME = "_ssgManifest.js"

      # Build manifest path.
      # @return [String]
      BUILD_MANIFEST_PATH = "/#{BUILD_MANIFEST_NAME}"

      # SSG manifest path.
      # @return [String]
      SSG_MANIFEST_PATH = "/#{SSG_MANIFEST_NAME}"

      # All manifest paths.
      # @return [Array<String>]
      MANIFEST_PATHS = [BUILD_MANIFEST_PATH, SSG_MANIFEST_PATH].freeze

      # Parses a Next.js build manifest JavaScript string.
      #
      # Executes the JavaScript to extract the build manifest object, which contains
      # information about pages, chunks, and other build artifacts.
      #
      # @param script [String] The build manifest JavaScript string.
      # @return [Hash] The parsed build manifest object (may contain "sortedPages" key).
      # @raise [ArgumentError] If the script doesn't start with "self.__BUILD_MANIFEST".
      # @raise [LoadError] If the execjs gem is not installed.
      #
      # @example
      #   manifest_js = File.read('_buildManifest.js')
      #   manifest = Njsparser::Parser::Manifests.parse_buildmanifest(manifest_js)
      #   pages = manifest['sortedPages'] || []
      def self.parse_buildmanifest(script)
        s = script.strip
        unless s.start_with?("self.__BUILD_MANIFEST")
          raise ArgumentError, 'Invalid build manifest (not starting by `"self.__BUILD_MANIFEST`).'
        end

        begin
          require "execjs"
        rescue LoadError
          raise MissingDependencyError, "execjs gem is required for parsing build manifests. Install it with: gem install execjs"
        end

        if ExecJS.respond_to?(:runtime=) && defined?(ExecJS::Runtimes::Node) && ExecJS::Runtimes::Node.available?
          ExecJS.runtime = ExecJS::Runtimes::Node
        end

        func = <<~JS
          (function () {
            var self = {};
            self.__BUILD_MANIFEST_CB = function () {};
            #{s.chomp(';')};
            return self.__BUILD_MANIFEST;
          })();
        JS

        begin
          ExecJS.eval(func)
        rescue ExecJS::Error => e
          Utils::LOGGER.warn("Could not parse the given build manifest `#{s}`: #{e.message}")
          extract_sorted_pages(s)
        end
      end

      # Generates the build manifest path for the given build ID.
      #
      # @param build_id [String] The Next.js build ID.
      # @param base_path [String, nil] The base path of the Next.js application.
      # @return [String] The generated build manifest path.
      #
      # @example
      #   path = Njsparser::Parser::Manifests.get_build_manifest_path("abc123", "/app")
      #   # => "/app/_next/static/abc123/_buildManifest.js"
      def self.get_build_manifest_path(build_id, base_path = nil)
        base_path ||= ""
        require_relative "../api"
        Api.join(base_path, "/_next/static/", build_id, BUILD_MANIFEST_NAME)
      end

      # Extracts the sortedPages array from a build manifest script using pure Ruby parsing.
      #
      # This is a fallback method used when execjs fails or is not available.
      # It parses the JavaScript string directly to find the sortedPages array.
      #
      # @param script [String] The build manifest JavaScript string.
      # @return [Hash, nil] A hash with "sortedPages" key, or nil if not found.
      #
      # @example
      #   manifest_js = File.read('_buildManifest.js')
      #   result = Njsparser::Parser::Manifests.extract_sorted_pages(manifest_js)
      #   pages = result['sortedPages'] if result
      def self.extract_sorted_pages(script)
        return {} if script.match?(/return\s*\{\s*\}/)

        if (index = script.index("sortedPages"))
          array_start = script.index("[", index)
          if array_start
            body = extract_bracket_body(script, array_start)
            if body
              begin
                return { "sortedPages" => JSON.parse("[#{body}]") }
              rescue JSON::ParserError
                # ignore, will return nil
              end
            end
          end
        end

        nil
      end

      # Extracts the body content between matching brackets starting at the given index.
      #
      # @param script [String] The JavaScript string to parse.
      # @param opening_index [Integer] The index of the opening bracket.
      # @return [String, nil] The bracket body content, or nil if brackets don't match.
      #
      # @example
      #   script = "var arr = [1, 2, [3, 4], 5];"
      #   body = Njsparser::Parser::Manifests.extract_bracket_body(script, 9)
      #   # => "1, 2, [3, 4], 5"
      def self.extract_bracket_body(script, opening_index)
        depth = 0
        body_start = opening_index + 1
        i = opening_index

        while i < script.length
          char = script[i]
          depth += 1 if char == "["
          depth -= 1 if char == "]"

          if depth.zero?
            return script[body_start...i]
          end

          i += 1
        end

        nil
      end
    end
  end
end
