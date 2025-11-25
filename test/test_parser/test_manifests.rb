require_relative "../test_helper"

class TestManifests < Minitest::Test
  def test_parse_buildmanifest
    assert Njsparser::Parser::Manifests.parse_buildmanifest(NEXTJS_ORG_4MSOWJPTZZPEMGZZI8AOO_BUILD_MANIFEST)
    assert Njsparser::Parser::Manifests.parse_buildmanifest(SWAG_LIVE_GIZ3A1H7OUZFXGRHIDMX_BUILD_MANIFEST)
    assert_equal({}, Njsparser::Parser::Manifests.parse_buildmanifest(<<~JS))
      self.__BUILD_MANIFEST = function(e) {
        return {}
      }(1), self.__BUILD_MANIFEST_CB && self.__BUILD_MANIFEST_CB();
    JS
    assert Njsparser::Parser::Manifests.parse_buildmanifest(APP_OSINT_INDUSTRIES_YAZR27J6CJHLWW3VXUZZI_BUILD_MANIFEST)
    assert_nil Njsparser::Parser::Manifests.parse_buildmanifest("self.__BUILD_MANIFEST=sdfnjjksdfn")
    assert Njsparser::Parser::Manifests.parse_buildmanifest(RUNPOD_IO_S4XE_TFYLTFF_BW1HFD4_BUILD_MANIFEST)

    assert_raises(ArgumentError) do
      Njsparser::Parser::Manifests.parse_buildmanifest("dfsfdn")
    end
  end

  def test_get_build_manifest_path
    build_id = Njsparser::Tools.find_build_id(M_SOUNDCLOUD_COM_HTML)
    assert_equal "/_next/static/1733156665/_buildManifest.js",
                 Njsparser::Parser::Manifests.get_build_manifest_path(build_id)
  end
end
