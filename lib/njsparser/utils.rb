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
      segments = args.compact.map(&:to_s)
      return "/" if segments.empty?

      first_segment = segments.shift
      
      # If the first segment is a full URL, preserve it.
      if first_segment.include?("://")
        base = first_segment.sub(%r{/+$}, "")
        segments.each do |segment|
          clean = segment.sub(%r{^/+}, "").sub(%r{/+$}, "")
          base << "/" << clean unless clean.empty?
        end
        base
      else
        # Otherwise treat as path segments
        # The original implementation always prepended "/" if no protocol, and joined with "/"
        # Example: join("", "a") -> "/a"
        # Example: join("a", "b") -> "/a/b"
        
        parts = []
        parts << first_segment unless first_segment.empty?
        parts.concat(segments)
        
        cleaned_parts = parts.map do |part| 
          part.sub(%r{^/+}, "").sub(%r{/+$}, "") 
        end.reject(&:empty?)
        
        "/" + cleaned_parts.join("/")
      end
    end
  end
end
