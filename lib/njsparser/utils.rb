# frozen_string_literal: true

require "nokogiri"
require "logger"

module Njsparser
  # Utility methods for HTML parsing and URL manipulation.
  module Utils
    # Logger instance for warning and error messages.
    # @return [Logger]
    LOGGER = Logger.new($stderr)
    LOGGER.level = Logger::WARN

    # Supported types for HTML tree parsing.
    # @return [Array<Class>]
    SupportedTree = [Nokogiri::HTML::Document, Nokogiri::XML::Element, String].freeze

    # Converts a value to a Nokogiri HTML document or element.
    #
    # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
    #   The value to convert to a tree.
    # @return [Nokogiri::HTML::Document, Nokogiri::XML::Element]
    #   The parsed HTML document or element.
    # @raise [TypeError] If the value type is not supported.
    #
    # @example
    #   html_string = "<html><body>Hello</body></html>"
    #   tree = Njsparser::Utils.make_tree(html_string)
    def self.make_tree(value)
      case value
      when Nokogiri::HTML::Document, Nokogiri::XML::Element
        value
      when String
        Nokogiri::HTML(value)
      else
        raise TypeError, "waited a `String` or `Nokogiri::HTML::Document`, got `#{value.class}`"
      end
    end

    # Joins URL path segments, handling leading/trailing slashes correctly.
    #
    # @param *args [String, nil] Variable number of path segments to join.
    # @return [String] The joined path with proper slash normalization.
    #
    # @example
    #   Njsparser::Utils.join("/hello", "world")  # => "/hello/world"
    #   Njsparser::Utils.join("https://example.com", "/api", "v1")  # => "https://example.com/api/v1"
    #   Njsparser::Utils.join("/hello/", "/world/")  # => "/hello/world"
    def self.join(*args)
      segments = []

      args.compact.each do |arg|
        str = arg.to_s.strip
        next if str.empty?

        if segments.empty? && str.include?("://")
          segments << str.sub(%r{/+\z}, "")
        else
          cleaned = str.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
          cleaned = cleaned.gsub(%r{/+}, "/") unless str.include?("://")
          segments << cleaned unless cleaned.empty?
        end
      end

      return "/" if segments.empty?

      if segments.first.include?("://")
        base = segments.shift
        ([base] + segments).reject(&:empty?).join("/")
      else
        "/" + segments.join("/")
      end
    end
  end
end
