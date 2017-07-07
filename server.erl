-module(server).
-export([init/0]).
-import(aux_functions, [string_to_list/1]).

-define(TOL, 1000).

init() -> 
    Listen = start_server(),
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
    
    %Lista con todos los pids de los workers
    Workers = [Pid1] ++ [Pid2] ++ [Pid3] ++ [Pid4] ++ [Pid5].
    
start_server() ->
    {ok, Listen} = gen_tcp:listen(8000, [list, {packet, 0}, {reuseaddr, true}, {active, false}]),
    Listen.
    
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
    
socket_process(Socket, Pid, ID) -> 
    receive 
        {tcp, Socket, 
    
%%%%%%%%%%%%%%%%%%%%%%%

%worker(-1) ->
%    receive
%        n -> worker(n)
%    end.
%worker(n) ->















