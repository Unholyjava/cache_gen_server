%%%-------------------------------------------------------------------
%% @doc cache_gen_server public API
%% @end
%%%-------------------------------------------------------------------

-module(cache_gen_server_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    case cache_gen_server_sup:start_link() of
        {ok, Pid} ->
            {ok, Pid};
        Other ->
            {error, Other}
    end.

stop(_State) ->
    ok.

%% internal functions
