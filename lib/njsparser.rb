# frozen_string_literal: true

require_relative "njsparser/version"
require_relative "njsparser/utils"
require_relative "njsparser/parser/types"
require_relative "njsparser/parser/flight_data"
require_relative "njsparser/parser/next_data"
require_relative "njsparser/parser/manifests"
require_relative "njsparser/parser/urls"
require_relative "njsparser/parser"
require_relative "njsparser/tools"
require_relative "njsparser/api"

# Main module for the njsparser gem.
#
# This module provides convenience methods for parsing Next.js applications
# and extracting flight data, build manifests, and other Next.js-specific
# information from HTML pages.
#
# @example Basic usage
#   require 'njsparser'
#
#   html = File.read('page.html')
#   flight_data = Njsparser::BeautifulFD(html)
#   next_data = Njsparser.get_next_data(html)
#
module Njsparser
  # Base error class for njsparser exceptions.
  class Error < StandardError; end

  # Creates a {Tools::BeautifulFD} instance from the given value.
  #
  # @param value [Hash, String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
  #   The flight data hash, HTML string, or parsed HTML document.
  # @return [Tools::BeautifulFD] A BeautifulFD instance for querying flight data.
  # @raise [TypeError] If the value type is unsupported.
  #
  # @example
  #   html = File.read('page.html')
  #   bfd = Njsparser::BeautifulFD(html)
  #   bfd.find_all(class_filters: [Njsparser::T::RSCPayload])
  def self.BeautifulFD(value)
    Tools::BeautifulFD.new(value)
  end

  # Extracts the `__NEXT_DATA__` script content from HTML.
  #
  # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
  #   The HTML string or parsed HTML document.
  # @return [Hash, nil] The parsed JSON data from `__NEXT_DATA__`, or nil if not found.
  # @raise [ArgumentError] If multiple `__NEXT_DATA__` scripts are found.
  #
  # @example
  #   html = File.read('page.html')
  #   next_data = Njsparser.get_next_data(html)
  #   build_id = next_data['buildId'] if next_data
  def self.get_next_data(value)
    Parser.get_next_data(value)
  end

  # Converts a BeautifulFD or Element instance to a hash.
  #
  # @param obj [Tools::BeautifulFD, Parser::Types::Element]
  #   The object to convert.
  # @return [Hash] A hash representation of the object.
  # @raise [TypeError] If the object type is unsupported.
  #
  # @example
  #   bfd = Njsparser::BeautifulFD(html)
  #   hash = Njsparser.default(bfd)
  def self.default(obj)
    Tools.default(obj)
  end

  # Re-export types for convenience.
  #
  # Provides access to all Element type classes without the full module path.
  #
  # @example
  #   Njsparser::T::RSCPayload
  #   Njsparser::T::Module
  #   Njsparser::T::Text
  T = Parser::Types::T
end
