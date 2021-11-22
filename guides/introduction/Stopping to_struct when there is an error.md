# Stopping to_struct when there is an error

When we create a struct from a schema `DataSchema.to_struct/2` a casting function can return an error, optionally with a message, but there are two ways we could handle this error. The first is to stop immediately and return that error. The other is to collect all of the errors from all cast functions and return all of them to the user.

Each has its place and both are possible in DataSchema. Contrast the following approaches:

TODO: finish this up. Also have to actually implement the collect errors functionality first which is a climb.
