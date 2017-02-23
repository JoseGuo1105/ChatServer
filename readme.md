这个程序用Erlang实现了一个聊天室功能。 包括用户注册， 登录，私聊， 消息广播， 当前在线人数，聊天记录的存储。

操作提示：
复制erl文件到erlang安装目录的bin文件夹
双击启动erl.exe，输入:
c(server).
c(client).

服务器：server:start().%%启动服务器

客户端：
1.client:start()%%启动客户端
2. client:registry(ID, Nick, Password) %% 注册, 例如： client:registry(1,apple, 888888).
2.client:login(ID, Passwd, Nick)%%登录， 例如：client:login(1, 888888, apple).
3.client:chat(ID, Nick, Matter)%%聊天    例如：client:chat(1, apple, "hello").
4.client:chat(private, LocID, LocNick, Matter, TargetID, TargetNick).
4.client:getNumOfPeople()  %%获取当前在线人数  
5.client:exitchat(ID)   %%退出聊天,断开连接    例如：client:exitchat(1)

