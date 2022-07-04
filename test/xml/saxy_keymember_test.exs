defmodule DataSchema.XML.SaxyKeymemberTest do
  use ExUnit.Case, async: true

  describe "handle_event - basics with ignoring elements" do
    test "creating a DOM with one root node works" do
      schema = %{
        "A" => %{
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = "<A attr=\"1\">text</A>"
      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], ["text"]}
    end

    test "when there is lots more XML than things we are querying for..." do
      schema = %{
        "A" => %{
          {:attr, "attr"} => true
        }
      }

      xml = """
      <A attr=\"1\">
        text
        <B />
        <B />
        <B />
        <B />
        <B />
        <B />
        <B />
        <B />
        <B />
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], []}
    end

    test "we can ignore text of an element if it's not in the schema" do
      schema = %{
        "A" => %{
          {:attr, "attr"} => true
        }
      }

      xml = "<A attr=\"1\">text</A>"
      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [{"attr", "1"}], []}
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

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
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

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
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
      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
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
      assert {:error, :not_found} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
    end

    # Doing this is actually great because it means when we query for the fields
    # we'll be able to handle the nodes not being there at that level.
    test "when children attrs are not there we still include the nodes to the children" do
      schema = %{
        "A" => %{
          "B" => %{"D" => %{{:attr, "bAttr"} => true}},
          "C" => %{"E" => %{{:attr, "cAttr"} => true}}
        }
      }

      xml = """
      <A attr=\"1\">
        <B bAttr=\"77\">b text</B>
        text
        <C cAttr=\"88\">
          this is C
        </C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [], [{"B", [], []}, {"C", [], []}]}
    end
  end

  describe "handle_event - XML siblings" do
    test "we can handle siblings in our schema" do
      schema = %{
        "A" => %{
          "B" => %{
            {:attr, "bAttr"} => true
          },
          "C" => %{:text => true},
          :text => true,
          {:attr, "attr"} => true
        }
      }

      xml = """
      <A attr=\"1\">
        <B bAttr=\"77\"></B>
        text
        <C>
          this is C
        </C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {"A", [{"attr", "1"}],
                [
                  "\n  ",
                  {"B", [{"bAttr", "77"}], []},
                  "\n  text\n  ",
                  {"C", [], ["\n    this is C\n  "]},
                  "\n"
                ]}
    end

    test "sibling's :text" do
      schema = %{
        "A" => %{
          "B" => %{:text => true},
          "C" => %{:text => true}
        }
      }

      xml = """
      <A attr=\"1\">
        <B bAttr=\"77\">b text</B>
        text
        <C>
          this is C
        </C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [], [{"B", [], ["b text"]}, {"C", [], ["\n    this is C\n  "]}]}
    end

    test "sibling's attr (ignoring some)" do
      schema = %{
        "A" => %{
          "B" => %{{:attr, "bAttr"} => true},
          "C" => %{{:attr, "cAttr"} => true}
        }
      }

      xml = """
      <A attr=\"1\">
        <B bAttr=\"77\">b text</B>
        text
        <C cAttr=\"88\">
          this is C
        </C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [], [{"B", [{"bAttr", "77"}], []}, {"C", [{"cAttr", "88"}], []}]}
    end

    test "sibling's children" do
      schema = %{
        "A" => %{
          "B" => %{"D" => %{{:attr, "dAttr"} => true}},
          "C" => %{"E" => %{{:attr, "eAttr"} => true}}
        }
      }

      xml = """
      <A attr=\"1\">
        <B><D dAttr=\"77\" /></B>
        text
        <C><E eAttr=\"88\"></E></C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {
                 "A",
                 [],
                 [
                   {"B", [], [{"D", [{"dAttr", "77"}], []}]},
                   {"C", [], [{"E", [{"eAttr", "88"}], []}]}
                 ]
               }
    end

    test "grandchild siblings" do
      schema = %{
        "A" => %{
          "B" => %{
            "D" => %{
              "G" => %{:text => true},
              {:attr, "dAttr"} => true
            }
          },
          "C" => %{
            "E" => %{
              "F" => %{:text => true},
              {:attr, "eAttr"} => true
            }
          }
        }
      }

      xml = """
      <A attr=\"1\">
        <B><D dAttr=\"77\"><G>g wizz</G></D></B>
        text
        <C><E eAttr=\"88\"><F>f-un</F></E></C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {"A", [],
                [
                  {"B", [], [{"D", [{"dAttr", "77"}], [{"G", [], ["g wizz"]}]}]},
                  {"C", [], [{"E", [{"eAttr", "88"}], [{"F", [], ["f-un"]}]}]}
                ]}
    end
  end

  describe "handle_event - XML children" do
    test "we can ignore text but include children" do
      schema = %{
        "A" => %{
          "B" => %{
            "D" => %{
              "G" => %{:text => true},
              {:attr, "dAttr"} => true
            }
          },
          "C" => %{
            "E" => %{
              "F" => %{:text => true},
              {:attr, "eAttr"} => true
            }
          }
        }
      }

      xml = """
      <A attr=\"1\">
        <B>
          b start text
          <D dAttr=\"77\">
            d start
            <G>g wizz</G>
            d end
          </D>
          b end text
        </B>
        text
        <C>
          c start
          <E eAttr=\"88\">
            e start
            <F>f-un</F>
            e end
          </E>
          c end
        </C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {"A", [],
                [
                  {"B", [], [{"D", [{"dAttr", "77"}], [{"G", [], ["g wizz"]}]}]},
                  {"C", [], [{"E", [{"eAttr", "88"}], [{"F", [], ["f-un"]}]}]}
                ]}
    end

    test "children's text" do
      schema = %{"A" => %{"B" => %{:text => true}}}

      xml = """
      <A attr=\"1\">
        <B>
          b start
          <D dAttr=\"77\">
            <G>g wizz</G>
          </D>
          b end
        </B>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [], [{"B", [], ["\n    b start\n    ", "\n    b end\n  "]}]}
    end

    test "children's attr" do
      schema = %{"A" => %{"B" => %{{:attr, "attr"} => true}}}

      xml = """
      <A attr=\"1\">
        <B attr=\"b attr best\">
          b start
          <D dAttr=\"77\">
            <G>g wizz</G>
          </D>
          b end
        </B>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [], [{"B", [{"attr", "b attr best"}], []}]}
    end
  end

  describe "fields in the schema that aren't in the XML" do
    test "when there are siblings that aren't in the XML it still works" do
      schema = %{
        "A" => %{
          "B" => %{{:attr, "attr"} => true},
          "C" => %{{:attr, "attr"} => true}
        }
      }

      xml = """
      <A attr=\"1\">
        <B attr=\"b attr best\">
          b start
          <D dAttr=\"77\">
            <G>g wizz</G>
          </D>
          b end
        </B>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [], [{"B", [{"attr", "b attr best"}], []}]}
    end

    test "when there are children that don't feature" do
      schema = %{
        "A" => %{
          "B" => %{"Z" => %{:text => true}, {:attr, "attr"} => true},
          "C" => %{"Z" => %{:text => true}, {:attr, "attr"} => true}
        }
      }

      xml = """
      <A attr=\"1\">
        <B attr=\"b attr best\">
          b start
          <D dAttr=\"77\">
            <G>g wizz</G>
          </D>
          b end
        </B>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)
      assert form == {"A", [], [{"B", [{"attr", "b attr best"}], []}]}
    end
  end

  describe "lists of things... supporting {:all in the schema" do
    test "when the xml contains a list of stuff in our schema we keep them all" do
      schema = %{
        "A" => %{
          "C" => %{},
          "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
        }
      }

      xml = """
      <A attr=\"1\">
        <G>g wizz</G>
        <G>g wizz 2</G>
        <G>g wizz 3</G>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {"A", [],
                [{"G", [], ["g wizz"]}, {"G", [], ["g wizz 2"]}, {"G", [], ["g wizz 3"]}]}
    end

    test "getting all attrs" do
      schema = %{
        "A" => %{
          "C" => %{},
          "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
        }
      }

      xml = """
      <A>
        <G attr="g wizz 1" />
        <G attr="g wizz 2" />
        <B>this is b</B>
        <G attr="g wizz 3" />
        <G attr="g wizz 4" />
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {"A", [],
                [
                  {"G", [{"attr", "g wizz 1"}], []},
                  {"G", [{"attr", "g wizz 2"}], []},
                  {"G", [{"attr", "g wizz 3"}], []},
                  {"G", [{"attr", "g wizz 4"}], []}
                ]}
    end

    test "querying for all children when there are elements in between." do
      schema = %{
        "A" => %{
          "C" => %{},
          "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
        }
      }

      xml = """
      <A>
        <G>g wizz 1</G>
        <G>g wizz 2</G>
        <B>this is b</B>
        <G>g wizz 3</G>
        <G>g wizz 4</G>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {"A", [],
                [
                  {"G", [], ["g wizz 1"]},
                  {"G", [], ["g wizz 2"]},
                  {"G", [], ["g wizz 3"]},
                  {"G", [], ["g wizz 4"]}
                ]}
    end

    test "text when there are children in the text that we dont want" do
      schema = %{
        "A" => %{
          "C" => %{},
          "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
        }
      }

      xml = """
      <A>
        <G><D>some txtz</D>g wizz 1</G>
        <G>g wizz 2</G>
        <B>this is b</B>
        <G>g wizz 3</G>
        <G>g wizz 4</G>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {"A", [],
                [
                  {"G", [], ["g wizz 1"]},
                  {"G", [], ["g wizz 2"]},
                  {"G", [], ["g wizz 3"]},
                  {"G", [], ["g wizz 4"]}
                ]}
    end

    test "when there is text on the parent level" do
      schema = %{
        "A" => %{
          :text => true,
          "C" => %{},
          "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
        }
      }

      xml = """
      <A>
        a before
        <G><D>some txtz</D>g wizz 1</G>
        <G>g wizz 2</G>
        a during
        <B>this is b</B>
        <G>g wizz 3</G>
        <G>g wizz 4</G>
        a text when we want a text too after
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {
                 "A",
                 [],
                 [
                   "\n  a before\n  ",
                   {"G", [], ["g wizz 1"]},
                   "\n  ",
                   {"G", [], ["g wizz 2"]},
                   "\n  a during\n  ",
                   "\n  ",
                   {"G", [], ["g wizz 3"]},
                   "\n  ",
                   {"G", [], ["g wizz 4"]},
                   "\n  a text when we want a text too after\n"
                 ]
               }
    end

    test "all grandchildren text" do
      schema = %{
        "A" => %{
          "C" =>
            {:all,
             %{
               "G" => %{:text => true, {:attr, "attr"} => true}
             }}
        }
      }

      xml = """
      <A>
        <C><G>g wizz 1</G></C>
        <C><G>g wizz 2</G></C>
        <C><B>this is b</B></C>
        <C><G>g wizz 3</G></C>
        <C><G>g wizz 4</G></C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {"A", [],
                [
                  {"C", [], [{"G", [], ["g wizz 1"]}]},
                  {"C", [], [{"G", [], ["g wizz 2"]}]},
                  {"C", [], []},
                  {"C", [], [{"G", [], ["g wizz 3"]}]},
                  {"C", [], [{"G", [], ["g wizz 4"]}]}
                ]}
    end

    test "all grandchild attrs" do
      schema = %{
        "A" => %{
          "C" =>
            {:all,
             %{
               "G" => %{:text => true, {:attr, "attr"} => true}
             }}
        }
      }

      xml = """
      <A>
        <C><G attr="g wizz 1"></G></C>
        <C><G attr="g wizz 2"></G></C>
        <C><B>this is b</B></C>
        <C><G attr="g wizz 3"></G></C>
        <C><G attr="g wizz 4"></G></C>
      </A>
      """

      assert {:ok, form} = DataSchema.XML.SaxyKeymember.parse_string(xml, schema)

      assert form ==
               {
                 "A",
                 [],
                 [
                   {"C", [], [{"G", [{"attr", "g wizz 1"}], []}]},
                   {"C", [], [{"G", [{"attr", "g wizz 2"}], []}]},
                   {"C", [], []},
                   {"C", [], [{"G", [{"attr", "g wizz 3"}], []}]},
                   {"C", [], [{"G", [{"attr", "g wizz 4"}], []}]}
                 ]
               }
    end

    test "when the path says one but there are many we error?" do
      schema = %{
        "A" => %{
          "C" => %{
            "G" => %{:text => true, {:attr, "attr"} => true}
          }
        }
      }

      xml = """
      <A>
        <C><G attr="g wizz 1"></G></C>
        <C><G attr="g wizz 2"></G></C>
        <C><B>this is b</B></C>
        <C><G attr="g wizz 3"></G></C>
        <C><G attr="g wizz 4"></G></C>
      </A>
      """

      assert DataSchema.XML.SaxyKeymember.parse_string(xml, schema) ==
               {:error, "Saw many C's expected one!"}
    end

    test "multiple results error but when the names are repeated at different levels" do
      schema = %{
        "A" => %{
          "C" => %{
            "G" => %{:text => true, {:attr, "attr"} => true}
          }
        }
      }

      xml = """
      <A>
        <C>
         <C />
          <G attr="g wizz 1"><C/></G>
        </C>
        <C><G attr="g wizz 2"></G></C>
        <C><B>this is b</B></C>
        <C><G attr="g wizz 3"></G></C>
        <C><G attr="g wizz 4"></G></C>
      </A>
      """

      assert DataSchema.XML.SaxyKeymember.parse_string(xml, schema) ==
               {:error, "Saw many C's expected one!"}
    end

    test "doesn't error when there are not multiple " do
      schema = %{
        "A" => %{
          "C" => %{
            "G" => %{:text => true, {:attr, "attr"} => true}
          }
        }
      }

      xml = """
      <A>
        <B />
        <B />
        <C>
          <G attr="g wizz 1"></G>
        </C>
        <B />
      </A>
      """

      assert DataSchema.XML.SaxyKeymember.parse_string(xml, schema) ==
               {:ok, {"A", [], [{"C", [], [{"G", [{"attr", "g wizz 1"}], []}]}]}}
    end

    test "when " do
      schema = %{
        "A" => %{
          "C" => %{
            "G" => %{:text => true, {:attr, "attr"} => true}
          }
        }
      }

      xml = """
      <A>
        <C>
          <G attr="g wizz 1"></G>
            <D />
          <G attr="g wizz 2"></G>
        </C>
      </A>
      """

      assert DataSchema.XML.SaxyKeymember.parse_string(xml, schema) ==
               {:error, "Saw many G's expected one!"}
    end

    test "repeated with a gap in between still errors" do
      schema = %{
        "A" => %{
          "C" => %{
            "G" => %{:text => true, {:attr, "attr"} => true}
          }
        }
      }

      xml = """
      <A>
        <C><G attr="g wizz 1"></G></C>
        <D />
        <C><G attr="g wizz 4"></G></C>
      </A>
      """

      assert DataSchema.XML.SaxyKeymember.parse_string(xml, schema) ==
               {:error, "Saw many C's expected one!"}
    end
  end
end