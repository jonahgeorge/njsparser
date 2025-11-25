# frozen_string_literal: true

require "uri"
require_relative "../utils"

module Njsparser
  module Parser
    # Methods for extracting Next.js static URLs and base paths.
    module Urls
      # Next.js base path.
      # @return [String]
      N = "/_next"

      # Next.js static path prefix.
      # @return [String]
      NS = "#{N}/static/"

      # Extracts all Next.js static URLs from the HTML.
      #
      # Finds all href and src attributes that contain the Next.js static path prefix.
      #
      # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
      #   The HTML string or parsed HTML document.
      # @return [Array<String>, nil] Array of static URLs, or nil if none found.
      #
      # @example
      #   html = File.read('page.html')
      #   urls = Njsparser::Parser::Urls.get_next_static_urls(html)
      def self.get_next_static_urls(value)
        tree = Utils.make_tree(value)
        result = []

        tree.xpath("//*[contains(@href, '#{NS}')]/@href").each { |href| result << href.value }
        tree.xpath("//*[contains(@src, '#{NS}')]/@src").each { |src| result << src.value }

        result.empty? ? nil : result
      end

      # Extracts the base path from Next.js static URLs.
      #
      # The base path is the common prefix before the `/_next/static/` path in all URLs.
      #
      # @param value [Array<String>, String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
      #   Array of URLs, or HTML to extract URLs from.
      # @param remove_domain [Boolean, nil] If true, removes the domain from the result.
      # @return [String, nil] The base path, or nil if no URLs found.
      # @raise [ArgumentError] If URLs have inconsistent base paths.
      #
      # @example
      #   urls = ["https://example.com/app/_next/static/abc123/chunk.js"]
      #   base_path = Njsparser::Parser::Urls.get_base_path(urls, remove_domain: true)
      #   # => "/app"
      def self.get_base_path(value, remove_domain: nil)
        paths = value.is_a?(Array) ? value : get_next_static_urls(value)
        return nil if paths.nil? || paths.empty?

        global_index = nil
        paths.each do |path|
          index = path.rindex(NS)
          raise ArgumentError, "can't find '#{NS}' in path=#{path}" if index.nil?

          if global_index.nil?
            global_index = index
          else
            raise ArgumentError, "index=#{index} of '#{NS}' in path=#{path} is != global_index=#{global_index}" if index != global_index
          end
        end

        result = paths[0][0...global_index]

        if remove_domain
          uri = URI.parse(result)
          result = result.split(uri.hostname, 2).last if uri.hostname
        end

        result
      end
    end
  end
end
