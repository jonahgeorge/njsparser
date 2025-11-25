require_relative "test_helper"

class ToolsTest < Minitest::Test
  def test_has_nextjs
    assert Njsparser::Tools.has_nextjs(M_SOUNDCLOUD_COM_HTML)
    assert Njsparser::Tools.has_nextjs(NEXTJS_ORG_HTML)
    refute Njsparser::Tools.has_nextjs(X_COM_HTML)
  end

  def test_findall_in_flight_data
    flight_data = {
      0 => Njsparser::Parser::Types::RSCPayload.new(
        value: {"b" => "BUILDID"},
        value_class: nil,
        index: 0
      ),
      1 => Njsparser::Parser::Types::Error.new(
        value: {"digest" => "NEXT_NOT_FOUND"},
        value_class: "E",
        index: 1
      ),
      2 => Njsparser::Parser::Types::SpecialData.new(
        value: "$Sreactblahblah",
        value_class: nil,
        index: 2
      ),
      3 => Njsparser::Parser::Types::Text.new(
        value: "hello world",
        value_class: "T",
        index: 3
      )
    }

    class_filters = [Njsparser::Parser::Types::RSCPayload, Njsparser::Parser::Types::Module]
    results = Njsparser::Tools.find_all_in_flight_data(flight_data, class_filters: class_filters)
    results.each do |item|
      assert class_filters.include?(item.class)
    end

    assert_equal flight_data.values, Njsparser::Tools.find_all_in_flight_data(flight_data)

    results = Njsparser::Tools.find_all_in_flight_data(
      flight_data,
      callback: ->(item) { !item.index.nil? && item.index.odd? }
    )
    results.each do |item|
      assert item.index.odd?
    end

    assert_equal [], Njsparser::Tools.find_all_in_flight_data(nil)
  end

  def test_find_in_flight_data
    flight_data = {
      0 => Njsparser::Parser::Types::RSCPayload.new(
        value: {"b" => "BUILDID"},
        value_class: nil,
        index: 0
      ),
      1 => Njsparser::Parser::Types::Error.new(
        value: {"digest" => "NEXT_NOT_FOUND"},
        value_class: "E",
        index: 1
      )
    }

    assert_nil Njsparser::Tools.find_in_flight_data(flight_data, class_filters: [Njsparser::Parser::Types::URLQuery])
    assert_equal flight_data[0], Njsparser::Tools.find_in_flight_data(flight_data, class_filters: [Njsparser::Parser::Types::RSCPayload])
    assert_nil Njsparser::Tools.find_in_flight_data(nil)

    # Test recursive search
    recursive_data = {
      "value" => [
        {"value" => nil, "value_class" => nil, "index" => nil},
        {"value" => false, "value_class" => nil, "index" => nil},
        {
          "value" => ["$", "$L16", nil, {"children" => ["$", "$L17", nil, {"profile" => {}}]}],
          "value_class" => nil,
          "index" => nil
        }
      ],
      "value_class" => nil,
      "index" => 5,
      "cls" => "DataContainer"
    }

    resolved = Njsparser::Parser::Types.resolve_type(**recursive_data.transform_keys(&:to_sym))
    found = Njsparser::Tools.find_in_flight_data({0 => resolved}, class_filters: [Njsparser::Parser::Types::Data])
    assert_equal({"profile" => {}}, found.content)

    assert_nil Njsparser::Tools.find_in_flight_data(
      {0 => resolved},
      class_filters: [Njsparser::Parser::Types::Data],
      recursive: false
    )
  end

  def test_find_build_id
    assert_equal "1733156665", Njsparser::Tools.find_build_id(M_SOUNDCLOUD_COM_HTML)
    assert_equal "4mSOwJptzzPemGzzI8AOo", Njsparser::Tools.find_build_id(NEXTJS_ORG_HTML)
    assert_nil Njsparser::Tools.find_build_id(X_COM_HTML)
    assert_equal "giz3a1H7OUzfxgxRHIdMx", Njsparser::Tools.find_build_id(SWAG_LIVE_HTML)

    # Recursive search here
    assert_equal "n2xbxZXkzoS6U5w7CgB-T", Njsparser::Tools.find_build_id(CLUB_FANS_HTML)
  end

  def test_flight_data_explorer
    assert_raises(TypeError) do
      Njsparser::Tools::FlightDataExplorer.new(nil)
    end

    fd = Njsparser::Tools::FlightDataExplorer.new(CLUB_FANS_HTML)
    assert fd.find
    assert_instance_of Njsparser::Parser::Types::Data, fd.find(class_filters: [Njsparser::T::Data])
    assert_instance_of Njsparser::Parser::Types::Data, fd.find(class_filters: ["Data"])

    assert_raises(KeyError) do
      fd.find(class_filters: ["Datsdfdsfa"])
    end

    fd.each do |key, value|
      assert key.is_a?(Integer)
      assert value.is_a?(Njsparser::Parser::Types::Element)
      break
    end

    assert Njsparser::Tools::FlightDataExplorer.new({})
    assert_equal 1, Njsparser::Tools::FlightDataExplorer.new({
      1 => Njsparser::Parser::Types::URLQuery.new(
        value: ["x", "y", "d"],
        value_class: nil,
        index: 1
      )
    }).length

    empty_bfd = Njsparser::Tools::FlightDataExplorer.new("<html></html>")
    assert empty_bfd.empty?
    assert_equal 0, empty_bfd.length
    assert_instance_of Array, empty_bfd.as_list
  end
end
