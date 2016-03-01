-module ( server ).
-compile ( export_all ).

start () -> io:format ("~nServer-> iniciando servidor. ~n"),
	    io:format ("~nServer-> registrando scheduler ~n"),
	    register ( ?MODULE, spawn ( ?MODULE, scheduler, [] ) ),
	    ?MODULE ! start.

scheduler () ->
		receive 
			start ->  io:format ("~nServer-> agregando grupos por defecto.~n"),
	    			  put ( default, [] ),
				  put ( groups, [default] ),
				  scheduler();

			{ add_group, Group, Pid } -> Tmp = get ( Group ),
						     TmpG = get ( groups ),
                                                     if Tmp == undefined ->
                                                                put ( Group, [] ),
								put ( groups, TmpG ++ [Group]  ),
                                                              io:format("~nServer-> ~p ah gregado al grupo ~p ~n ~n",[Pid,Group] ),
                                                                scheduler ();

                                                         true -> Pid ! { print, 'Ya se ha registrado este nombre !', ?MODULE },
                                                                 scheduler()
                                                                 end;

			{ get_groups, Pid }	  -> Pid ! { print , get ( groups ), ?MODULE },
						     scheduler ();

			{ get_all, Pid }	  -> Pid ! { print, get(), ?MODULE },
						     scheduler();
	
			{ get_all_from, Group, Pid }->  Pid ! { print , get ( Group ), ?MODULE },
							scheduler ();

			{ send_to_group, Group, Msg, Pid } -> Tmp = is_group ( Group, get (groups)), 
							     if 
							        Tmp == true ->
										  send_to_group ( Group, Msg, Pid, get ( Group ) ),
							        		  scheduler ();
								true -> Pid ! { print,'No existe el grupo', ?MODULE },
									scheduler()
							     end;

			{ del_group, Group, Pid } -> erase (Group),
						     delete_group ( Group, get(groups), []),
						     io:format ("~nServer-> ~p borro el grupo ~w ~n", [Pid, Group] ),
						     scheduler ();
			
			{ add, Name } -> Tmp = get (default),
					 put ( Name, is_user ),
					 put ( default, Tmp ++ [Name] ),
					 io:format ("~nServer-> ~w nuevo usuario conectado. ~n", [Name] ),
					 scheduler ();

			{ add, Name, Group, Pid } -> Tmp = get (Name),
						     TmpG = get (Group),
						     if Tmp /= undefined andalso TmpG /= undefined ->
								put ( Name, is_user ),
								put ( Group, TmpG ++ [Name] ),
								io:format ("~nServer-> ~p agregado al grupo ~p ~n ~n",[Name, Group] ),
								scheduler ();
						    
						         true -> Pid ! { print, 'El usuario o grupo no existen ~n', ?MODULE },
								 scheduler()
                                                                 end;
			
			{get_users, Pid } -> Pid ! { print , get_keys ( is_user ), ?MODULE },
                                             scheduler ();

			{del_user, Name, Pid } -> Tmp = get (Name),
						  if
							Tmp == is_user ->
						  		io:format ("~nServer-> ~p kickeo ha ~w.~n ~n", [Pid,Name] ),
								erase ( Name ),
								delete_user_in ( Name, get( groups ) ),
						  		Name ! { shut_down, Pid },
						  		scheduler();

							true -> Pid ! { print, 'No hay usuario para borrar!', ?MODULE},
								scheduler()
						  end;
 
			{sms , Name, Msg, Pid } -> Tmp = get (Name),
                                                   if
                                                        Tmp == is_user ->
									
								 Name ! { print, Msg, Pid },
						  		 io:format("~nServer-> ~w envio mensaje a ~w. ~n ~n", [Pid, Name]),
						   		 scheduler ();

                                                        true -> Pid ! { print, 'No hay usuario con ese nombre!', ?MODULE},
                                                                scheduler()
                                                  end;


			stop -> io:format ("~nServer-> Good Bye ! ~n ~n");

			_ -> io:format ("~nSever-> no se entendio como proceder. ~n ~n"),
			     scheduler ()			
		end.

send_to_group ( Group, _  , Pid, [] ) -> io:format ("~nServer-> ~p envio mensaje a ~w . ~n ~n", [Pid,Group] );
send_to_group ( Group, Msg, Pid, [USER | QUEUE] ) -> USER ! { print, Msg, Pid },
						     send_to_group ( Group, Msg, Pid, QUEUE).

delete_user_in ( _ , [] ) -> io:format ("~n Server-> usuario borrado exitosamente. ~n ~n");
delete_user_in ( Name, [Grp | Tail] ) -> delete_user_aux ( Name, Grp, get(Grp) , [] ),
					 delete_user_in ( Name , Tail).

delete_user_aux ( _ , Group, [], Tmp ) -> put ( Group, Tmp);
delete_user_aux ( Name, Group, [Usr|Tail], Tmp ) -> if 
							Name == Usr -> delete_user_aux ( Name, Group, Tail, Tmp );
		 					true -> delete_user_aux ( Name, Group, Tail, Tmp ++ [Usr] )
		                                    end.

delete_group ( _    ,     []    , Tmp ) -> put ( groups, Tmp );
delete_group ( Group, [Grp|Tail], Tmp ) -> if
						Group == Grp -> delete_group ( Group, Tail, Tmp );
						true -> delete_group ( Group, Tail, Tmp ++ [Grp] )
					   end.
is_group ( _	, [] ) -> false;
is_group ( Group, [Grp | Tail]  ) -> if
					Group == Grp -> true;
					true -> is_group ( Group, Tail)
				     end. 
stop () -> ?MODULE ! stop.




