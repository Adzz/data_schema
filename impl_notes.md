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
