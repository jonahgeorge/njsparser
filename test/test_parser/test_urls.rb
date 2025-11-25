require_relative "../test_helper"

class TestUrls < Minitest::Test
  def test_get_next_static_urls
    assert Njsparser::Parser::Urls.get_next_static_urls(M_SOUNDCLOUD_COM_HTML)
    assert_nil Njsparser::Parser::Urls.get_next_static_urls(X_COM_HTML)
    assert Njsparser::Parser::Urls.get_next_static_urls(NEXTJS_ORG_HTML)
  end

  def test_get_base_path
    assert_equal "https://m.sndcdn.com",
                 Njsparser::Parser::Urls.get_base_path(M_SOUNDCLOUD_COM_HTML)
    assert_equal "",
                 Njsparser::Parser::Urls.get_base_path(M_SOUNDCLOUD_COM_HTML, remove_domain: true)
    assert_nil Njsparser::Parser::Urls.get_base_path(X_COM_HTML)
    assert_equal "/static",
                 Njsparser::Parser::Urls.get_base_path(SWAG_LIVE_HTML, remove_domain: true)

    assert_raises(ArgumentError) do
      # Doesn't contain any `/_next/static/`.
      Njsparser::Parser::Urls.get_base_path(["https://test.com/hello"])
    end

    assert_raises(ArgumentError) do
      # The position of `/_next/static/` isn't the same.
      Njsparser::Parser::Urls.get_base_path(["/bubu/_next/static/", "/bububu/_next/static/"])
    end
  end
end
