-module ( usuario ).
-compile ( export_all).

start () -> io:format ("~nIniciando cliente. ~n"),
	    io:format ("~nRegistrando cliente. ~n"),
	    server ! { add, ?MODULE },
	    io:format ("~nIniciando el scheduler. ~n"),
	    register ( ?MODULE , spawn ( ?MODULE, read, [] ) ).

read () -> 
		receive 
			{ print, Msg, Pid }  -> io:format ("~n~w -> ~p dice: ~w . ~n ~n", [ ?MODULE,Pid, Msg ] ),
						read ();

			{ shut_down, Pid } -> io:format ("~n~w -> ~p te ha kickeado. ~n ~n", [?MODULE,Pid]);
			
			_ -> io:format ("~n~w-> no se entiende la accion. ~n ~n",[?MODULE]),
			     read()
		end.

add_group ( Group ) -> server ! { add_group, Group, ?MODULE}.
get_groups () -> server ! { get_groups, ?MODULE }.
get_all () -> server ! { get_all, ?MODULE}.
get_all_from ( Group ) -> server ! { get_all_from, Group, ?MODULE }.
send_to_group ( Group, Msg ) -> server ! { send_to_group, Group, Msg, ?MODULE }.
del_group ( Group ) -> server ! { del_group, Group, ?MODULE }.

add_user ( Name, Group ) -> server ! { add, Name, Group, ?MODULE }.
get_users ( ) -> server ! { get_users, ?MODULE }.
del_user ( Name ) -> server ! { del_user, Name, ?MODULE }.
send_to ( Name, Msg ) -> server ! { sms, Name, Msg, self() }.
bye() -> server ! { del_user, ?MODULE, ?MODULE }.
