���������Erlangʵ����һ�������ҹ��ܡ� �����û�ע�ᣬ ��¼��˽�ģ� ��Ϣ�㲥�� ��ǰ���������������¼�Ĵ洢��

������ʾ��
����erl�ļ���erlang��װĿ¼��bin�ļ���
˫������erl.exe������:
c(server).
c(client).

��������server:start().%%����������

�ͻ��ˣ�
1.client:start()%%�����ͻ���
2. client:registry(ID, Nick, Password) %% ע��, ���磺 client:registry(1,apple, 888888).
2.client:login(ID, Passwd, Nick)%%��¼�� ���磺client:login(1, 888888, apple).
3.client:chat(ID, Nick, Matter)%%����    ���磺client:chat(1, apple, "hello").
4.client:chat(private, LocID, LocNick, Matter, TargetID, TargetNick).
4.client:getNumOfPeople()  %%��ȡ��ǰ��������  
5.client:exitchat(ID)   %%�˳�����,�Ͽ�����    ���磺client:exitchat(1)

