-module(cs_app).
-behaviour(application).
-export([start/2, stop/1]).
-include("cs_header.hrl").
start(_StartType, _StartArgs)->
	{ok, Listen} = gen_tcp:listen(2345, [binary, {packet, 4}, {reuseaddr, true}, {active, true}]),
	create_db(),
	start_db(),
	ets:new(userSockets, [named_table,public,set]),% saving user sockets for chating
	case cs_sup:start_link(Listen) of
		{ok, Pid}->
			cs_sup:start_child(),
			{ok, Pid};
		Other->
			{error, Other}
	end.

stop(_State)->
	ok.

create_db() ->
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(user, [{attributes, record_info(fields, user)}]),
    mnesia:create_table(loginUser, [{attributes, record_info(fields, loginUser)}, {type, bag}]),
	mnesia:create_table(chatLog, [{attributes, record_info(fields,chatLog)}, {type, set}, {disc_copies,[node()]}]),
	mnesia:create_table(sequence, [{attributes,record_info(fields, sequence)},{type, set}, {disc_copies,[node()]}]),
    mnesia:stop().

start_db() ->
    mnesia:start(),
    mnesia:wait_for_tables([user,loginUser, chatLog], 20000).
