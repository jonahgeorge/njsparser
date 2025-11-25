# frozen_string_literal: true

require "set"
require_relative "utils"
require_relative "parser"
require_relative "parser/types"

module Njsparser
  # Tools for working with Next.js flight data and build information.
  module Tools
    # Checks if the given value contains Next.js data (either __NEXT_DATA__ or flight data).
    #
    # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
    #   The HTML string or parsed HTML document.
    # @return [Boolean] True if Next.js data is found.
    #
    # @example
    #   html = File.read('page.html')
    #   has_nextjs = Njsparser::Tools.has_nextjs(html)
    def self.has_nextjs(value)
      Parser.has_next_data(value) || Parser.has_flight_data(value)
    end

    # Finds the Next.js build ID from various sources in the HTML.
    #
    # Attempts to find the build ID from:
    # 1. Next.js static URLs (build manifest paths)
    # 2. __NEXT_DATA__ script
    # 3. Flight data (RSCPayload)
    #
    # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
    #   The HTML string or parsed HTML document.
    # @return [String, nil] The build ID if found, nil otherwise.
    #
    # @example
    #   html = File.read('page.html')
    #   build_id = Njsparser::Tools.find_build_id(html)
    def self.find_build_id(value)
      tree = Utils.make_tree(value)

      if (next_static_urls = Parser.get_next_static_urls(tree))
        base_path = Parser.get_base_path(next_static_urls, remove_domain: false)
        next_static_urls.each do |next_static_url|
          sliced_su = next_static_url.sub(/^#{Regexp.escape(base_path)}/, "").sub(/^#{Regexp.escape(Parser::Urls::NS)}/, "")
          require_relative "parser/manifests"
          Parser::Manifests::MANIFEST_PATHS.each do |manifest_path|
            if sliced_su.end_with?(manifest_path)
              return sliced_su[0...-manifest_path.length]
            end
          end
        end
      end

      if (next_data = Parser.get_next_data(tree))
        return next_data["buildId"] if next_data.key?("buildId")
        Utils::LOGGER.warn("Found a next_data dict in the page, but didn't contain any `buildId` key.")
      elsif (flight_data = Parser.get_flight_data(tree))
        found = find_in_flight_data(flight_data, class_filters: [Parser::Types::RSCPayload])
        return found.build_id if found
        Utils::LOGGER.warn("Found flight data in the page, but couldn't find the build id. If you are certain there is one, open an issue with your html to investigate :)")
      end

      nil
    end

    # Iterates over flight data elements matching the given filters.
    #
    # @param flight_data [Hash] The flight data hash to search.
    # @param class_filters [Array<Class, String>, Set<Class>, nil]
    #   Array or Set of Element classes or class names to filter by.
    # @param callback [Proc, nil] Optional callback proc to further filter elements.
    # @param recursive [Boolean, nil] Whether to recursively search DataContainer and DataParent elements.
    # @yield [Parser::Types::Element] Each matching element.
    # @return [Enumerator] An enumerator if no block is given.
    #
    # @example
    #   flight_data = Njsparser::Parser.get_flight_data(html)
    #   Njsparser::Tools.find_iter_in_flight_data(
    #     flight_data,
    #     class_filters: [Njsparser::Parser::Types::RSCPayload]
    #   ) { |element| puts element.build_id }
    def self.find_iter_in_flight_data(flight_data, class_filters: nil, callback: nil, recursive: nil)
      return enum_for(:find_iter_in_flight_data, flight_data, class_filters: class_filters, callback: callback, recursive: recursive) unless block_given?

      return if flight_data.nil?

      class_filters = class_filters.to_set if class_filters && !class_filters.is_a?(Set)

      flight_data.each_value do |value|
        if recursive != false && value.is_a?(Parser::Types::DataContainer)
          find_iter_in_flight_data(
            value.value.each_with_index.to_h { |v, i| [i, v] },
            class_filters: class_filters,
            callback: callback,
            recursive: recursive
          ) { |item| yield item }
        elsif recursive != false && value.is_a?(Parser::Types::DataParent)
          find_iter_in_flight_data(
            { 0 => value.children },
            class_filters: class_filters,
            callback: callback,
            recursive: recursive
          ) { |item| yield item }
        else
          matches_class = class_filters.nil? || class_filters.include?(value.class)
          matches_callback = callback.nil? || callback.call(value)

          yield value if matches_class && matches_callback
        end
      end
    end

    # Finds all elements in flight data matching the given filters.
    #
    # @param flight_data [Hash] The flight data hash to search.
    # @param class_filters [Array<Class, String>, Set<Class>, nil]
    #   Array or Set of Element classes or class names to filter by.
    # @param callback [Proc, nil] Optional callback proc to further filter elements.
    # @param recursive [Boolean, nil] Whether to recursively search DataContainer and DataParent elements.
    # @return [Array<Parser::Types::Element>] Array of all matching elements.
    #
    # @example
    #   flight_data = Njsparser::Parser.get_flight_data(html)
    #   rsc_payloads = Njsparser::Tools.find_all_in_flight_data(
    #     flight_data,
    #     class_filters: [Njsparser::Parser::Types::RSCPayload]
    #   )
    def self.find_all_in_flight_data(flight_data, class_filters: nil, callback: nil, recursive: nil)
      find_iter_in_flight_data(flight_data, class_filters: class_filters, callback: callback, recursive: recursive).to_a
    end

    # Finds the first element in flight data matching the given filters.
    #
    # @param flight_data [Hash] The flight data hash to search.
    # @param class_filters [Array<Class, String>, Set<Class>, nil]
    #   Array or Set of Element classes or class names to filter by.
    # @param callback [Proc, nil] Optional callback proc to further filter elements.
    # @param recursive [Boolean, nil] Whether to recursively search DataContainer and DataParent elements.
    # @return [Parser::Types::Element, nil] The first matching element, or nil if none found.
    #
    # @example
    #   flight_data = Njsparser::Parser.get_flight_data(html)
    #   rsc_payload = Njsparser::Tools.find_in_flight_data(
    #     flight_data,
    #     class_filters: [Njsparser::Parser::Types::RSCPayload]
    #   )
    def self.find_in_flight_data(flight_data, class_filters: nil, callback: nil, recursive: nil)
      find_iter_in_flight_data(flight_data, class_filters: class_filters, callback: callback, recursive: recursive).first
    end

    # A convenient interface for querying and manipulating Next.js flight data.
    #
    # BeautifulFD provides a BeautifulSoup-like API for working with flight data,
    # allowing you to search, filter, and iterate over elements in the flight data structure.
    #
    # @example Basic usage
    #   html = File.read('page.html')
    #   bfd = Njsparser::Tools::BeautifulFD.new(html)
    #   rsc_payload = bfd.find(class_filters: [Njsparser::T::RSCPayload])
    #   puts rsc_payload.build_id if rsc_payload
    class BeautifulFD
      # The internal flight data hash.
      # @return [Hash<Integer, Parser::Types::Element>]
      attr_reader :_flight_data

      # Creates a new BeautifulFD instance from the given value.
      #
      # @param value [Hash, String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
      #   A flight data hash, HTML string, or parsed HTML document.
      # @raise [TypeError] If the value type is unsupported or contains invalid data.
      #
      # @example From HTML
      #   html = File.read('page.html')
      #   bfd = Njsparser::Tools::BeautifulFD.new(html)
      #
      # @example From hash
      #   flight_data_hash = { 0 => element1, 1 => element2 }
      #   bfd = Njsparser::Tools::BeautifulFD.new(flight_data_hash)
      def initialize(value)
        if value.is_a?(Hash)
          @_flight_data = {}
          value.each do |key, val|
            key = key.to_i if key.is_a?(String) && key.match?(/^\d+$/)
            raise TypeError, "Given key #{key} in flight data dict is neither a digit string, neither an int." unless key.is_a?(Integer)

            if val.is_a?(Hash) && (Parser::Types::DUMPED_ELEMENT_KEYS - val.keys.map(&:to_s)).empty?
              val = Parser::Types.resolve_type(
                value: val["value"] || val[:value],
                value_class: val["value_class"] || val[:value_class],
                index: val["index"] || val[:index]
              )
            elsif !val.is_a?(Parser::Types::Element)
              raise TypeError, "Given value for key #{key} in flight data dict is not an Element."
            end
            @_flight_data[key] = val
          end
        elsif Utils::SupportedTree.any? { |t| value.is_a?(t) }
          @_flight_data = Parser.get_flight_data(value)
        else
          raise TypeError, "Given type \"#{value.class}\" is unsupported"
        end
      end

      # Returns a string representation of the BeautifulFD instance.
      #
      # @return [String] A string showing the number of elements.
      def to_s
        "BeautifulFD(<#{length} elements>)"
      end

      # Returns a string representation for inspection.
      #
      # @return [String] A string showing the number of elements.
      def inspect
        to_s
      end

      # Returns the number of elements in the flight data.
      #
      # @return [Integer] The number of elements.
      def length
        @_flight_data&.length || 0
      end

      # Checks if the flight data is empty.
      #
      # @return [Boolean] True if the flight data is nil or empty.
      def empty?
        @_flight_data.nil? || @_flight_data.empty?
      end

      # Iterates over each key-value pair in the flight data.
      #
      # @yield [Integer, Parser::Types::Element] Each index and element pair.
      # @return [Enumerator] An enumerator if no block is given.
      def each(&block)
        return enum_for(:each) unless block_given?
        return if @_flight_data.nil?
        @_flight_data.each(&block)
      end

      # Returns all elements as an array.
      #
      # @return [Array<Parser::Types::Element>] Array of all elements.
      def as_list
        @_flight_data&.values || []
      end

      # Creates a BeautifulFD instance from a list of elements.
      #
      # @param list [Array<Hash, Parser::Types::Element>]
      #   Array of element hashes or Element instances.
      # @param via_enumerate [Boolean, nil]
      #   If true, uses the list index as the element index when elements don't have indices.
      # @return [BeautifulFD] A new BeautifulFD instance.
      # @raise [ArgumentError] If elements don't have indices and via_enumerate is not true.
      #
      # @example
      #   elements = [element1, element2, element3]
      #   bfd = Njsparser::Tools::BeautifulFD.from_list(elements, via_enumerate: true)
      def self.from_list(list, via_enumerate: nil)
        if list.all? { |item| item.is_a?(Hash) && (item.key?("cls") || item.key?(:cls)) }
          list = list.map do |item|
            Parser::Types.resolve_type(
              value: item["value"] || item[:value],
              value_class: item["value_class"] || item[:value_class],
              index: item["index"] || item[:index]
            )
          end
        end

        if list.all? { |item| item.is_a?(Parser::Types::Element) && !item.index.nil? }
          value = list.to_h { |item| [item.index, item] }
        elsif via_enumerate != true
          raise ArgumentError, "Cannot load the given list since elements do not all have an index written on them. You can set `via_enumerate` to `true` to put the elements indexes in the given list as their indexes."
        else
          value = list.each_with_index.to_h { |item, index| [index, item] }
        end

        new(value)
      end

      # Iterates over elements matching the given filters.
      #
      # @param class_filters [Array<Class, String>, nil]
      #   Array of Element classes or class names to filter by.
      # @param callback [Proc, nil] Optional callback proc to further filter elements.
      # @param recursive [Boolean, nil] Whether to recursively search DataContainer and DataParent elements.
      # @yield [Parser::Types::Element] Each matching element.
      # @return [Enumerator] An enumerator if no block is given.
      #
      # @example
      #   bfd = Njsparser::Tools::BeautifulFD.new(html)
      #   bfd.find_iter(class_filters: [Njsparser::T::RSCPayload]) do |element|
      #     puts element.build_id
      #   end
      def find_iter(class_filters: nil, callback: nil, recursive: nil, &block)
        return enum_for(:find_iter, class_filters: class_filters, callback: callback, recursive: recursive) unless block_given?

        new_class_filters = nil
        if class_filters
          new_class_filters = Set.new
          class_filters.each do |cls|
            if cls.is_a?(Class) && cls < Parser::Types::Element
              new_class_filters.add(cls)
            else
              cls_name = cls.is_a?(String) ? cls : cls.name.split("::").last
              if Parser::Types::TL2OBJ.key?(cls_name)
                new_class_filters.add(Parser::Types::TL2OBJ[cls_name])
              else
                raise KeyError, "The class filter \"#{cls}\" is not present in the list of conversion: #{Parser::Types::TL2OBJ.keys}."
              end
            end
          end
        end

        Tools.find_iter_in_flight_data(
          @_flight_data,
          class_filters: new_class_filters,
          callback: callback,
          recursive: recursive
        ) { |item| yield item }
      end

      # Finds all elements matching the given filters.
      #
      # @param class_filters [Array<Class, String>, nil]
      #   Array of Element classes or class names to filter by.
      # @param callback [Proc, nil] Optional callback proc to further filter elements.
      # @param recursive [Boolean, nil] Whether to recursively search DataContainer and DataParent elements.
      # @return [Array<Parser::Types::Element>] Array of all matching elements.
      #
      # @example
      #   bfd = Njsparser::Tools::BeautifulFD.new(html)
      #   modules = bfd.find_all(class_filters: [Njsparser::T::Module])
      def find_all(class_filters: nil, callback: nil, recursive: nil)
        find_iter(class_filters: class_filters, callback: callback, recursive: recursive).to_a
      end

      # Finds the first element matching the given filters.
      #
      # @param class_filters [Array<Class, String>, nil]
      #   Array of Element classes or class names to filter by.
      # @param callback [Proc, nil] Optional callback proc to further filter elements.
      # @param recursive [Boolean, nil] Whether to recursively search DataContainer and DataParent elements.
      # @return [Parser::Types::Element, nil] The first matching element, or nil if none found.
      #
      # @example
      #   bfd = Njsparser::Tools::BeautifulFD.new(html)
      #   rsc_payload = bfd.find(class_filters: [Njsparser::T::RSCPayload])
      def find(class_filters: nil, callback: nil, recursive: nil)
        find_iter(class_filters: class_filters, callback: callback, recursive: recursive).first
      end
    end

    # Converts a BeautifulFD or Element instance to a hash.
    #
    # @param obj [BeautifulFD, Parser::Types::Element] The object to convert.
    # @return [Hash] A hash representation of the object.
    # @raise [TypeError] If the object type is unsupported.
    #
    # @example
    #   bfd = Njsparser::Tools::BeautifulFD.new(html)
    #   hash = Njsparser::Tools.default(bfd)
    def self.default(obj)
      case obj
      when BeautifulFD
        obj.each_with_object({}) { |(key, value), hash| hash[key.to_s] = value }
      when Parser::Types::Element
        obj.to_h
      else
        raise TypeError, "Unsupported type: #{obj.class}"
      end
    end
  end
end
