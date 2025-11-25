require_relative "../test_helper"

class TestFlightData < Minitest::Test
  def test_has_flight_data
    assert Njsparser::Parser::FlightData.has_flight_data(NEXTJS_ORG_HTML)
    refute Njsparser::Parser::FlightData.has_flight_data(X_COM_HTML)
    refute Njsparser::Parser::FlightData.has_flight_data(M_SOUNDCLOUD_COM_HTML)
  end

  def test_get_raw_flight_data
    assert Njsparser::Parser::FlightData.get_raw_flight_data(NEXTJS_ORG_HTML)
    assert Njsparser::Parser::FlightData.get_flight_data(NEXTJS_ORG_HTML)
    assert_nil Njsparser::Parser::FlightData.get_raw_flight_data(X_COM_HTML)
    assert_nil Njsparser::Parser::FlightData.get_flight_data(X_COM_HTML)
    assert_nil Njsparser::Parser::FlightData.get_raw_flight_data(M_SOUNDCLOUD_COM_HTML)
    assert_nil Njsparser::Parser::FlightData.get_flight_data(M_SOUNDCLOUD_COM_HTML)
    assert Njsparser::Parser::FlightData.get_raw_flight_data(MINTSTARS_COM_HTML)
    assert Njsparser::Parser::FlightData.get_flight_data(MINTSTARS_COM_HTML)
  end
end
