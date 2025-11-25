# frozen_string_literal: true

require "json"
require "base64"
require_relative "../utils"
require_relative "types"

module Njsparser
  module Parser
    # Methods for parsing Next.js React Server Components (RSC) flight data.
    #
    # Flight data is embedded in Next.js pages as JavaScript arrays pushed to
    # `self.__next_f` and contains serialized React component data.
    module FlightData
      # Flight data segment types.
      module Segment
        # Bootstrap segment type.
        IS_BOOTSTRAP = 0

        # Non-bootstrap segment type.
        IS_NOT_BOOTSTRAP = 1

        # Form state segment type.
        IS_FORM_STATE = 2

        # Binary segment type (Base64 encoded).
        IS_BINARY = 3
      end

      # Regular expression for matching flight data initialization.
      # @return [Regexp]
      RE_F_INIT = /\(self\.__next_f\s?=\s?self\.__next_f\s?\|\|\s?\[\]\)\.push\((\[.+?\])\)/

      # Regular expression for matching flight data payload pushes.
      # @return [Regexp]
      RE_F_PAYLOAD = /self\.__next_f\.push\((\[.+)\)$/

      # Checks if the given value contains flight data.
      #
      # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
      #   The HTML string or parsed HTML document.
      # @return [Boolean] True if flight data is found.
      #
      # @example
      #   html = File.read('page.html')
      #   has_data = Njsparser::Parser::FlightData.has_flight_data(html)
      def self.has_flight_data(value)
        tree = Utils.make_tree(value)
        scripts = tree.xpath("//script/text()")
        scripts.any? { |script| RE_F_INIT.match(script.text) }
      end

      # Extracts raw flight data arrays from HTML scripts.
      #
      # Finds all `self.__next_f.push(...)` calls and extracts the array arguments.
      #
      # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
      #   The HTML string or parsed HTML document.
      # @return [Array<Array>, nil] Array of flight data segments, or nil if none found.
      #
      # @example
      #   html = File.read('page.html')
      #   raw_data = Njsparser::Parser::FlightData.get_raw_flight_data(html)
      def self.get_raw_flight_data(value)
        result = []
        found_init = false

        tree = Utils.make_tree(value)
        tree.xpath("//script/text()").each do |script_node|
          script = script_node.text.strip

          if !found_init && (match = RE_F_INIT.match(script))
            found_init = true
            result << JSON.parse(match[1])
          end

          if match = RE_F_PAYLOAD.match(script)
            result << JSON.parse(match[1])
          end
        end

        result.empty? ? nil : result
      end

      def self.decode_raw_flight_data(raw_flight_data)
        initial_server_data_buffer = nil

        raw_flight_data.each do |seg|
          case seg[0]
          when Segment::IS_BOOTSTRAP
            initial_server_data_buffer = []
          when Segment::IS_NOT_BOOTSTRAP
            raise "initial_server_data_buffer not initialized" if initial_server_data_buffer.nil?
            initial_server_data_buffer << seg[1]
          when Segment::IS_FORM_STATE
            # Form state data (currently unused)
            _initial_form_state_data = seg[1]
          when Segment::IS_BINARY
            raise "initial_server_data_buffer not initialized" if initial_server_data_buffer.nil?
            decoded_chunk = Base64.decode64(seg[1])
            initial_server_data_buffer << decoded_chunk.force_encoding("UTF-8")
          else
            raise KeyError, "Unknown segment type seg[0]=#{seg[0]}"
          end
        end

        initial_server_data_buffer || []
      end

      # Regular expression for matching split points in decoded flight data.
      # @return [Regexp]
      SPLIT_POINTS = /(?<!\\)\n[a-f0-9]*:/.freeze

      # Parses decoded flight data into a hash of indexed elements.
      #
      # The decoded flight data is a binary string containing hex-encoded indices
      # and serialized JSON or text values. This method parses it into a structured
      # hash where keys are indices and values are resolved Element instances.
      #
      # @param decoded_raw_flight_data [Array<String>] Array of decoded string chunks.
      # @return [Hash<Integer, Parser::Types::Element>]
      #   Hash mapping indices to Element instances.
      #
      # @example
      #   decoded = ["0:HL[\"href\",\"type\"],1:T,10:Hello"]
      #   parsed = Njsparser::Parser::FlightData.parse_decoded_raw_flight_data(decoded)
      def self.parse_decoded_raw_flight_data(decoded_raw_flight_data)
        compiled_raw_flight_data = decoded_raw_flight_data.join("").force_encoding("ASCII-8BIT")
        indexed_result = {}
        pos = 0

        loop do
          index_string_end = compiled_raw_flight_data.index(":", pos)
          break if index_string_end.nil?

          index_string_raw = compiled_raw_flight_data[pos...index_string_end]
          index = index_string_raw.empty? ? nil : index_string_raw.to_i(16)
          pos = index_string_end + 1

          value_class = ""
          while pos < compiled_raw_flight_data.length
            char = compiled_raw_flight_data[pos].chr
            break unless char.match?(/[A-Z]/)
            value_class += char
            pos += 1
          end
          value_class = value_class.empty? ? nil : value_class

          if value_class == "T"
            text_length_string_end = compiled_raw_flight_data.index(",", pos)
            text_length_hex = compiled_raw_flight_data[pos...text_length_string_end]
            text_length = text_length_hex.to_i(16)
            text_start = text_length_string_end + 1
            raw_value = compiled_raw_flight_data[text_start...(text_start + text_length)].force_encoding("UTF-8")
            pos = text_start + text_length
          else
            if match = SPLIT_POINTS.match(compiled_raw_flight_data, pos)
              data_end = match.begin(0)
              raw_value = compiled_raw_flight_data[pos...data_end]
              pos = data_end + 1
            else
              raw_value = compiled_raw_flight_data[pos..-2]
              pos += raw_value.length
            end
          end

          value = if value_class != "T"
            JSON.parse(raw_value.force_encoding("UTF-8"))
          else
            raw_value
          end

          resolved = Types.resolve_type(value: value, value_class: value_class, index: index)

          if index.nil?
            indexed_result[index] ||= []
            indexed_result[index] << resolved
          else
            indexed_result[index] = resolved
          end
        end

        indexed_result
      end

      # Extracts and parses flight data from HTML.
      #
      # This is the main entry point for flight data parsing. It combines all
      # the steps: extraction, decoding, and parsing.
      #
      # @param value [String, Nokogiri::HTML::Document, Nokogiri::XML::Element]
      #   The HTML string or parsed HTML document.
      # @return [Hash<Integer, Parser::Types::Element>, nil]
      #   Hash mapping indices to Element instances, or nil if no flight data found.
      #
      # @example
      #   html = File.read('page.html')
      #   flight_data = Njsparser::Parser::FlightData.get_flight_data(html)
      #   rsc_payload = flight_data.values.find { |e| e.is_a?(Njsparser::Parser::Types::RSCPayload) }
      def self.get_flight_data(value)
        raw_flight_data = get_raw_flight_data(value)
        return nil if raw_flight_data.nil?

        decoded_raw_flight_data = decode_raw_flight_data(raw_flight_data)
        parse_decoded_raw_flight_data(decoded_raw_flight_data)
      end
    end
  end
end
