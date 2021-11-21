# Todo List

- add mad tests... For optional?, not. Aggregate fields inline and not inline. For when access returns nil for each field and for when the cast fn returns nil for all fields and cases.
- update docs
- Remove data_schema/2 and supply the accessor as a module attribute instead
- Fix the doc below to make sense.
- make an DataSchema.Error struct or similar.
- collect_errors version of to_struct using the above error struct.
- Livebook for the repo (make the guides livebooks that would mean they are easier to test too.)
- inline schema fields for has_one / has_many - Probably not doing as need a nice way to add the name of the struct when it is inline... I don't think there is one particularly. The other option is to just make a map for inline schemas but seems worse for some reason. Think it's better than supplying a struct name though.






#### Historical context on why has_one / has_many are their own fields

You might think they could be encompassed by field and list_of but there are subtle reasons why not. One day I may fully explain the reasoning properly but for now here are the ramblings as I figured it out. I will make it make more sense later.

 if we recur that means list has to be a nested schema
 if we dont then there is the confusion with nested schemas implementing
 to_struct with different options from the usual.
 basically the options for to_struct stop becoming runtime "whn you call then fn"
 options and become schema compile time options... unless you pass the options to
 all the cast fns which like... meh. Maybe.

 the alternative is that we add a list_of and a has_many / one is just for
 schemas. list_of is self explanatory and is better than just a field because it allows
 to_struct to handle the looping behaviour (ie halt or not).
 It also means you can have more generic types that work across input data types. So instead
 of all xmerl schemas having Xmerl.data types you can have them take a string and return
 a number or whatever.


 What we are learning is we want this function to be able to control the looping
 and the error behaviour. We don't want tit to be possible to accidentally mix and
 match. And we want as a simple an interface as possible.

 The other issue is we want to be able to have different access behaviour for
 different field types. So although it may seem that a has_many is just a list_of
 it's actually not because with xmerl for example you want different access behaviour
 It might seem like the flexibility is desirable and it could be - maybe you do want to collect
 all errors sometimes but not others. It is more likely that it's a footgun AND it also ends
 up baking in the decision of whether you want to collect errors or not @ compile time (as that's
 when the schema is created.). Which is not as optimal. It seems more likely that one would
 want to have the collect errors option be decided at runtime AND that it should be consistent
 for all cast fns.

 In fact if you want the collect errors behaviour then you could enable it yourself by doing
 list_of with a cast fn that calls to_struct.

 So the answer is for sure list_of and has_many, le sigh.

 The tradeoff with has_many / has_one is that implementing non_null is trickier?
 not if it's a field option though. But it does mean you can't have higher level
 stuff outside of whatever the normal cast fn is. I'm not sure if that will be
 a problem/ there is probably a reason we switched to list_of???
 I guess you can always switch to list_of / field if you want more fine grained
 control.
