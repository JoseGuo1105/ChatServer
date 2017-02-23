-module(server).
-export([start/0,do_this_once/0]).
-compile(export_all).
-record(user, {id, name ,passwd, login_times, chat_times, last_login}).%%ÓÃ»§ÐÅÏ¢
-record(loginUser, {id, name}).%%µÇÂŒÓÃ»§ÐÅÏ¢£š°üÀšid£¬êÇ³Æ£©
-record(chatLog, {id, time,name,chatMessage}).
-record(sequence, {name, seq}). %the table keep id of auto acreasing for other table
-include_lib("stdlib/include/qlc.hrl").

%¹ŠÄÜ£ºŽŽœšÊýŸÝ¿â±í
do_this_once() ->
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(user, [{attributes, record_info(fields, user)}]),
    mnesia:create_table(loginUser, [{attributes, record_info(fields, loginUser)}, {type, bag}]),
	mnesia:create_table(chatLog, [{attributes, record_info(fields,chatLog)}, {type, set}, {disc_copies,[node()]}]),
	mnesia:create_table(sequence, [{attributes,record_info(fields, sequence)},{type, set}, {disc_copies,[node()]}]),
    mnesia:stop().

%%¹ŠÄÜ£ºÆô¶¯ÊýŸÝ¿â
start_db() ->
    mnesia:start(),
    mnesia:wait_for_tables([user,loginUser, chatLog], 20000).

%%¹ŠÄÜ£ºÊÖ¶¯ÌíŒÓµÄÓÃ»§ÐÅÏ¢
example_user() ->
    [
     {user, 1, apple, 888888, 0, 0, {0,0,0,0,0,0}},
     {user, 2, pear,  888888, 0, 0, {0,0,0,0,0,0}},
     {user, 3, orange, 888888, 0, 0, {0,0,0,0,0,0}},
     {user, 4, potato, 888888, 0, 0, {0,0,0,0,0,0}},
     {user, 5, banana, 888888, 0, 0, {0,0,0,0,0,0}}
    ].

%%¹ŠÄÜ£º°Ñexample_user()ÖÐµÄÓÃ»§ÐÅÏ¢ÌíŒÓµœÊýŸÝ¿âuser±íÖÐ
reset_tables() ->
    mnesia:clear_table(user),
    F = fun() ->
		lists:foreach(fun mnesia:write/1, example_user())
	end,
    mnesia:transaction(F).

%%¹ŠÄÜ£º²éÑ¯±íÖÐËùÓÐµÄÊýŸÝ
%%²ÎÊý£ºTableName£º±íÃû
selectall(TableName) ->
	do(qlc:q([X || X <- mnesia:table(TableName)])).

%%¹ŠÄÜ£ºÖŽÐÐ²éÑ¯ÓïŸä
%%²ÎÊý£ºQ£º²éÑ¯ÓïŸä
do(Q) ->
    F = fun() -> qlc:e(Q) end,
    {atomic, Val} = mnesia:transaction(F),
    Val.

