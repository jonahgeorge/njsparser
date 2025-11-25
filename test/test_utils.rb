require_relative "test_helper"

class TestUtils < Minitest::Test
  def test_make_tree
    h = "<html>hello</html>"
    result = Njsparser::Utils.make_tree(h.encode("UTF-8"))
    assert_instance_of Nokogiri::HTML::Document, result

    result = Njsparser::Utils.make_tree(h)
    assert_instance_of Nokogiri::HTML::Document, result

    result2 = Njsparser::Utils.make_tree(result)
    assert_equal result, result2

    assert_raises(TypeError) do
      Njsparser::Utils.make_tree(1)
    end
  end

  def test_join
    assert_equal "/hello/world", Njsparser::Utils.join("hello", "world")
    assert_equal "/hello/world", Njsparser::Utils.join("/hello///", "/world/")
  end
end
