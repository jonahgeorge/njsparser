require_relative "../test_helper"

class TestNextData < Minitest::Test
  def test_find_nextdata
    assert Njsparser::Parser::NextData.get_next_data(M_SOUNDCLOUD_COM_HTML)
    assert_nil Njsparser::Parser::NextData.get_next_data(X_COM_HTML)
    assert_nil Njsparser::Parser::NextData.get_next_data(NEXTJS_ORG_HTML)
  end
end