%%¹ŠÄÜ£ºµÇÂŒÐ£ÑéIDºÍÃÜÂëÊÇ·ñÆ¥Åä
%%²ÎÊý£ºID£º    ÓÃ»§ID
%%	Passwd£ºÓÃ»§ÃÜÂë
loginCheck(login, ID, Passwd) ->
    do(qlc:q([X || X <- mnesia:table(user),
		    X#user.id =:= ID, X#user.passwd =:= Passwd])).

%%¹ŠÄÜ£ºŒÇÂŒÒÑµÇÂŒÓÃ»§µÄÐÅÏ¢£¬ÌíŒÓµœÊýŸÝ¿âloginUser±íÖÐ
%%²ÎÊý£ºID£º      ÓÃ»§ID
%%      Nicke£º   ÓÃ»§êÇ³Æ
%%      Position£ºµÇÂŒÓÃ»§µÄSocketÖµ
addLoginUser(ID, Nick) ->
	Row = #loginUser{id = ID, name = Nick},
	io:format("before addloginUser Row:~p~n", [Row]),
	F = fun() ->
			mnesia:write(Row)
	end,
	mnesia:transaction(F).

%%¹ŠÄÜ£ºŽÓloginUser±íÖÐÉŸ³ýÒÑÍË³öµÄÓÃ»§ÐÅÏ¢
%%²ÎÊý£ºID£º      ÓÃ»§ID
deleteLoginUser(ID) ->
	Oid = {loginUser, ID},
	F = fun() ->
			mnesia:delete(Oid)
 	    end,
	mnesia:transaction(F).

%%¹ŠÄÜ£ºžüÐÂÁÄÌìµÄŽÎÊý£¬µÇÂŒŽÎÊýºÍ×îºóµÇÂŒÊ±Œä
%%²ÎÊý£ºID£º      ÓÃ»§ID
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

%%¹ŠÄÜ£ºÆô¶¯·þÎñÆ÷
start() ->
	do_this_once(), %%ÊýŸÝ¿âœš±íµÈ²Ù×÷
	start_db(),	%%Žò¿ªÊýŸÝ¿â
	%reset_tables(), %%³õÊŒ»¯user±í£šÏò±íÖÐÌíŒÓÁË5ÌõÊýŸÝ£©
	register(user_store, spawn(fun() -> store_user([]) end)),
	{ok, Listen} = gen_tcp:listen(2345, [binary, {packet, 4}, {reuseaddr, true}, {active, true}]),
	spawn(fun() -> par_connect(Listen) end).

%%¹ŠÄÜ£º±£ŽæÒÑµÇÂŒÓÃ»§µÄSocket£¬Èç¹ûÊÕµœ{getChater, From}ÏûÏ¢£¬Ôò°Ñµ±Ç°µÄÒÑµÇÂŒÓÃ»§ÁÐ±í·¢¹ýÈ¥
%%²ÎÊý£ºUser_list:ÒÑµÇÂŒÓÃ»§ÁÐ±í£šÁÐ±íµÄÔªËØ¶ŒÊÇSocket£©
store_user(User_list) ->
	receive
		{addChater, ID, User} ->
			New_user_list = [{socket, ID, User}|User_list],
			store_user(New_user_list);
		{getChater, From} ->
			From ! {User_list},
			store_user(User_list)
	end.

%%¹ŠÄÜ£º»ñÈ¡ÒÑµÇÂŒÓÃ»§ÁÐ±í£šÁÐ±íµÄÔªËØ¶ŒÊÇSocket£©
%%²ÎÊý£ºPid£ºµ÷ÓÃŽËº¯ÊýµÄœø³Ìid
get_user(Pid) ->
	user_store ! {getChater, Pid},
	receive
		{User_list} ->
			User_list
	end.

%%¹ŠÄÜ£ºÌíŒÓÁÄÌìÏûÏ¢µÄœÓÊÕÈËSocket
%%²ÎÊý£ºSocket£ºÁÄÌìÏûÏ¢µÄœÓÊÕÈËSocket
addChater(ID, Socket) ->
	user_store ! {addChater, ID, Socket}.

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

%%¹ŠÄÜ£ºÊ¹Á¬œÓµœ·þÎñÆ÷µÄSocketÄÜ¹»²¢ÐÐ
%%²ÎÊý£ºListen£ºÒÑŽò¿ªµÄSocket
par_connect(Listen) ->
	{ok, Socket} = gen_tcp:accept(Listen),
	spawn(fun() -> par_connect(Listen) end),
	loop(Socket).

loop(Socket) ->
	receive
		{tcp, Socket, Bin} ->
			Context = binary_to_term(Bin),
			io:format("Server receive: Context = ~p~n", [Context]),
			case Context of
				{login, ID, Passwd, Nick} ->%%œÓÊÕµœµÇÂŒÇëÇó
					Value = loginCheck(login, ID, Passwd),%%ÏÈœøÐÐµÇÂŒÐ£Ñé£¬Èç¹û²»Æ¥Åä£¬ValÎª[]£»Èç¹ûÆ¥Åä£¬ÔòžüÐÂµÇÂŒŽÎÊýºÍ×îºóµÇÂŒÊ±Œä
					if
						Value =:= [] ->
							Reply = {login, failed};
						true ->
							Reply = {login, ID, ok},
							updatedata(login, ID),%%žüÐÂµÇÂŒŽÎÊýºÍ×îºóµÇÂŒÊ±Œä
							
							io:format("after addLoginUser: ~p~n", [addLoginUser(ID, Nick)])%%ÌíŒÓÓÃ»§ÐÅÏ¢µœloginUser±íÖÐ
					end;
				{addChater, ID}->
					addChater(ID, Socket),
					Reply = {addChater, ok};
				{exitchat, ID} ->%%œÓÊÕµœÍË³öÇëÇó
					deleteLoginUser(ID),%%ÉŸ³ýloginUser±íÖÐ¶ÔÓŠµÄÒÑµÇÂŒÓÃ»§ÐÅÏ¢
					Reply = {exitchat, ok};
				{chat, ID, Nick, Matter} ->%%œÓÊÕµœÁÄÌìÇëÇó
					updatedata(chat, ID),%%žüÐÂÁÄÌìŽÎÊý
					addChatLog(Nick, Matter),
					Pid = self(),
					User_list = get_user(Pid),
					ok = transmit(User_list, Nick, Matter),%%°ÑÁÄÌìÄÚÈÝ×ª·¢žøž÷žöÒÑµÇÂŒµÄÓÃ»§
					Reply = {chat, ok};
				{privateChat, LocID, LocNick, Matter, TrgID, TrgNick}->
					updatedata(chat, LocID),
					addChatLog(LocNick, Matter),
					Pid = self(),
					User_list = get_user(Pid),
					Trg_list = lists:filter(fun({socket,ID,_})->ID =:= TrgID end, User_list),
					ok = transmit(Trg_list, LocNick, Matter),%%°ÑÁÄÌìÄÚÈÝ×ª·¢žøž÷žöÒÑµÇÂŒµÄÓÃ»§
					Reply = {privateChat, ok};
				{get_number_of_people_on_line} ->%%»ñÈ¡µ±Ç°ÔÚÏßÈËÊý
					List = selectall(loginUser),%%ListÎªµ±Ç°ÒÑµÇÂŒÓÃ»§ÐÅÏ¢µÄÁÐ±í
					Number = erlang:length(List),%%ListµÄ³€¶ÈŸÍÊÇListµÄÔªËØžöÊý£¬Ò²ŸÍÊÇµ±Ç°ÔÚÏßÈËÊý
					Reply = {get_number_of_people_on_line, Number};
				{registry, ID, Name, Pwd}->
					Result = registry(ID, Name, Pwd),
					if 
						Result =:= ok ->
							Reply = {registry, ok};
						true->
							Reply = {registry, fail, "user id or name has existed!"}
					end
			end,
			gen_tcp:send(Socket, term_to_binary(Reply)),
			loop(Socket);
		{tcp_closed, Socket} ->
			io:format("Client socket closed~n")
	end.

%%¹ŠÄÜ£º×ª·¢Ëµ»°ÄÚÈÝµœž÷žöÒÑµÇÂŒµÄÓÃ»§
%%²ÎÊý£º[H|T]:  ÒÑµÇÂŒÓÃ»§ÁÐ±í
%%	Nick:   Ëµ»°ÈËµÄêÇ³Æ
%%	Matter£ºËµ»°ÄÚÈÝ
transmit([], _, _) -> ok;
transmit([H|T], Nick, Matter) ->
	case H of
		{socket, _, Socket} ->%%ÁÐ±íÀïµÄÄÚÈÝÊÇSocket
			io:format("before transmit!	H = ~p~n", [H]),
			gen_tcp:send(Socket, term_to_binary({transmit, Nick, Matter})),
			transmit(T, Nick, Matter);
		_ ->
			io:format("before transmit!	H = ~p~n", [H]),
			wrong
	end.	

