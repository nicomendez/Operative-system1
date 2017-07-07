-module(aux_functions).
-export([string_to_list/1]).

string_to_list([A | []]) -> [[A]];
string_to_list([A | [32 | List]]) -> [[A]] ++ string_to_list(List).

list_to_string(A) -> lists:flatten(lists:map(fun(X) -> X ++ " " end, A)).
