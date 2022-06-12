defmodule DataSchema.XML.SaxyTest do
  use ExUnit.Case, async: true

  describe "handle_event" do
    test "creating a DOM with one root node works" do
      schema = %{
        "A" => %{
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = "<A attr=\"1\">text</A>"
      assert {:ok, form} = DataSchema.XML.Saxy.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], ["text"]}
    end

    test "we skip xml nodes that are not in the schema" do
      schema = %{
        "A" => %{
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = """
      <A attr=\"1\">
        <B />
        text
        <C>
          this is C
        </C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.Saxy.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], ["\n  ", "\n  text\n  ", "\n"]}
    end

    test "duplicate node names are not a problem when skipping" do
      schema = %{
        "A" => %{
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = """
      <A attr=\"1\">
        <B>
          <C>
          <B />
          </C>
        </B>
        text
      </A>
      """

      assert {:ok, form} = DataSchema.XML.Saxy.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], ["\n  ", "\n  text\n"]}
    end

    test "we only keep the attrs mentioned in the schema" do
      schema = %{
        "A" => %{
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = "<A attr=\"1\" ignored=\"not here\">text</A>"
      assert {:ok, form} = DataSchema.XML.Saxy.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], ["text"]}
    end

    test "when we skip everything we return an error" do
      schema = %{
        "C" => %{
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = "<A attr=\"1\">text</A>"
      assert {:error, :not_found} = DataSchema.XML.Saxy.parse_string(xml, schema)
    end
  end
end
