cache_gen_server
=====

An OTP application, creating ets database. 

External functions:

insert(Item) -> insert Item into database;

delete_item(Key) -> delete Item from database by Key.

delete_per_time() -> delete Item from database by determined time.

delete_periodic({drop_interval, Drop_Interval}) ->
  start automatic deleting Item from database by drop interval.

show_items(Key) -> get Item by Key.

show_items_by_date(Date_from, Date_to) ->
  get Items between born characters "Date_from" and "Date_to".

stop() -> stop application command.

Build
-----

    $ rebar3 compile
