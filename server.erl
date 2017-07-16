-module(server).
-export([init/0]).
-import(aux_functions, [string_to_list/1, list_to_string/1, convert_fd_io/2, convert_io_fd/2, remove_element/2]).
-import(worker, [worker/1]).

-define(TOL, 1000).

init() -> 
    {_, Listen} = start_server(),
    Workers = start_workers(),
    listening(Listen, Workers, 1).

start_workers() ->
    Pid1 = spawn(?MODULE, worker, [-1, []]),
    Pid2 = spawn(?MODULE, worker, [-1, []]),
    Pid3 = spawn(?MODULE, worker, [-1, []]),
    Pid4 = spawn(?MODULE, worker, [-1, []]),
    Pid5 = spawn(?MODULE, worker, [-1, []]),
    
    Pid1!Pid2,
    Pid2!Pid3,
    Pid3!Pid4,
    Pid4!Pid5,
    Pid5!Pid1,

   [Pid1, Pid2, Pid3, Pid4, Pid5].
    
start_server() ->
   gen_tcp:listen(8000, [list, {packet, 0}, {reuseaddr, true}, {active, false}]).
    
listening(Listen, Workers, ID) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    spawn(fun() -> listening(Listen, Workers, ID+1) end),
    Pid = lists:nth(ID rem 5, Workers),
    start_socket(Socket, Pid, ID).
    
start_socket(Socket, Pid, ID) -> 
    receive
        {tcp, Socket, Msg} -> 
            io:format("Socket, ~p~n", [Socket]),
            
            case Msg of
                "CON" -> 
                    io:format("Conexion exitosa con: ~p ~n", [Socket]),
                    Reply = term_to_binary("OK ID " ++ integer_to_list(ID)),
                    gen_tcp:send(Socket, Reply),
                    spawn(?MODULE, socket_process, [Socket, Pid, ID, []]); %ver de hacer un spawn
                _ -> 
                    io:format("Comando \"~p\" invalido con: ~p ~n", [Msg, Socket]),
                    Reply = term_to_binary("ERROR, INVALID COMMAND ~n"),
                    start_socket(Socket, Pid, ID)
            end
    end.     

% LDfIo: List of file descriptors and IoDevice ({Fd, Io})
socket_process(Socket, Pid, ID, LFdIo) -> 
    receive 
        {tcp, Socket, Str} ->
            io:format("~p~n", Str),
            Com = string_to_list(Str),
            case Com of
                ["LSD"] -> Pid!{self(), lsd},
                           receive
                              {ok, List} -> gen_tcp:send(Socket, list_to_string(List))
                           end;
                ["DEL", Arg0] -> Pid!{self(), del, Arg0},
                                 receive
                                    {ok} -> gen_tcp:send(Socket, "OK");
                                    {error, fileNoExist} -> gen_tcp:send(Socket, "FILE INEXISTENT");
                                    {error, fileOpen} -> gen_tcp:send(Socket, "FILE IS OPEN")
                                 end;
                ["CRE", Arg0] -> Pid!{self(), cre, Arg0},
                                 receive
                                    {ok} -> gen_tcp:send(Socket, "OK");
                                    {error, fileExist} -> gen_tcp:send(Socket, "FILE EXIST")
                                 end;
                ["OPN", Arg0] -> Pid!{self(), opn, Arg0},
                                 receive
                                    {ok, IoDevice} -> case(convert_io_fd(IoDevice, LFdIo)) of
                                                        {ok, LS, Fd} -> gen_tcp:send(Socket, "OK FD " ++ integer_to_list(Fd)),
                                                                        socket_process(Socket, Pid, ID, LFdIo ++ LS)
                                                      end;
                                    {error, isOpen} -> gen_tcp:send(Socket, "ERROR THE FILE IS ALREADY OPEN");
                                    {error, fileNoExist} -> gen_tcp:send(Socket, "ERROR THE FILA NO EXIST")
                                 end;
                ["WRT", "FD", Fd, "SIZE", _, Buff] -> 
                                 case(convert_fd_io(Fd, LFdIo)) of
                                    error -> gen_tcp:send(Socket, "ERROR INVALID FILE DESCRIPTOR");
                                    {ok, IoDe} -> Pid!{self(), wrt, IoDe, Buff},
                                                  receive
                                                    {ok} -> gen_tcp:send(Socket, "OK");
                                                    {error} -> gen_tcp:send(Socket, "ERROR")
                                                  end
                                 end;

                ["REA", "FD", Fd, _, Num] -> Pid!{self(), rea, Fd, Num},
                                 receive
                                    {ok, Read} -> gen_tcp:send(Socket, Read);
                                    {error} -> gen_tcp:send(Socket, "ERROR")
                                 end;

                ["CLO", _, Fd] -> case(convert_fd_io(Fd, LFdIo)) of
                                    error -> NLFdIo = LFdIo, gen_tcp:send(Socket, "ERROR INVALID FILE DESCRIPTOR");
                                    {ok, IoDe} -> Pid!{self(), clo, IoDe},
                                                  receive
                                                    {ok} -> NLFdIo = remove_element(Fd, LFdIo),
                                                            gen_tcp:send(Socket, "OK")
                                                  end
                                  end,
                                  socket_process(Socket, Pid, ID, NLFdIo); 

                ["BYE"] -> Pid!{self(), bye},
                           receive
                               {ok} -> 
                                    gen_tcp:send(Socket, "OK"),
                                    io:format("Conexion cerrada con ~p ~n", [Socket]),
                                    tcp:close(Socket) 
                           end;
                _ -> gen_tcp:send(Socket, "INVALID COMMAND " ++ Com)
            end
    end.
                           
                 
    
%%%%%%%%%%%%%%%%%%%%%%%
















