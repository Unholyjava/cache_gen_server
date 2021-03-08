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
  insert/1, delete_item/1, delete_per_time/0, delete_periodic/1,
  show_items/1, show_items_by_date/2, stop/0, delete_obsolete/0]).
-include_lib("stdlib/include/ms_transform.hrl").


start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
  gen_server:cast(?MODULE, {create}),
  {ok, []}.

insert(Item) ->
  gen_server:call(?MODULE, {add, Item}).

delete_item(Key) ->
  gen_server:call(?MODULE, {remove, Key}).

delete_per_time() ->
  gen_server:call(?MODULE, {remove_per_time}).

delete_periodic({drop_interval, Drop_Interval}) ->
  erlang:start_timer(Drop_Interval*1000, ?MODULE, drop_interval).

show_items(Key) ->
  gen_server:call(?MODULE, {read, Key}).

show_items_by_date(Date_from, Date_to) ->
  gen_server:call(?MODULE, {read_by_date, {Date_from, Date_to}}).

stop() ->
  gen_server:call(?MODULE, terminate).

handle_call({add, {Key, Value, T_Life}}, _From, State) ->
  io:format("Adds ~p into table~n", [{Key, Value, T_Life}]),
      ets:insert(table_cache, {Key, Value, T_Life, erlang:system_time(second)}),
  {reply, ok, State};

handle_call({remove, Key}, _From, State) ->
  Reply =
        case ets:lookup(table_cache, Key) of
          [] -> {error, not_exist};
          _Ani_Item -> ets:delete(table_cache, Key),
            ok
        end,
  {reply, Reply, State};

handle_call({remove_per_time}, _From, State) ->
  delete_obsolete(),
  {reply, ok, State};

handle_call({read, Key}, _From, State) ->
  io:format("Read table, key: ~p~n", [Key]),
      Time_Now = erlang:system_time(second),
      Reply = ets:select(table_cache, ets:fun2ms(fun({Key_, Value, T_Life, T_Born})
        when Key_ =:= Key
          andalso Time_Now - T_Born =< T_Life ->
          {ok, Value} end)),
  {reply, Reply, State};

handle_call({read_by_date, {Date_from, Date_to}}, _From, State) ->
  io:format("Read table by Date_from: ~p to Date_to: ~p~n", [Date_from, Date_to]),
  Date_from_convert = convert_DateTime_to_second(Date_from),
  Date_to_convert = convert_DateTime_to_second(Date_to),
  Reply = ets:select(table_cache, ets:fun2ms(fun({_Key, _Value, T_Life, T_Born})
    when T_Born >= Date_from_convert
    andalso T_Born =< Date_to_convert ->
    ok end)),
  {reply, Reply, State};

handle_call(terminate, _From, State) ->
  {stop, normal, ok, State};

handle_call(Msg, _From, State) ->
  io:format("Unexpected message in handle_call ~p~n", [Msg]),
  {reply, Msg, State}.

handle_cast({create}, State) ->
  io:format("Create table~n"),
  ets:new(table_cache, [bag, public, named_table]),
  {noreply, State};

handle_cast(Msg, State) ->
  io:format("Unexpected message in handle_cast ~p~n", [Msg]),
  {noreply, State}.

handle_info({timeout, _Ref, drop_interval}, State = #{period := Drop_Interval}) ->
  erlang:start_timer(Drop_Interval*1000, self(), drop_interval),
  delete_obsolete(),
  {noreply, State};

handle_info(Msg, State) ->
  io:format("Unexpected message in handle_info ~p~n", [Msg]),
  {noreply, State}.

terminate(normal, State) ->
  io:format("work with the server has finished ~p~n",[State]),
  ok.

delete_obsolete() ->
  Time_Now = erlang:system_time(second),
  ets:select_delete(table_cache, ets:fun2ms(fun({_, _, T_Life, T_Born})
    when Time_Now - T_Born > T_Life -> true end)),
  io:format("delete overdue items~n").

convert_DateTime_to_second(Date) ->
  Date_Universal = erlang:localtime_to_universaltime(Date),
  calendar:datetime_to_gregorian_seconds(Date_Universal) - 62167219200.




