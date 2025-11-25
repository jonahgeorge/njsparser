# frozen_string_literal: true

require_relative "../utils"
require_relative "urls"

module Njsparser
  module Parser
    # Type system for Next.js flight data elements.
    #
    # This module defines all Element classes that represent different types of
    # data structures found in Next.js flight data, and provides a factory method
    # for resolving the appropriate type from raw data.
    module Types
      # Enable type verification during element initialization.
      # @return [Boolean]
      ENABLE_TYPE_VERIF = true

      # Checks if a value is a flight data object structure.
      #
      # Flight data objects are arrays with 4 elements: ["$", string, string_or_nil, hash_or_nil]
      #
      # @param value [Object] The value to check.
      # @return [Boolean] True if the value matches the flight data object structure.
      def self.is_flight_data_obj(value)
        value.is_a?(Array) &&
          value.length == 4 &&
          value[0] == "$" &&
          value[1].is_a?(String) &&
          (value[2].nil? || value[2].is_a?(String))
      end

      # Base class for all flight data elements.
      #
      # All Element instances are frozen (immutable) after initialization.
      # This ensures data integrity and prevents accidental modifications.
      class Element
        # The raw value of the element.
        # @return [Object]
        attr_reader :value

        # The value class identifier (e.g., "HL", "I", "T", "E").
        # @return [String, nil]
        attr_reader :value_class

        # The index of the element in the flight data structure.
        # @return [Integer, nil]
        attr_reader :index

        # Creates a new Element instance.
        #
        # @param value [Object] The raw value of the element.
        # @param value_class [String, nil] The value class identifier.
        # @param index [Integer, nil] The index of the element.
        def initialize(value:, value_class:, index: nil)
          @value = value
          @value_class = value_class
          @index = index
          freeze
        end

        # Prevents modification of the value attribute.
        # @raise [FrozenError] Always raises, as Element instances are frozen.
        def value=(_)
          raise FrozenError, "can't modify frozen Element"
        end

        # Prevents modification of the value_class attribute.
        # @raise [FrozenError] Always raises, as Element instances are frozen.
        def value_class=(_)
          raise FrozenError, "can't modify frozen Element"
        end

        # Prevents modification of the index attribute.
        # @raise [FrozenError] Always raises, as Element instances are frozen.
        def index=(_)
          raise FrozenError, "can't modify frozen Element"
        end

        # Converts the element to a hash representation.
        #
        # @return [Hash] A hash with :value, :value_class, :index, and :cls keys.
        def to_h
          {
            value: @value,
            value_class: @value_class,
            index: @index,
            cls: self.class.name.split("::").last
          }
        end
      end

      # Represents a hint preload element (HL).
      #
      # Hint preload elements contain information about resources that should be
      # preloaded, such as stylesheets or scripts.
      class HintPreload < Element
        # Value class identifier for hint preload elements.
        # @return [String]
        VALUE_CLASS = "HL"

        # Creates a new HintPreload instance.
        #
        # @param value [Array] Array of 2-3 elements: [href, type_name, attrs?]
        # @param value_class [String] The value class (defaults to "HL").
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value validation fails.
        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be an array" unless value.is_a?(Array)
            raise ArgumentError, "value length must be 2-3" unless (2..3).include?(value.length)
            raise ArgumentError, "href must be a string" unless href.is_a?(String)
            raise ArgumentError, "type_name must be a string" unless type_name.is_a?(String)
            raise ArgumentError, "attrs must be nil or hash" unless attrs.nil? || attrs.is_a?(Hash)
          end
        end

        # The href URL of the preload resource.
        # @return [String]
        def href
          @value[0]
        end

        # The type name of the preload resource.
        # @return [String]
        def type_name
          @value[1]
        end

        # Optional attributes for the preload resource.
        # @return [Hash, nil]
        def attrs
          @value[2] if @value.length >= 3
        end
      end

      # Represents a hint config element (HC).
      #
      # Hint config elements contain configuration information, typically including
      # a base URL and configuration string.
      class HintConfig < Element
        # Value class identifier for hint config elements.
        # @return [String]
        VALUE_CLASS = "HC"

        # Creates a new HintConfig instance.
        #
        # @param value [Array] Array of 2 elements: [url, config_string]
        # @param value_class [String] The value class (defaults to "HC").
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value validation fails.
        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be an array" unless value.is_a?(Array)
            raise ArgumentError, "value length must be 2" unless value.length == 2
            raise ArgumentError, "url must be a string" unless url.is_a?(String)
            raise ArgumentError, "config_string must be a string" unless config_string.is_a?(String)
          end
        end

        # The URL of the configuration.
        # @return [String]
        def url
          @value[0]
        end

        # The configuration string.
        # @return [String]
        def config_string
          @value[1]
        end
      end

      # Represents a module element (I).
      #
      # Module elements contain information about JavaScript modules, including
      # module ID, chunks, and module name.
      class Module < Element
        # Value class identifier for module elements.
        # @return [String]
        VALUE_CLASS = "I"

        # Creates a new Module instance.
        #
        # @param value [Array, Hash] Module data (array or hash format).
        # @param value_class [String] The value class (defaults to "I").
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value validation fails.
        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be array or hash" unless value.is_a?(Array) || value.is_a?(Hash)
            raise ArgumentError, "value length must be 3-4" if value.is_a?(Array) && !(3..4).include?(value.length)
            raise ArgumentError, "module_id must be integer" unless module_id.is_a?(Integer)
            if value.is_a?(Array)
              raise ArgumentError, "chunks must be array" unless value[1].is_a?(Array)
              raise ArgumentError, "chunks length must be even" unless value[1].length.even?
            else
              raise ArgumentError, "chunks must be array" unless value["chunks"].is_a?(Array)
            end
            raise ArgumentError, "module_name must be string" unless module_name.is_a?(String)
          end
        end

        # The module ID.
        # @return [Integer]
        def module_id
          @value.is_a?(Array) ? @value[0] : @value["id"].to_i
        end

        # Raw module chunks as a hash of chunk names to paths.
        # @return [Hash<String, String>]
        def module_chunks_raw
          if @value.is_a?(Array)
            chunks = @value[1]
            chunks.each_slice(2).to_h
          else
            @value["chunks"].to_h { |item| item.split(":", 2) }
          end
        end

        # Module chunks with full Next.js paths.
        # @return [Hash<String, String>]
        def module_chunks
          base = Parser::Urls::N
          module_chunks_raw.transform_values { |v| Utils.join(base, v) }
        end

        # The module name.
        # @return [String]
        def module_name
          @value.is_a?(Array) ? @value[2] : @value["name"]
        end

        # Whether the module is async.
        # @return [Boolean]
        def is_async
          @value.is_a?(Hash) ? @value["async"] : false
        end
      end

      # Represents a text element (T).
      #
      # Text elements contain plain text content.
      class Text < Element
        # Value class identifier for text elements.
        # @return [String]
        VALUE_CLASS = "T"

        # Creates a new Text instance.
        #
        # @param value [String] The text content.
        # @param value_class [String] The value class (defaults to "T").
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value is not a string.
        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be a string" unless value.is_a?(String)
          end
        end

        # The text content.
        # @return [String]
        def text
          @value
        end
      end

      # Represents a data element.
      #
      # Data elements contain flight data object structures with optional content.
      class Data < Element
        # Value class identifier for data elements (nil).
        # @return [nil]
        VALUE_CLASS = nil

        # Creates a new Data instance.
        #
        # @param value [Array] Flight data object array: ["$", string, string_or_nil, hash_or_nil]
        # @param value_class [nil] The value class (nil for data elements).
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value validation fails.
        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be flight data obj" unless Types.is_flight_data_obj(value)
            raise ArgumentError, "content must be nil or hash" unless content.nil? || content.is_a?(Hash)
          end
        end

        # The content hash of the data element.
        # @return [Hash, nil]
        def content
          @value[3]
        end
      end

      # Represents an empty data element.
      #
      # Empty data elements have a nil value and represent empty/null data.
      class EmptyData < Element
        # Value class identifier for empty data elements (nil).
        # @return [nil]
        VALUE_CLASS = nil

        # Creates a new EmptyData instance.
        #
        # @param value [nil] Must be nil for empty data.
        # @param value_class [nil] The value class (nil for empty data elements).
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value is not nil.
        def initialize(value: nil, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be nil" unless @value.nil?
          end
        end
      end

      # Represents a special data element.
      #
      # Special data elements are strings that start with "$" and represent
      # special data structures.
      class SpecialData < Element
        # Value class identifier for special data elements (nil).
        # @return [nil]
        VALUE_CLASS = nil

        # Creates a new SpecialData instance.
        #
        # @param value [String] A string starting with "$".
        # @param value_class [nil] The value class (nil for special data elements).
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value validation fails.
        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be a string" unless value.is_a?(String)
            raise ArgumentError, "value must start with $" unless value.start_with?("$")
          end
        end
      end

      # Represents an HTML element.
      #
      # HTML elements represent DOM elements in the flight data structure.
      class HTMLElement < Element
        # Value class identifier for HTML elements (nil).
        # @return [nil]
        VALUE_CLASS = nil

        # Creates a new HTMLElement instance.
        #
        # @param value [Array] Flight data object array: ["$", tag, href_or_nil, attrs]
        # @param value_class [nil] The value class (nil for HTML elements).
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value validation fails.
        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be flight data obj" unless Types.is_flight_data_obj(value)
            raise ArgumentError, "tag must be a string" unless tag.is_a?(String)
            raise ArgumentError, "href must be nil or string" unless href.nil? || href.is_a?(String)
            raise ArgumentError, "attrs must be a hash" unless attrs.is_a?(Hash)
          end
        end

        # The HTML tag name.
        # @return [String]
        def tag
          @value[1]
        end

        # The href attribute value, if present.
        # @return [String, nil]
        def href
          @value[2]
        end

        # The attributes hash.
        # @return [Hash]
        def attrs
          @value[3]
        end
      end

      # Represents a data container element.
      #
      # Data containers are arrays of other elements, providing a way to group
      # multiple elements together.
      class DataContainer < Element
        # Value class identifier for data container elements (nil).
        # @return [nil]
        VALUE_CLASS = nil

        # Creates a new DataContainer instance.
        #
        # @param value [Array] Array of element values to resolve.
        # @param value_class [nil] The value class (nil for data containers).
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value validation fails.
        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          @value = value.map do |item|
            Types.resolve_type(value: item, value_class: nil, index: nil)
          end
          super(value: @value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "all items must be Elements" unless @value.all? { |item| item.is_a?(Element) }
          end
        end
      end

      # Represents a data parent element.
      #
      # Data parents are flight data objects that contain a "children" key,
      # representing a parent-child relationship in the data structure.
      class DataParent < Element
        # Value class identifier for data parent elements (nil).
        # @return [nil]
        VALUE_CLASS = nil

        # Creates a new DataParent instance.
        #
        # @param value [Array] Flight data object array with children: ["$", string, string_or_nil, {"children" => ...}]
        # @param value_class [nil] The value class (nil for data parents).
        # @param index [Integer, nil] The index of the element.
        # @raise [ArgumentError] If value validation fails.
        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          children_value = value[3]["children"]
          resolved_children = Types.resolve_type(value: children_value, value_class: nil, index: nil)
          new_value = value.dup
          new_value[3] = value[3].dup
          new_value[3]["children"] = resolved_children

          super(value: new_value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be flight data obj" unless Types.is_flight_data_obj(new_value)
            raise ArgumentError, "children must be an Element" unless children.is_a?(Element)
          end
        end

        def children
          @value[3]["children"]
        end
      end

      class URLQuery < Element
        VALUE_CLASS = nil

        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value length must be 3" unless value.length == 3
            raise ArgumentError, "key must be a string" unless key.is_a?(String)
            raise ArgumentError, "val must be a string" unless val.is_a?(String)
          end
        end

        def key
          @value[0]
        end

        def val
          @value[1]
        end
      end

      class RSCPayloadVersion
        OLD = 0
        NEW = 1
      end

      class RSCPayload < Element
        VALUE_CLASS = nil

        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be flight data obj or hash" unless Types.is_flight_data_obj(value) || value.is_a?(Hash)
            raise ArgumentError, "build_id must be a string" unless build_id.is_a?(String)
          end
        end

        def version
          if @value.is_a?(Array) && @value.length == 4
            RSCPayloadVersion::OLD
          elsif @value.is_a?(Hash) && @value.key?("b")
            RSCPayloadVersion::NEW
          else
            raise ArgumentError, "unknown flight rcs payload version"
          end
        end

        def build_id
          case version
          when RSCPayloadVersion::NEW
            @value["b"]
          when RSCPayloadVersion::OLD
            @value[3]["buildId"]
          end
        end
      end

      class Error < Element
        VALUE_CLASS = "E"

        def initialize(value:, value_class: VALUE_CLASS, index: nil)
          super(value: value, value_class: value_class, index: index)

          if ENABLE_TYPE_VERIF
            raise ArgumentError, "value must be a hash" unless value.is_a?(Hash)
            raise ArgumentError, "value must contain digest" unless value.key?("digest")
            raise ArgumentError, "digest must be a string" unless digest.is_a?(String)
          end
        end

        def digest
          @value["digest"]
        end
      end

      ELEMENT_KEYS = ["value", "value_class", "index"].freeze
      DUMPED_ELEMENT_KEYS = (ELEMENT_KEYS + ["cls"]).freeze

      TYPES = {
        "HL" => HintPreload,
        "HC" => HintConfig,
        "I" => Module,
        "T" => Text,
        "E" => Error
      }.freeze

      TL2OBJ = {
        "Element" => Element,
        "HintPreload" => HintPreload,
        "HintConfig" => HintConfig,
        "Module" => Module,
        "Text" => Text,
        "Data" => Data,
        "EmptyData" => EmptyData,
        "SpecialData" => SpecialData,
        "HTMLElement" => HTMLElement,
        "DataContainer" => DataContainer,
        "DataParent" => DataParent,
        "URLQuery" => URLQuery,
        "RSCPayload" => RSCPayload,
        "Error" => Error
      }.freeze

      def self.resolve_type(value:, value_class:, index:, cls: nil)
        if value.is_a?(Hash) && (ELEMENT_KEYS - value.keys.map(&:to_s)).empty?
          return resolve_type(
            value: value["value"] || value[:value],
            value_class: value["value_class"] || value[:value_class],
            index: value["index"] || value[:index],
            cls: cls
          )
        end

        if cls && cls.is_a?(String)
          cls = TL2OBJ.fetch(cls)
        end

        if cls.nil?
          if value_class.nil?
            if value.is_a?(Array)
              if is_flight_data_obj(value)
                if value[1].start_with?("$")
                  if value[3].nil?
                    cls = Data
                  elsif value[3].is_a?(Hash) && value[3].key?("buildId")
                    cls = RSCPayload
                  elsif value[3].is_a?(Hash) && value[3].length == 1 && value[3].key?("children")
                    cls = DataParent
                  else
                    cls = Data
                  end
                else
                  cls = HTMLElement
                end
              elsif value.length == 3 && value[2] == "d" && value.all? { |item| item.is_a?(String) }
                cls = URLQuery
              else
                cls = DataContainer
              end
            elsif value.nil?
              cls = EmptyData
            elsif value.is_a?(Hash) && index == 0
              cls = RSCPayload
            elsif value.is_a?(String) && value.start_with?("$")
              cls = SpecialData
            end
          elsif TYPES.key?(value_class)
            cls = TYPES[value_class]
          end
        end

        if cls.nil?
          if index == 0
            raise ArgumentError, "Data at index 0 did not find any object to store its RSCPayload."
          end
          Utils::LOGGER.warn("Couldn't find an appropriate type for given class `#{value_class}`. Giving `Element`.")
          cls = Element
        end

        cls.new(value: value, value_class: value_class, index: index)
      end

      module T
        Element = Types::Element
        HintPreload = Types::HintPreload
        HintConfig = Types::HintConfig
        Module = Types::Module
        Text = Types::Text
        Data = Types::Data
        EmptyData = Types::EmptyData
        SpecialData = Types::SpecialData
        HTMLElement = Types::HTMLElement
        DataContainer = Types::DataContainer
        DataParent = Types::DataParent
        URLQuery = Types::URLQuery
        RSCPayload = Types::RSCPayload
        Error = Types::Error
      end
    end
  end
end
