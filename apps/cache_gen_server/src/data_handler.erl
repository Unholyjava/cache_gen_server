%%%-------------------------------------------------------------------
%%% @author home
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. лют 2021 20:54
%%%-------------------------------------------------------------------
-module(data_handler).
-author("home").

%% API
-export([init/2]).

init(Req0, Opts) ->
  Method = cowboy_req:method(Req0),
  HasBody = cowboy_req:has_body(Req0),
  io:format("Method = ~p~n", [Method]),
  io:format("HasBody = ~p~n", [HasBody]),
  Req = response_database(Method, HasBody, Req0),
  io:format("Req0 = ~p~n", [Req0]),
  {ok, Req, Opts}.

response_database(<<"POST">>, true, Req0) ->
  {ok, PostVals, Req} = cowboy_req:read_body(Req0),
  PostVals_map = jsx:decode(PostVals, []),
  Response_DB =
    case
      maps:get(<<"action">>, PostVals_map) of
      <<"insert">> ->
        Key = maps:get(<<"key">>, PostVals_map),
        Value = maps:get(<<"value">>, PostVals_map),
        T_Life = maps:get(<<"t_life">>, PostVals_map),
        #{status => cache_gen_server:insert({Key, Value, T_Life})};

      <<"lookup">> ->
        Key = maps:get(<<"key">>, PostVals_map),
        #{value => cache_gen_server:show_items(Key)};

      <<"lookup_by_date">> ->
        Date_from_String = binary_to_list(maps:get(<<"date_from">>, PostVals_map)),
        Date_to_String = binary_to_list(maps:get(<<"date_to">>, PostVals_map)),
        Date_from = data_convert_to_localtime(Date_from_String),
        Date_to = data_convert_to_localtime(Date_to_String),
        #{value => [cache_gen_server:show_items_by_date(Date_from, Date_to)]};

      <<"delete_item">> ->
        Key = maps:get(<<"key">>, PostVals_map),
        #{status => cache_gen_server:delete_item(Key)};

      <<"delete_per_time">> ->
        #{status => cache_gen_server:delete_per_time()};

      <<"delete_periodic">> ->
        Key = binary_to_existing_atom(maps:get(<<"key">>, PostVals_map), latin1),
        Value = maps:get(<<"value">>, PostVals_map),
        cache_gen_server:delete_periodic({Key, Value}),
        #{delete_periodic => Value};
%%        #{status => cache_gen_server:delete_periodic({Key, Value})};

      <<"stop">> ->
        #{status => cache_gen_server:stop()};

      <<_Another>> ->
        #{status => indefinite_command}
    end,

  resp_http(Response_DB, Req);
response_database(<<"POST">>, false, Req) ->
  cowboy_req:reply(400, [], <<"Missing body.">>, Req);
response_database(_, _, Req) ->
  %% Method not allowed.
  cowboy_req:reply(405, Req).

resp_http(undefined, Req) ->
  cowboy_req:reply(400, [], <<"Missing response for database.">>, Req);
resp_http(Response_DB, Req) ->
  cowboy_req:reply(200, #{
    <<"content-type">> => <<"text/plain; charset=utf-8">>
  }, jsx:encode(Response_DB), Req).

data_convert_to_localtime(Data_string) ->
  [Year,Month,Day,Hour,Min,Sec] = string:tokens(Data_string, " /:"),
  {{list_to_integer(Year),list_to_integer(Month),list_to_integer(Day)},
    {list_to_integer(Hour),list_to_integer(Min),list_to_integer(Sec)}}.
