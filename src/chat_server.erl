-module(chat_server).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-include_lib("stdlib/include/qlc.hrl").
-include("cs_header.hrl").
start_link(LSocket)->
	gen_server:start_link(?MODULE, [LSocket], []).
%% gen_server interface
init([LSocket])->
	{ok, #state{lSocket = LSocket},0}.
handle_call(Msg, _From, State)->
	{reply, {ok, Msg}, State}.
handle_cast(stop, State)->
	{stop, normal, State}.

terminate(_Reason, _State)->ok.

code_change(_OldVan, State, _Extra)->
	{ok, State}.

handle_info(timeout, State)->
	{ok, _Socket} = gen_tcp:accept(State#state.lSocket),
	cs_sup:start_child(),
	{noreply, State};

handle_info({tcp_closed, _Socket}, State)->
	{stop, normal, State};

handle_info({tcp, Socket, RawData}, State)->
	NewState = handle_data(Socket, RawData, State),
	{noreply, NewState}.
	
%% private mwthods

registry(ID, Name, Pwd)->
	OldUser = do(qlc:q([X||X<-mnesia:table(user), ((X#user.id =:= ID) or (X#user.name =:= Name))])),
	if 
		OldUser =:= [] ->
			Row = #user{id = ID, name = Name, passwd = Pwd, login_times = 0, chat_times = 0, last_login ={0,0,0,0,0,0}},
			F = fun()->
					mnesia:write(Row)
				end,
			mnesia:transaction(F),
			
			ok;
		true->
			fail
	end.
addLoginUser(ID, Nick) ->
	Row = #loginUser{id = ID, name = Nick},
	F = fun() ->
			mnesia:write(Row)
	end,
	mnesia:transaction(F).

deleteLoginUser(ID) ->
	Oid = {loginUser, ID},
	F = fun() ->
			mnesia:delete(Oid)
 	    end,
	mnesia:transaction(F).

handle_data(Socket, Bin, State)->
	Context = binary_to_term(Bin),
	io:format("Server receive: Context = ~p~n", [Context]),
	case Context of
		{login, ID, Passwd, _Nick} ->
			Value = loginCheck(login, ID, Passwd),
					if
						Value =:= [] ->
							Reply = {login, failed};
						true ->
							Reply = {login, ID, ok},
							updatedata(login, ID),
							io:format("after addLoginUser: ~p~n", [addLoginUser(ID, _Nick)])%%ÌíŒÓÓÃ»§ÐÅÏ¢µœloginUser±íÖÐ
					end;
		{addChater, ID}->
					ets:insert(userSockets, {ID, {socket, ID, Socket}}),
					Reply = {addChater, ok};
		{registry, ID, Name, Pwd}->
					Result = registry(ID, Name, Pwd),
					if 
						Result =:= ok ->
							Reply = {registry, ok};
						true->
							Reply = {registry, fail, "user id or name has existed!"}
					end;
		{exitchat, ID} ->
					deleteLoginUser(ID),
					Reply = {exitchat, ok};
		{chat, ID, Nick, Matter} ->%%œÓÊÕµœÁÄÌìÇëÇó
					updatedata(chat, ID),%%žüÐÂÁÄÌìŽÎÊý
					addChatLog(Nick, Matter),
					SocksList = ets:tab2list(userSockets),
					ok = transmit(SocksList, Nick, Matter),%%°ÑÁÄÌìÄÚÈÝ×ª·¢žøž÷žöÒÑµÇÂŒµÄÓÃ»§
					Reply = {chat, ok};
		{privateChat, LocID, LocNick, Matter, TrgID, _TrgNick}->
					updatedata(chat, LocID),
					addChatLog(LocNick, Matter),
					Trg_list = ets:lookup(userSockets, TrgID),
					ok = transmit(Trg_list, LocNick, Matter),%%°ÑÁÄÌìÄÚÈÝ×ª·¢žøž÷žöÒÑµÇÂŒµÄÓÃ»§
					Reply = {privateChat, ok};
		{get_number_of_people_on_line} ->%%»ñÈ¡µ±Ç°ÔÚÏßÈËÊý
					List = selectall(loginUser),%%ListÎªµ±Ç°ÒÑµÇÂŒÓÃ»§ÐÅÏ¢µÄÁÐ±í
					Number = erlang:length(List),%%ListµÄ³€¶ÈŸÍÊÇListµÄÔªËØžöÊý£¬Ò²ŸÍÊÇµ±Ç°ÔÚÏßÈËÊý
					Reply = {get_number_of_people_on_line, Number}
	end,
	gen_tcp:send(Socket, term_to_binary(Reply)),
	State.
		

	
selectall(TableName) ->
	do(qlc:q([X || X <- mnesia:table(TableName)])).

do(Q) ->
    F = fun() -> qlc:e(Q) end,
    {atomic, Val} = mnesia:transaction(F),
    Val.

%%write file
timer(Time, Fun)->
	receive
		cancel->void
		after Time->
			io:format("timer after"),
			Fun(),
			timer(Time, Fun)
		end.

writeLogToFile(FileName)->
	LogList = selectall(chatLog),
	io:format("loglist = ~p ~n", [LogList]),
	if
		erlang:length(LogList) > 0 ->
			{ok, FD} = file:open(FileName, [write]),
			lists:foreach(fun({chatLog, _, T, N, L})->writeFile(FD, {T,N,L}) end, LogList),
			file:close(FD);
		true->
			void
	end.
	

writeFile(IODevice, {Time, Name, Log })->
	io:format(IODevice, "~p ~p:~p ~n", [Time, Name, Log]).
%%%%%%%%%%%%%%%%%%%%%



transmit([], _, _) -> ok;
transmit([H|T], Nick, Matter) ->
	case H of
		{_, {socket, _, Socket}} ->%%ÁÐ±íÀïµÄÄÚÈÝÊÇSocket
			io:format("before transmit!	H = ~p~n", [H]),
			gen_tcp:send(Socket, term_to_binary({transmit, Nick, Matter})),
			transmit(T, Nick, Matter);
		_ ->
			io:format("before transmit!	H = ~p~n", [H]),
			wrong
	end.

loginCheck(login, ID, Passwd) ->
    do(qlc:q([X || X <- mnesia:table(user),
		    X#user.id =:= ID, X#user.passwd =:= Passwd])).

updatedata(chat, ID) ->
	UserInfo = lists:last((do(qlc:q([X || X <- mnesia:table(user), X#user.id =:= ID])))),
	#user{chat_times = NewChatTimes} = UserInfo,
	NewUserInfo = UserInfo#user{chat_times = NewChatTimes +1},%%ÁÄÌìŽÎÊýÔöŒÓ1
	F = fun() ->
			mnesia:write(NewUserInfo)
	end,
	mnesia:transaction(F);
updatedata(login, ID) ->
	UserInfo = lists:last((do(qlc:q([X || X <- mnesia:table(user), X#user.id =:= ID])))),
	#user{login_times = NewLoginTimes} = UserInfo,
	NewUserInfo = UserInfo#user{login_times = NewLoginTimes+1,%%µÇÂŒŽÎÊýÔöŒÓ1 
				    last_login = list_to_tuple(tuple_to_list(date()) ++ tuple_to_list(time()))},%%žüÐÂ×îºóµÇÂŒÊ±ŒäÎªÕâŽÎµÄµÇÂŒÊ±Œä
	F = fun() ->
			mnesia:write(NewUserInfo)
	end,
	mnesia:transaction(F).

addChatLog(Name, Message) ->
	F = fun() ->
			Id = mnesia:dirty_update_counter(sequence, chatLog, 1),
			Row = #chatLog{id = Id, time = erlang:now(), name = Name, chatMessage = Message},
			io:format("before addChatLog Row:~p~n", [Row]),
			mnesia:write(Row)
	end,
	mnesia:transaction(F).