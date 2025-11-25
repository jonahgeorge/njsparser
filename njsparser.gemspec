# frozen_string_literal: true

require_relative "lib/njsparser/version"

Gem::Specification.new do |spec|
  spec.name          = "njsparser"
  spec.version       = Njsparser::VERSION
  spec.authors       = ["Jonah George"]
  spec.email         = ["jonah.george@icloud.com"]

  spec.summary       = "A Ruby NextJS data parser from HTML"
  spec.description   = "A powerful parser and explorer for any website built with NextJS. Parses flight data, next data, build manifests, and more."
  spec.homepage      = "https://github.com/jonahgeorge/njsparser"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.15"
  spec.add_dependency "execjs", "~> 2.8"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
