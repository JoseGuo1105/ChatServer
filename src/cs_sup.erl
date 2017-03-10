-module(cs_sup).
-behaviour(supervisor).
-export([start_link/1, start_child/0, init/1]).

start_link(LSocket)->
	supervisor:start_link({local, ?MODULE}, ?MODULE, [LSocket]).

start_child()->
	supervisor:start_child(?MODULE, []).

init([LSocket])->
	CS = {chat_server, {chat_server, start_link, [LSocket]}, temporary, brutal_kill, worker, [chat_server]},
	Child = [CS],
	RestartStrategy = {simple_one_for_one, 0, 1},
	{ok, {RestartStrategy, Child}}.