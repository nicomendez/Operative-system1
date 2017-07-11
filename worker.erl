-module(worker).
-compile(export_all).
-import(aux_functions, [exist_file/2]).

worker(-1) ->
    receive
        n -> worker(n, [], [])
    end.

% worker(PidNext, ListFilesOpen, 
% file structure {Name, Owner
worker(Nxt, FOpen) ->
    I = self(),
    receive
        %lsd from workers
        {wlsd, I, Files, Pid} -> {_, List} = file:list_dir("Archivos"), Pid!{Files, List};
        {wlsd, Who, Files, Pid} -> Nxt!{Who, lsd, Files ++ FOpen, Pid};
        
        %del from workers
        {wdel, I, FileName, error, Pid} -> Pid!{error, fileOpen};
        {wdel, I, FileName, _, Pid} -> case(file:delete("archivos/" ++ FileName) of
                                          ok -> Pid!{ok};
                                          {error, _} -> Pid{error, FileNoExist}
                                       end;
        {wdel, Who, FileName, error, Pid} -> Nxt!{wdel, Who, FileName, error, Pid};
        {wdel, Who, FileName, _, Pid} -> Nxt!{wdel, Who, FileName, exist_file(FileName, Fopen), Pid};

        %cre from workers
        {wcre, I, FileName, error, Pid} -> Pid!{error, fileExist};
        {wcre, I, FileName, _, Pid} -> os:cmd("touch archivos/" ++ FileName),
                                       Pid!{ok};
        {wcre, Who, FileName, error, Pid} -> Nxt!{wcre, Who, FileName, error, Pid};
        {wcre, Who, FileName, _, Pid} -> Nxt!{wcre, Who, FileName, exist_file(FileName, FOpen), Pid};

        %opn from workers
        {wopn, I, FileName, error, Pid} -> Pid!{error, isOpen};
        {wopn, I, FileName, _, Pid} -> case file:open("archivos/" ++ FileName, [read, append]) of
                                          {ok, IoDevice} -> Pid!{ok, IoDevice};
                                          {error, TipeError} -> io:format("error in open, tipe of error ~p ~n", [TipeError]),
                                                                Pid{error, isOpen}
                                       end;
        {wopen, Who, FileName, error, Pid} -> Nxt!{wopen, Who, FileName, error, Pid};
        {wopen, Who, FileName, _, Pid} -> Nxt!{wopen, Who, FileName, exist_file(FileName, FOpen), Pid};

        
