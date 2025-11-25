require_relative "../test_helper"

class TestTypes < Minitest::Test
  def test_element
    element = Njsparser::Parser::Types::Element.new(
      value: "hi",
      value_class: nil,
      index: 1
    )
    assert_equal "hi", element.value
    assert_nil element.value_class
    assert_equal 1, element.index

    # Test frozen
    assert_raises(FrozenError) do
      element.value = "hello"
    end
  end

  def test_hint_preload
    href1 = "/_next/static/media/569ce4b8f30dc480-s.p.woff2"
    type_name1 = "font"
    attrs1 = {"crossOrigin" => "", "type" => "font/woff2"}

    payload1 = {
      value: [href1, type_name1, attrs1],
      value_class: "HL",
      index: 1
    }

    assert_raises(ArgumentError) do
      Njsparser::Parser::Types::HintPreload.new(value: ["hello"])
    end

    hl1 = Njsparser::Parser::Types::HintPreload.new(**payload1)
    assert_equal href1, hl1.href
    assert_equal type_name1, hl1.type_name
    assert_equal attrs1, hl1.attrs

    href2 = "/_next/static/css/3a4b7cc0153d49b4.css?dpl=dpl_F2qLi1zuzNsnuiFMqRXyYU9dbJYw"
    type_name2 = "style"
    payload2 = {
      value: [href2, type_name2],
      value_class: "HL",
      index: 1
    }

    hl2 = Njsparser::Parser::Types::HintPreload.new(**payload2)
    assert_equal href2, hl2.href
    assert_equal type_name2, hl2.type_name
    assert_nil hl2.attrs
  end

  def test_module
    payload1 = {
      value: [
        30777,
        [
          "71523",
          "static/chunks/25c8a87d-0d1c991f726a4cc1.js",
          "10411",
          "static/chunks/app/(webapp)/%5Blang%5D/(public)/user/layout-bd7c1d222b477529.js"
        ],
        "default"
      ],
      value_class: "I",
      index: 1
    }

    i = Njsparser::Parser::Types::Module.new(**payload1)
    assert_equal 30777, i.module_id
    assert_equal({
      "71523" => "static/chunks/25c8a87d-0d1c991f726a4cc1.js",
      "10411" => "static/chunks/app/(webapp)/%5Blang%5D/(public)/user/layout-bd7c1d222b477529.js"
    }, i.module_chunks_raw)
    assert_equal({
      "71523" => "/_next/static/chunks/25c8a87d-0d1c991f726a4cc1.js",
      "10411" => "/_next/static/chunks/app/(webapp)/%5Blang%5D/(public)/user/layout-bd7c1d222b477529.js"
    }, i.module_chunks)
    assert_equal "default", i.module_name
    assert_equal false, i.is_async

    payload2 = {
      value: {
        "id" => "47858",
        "chunks" => [
          "272:static/chunks/webpack-2f0e36f832c3608a.js",
          "667:static/chunks/2443530c-7d590f93d1ab76bc.js",
          "139:static/chunks/139-1e0b88e46566ba7f.js"
        ],
        "name" => "",
        "async" => false
      },
      value_class: "I",
      index: 1
    }

    i2 = Njsparser::Parser::Types::Module.new(**payload2)
    assert_equal 47858, i2.module_id
    assert_equal({
      "272" => "static/chunks/webpack-2f0e36f832c3608a.js",
      "667" => "static/chunks/2443530c-7d590f93d1ab76bc.js",
      "139" => "static/chunks/139-1e0b88e46566ba7f.js"
    }, i2.module_chunks_raw)
    assert_equal "", i2.module_name
    assert_equal false, i2.is_async
  end

  def test_text
    hw = "hello world"
    payload = {
      value: hw,
      value_class: "T",
      index: 1
    }

    t = Njsparser::Parser::Types::Text.new(**payload)
    assert_equal hw, t.value
    assert_equal hw, t.text
  end

  def test_data
    payload1 = {
      value: ["$", "$L1", nil, nil],
      value_class: nil,
      index: 1
    }
    payload2 = {
      value: ["$", "$L1", nil, {}],
      value_class: nil,
      index: 1
    }

    assert_nil Njsparser::Parser::Types::Data.new(**payload1).content
    assert_equal({}, Njsparser::Parser::Types::Data.new(**payload2).content)
  end

  def test_empty_data
    payload = {
      value: nil,
      value_class: nil,
      index: 1
    }

    assert_nil Njsparser::Parser::Types::EmptyData.new(**payload).value
  end

  def test_special_data
    payload = {
      value: "$Sreact.suspense",
      value_class: nil,
      index: 1
    }

    assert_equal "$Sreact.suspense", Njsparser::Parser::Types::SpecialData.new(**payload).value
  end

  def test_html_element
    payload1 = {
      value: ["$", "div", nil, {}],
      value_class: nil,
      index: 1
    }
    payload2 = {
      value: [
        "$",
        "link",
        "https://sentry.io",
        {"rel" => "dns-prefetch", "href" => "https://sentry.io"}
      ],
      value_class: nil,
      index: 1
    }

    h1 = Njsparser::Parser::Types::HTMLElement.new(**payload1)
    assert_equal "div", h1.tag
    assert_nil h1.href
    assert_equal({}, h1.attrs)

    h2 = Njsparser::Parser::Types::HTMLElement.new(**payload2)
    assert_equal "link", h2.tag
    assert_equal "https://sentry.io", h2.href
    assert_equal({"rel" => "dns-prefetch", "href" => "https://sentry.io"}, h2.attrs)
  end

  def test_data_container
    payload = {
      value: [
        ["$", "div", nil, {}],
        ["$", "link", "https://sentry.io", {"rel" => "dns-prefetch", "href" => "https://sentry.io"}]
      ],
      value_class: nil,
      index: 1
    }

    dcp = Njsparser::Parser::Types::DataContainer.new(**payload)
    assert_equal 2, dcp.value.length
    assert dcp.value.all? { |item| item.is_a?(Njsparser::Parser::Types::HTMLElement) }
  end

  def test_data_parent
    payload = {
      value: [
        "$",
        "$L16",
        nil,
        {
          "children" => [
            "$",
            "$L17",
            nil,
            {
              "profile" => {}
            }
          ]
        }
      ],
      value_class: nil,
      index: nil
    }

    dp = Njsparser::Parser::Types::DataParent.new(**payload)
    assert_equal({"profile" => {}}, dp.children.content)
  end

  def test_url_query
    phv = ["key", "val", "d"]
    payload = {
      value: phv,
      value_class: nil,
      index: 1
    }

    urlp = Njsparser::Parser::Types::URLQuery.new(**payload)
    assert_equal phv[0], urlp.key
    assert_equal phv[1], urlp.val
  end

  def test_rsc_payload
    iam = "i am a build id"
    payload_old = {
      value: ["$", "$L1", nil, {"buildId" => iam}],
      value_class: nil,
      index: 0
    }

    rscp1 = Njsparser::Parser::Types::RSCPayload.new(**payload_old)
    assert_equal Njsparser::Parser::Types::RSCPayloadVersion::OLD, rscp1.version
    assert_equal iam, rscp1.build_id

    iamn = "i am a new build id"
    payload_new = {
      value: {"b" => iamn},
      value_class: nil,
      index: 0
    }

    rscp2 = Njsparser::Parser::Types::RSCPayload.new(**payload_new)
    assert_equal Njsparser::Parser::Types::RSCPayloadVersion::NEW, rscp2.version
    assert_equal iamn, rscp2.build_id
  end

  def test_error
    err = "NEXT_NOT_FOUND"
    payload = {
      value: {"digest" => err},
      value_class: "E",
      index: 1
    }

    fe = Njsparser::Parser::Types::Error.new(**payload)
    assert_equal err, fe.digest
  end

  def test_resolve_type
    href1 = "/_next/static/media/569ce4b8f30dc480-s.p.woff2"
    type_name1 = "font"
    attrs1 = {"crossOrigin" => "", "type" => "font/woff2"}

    assert_instance_of Njsparser::Parser::Types::HintPreload,
                       Njsparser::Parser::Types.resolve_type(
                         value: [href1, type_name1, attrs1],
                         value_class: "HL",
                         index: 1
                       )

    assert_instance_of Njsparser::Parser::Types::Module,
                       Njsparser::Parser::Types.resolve_type(
                         value: [30777, ["71523", "static/chunks/test.js"], "default"],
                         value_class: "I",
                         index: 1
                       )

    assert_instance_of Njsparser::Parser::Types::Text,
                       Njsparser::Parser::Types.resolve_type(
                         value: "hello world",
                         value_class: "T",
                         index: 1
                       )

    assert_instance_of Njsparser::Parser::Types::Data,
                       Njsparser::Parser::Types.resolve_type(
                         value: ["$", "$L1", nil, nil],
                         value_class: nil,
                         index: 1
                       )

    assert_instance_of Njsparser::Parser::Types::EmptyData,
                       Njsparser::Parser::Types.resolve_type(
                         value: nil,
                         value_class: nil,
                         index: 1
                       )

    assert_instance_of Njsparser::Parser::Types::SpecialData,
                       Njsparser::Parser::Types.resolve_type(
                         value: "$Sreact.suspense",
                         value_class: nil,
                         index: 1
                       )

    assert_instance_of Njsparser::Parser::Types::URLQuery,
                       Njsparser::Parser::Types.resolve_type(
                         value: ["key", "val", "d"],
                         value_class: nil,
                         index: 1
                       )

    assert_instance_of Njsparser::Parser::Types::HTMLElement,
                       Njsparser::Parser::Types.resolve_type(
                         value: ["$", "div", nil, {}],
                         value_class: nil,
                         index: 1
                       )

    assert_instance_of Njsparser::Parser::Types::RSCPayload,
                       Njsparser::Parser::Types.resolve_type(
                         value: {"b" => "build_id"},
                         value_class: nil,
                         index: 0
                       )

    error_obj = Njsparser::Parser::Types.resolve_type(
      value: {"digest" => "NEXT_NOT_FOUND"},
      value_class: "E",
      index: 1
    )
    assert_instance_of Njsparser::Parser::Types::Error, error_obj

    # Test serialization round-trip
    ready_serialized = error_obj.to_h
    assert_instance_of Njsparser::Parser::Types::Error,
                       Njsparser::Parser::Types.resolve_type(**ready_serialized.transform_keys(&:to_sym))

    assert_raises(KeyError) do
      Njsparser::Parser::Types.resolve_type(
        value: "val",
        value_class: nil,
        index: nil,
        cls: "WONTEXISTSTS"
      )
    end
  end
end
