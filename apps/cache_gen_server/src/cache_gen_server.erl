%%%-------------------------------------------------------------------
%%% @author home
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. січ 2021 21:21
%%%-------------------------------------------------------------------
-module(cache_gen_server).
-author("gregory").
-behaviour(gen_server).

%% API
-export([start_link/0, init/1, handle_call/3,
  handle_cast/2, handle_info/2, terminate/2,
  insert/2, delete_item/2, delete_per_time/1, delete_periodic/2,
  show_items/2, stop/1, create/1, delete_obsolete/0]).
-include_lib("stdlib/include/ms_transform.hrl").

start_link() ->
  gen_server:start_link(?MODULE, [], []).

init([]) ->
  {ok, []}.

create(Pid) ->
  gen_server:call(Pid, {create}).

insert(Pid, Item) ->
  gen_server:call(Pid, {add, Item}).

delete_item(Pid, Key) ->
  gen_server:call(Pid, {remove, Key}).

delete_per_time(Pid) ->
  gen_server:call(Pid, {remove_per_time}).

delete_periodic(Pid, {drop_interval, Drop_Interval}) ->
  gen_server:cast(Pid, {remove_periodic_per_time, Drop_Interval}).

show_items(Pid, Key) ->
  gen_server:call(Pid, {read, Key}).

stop(Pid) ->
  gen_server:call(Pid, terminate).

handle_call({create}, _From, []) ->
  io:format("Create table~n"),
  ets:new(table_cache, [bag, public, named_table]),
  {reply, ok, []};

handle_call({add, {Key, Value, T_Life}}, _From, []) ->
  io:format("Adds ~p into table~n", [{Key, Value, T_Life}]),
      ets:insert(table_cache, {Key, Value, T_Life, erlang:timestamp()}),
  {reply, ok, []};

handle_call({remove, Key}, _From, []) ->
  {Reply} =
        case ets:delete(table_cache, Key) of
          true -> {ok};
          [] -> {error, not_exist}
        end,
  {reply, Reply, []};

handle_call({remove_per_time}, _From, []) ->
  delete_obsolete(),
  {reply, ok, []};

handle_call({read, Key}, _From, []) ->
  io:format("Read table, key: ~p~n", [Key]),
      Time_Now = time_now(),
      Reply = ets:select(table_cache, ets:fun2ms(fun({Key_, Value_, T_Life_, {MegaSec,Sec,_}})
        when Key_ =:= Key
          andalso Time_Now - (MegaSec * 1000000 + Sec) =< T_Life_ ->
          {ok, Value_} end)),
  {reply, Reply, []};

handle_call(terminate, _From, []) ->
  {stop, normal, ok, []}.

handle_cast({remove_periodic_per_time, Drop_Interval}, []) ->
  timer:apply_interval(Drop_Interval*1000, ?MODULE, delete_obsolete, []),
  {noreply, []}.

handle_info(Msg, []) ->
  io:format("Unexpected message ~p~n", [Msg]),
  {noreply, []}.

terminate(normal, []) ->
  [io:format("work with the server has finished~n")],
  ok.


time_now() ->
  {MegaSecNow,SecNow,_MicroSecNow} = erlang:timestamp(),
  MegaSecNow * 1000000 + SecNow.

delete_obsolete() ->
  Time_Now = time_now(),
  ets:select_delete(table_cache, ets:fun2ms(fun({_, _, T_Life, {MegaSec,Sec,_}})
    when Time_Now - (MegaSec * 1000000 + Sec) > T_Life -> true end)),
  io:format("delete overdue items~n").




