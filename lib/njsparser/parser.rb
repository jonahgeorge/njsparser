# frozen_string_literal: true

require_relative "parser/flight_data"
require_relative "parser/next_data"
require_relative "parser/urls"
require_relative "parser/manifests"
require_relative "parser/types"

module Njsparser
  module Parser
    module Urls
      extend self
    end

    module FlightData
      extend self
    end

    module NextData
      extend self
    end

    module Manifests
      extend self
    end

    module Types
      extend self
    end

    def self.has_flight_data(value)
      FlightData.has_flight_data(value)
    end

    def self.get_flight_data(value)
      FlightData.get_flight_data(value)
    end

    def self.has_next_data(value)
      NextData.has_next_data(value)
    end

    def self.get_next_data(value)
      NextData.get_next_data(value)
    end

    def self.get_next_static_urls(value)
      Urls.get_next_static_urls(value)
    end

    def self.get_base_path(value, remove_domain: nil)
      Urls.get_base_path(value, remove_domain: remove_domain)
    end

    def self.parse_buildmanifest(script)
      Manifests.parse_buildmanifest(script)
    end

    def self.get_build_manifest_path(build_id, base_path = nil)
      Manifests.get_build_manifest_path(build_id, base_path)
    end
  end
end
