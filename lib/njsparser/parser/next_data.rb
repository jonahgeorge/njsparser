# frozen_string_literal: true

require "json"
require_relative "../utils"

module Njsparser
  module Parser
    # Methods for parsing the `__NEXT_DATA__` script from Next.js pages.
    module NextData
      # Extracts and parses the `__NEXT_DATA__` script content from HTML.
      #
      # The `__NEXT_DATA__` script contains Next.js page data including build ID,
      # page props, and other server-side rendering information.
      #
      # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
      #   The HTML string or parsed HTML document.
      # @return [Hash, nil] The parsed JSON data from `__NEXT_DATA__`, or nil if not found.
      # @raise [ArgumentError] If multiple `__NEXT_DATA__` scripts are found.
      #
      # @example
      #   html = File.read('page.html')
      #   next_data = Njsparser::Parser::NextData.get_next_data(html)
      #   build_id = next_data['buildId'] if next_data
      def self.get_next_data(value)
        tree = Utils.make_tree(value)
        nextdata = tree.xpath("//script[@id='__NEXT_DATA__']/text()")

        return nil if nextdata.empty?
        raise ArgumentError, "invalid nextdata length=#{nextdata.length}" if nextdata.length != 1

        JSON.parse(nextdata.first.text.strip)
      end

      # Checks if the given value contains a `__NEXT_DATA__` script.
      #
      # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
      #   The HTML string or parsed HTML document.
      # @return [Boolean] True if `__NEXT_DATA__` is found.
      #
      # @example
      #   html = File.read('page.html')
      #   has_data = Njsparser::Parser::NextData.has_next_data(html)
      def self.has_next_data(value)
        !get_next_data(value).nil?
      end
    end
  end
end
