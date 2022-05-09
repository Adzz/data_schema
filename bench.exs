large_xml = File.read!(Path.expand("really_large_xml_fixture.xml"))
{:ok, x} = DataSchema.Saxy.StructHandler.parse_string(large_xml);

Benchee.run(
  %{
    "StructHanlder" => fn ->
      DataSchema.to_struct(x, AirShop)
    end
  },
  memory_time: 1,
  reduction_time: 1
)
