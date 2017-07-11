-module(aux_functions).
-compile(export_all).

string_to_list([A | []]) -> [[A]];
string_to_list([A | [32 | List]]) -> [[A]] ++ string_to_list(List).

list_to_string(A) -> lists:flatten(lists:map(fun(X) -> X ++ " " end, A)).

exist_file(FileName, []) -> true;
exist_file(FileName, [FileName | Tail]) -> false;
exist_file(FileName, [_ | Tail]) -> exist_file(FileName, Tail).

%convert file descriptor (number for users) to IoDevice
convert_fd_io(Fd, []) -> error;
convert_fd_io(Fd, [{Fd, IoDe} | _]) -> {ok, IoDe};
convert_fd_io(Fd, [_ | Tail]) -> convert_fd_io(Fd, Tail).

%convert IoDevice to file descriptor
convert_io_fd(Io, []) -> {add, [{Io, 1}], 1};
convert_io_fd(Io, [{Fd, Io}]) -> {ok, Fd};
convert_io_fd(Io, [{Fd, _}]) -> {add, [{Fd + 1, Io}], Fd + 1};
convert_io_fd(Io, [{Fd, Io} | _]) -> {ok, Fd};
convert_io_fd(Io, [_ | Tail]) -> convert_io_fd(Io, Tail).

lock_open() -> receive
                lock -> ok,
                        receive
                            unlock -> ok
                        end
               end
               lock_open().
