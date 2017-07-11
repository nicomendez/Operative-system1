-module(worker).
-compile(export_all).
-import(aux_functions, [exist_file/2]).

worker(-1) ->
    receive
        n -> worker(n, [], [])
    end.

% worker(PidNext, ListFilesOpen, 
% file structure {Name, OwnerPid, IoDevice}
worker(Nxt, FOpen) ->
    I = self(),
    receive
        %lsd from workers
%        {wlsd, I, Files, Pid} -> {_, List} = file:list_dir("Archivos"), Pid!{Files, List};
%        {wlsd, Who, Files, Pid} -> Nxt!{Who, lsd, Files ++ FOpen, Pid};
        
        %del from workers
        {wdel, I, FileName, Atom, Pid} -> NFOpen = remove_file_name(FileName, FOpen),
                                          case(Atom) of
                                            error -> Pid!{error, fileOpen};
                                            _ -> %ask for lock ¡ATTENTION!
                                                 case(file:delete("archivos/" ++ FileName) of
                                                    ok -> Pid!{ok};
                                                    {error, _} -> Pid{error, fileNoExist}
                                                 end
                                          end,
                                          worker(Nxt, NFOpen);

        {wdel, Who, FileName, error, Pid} -> Nxt!{wdel, Who, FileName, error, Pid};
        {wdel, Who, FileName, _, Pid} -> Nxt!{wdel, Who, FileName, not_exist_file(FileName, Fopen), Pid};

        %opn from workers
        {wopn, I, FileName, Atom, Pid} -> NFOpen = remove_file_name(FileName, FOpen),
                                          case(Atom) of
                                            error -> Pid!{error, isOpen}, worker(Nxt, NFOpen);
                                            _ ->  case(lists:member(FileName, Files)) of %Todo esto por si se produce un del antes del opn
                                                      true -> {ok, IoDevice} = file:open("archivos/" ++ FileName, [read, append]), 
                                                              Pid!{ok, IoDevice}, 
                                                              worker(Nxt, NFOpen ++ [{FileName, Pid, IoDevice}]);
                                                      _ -> Pid!{error, fileNoExist}, worker(Nxt, NFOpen)
                                                  end
                                          end;

        {wopen, Who, FileName, error, Pid} -> Nxt!{wopen, Who, FileName, error, Pid};
        {wopen, Who, FileName, _, Pid} -> Nxt!{wopen, Who, FileName, not_exist_file(FileName, FOpen), Pid};


        %LSD
        {Pid, lsd} -> {_, Files} = file:list_dir("Archivos"),
                                   Pid!{ok, Files},
                                   worker(Nxt, FOpen);

        %CRE
        {Pid, cre, FileName} -> %ask for lock ¡ATTENTION!
                                {_, Files} = file:list_dir("Archivos"),
                                case(lists:member(FileName, Files) of
                                    true -> Pid!{error, fileExist};
                                    false -> os:cmd("touch archivos/" ++ FileName),
                                             Pid!{ok}
                                end,
                                worker(Nxt, FOpen);
        %DEL
        {Pid, del, FileName} -> case(not_exist_file(FileName, FOpen)) of
                                    true -> Pid!{error, fileOpen};
                                    false -> NFOpen = FOpen ++ [{FileName, Pid, []}], %include the target file into opens
                                             Nxt!{wdel, I, FileName, true, Pid}
                                end,
                                worker(Nxt, NFOpen);

        %OPN
        {Pid, opn, FileName} -> case(not_exist_file(FileName, FOpen))of
                                    false -> Pid!{error, fileIsOpen};
                                    _ -> {_, Files} = file:list_dir("Archivos"),
                                         case(lists:member(FileName, Files)) of
                                                false ->  Pid!{error, fileNoExist};
                                                true  -> NFOpen = FOpen ++ [{FileName, Pid, []}],
                                                         Nxt!{wopen, I, FileName, true, Pid}
                                         end
                                end,
                                worker(Nxt, NFOpen);
            
        %WRT
        {Pid, wrt, IoDe, Buff} -> 

        %CLO
        {Pid, clo, Io} -> NFOpen = remove_file_Io(Io, FOpen),
                          Pid!{ok},
                          worker(Nxt, NFOpen);
        %BYE
        {Pid, bye} -> NFOpen = remove_files_by_own(Pid, FOpen),
                      Pid!{ok},
                      worker(Nxt, NFOpen)
        
        end.










