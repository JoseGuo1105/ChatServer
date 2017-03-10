-module(client).
-compile(export_all).

%%���ܣ������ͻ���
start() ->
	start_send(),%%�����ͻ��˷�����Ϣ����
	register(socket_receiver, spawn(fun() -> start_receive() end)).%%Ϊ����������Ϣ���ܿ�����һ�����̣��������Ϳ��Խ��ս�����Ϣ��Ҳ������������Ϣ

%%���ܣ����ӷ����������ڷ�����Ϣ��
start_send() ->
	{ok, Socket} = gen_tcp:connect("localhost", 2345, [binary, {packet, 4}]),
	register(socket_store, spawn(fun() -> store_socket(Socket) end)).

%%���ܣ����ӷ����������ڽ���������Ϣ��
start_receive() ->
	{ok, Socket} = gen_tcp:connect("localhost", 2345, [binary, {packet, 4}]),
	%gen_tcp:send(Socket, term_to_binary({receiver})),
	receiveChatMsg(Socket).

%%���ܣ����ڱ���һ��Socket������յ�get_socket��������Socket������
%%������Sock������������Socket
store_socket(Socket) ->
	receive
		{get_socket, From} ->
			From ! {Socket},
			store_socket(Socket)
	end.

%%���ܣ���store_socket�����л�ȡSocket
%%������Pid��Ҫ��ȡSocket�Ľ���id
get_socket(Pid) ->
	socket_store ! {get_socket, Pid},
	receive
		{Socket} ->
			Socket
	end.
get_receiveSocket(Pid)->
	socket_receiver ! {get_socket, Pid},
	receive
		{Socket}->
			Socket
	end.

%%���ܣ�������Ϣ��������
%%������Socket:���ӵ���������Socket
%%	Msg   :Ҫ���͵���Ϣ
sendmsg(Socket, Msg) ->
	gen_tcp:send(Socket, term_to_binary(Msg)).

%%���ܣ���¼
%%������Socket:���ӵ���������Socket
%%	ID��	��¼�õ���ID���˴�������1.2.3.4.5�е�һ��
%%	Passwd����¼��Ҫ�õ����룬����ȫ��Ĭ��Ϊ888888��6��8��
%%	Nick��  �û��ǳ�
login(ID, Passwd, Nick) ->
	Pid = self(),
	Socket = get_socket(Pid),	
	Msg = {login, ID, Passwd, Nick},%%����Ҫ���͵���Ϣ
	sendmsg(Socket, Msg),		
	receiveMsg(Socket).		

%%���ܣ�����������Ϣ
%%������Socket:���ӵ���������Socket
%%	ID��	��¼�õ���ID���˴�������1.2.3.4.5�е�һ��
%%	Nick��  �û��ǳ�
%%	Matter��������Ϣ
chat(ID, Nick, Matter) ->
	Msg = {chat, ID, Nick, Matter}, %%����Ҫ���͵���Ϣ
	Pid = self(),
	Socket = get_socket(Pid),
	sendmsg(Socket, Msg),	        
	receiveMsg(Socket).	

chat(private, LocID, LocNick, Matter, TrgID, TrgNick)->
  	Msg = {privateChat, LocID, LocNick, Matter, TrgID, TrgNick},
	Pid = self(),
	Socket = get_socket(Pid),
	sendmsg(Socket, Msg),	        
	receiveMsg(Socket).	

%%���ܣ���ȡ��ǰ��¼����
%%������Socket:���ӵ���������Socket
getNumOfPeople() ->
	Msg = {get_number_of_people_on_line}, %%����Ҫ���͵���Ϣ
	Pid = self(),
	Socket = get_socket(Pid),
	sendmsg(Socket, Msg),		      
	receiveMsg(Socket).		      

%%���ܣ��˳�
%%������Socket:���ӵ���������Socket
%%	ID��	��¼�õ���ID���˴�������1.2.3.4.5�е�һ��
exitchat(ID) ->
	Msg = {exitchat, ID},%%����Ҫ���͵���Ϣ
	Pid = self(),
	Socket = get_socket(Pid),
	sendmsg(Socket, Msg),
	receiveMsg(Socket),  
	gen_tcp:close(Socket).%%�ر�Socket���Ͽ�����

registry(ID, Name, Pwd)->
	Msg = {registry, ID, Name, Pwd},
	Pid = self(),
	Socket = get_socket(Pid),
	sendmsg(Socket, Msg),
	receiveMsg(Socket).

%%���ܣ����շ��������ص���Ϣ
%%������Socket:���ӵ���������Socket
receiveMsg(Socket) ->
	receive
		{tcp, Socket, Bin} ->
			Val = binary_to_term(Bin),
			case Val of
				{login, ID, ok} ->
					io:format("login succefully!~n",[]),
					Receive_Socket = get_receiveSocket(self()),
					Msg = {addChater, ID},
					sendmsg(Receive_Socket, Msg);
					
				{login, failed} ->
					io:format("login failed!~n",[]);
				{exitchat, ok} ->
					io:format("exit chat succefully!~n",[]);
				{chat, ok} ->
					io:format("ok!~n", []);
				{get_number_of_people_on_line, Number} ->
					io:format("the number of people on-line is:~p~n", [Number]);
				{privateChat, ok} ->
					io:format("private chat ok!~n", []);
				{registry, ok}->
					io:format("registry ok!");
				{registry, fail, Error}->
					io:format("registry fail! The reason is ~p ~n", [Error])

			end			
	end.

%%���ܣ�������������
%%������Socket:���ӵ���������Socket
receiveChatMsg(Socket) ->
	receive
		{get_socket, From}->
			From ! {Socket},
			receiveChatMsg(Socket);
		{tcp, Socket, Bin} ->
			Val = binary_to_term(Bin),
			case Val of
				{addChater, ok}->
					io:format("add chater ok!~n", []),
					receiveChatMsg(Socket);
				%{receiver, ok} ->
					%io:format("receiver send message succefully!~n",[]),
					%receiveChatMsg(Socket);
				{transmit, Name, Matter}->%%������������ݣ�����ӡ����Ļ��
					io:format("~p:~p.~n", [Name, Matter]),
					receiveChatMsg(Socket);
				Other->
					io:format("receiveChatMsg get a error: ~p ~n", [Other])
			end			
	end.
