-module(aux_functions).
-compile(export_all).

%file structure {Name, PidOwner, Io}

string_to_list([A | []]) -> [[A]];
string_to_list([A | [32 | List]]) -> [[A]] ++ string_to_list(List).

list_to_string(A) -> lists:flatten(lists:map(fun(X) -> X ++ " " end, A)).

not_exist_file(_, []) -> true;
not_exist_file(FileName, [{FileName, _, _} | Tail]) -> error;
not_exist_file(FileName, [_ | Tail]) -> not_exist_file(FileName, Tail).

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

%remove file by Io
remove_file_Io(Io, FOpen) -> lists:filter(fun({_, _, Io2}) -> Io =/= Io2 end, FOpen).

%remove file by Name
remove_file_Name(FN, FOpen) -> lists:filter(fun({FN2, _, _}) -> FN =/= FN2 end, FOpen).

%remove all the files of an owner
remove_files_by_own(Pid, FOpen) -> lists:filter(fun({_, Pid2, _}) -> Pid =/= Pid2 end, FOpen).

lock_open() -> receive
                lock -> ok,
                        receive
                            unlock -> ok
                        end
               end
               lock_open().


