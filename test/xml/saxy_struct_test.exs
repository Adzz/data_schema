defmodule DataSchema.XML.SaxyStructTest do
  use ExUnit.Case, async: true

  describe "handle_event :field / :text " do
    test "when :text has an error we halt" do
      schema = %{"A" => {%{}, %{:text => {:a, :field, fn _ -> :error end, []}}}}
      xml = "<A attr=\"1\">text</A>"

      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) ==
               {:error, %DataSchema.Errors{errors: [a: "There was an error!"]}}
    end

    test "when text is nil but shouldn't be we error" do
      schema = %{"A" => {%{}, %{:text => {:a, :field, fn _ -> {:ok, nil} end, []}}}}
      xml = "<A attr=\"1\">text</A>"

      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) ==
               {:error,
                %DataSchema.Errors{
                  errors: [a: "Field was marked as not null but was found to be null."]
                }}
    end

    test "when we error with a message from cast we return that" do
      schema = %{
        "A" => {%{}, %{:text => {:a, :field, fn _ -> {:error, "hey watcha doing"} end, []}}}
      }

      xml = "<A attr=\"1\">text</A>"

      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) ==
               {:error,
                %DataSchema.Errors{
                  errors: [a: "hey watcha doing"]
                }}
    end

    test "we raise if the casting function doesn't return an okay / error tuple" do
      schema = %{"A" => {%{}, %{:text => {:a, :field, fn _ -> "hey watcha doing" end, []}}}}
      xml = "<A attr=\"1\">text</A>"

      message =
        "Casting error for field a, cast function should return one of the following:\n\n  {:ok, any()} | :error | {:error, any()}\n\nCast function returned \"hey watcha doing\"\n"

      assert_raise(DataSchema.InvalidCastFunction, message, fn ->
        DataSchema.XML.SaxyStruct.parse_string(xml, schema)
      end)
    end

    test "we cast the value if it returns okay" do
      schema = %{
        "A" => {%{}, %{:text => {:a, :field, fn s -> {:ok, String.to_integer(s)} end, []}}}
      }

      xml = "<A attr=\"1\">250</A>"
      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) == {:ok, %{a: 250}}
    end
  end

  describe "handle event :field / attrs" do
    test "when has an error we halt" do
      schema = %{"A" => {%{}, %{{:attr, "attr"} => {:a, :field, fn _ -> :error end, []}}}}
      xml = "<A attr=\"1\">text</A>"

      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) ==
               {:error, %DataSchema.Errors{errors: [a: "There was an error!"]}}
    end

    test "when text is nil but shouldn't be we error" do
      schema = %{"A" => {%{}, %{{:attr, "attr"} => {:a, :field, fn _ -> {:ok, nil} end, []}}}}
      xml = "<A attr=\"1\">text</A>"

      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) ==
               {:error,
                %DataSchema.Errors{
                  errors: [a: "Field was marked as not null but was found to be null."]
                }}
    end

    test "when we error with a message from cast we return that" do
      schema = %{
        "A" =>
          {%{}, %{{:attr, "attr"} => {:a, :field, fn _ -> {:error, "hey watcha doing"} end, []}}}
      }

      xml = "<A attr=\"1\">text</A>"

      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) ==
               {:error,
                %DataSchema.Errors{
                  errors: [a: "hey watcha doing"]
                }}
    end

    test "we raise if the casting function doesn't return an okay / error tuple" do
      schema = %{
        "A" => {%{}, %{{:attr, "attr"} => {:a, :field, fn _ -> "hey watcha doing" end, []}}}
      }

      xml = "<A attr=\"1\">text</A>"

      message =
        "Casting error for field a, cast function should return one of the following:\n\n  {:ok, any()} | :error | {:error, any()}\n\nCast function returned \"hey watcha doing\"\n"

      assert_raise(DataSchema.InvalidCastFunction, message, fn ->
        DataSchema.XML.SaxyStruct.parse_string(xml, schema)
      end)
    end

    test "we cast the value if it returns okay" do
      schema = %{
        "A" =>
          {%{}, %{{:attr, "attr"} => {:a, :field, fn s -> {:ok, String.to_integer(s)} end, []}}}
      }

      xml = "<A attr=\"1\">250</A>"

      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) == {:ok, %{a: 1}}
    end
  end

  describe ":has_one " do
    test "we can create a nested struct" do
      b_schema = %{{:attr, "attr"} => {:b, :field, fn s -> {:ok, String.to_integer(s)} end, []}}

      schema = %{
        "A" =>
          {%{},
           %{
             "B" => {:b, :has_one, {%{}, b_schema}, []}
           }}
      }

      xml = "<A attr=\"1\"><B attr=\"2\">250</B></A>"
      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) == {:ok, %{b: %{b: 2}}}
    end

    test "text" do
      b_schema = %{:text => {:b, :field, fn s -> {:ok, String.to_integer(s)} end, []}}

      schema = %{
        "A" =>
          {%{},
           %{
             "B" => {:b, :has_one, {%{}, b_schema}, []}
           }}
      }

      xml = "<A attr=\"1\"><B attr=\"2\">250</B></A>"
      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) == {:ok, %{b: %{b: 250}}}
    end

    test "attr when there are siblings" do
      b_schema = %{{:attr, "attr"} => {:b, :field, fn s -> {:ok, String.to_integer(s)} end, []}}

      schema = %{
        "A" =>
          {%{},
           %{
             "B" => {:a, :has_one, {%{}, b_schema}, []},
             "C" => %{:text => {:c, :field, fn s -> {:ok, String.to_integer(s)} end, []}}
           }}
      }

      xml = "<A attr=\"1\"><B attr=\"2\">250</B><C>1234</C></A>"
      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) == {:ok, %{a: %{b: 2}, c: 1234}}
    end

    test "text when there are siblings" do
      b_schema = %{
        {:attr, "attr"} => {:b, :field, fn s -> {:ok, String.to_integer(s)} end, []},
        :text => {:b_text, :field, fn s -> {:ok, String.to_integer(s)} end, []}
      }

      schema = %{
        "A" =>
          {%{},
           %{
             "B" => {:a, :has_one, {%{}, b_schema}, []},
             "C" => %{:text => {:c, :field, fn s -> {:ok, String.to_integer(s)} end, []}}
           }}
      }

      xml = "<A attr=\"1\"><B attr=\"2\">250</B><C>1234</C></A>"

      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) ==
               {:ok, %{a: %{b: 2, b_text: 250}, c: 1234}}
    end

    test "nested has_one ( has_one has_one)" do
      d_schema = %{
        :text => {:d_text, :field, fn s -> {:ok, String.to_integer(s)} end, []}
      }

      b_schema = %{
        :text => {:b_text, :field, fn s -> {:ok, String.trim(s)} end, []},
        {:attr, "attr"} => {:b, :field, fn s -> {:ok, String.to_integer(s)} end, []},
        "D" => {:d, :has_one, {%{}, d_schema}, []}
      }

      schema = %{
        "A" =>
          {%{},
           %{
             "B" => {:a, :has_one, {%{}, b_schema}, []},
             "C" => %{:text => {:c, :field, fn s -> {:ok, String.to_integer(s)} end, []}}
           }}
      }

      xml = """
      <A attr=\"1\">
        <B attr=\"2\">
          <D>100</D>
            250
        </B>
        <C>1234</C>
      </A>
      """

      assert DataSchema.XML.SaxyStruct.parse_string(xml, schema) ==
               {:ok, %{a: %{b: 2, d: %{d_text: 100}, b_text: "250"}, c: 1234}}
    end
  end

  describe "rest " do
    # test "creating a DOM with one root node works" do
    #   # We could simplify by always having options when we create these schemas. As
    #   # these will likely be derived from the usual data schemas.
    #   schema = %{
    #     "A" => %{
    #       :text => {:a, DataSchema.String, []},
    #       {:attr, "attr"} => {:b, DataSchema.String, []}
    #     }
    #   }

    #   xml = "<A attr=\"1\">text</A>"
    #   assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #   assert form == {"A", [{"attr", "1"}], ["text"]}
    # end

    #   test "when there is lots more XML than things we are querying for..." do
    #     schema = %{
    #       "A" => %{
    #         {:attr, "attr"} => true
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       text
    #       <B />
    #       <B />
    #       <B />
    #       <B />
    #       <B />
    #       <B />
    #       <B />
    #       <B />
    #       <B />
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [{"attr", "1"}], []}
    #   end

    #   test "we can ignore text of an element if it's not in the schema" do
    #     schema = %{
    #       "A" => %{
    #         {:attr, "attr"} => true
    #       }
    #     }

    #     xml = "<A attr=\"1\">text</A>"
    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [{"attr", "1"}], []}
    #   end

    #   test "we skip xml nodes that are not in the schema" do
    #     schema = %{
    #       "A" => %{
    #         :text => true,
    #         {:attr, "attr"} => true
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B />
    #       text
    #       <C>
    #         this is C
    #       </C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [{"attr", "1"}], ["\n  ", "\n  text\n  ", "\n"]}
    #   end

    #   test "duplicate node names are not a problem when skipping" do
    #     schema = %{
    #       "A" => %{
    #         :text => true,
    #         {:attr, "attr"} => true
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B>
    #         <C>
    #         <B />
    #         </C>
    #       </B>
    #       text
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [{"attr", "1"}], ["\n  ", "\n  text\n"]}
    #   end

    #   test "we only keep the attrs mentioned in the schema" do
    #     schema = %{
    #       "A" => %{
    #         :text => true,
    #         {:attr, "attr"} => true
    #       }
    #     }

    #     xml = "<A attr=\"1\" ignored=\"not here\">text</A>"
    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [{"attr", "1"}], ["text"]}
    #   end

    #   test "when we skip everything we return an error" do
    #     schema = %{
    #       "C" => %{
    #         :text => true,
    #         {:attr, "attr"} => true
    #       }
    #     }

    #     xml = "<A attr=\"1\">text</A>"
    #     assert {:error, :not_found} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #   end

    #   # Doing this is actually great because it means when we query for the fields
    #   # we'll be able to handle the nodes not being there at that level.
    #   test "when children attrs are not there we still include the nodes to the children" do
    #     schema = %{
    #       "A" => %{
    #         "B" => %{"D" => %{{:attr, "bAttr"} => true}},
    #         "C" => %{"E" => %{{:attr, "cAttr"} => true}}
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B bAttr=\"77\">b text</B>
    #       text
    #       <C cAttr=\"88\">
    #         this is C
    #       </C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [], [{"B", [], []}, {"C", [], []}]}
    #   end
    # end

    # describe "handle_event - XML siblings" do
    #   test "we can handle siblings in our schema" do
    #     schema = %{
    #       "A" => %{
    #         "B" => %{
    #           {:attr, "bAttr"} => true
    #         },
    #         "C" => %{:text => true},
    #         :text => true,
    #         {:attr, "attr"} => true
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B bAttr=\"77\"></B>
    #       text
    #       <C>
    #         this is C
    #       </C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {"A", [{"attr", "1"}],
    #               [
    #                 "\n  ",
    #                 {"B", [{"bAttr", "77"}], []},
    #                 "\n  text\n  ",
    #                 {"C", [], ["\n    this is C\n  "]},
    #                 "\n"
    #               ]}
    #   end

    #   test "sibling's :text" do
    #     schema = %{
    #       "A" => %{
    #         "B" => %{:text => true},
    #         "C" => %{:text => true}
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B bAttr=\"77\">b text</B>
    #       text
    #       <C>
    #         this is C
    #       </C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [], [{"B", [], ["b text"]}, {"C", [], ["\n    this is C\n  "]}]}
    #   end

    #   test "sibling's attr (ignoring some)" do
    #     schema = %{
    #       "A" => %{
    #         "B" => %{{:attr, "bAttr"} => true},
    #         "C" => %{{:attr, "cAttr"} => true}
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B bAttr=\"77\">b text</B>
    #       text
    #       <C cAttr=\"88\">
    #         this is C
    #       </C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [], [{"B", [{"bAttr", "77"}], []}, {"C", [{"cAttr", "88"}], []}]}
    #   end

    #   test "sibling's children" do
    #     schema = %{
    #       "A" => %{
    #         "B" => %{"D" => %{{:attr, "dAttr"} => true}},
    #         "C" => %{"E" => %{{:attr, "eAttr"} => true}}
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B><D dAttr=\"77\" /></B>
    #       text
    #       <C><E eAttr=\"88\"></E></C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {
    #                "A",
    #                [],
    #                [
    #                  {"B", [], [{"D", [{"dAttr", "77"}], []}]},
    #                  {"C", [], [{"E", [{"eAttr", "88"}], []}]}
    #                ]
    #              }
    #   end

    #   test "grandchild siblings" do
    #     schema = %{
    #       "A" => %{
    #         "B" => %{
    #           "D" => %{
    #             "G" => %{:text => true},
    #             {:attr, "dAttr"} => true
    #           }
    #         },
    #         "C" => %{
    #           "E" => %{
    #             "F" => %{:text => true},
    #             {:attr, "eAttr"} => true
    #           }
    #         }
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B><D dAttr=\"77\"><G>g wizz</G></D></B>
    #       text
    #       <C><E eAttr=\"88\"><F>f-un</F></E></C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {"A", [],
    #               [
    #                 {"B", [], [{"D", [{"dAttr", "77"}], [{"G", [], ["g wizz"]}]}]},
    #                 {"C", [], [{"E", [{"eAttr", "88"}], [{"F", [], ["f-un"]}]}]}
    #               ]}
    #   end
    # end

    # describe "handle_event - XML children" do
    #   test "we can ignore text but include children" do
    #     schema = %{
    #       "A" => %{
    #         "B" => %{
    #           "D" => %{
    #             "G" => %{:text => true},
    #             {:attr, "dAttr"} => true
    #           }
    #         },
    #         "C" => %{
    #           "E" => %{
    #             "F" => %{:text => true},
    #             {:attr, "eAttr"} => true
    #           }
    #         }
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B>
    #         b start text
    #         <D dAttr=\"77\">
    #           d start
    #           <G>g wizz</G>
    #           d end
    #         </D>
    #         b end text
    #       </B>
    #       text
    #       <C>
    #         c start
    #         <E eAttr=\"88\">
    #           e start
    #           <F>f-un</F>
    #           e end
    #         </E>
    #         c end
    #       </C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {"A", [],
    #               [
    #                 {"B", [], [{"D", [{"dAttr", "77"}], [{"G", [], ["g wizz"]}]}]},
    #                 {"C", [], [{"E", [{"eAttr", "88"}], [{"F", [], ["f-un"]}]}]}
    #               ]}
    #   end

    #   test "children's text" do
    #     schema = %{"A" => %{"B" => %{:text => true}}}

    #     xml = """
    #     <A attr=\"1\">
    #       <B>
    #         b start
    #         <D dAttr=\"77\">
    #           <G>g wizz</G>
    #         </D>
    #         b end
    #       </B>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [], [{"B", [], ["\n    b start\n    ", "\n    b end\n  "]}]}
    #   end

    #   test "children's attr" do
    #     schema = %{"A" => %{"B" => %{{:attr, "attr"} => true}}}

    #     xml = """
    #     <A attr=\"1\">
    #       <B attr=\"b attr best\">
    #         b start
    #         <D dAttr=\"77\">
    #           <G>g wizz</G>
    #         </D>
    #         b end
    #       </B>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [], [{"B", [{"attr", "b attr best"}], []}]}
    #   end
    # end

    # describe "fields in the schema that aren't in the XML" do
    #   test "when there are siblings that aren't in the XML it still works" do
    #     schema = %{
    #       "A" => %{
    #         "B" => %{{:attr, "attr"} => true},
    #         "C" => %{{:attr, "attr"} => true}
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B attr=\"b attr best\">
    #         b start
    #         <D dAttr=\"77\">
    #           <G>g wizz</G>
    #         </D>
    #         b end
    #       </B>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [], [{"B", [{"attr", "b attr best"}], []}]}
    #   end

    #   test "when there are children that don't feature" do
    #     schema = %{
    #       "A" => %{
    #         "B" => %{"Z" => %{:text => true}, {:attr, "attr"} => true},
    #         "C" => %{"Z" => %{:text => true}, {:attr, "attr"} => true}
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <B attr=\"b attr best\">
    #         b start
    #         <D dAttr=\"77\">
    #           <G>g wizz</G>
    #         </D>
    #         b end
    #       </B>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)
    #     assert form == {"A", [], [{"B", [{"attr", "b attr best"}], []}]}
    #   end
    # end

    # describe "lists of things... supporting {:all in the schema" do
    #   test "when the xml contains a list of stuff in our schema we keep them all" do
    #     schema = %{
    #       "A" => %{
    #         "C" => %{},
    #         "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
    #       }
    #     }

    #     xml = """
    #     <A attr=\"1\">
    #       <G>g wizz</G>
    #       <G>g wizz 2</G>
    #       <G>g wizz 3</G>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {"A", [],
    #               [{"G", [], ["g wizz"]}, {"G", [], ["g wizz 2"]}, {"G", [], ["g wizz 3"]}]}
    #   end

    #   test "getting all attrs" do
    #     schema = %{
    #       "A" => %{
    #         "C" => %{},
    #         "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
    #       }
    #     }

    #     xml = """
    #     <A>
    #       <G attr="g wizz 1" />
    #       <G attr="g wizz 2" />
    #       <B>this is b</B>
    #       <G attr="g wizz 3" />
    #       <G attr="g wizz 4" />
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {"A", [],
    #               [
    #                 {"G", [{"attr", "g wizz 1"}], []},
    #                 {"G", [{"attr", "g wizz 2"}], []},
    #                 {"G", [{"attr", "g wizz 3"}], []},
    #                 {"G", [{"attr", "g wizz 4"}], []}
    #               ]}
    #   end

    #   test "querying for all children when there are elements in between." do
    #     schema = %{
    #       "A" => %{
    #         "C" => %{},
    #         "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
    #       }
    #     }

    #     xml = """
    #     <A>
    #       <G>g wizz 1</G>
    #       <G>g wizz 2</G>
    #       <B>this is b</B>
    #       <G>g wizz 3</G>
    #       <G>g wizz 4</G>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {"A", [],
    #               [
    #                 {"G", [], ["g wizz 1"]},
    #                 {"G", [], ["g wizz 2"]},
    #                 {"G", [], ["g wizz 3"]},
    #                 {"G", [], ["g wizz 4"]}
    #               ]}
    #   end

    #   test "text when there are children in the text that we dont want" do
    #     schema = %{
    #       "A" => %{
    #         "C" => %{},
    #         "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
    #       }
    #     }

    #     xml = """
    #     <A>
    #       <G><D>some txtz</D>g wizz 1</G>
    #       <G>g wizz 2</G>
    #       <B>this is b</B>
    #       <G>g wizz 3</G>
    #       <G>g wizz 4</G>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {"A", [],
    #               [
    #                 {"G", [], ["g wizz 1"]},
    #                 {"G", [], ["g wizz 2"]},
    #                 {"G", [], ["g wizz 3"]},
    #                 {"G", [], ["g wizz 4"]}
    #               ]}
    #   end

    #   test "when there is text on the parent level" do
    #     schema = %{
    #       "A" => %{
    #         :text => true,
    #         "C" => %{},
    #         "G" => {:all, %{:text => true, {:attr, "attr"} => true}}
    #       }
    #     }

    #     xml = """
    #     <A>
    #       a before
    #       <G><D>some txtz</D>g wizz 1</G>
    #       <G>g wizz 2</G>
    #       a during
    #       <B>this is b</B>
    #       <G>g wizz 3</G>
    #       <G>g wizz 4</G>
    #       a text when we want a text too after
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {
    #                "A",
    #                [],
    #                [
    #                  "\n  a before\n  ",
    #                  {"G", [], ["g wizz 1"]},
    #                  "\n  ",
    #                  {"G", [], ["g wizz 2"]},
    #                  "\n  a during\n  ",
    #                  "\n  ",
    #                  {"G", [], ["g wizz 3"]},
    #                  "\n  ",
    #                  {"G", [], ["g wizz 4"]},
    #                  "\n  a text when we want a text too after\n"
    #                ]
    #              }
    #   end

    #   test "all grandchildren text" do
    #     schema = %{
    #       "A" => %{
    #         "C" =>
    #           {:all,
    #            %{
    #              "G" => %{:text => true, {:attr, "attr"} => true}
    #            }}
    #       }
    #     }

    #     xml = """
    #     <A>
    #       <C><G>g wizz 1</G></C>
    #       <C><G>g wizz 2</G></C>
    #       <C><B>this is b</B></C>
    #       <C><G>g wizz 3</G></C>
    #       <C><G>g wizz 4</G></C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {"A", [],
    #               [
    #                 {"C", [], [{"G", [], ["g wizz 1"]}]},
    #                 {"C", [], [{"G", [], ["g wizz 2"]}]},
    #                 {"C", [], []},
    #                 {"C", [], [{"G", [], ["g wizz 3"]}]},
    #                 {"C", [], [{"G", [], ["g wizz 4"]}]}
    #               ]}
    #   end

    #   test "all grandchild attrs" do
    #     schema = %{
    #       "A" => %{
    #         "C" =>
    #           {:all,
    #            %{
    #              "G" => %{:text => true, {:attr, "attr"} => true}
    #            }}
    #       }
    #     }

    #     xml = """
    #     <A>
    #       <C><G attr="g wizz 1"></G></C>
    #       <C><G attr="g wizz 2"></G></C>
    #       <C><B>this is b</B></C>
    #       <C><G attr="g wizz 3"></G></C>
    #       <C><G attr="g wizz 4"></G></C>
    #     </A>
    #     """

    #     assert {:ok, form} = DataSchema.XML.SaxyStruct.parse_string(xml, schema)

    #     assert form ==
    #              {
    #                "A",
    #                [],
    #                [
    #                  {"C", [], [{"G", [{"attr", "g wizz 1"}], []}]},
    #                  {"C", [], [{"G", [{"attr", "g wizz 2"}], []}]},
    #                  {"C", [], []},
    #                  {"C", [], [{"G", [{"attr", "g wizz 3"}], []}]},
    #                  {"C", [], [{"G", [{"attr", "g wizz 4"}], []}]}
    #                ]
    #              }
    #   end
  end
end
