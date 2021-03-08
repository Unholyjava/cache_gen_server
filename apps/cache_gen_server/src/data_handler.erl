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
  Req = maybe_echo(Method, HasBody, Req0),
  io:format("Req0 = ~p~n", [Req0]),
  {ok, Req, Opts}.

maybe_echo(<<"POST">>, true, Req0) ->
%%  {ok, PostVals, Req} = cowboy_req:read_urlencoded_body(Req0),
  {ok, PostVals, Req} = cowboy_req:read_body(Req0),
%%  Echo = proplists:get_value(<<"echo">>, PostVals),
%%  Echo = 1,


%%  io:format("Echo = ~p~n", [Echo]),

  io:format("PostVals = ~p~n", [PostVals]),
  PostVals_map = jsx:decode(PostVals, []),
  io:format("PostVals_map = ~p~n", [PostVals_map]),
  [Key_|_] = maps:keys(PostVals_map),
  io:format("Keys = ~p~n", [Key_]),
  io:format("Value = ~p~n", [maps:get(Key_, PostVals_map)]),
  Echo =
    case
      maps:get(<<"action">>, PostVals_map) of
      <<"insert">> ->
        Key = binary_to_atom(maps:get(<<"key">>, PostVals_map), latin1),
        Value = maps:get(<<"value">>, PostVals_map),
        T_Life = maps:get(<<"t_life">>, PostVals_map),
%%        cache_gen_server:insert({Key, Value, T_Life}),
%%        #{insert => [Key, Value, T_Life]};
        #{insert => [cache_gen_server:insert({Key, Value, T_Life})]};

      <<"lookup">> ->
        Key = binary_to_atom(maps:get(<<"key">>, PostVals_map), latin1),
%%        cache_gen_server:show_items(Key),
%%        #{show => Key};
        #{show => cache_gen_server:show_items(Key)};

      <<"lookup_by_date">> ->
        Date_from = binary_to_atom(maps:get(<<"date_from">>, PostVals_map), latin1),
        Date_to = binary_to_atom(maps:get(<<"date_to">>, PostVals_map), latin1),
%%        cache_gen_server:show_items_by_date(Date_from, Date_to),
%%        #{show => [Date_from, Date_to]};
        #{show => [cache_gen_server:show_items_by_date(Date_from, Date_to)]};

      <<"delete_item">> ->
        Key = binary_to_atom(maps:get(<<"key">>, PostVals_map), latin1),
%%        cache_gen_server:delete_item(Key),
%%        #{delete => Key};
        #{delete => cache_gen_server:delete_item(Key)};

      <<"delete_per_time">> ->
        cache_gen_server:delete_per_time(),
        #{delete_per_time => ok};

      <<"delete_periodic">> ->
        Key = binary_to_atom(maps:get(<<"key">>, PostVals_map), latin1),
        Value = maps:get(<<"value">>, PostVals_map),
%%        cache_gen_server:delete_periodic({Key, Value}),
%%        #{delete_periodic => Value};
        #{delete_periodic => cache_gen_server:delete_periodic({Key, Value})};

      <<"stop">> ->
%%        cache_gen_server:stop(),
%%        #{stop_cache_server => ok};
        #{stop_cache_server => cache_gen_server:stop()};

      <<_Another>> ->
        #{indefinite_command => no_work}
    end,

  echo(Echo, Req);
maybe_echo(<<"POST">>, false, Req) ->
  cowboy_req:reply(400, [], <<"Missing body.">>, Req);
maybe_echo(_, _, Req) ->
  %% Method not allowed.
  cowboy_req:reply(405, Req).

echo(undefined, Req) ->
  cowboy_req:reply(400, [], <<"Missing echo parameter.">>, Req);
echo(Echo, Req) ->
  cowboy_req:reply(200, #{
    <<"content-type">> => <<"text/plain; charset=utf-8">>
  }, jsx:encode(Echo), Req).
