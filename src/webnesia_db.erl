%% @author Bruno Pedro <bpedro@tarpipe.com>
%% @copyright 2010 tarpipe.com.

%% @doc TEMPLATE.

-module(webnesia_db).
-author('Bruno Pedro <bpedro@tarpipe.com>').

-include_lib("stdlib/include/qlc.hrl").

-export ([start/0]).
-export ([info/1]).
-export ([tables/0]).
-export ([create_table/2]).
-export ([delete_table/1]).
-export ([list/1]).
-export ([list/2]).
-export ([list/3]).
-export ([save/2]).
-export ([read/2]).
-export ([delete/2]).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
start () ->
    mnesia:create_schema([node()]),
    webnesia_response:encode(mnesia:start()).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
info (Table) ->
    T = list_to_atom(Table),
    webnesia_response:encode({bert, dict,
                              [{table_name, Table},
                               {attributes, mnesia:table_info(T, attributes)},
                               {number_of_attributes, mnesia:table_info(T, arity) - 1},
                               {size, mnesia:table_info(T, size)}]}).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
tables () ->
    webnesia_response:encode(mnesia:system_info(tables)).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
create_table (Table, Data) ->
    io:format("~p~n", [Data]),
    Attributes = [list_to_atom(Attribute) || Attribute <- decode(Data)],
    case mnesia:create_table(list_to_atom(Table), [{attributes, Attributes}]) of
        {atomic, ok} ->
            webnesia_response:encode(ok);
        {aborted, Reason} ->
            webnesia_response:encode({struct, [Reason]})
    end.

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
delete_table (Table) ->
    case mnesia:delete_table(list_to_atom(Table)) of
        {atomic, ok} ->
            webnesia_response:encode(ok);
        {aborted, Reason} ->
            webnesia_response:encode({struct, [Reason]})
    end.

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
list (Table, 0, Offset) ->
    list(Table, mnesia:table_info(list_to_atom(Table), size), Offset);

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
list (Table, Limit, 0) ->
    list(Table, Limit);

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
list (Table, Limit, Offset) ->
    {atomic, Records} = mnesia:transaction(fun() -> C = qlc:cursor(qlc:q([X||X<-mnesia:table(list_to_atom(Table))])), qlc:next_answers(C, Offset), qlc:next_answers(C, Limit) end ),
    webnesia_response:encode_records(Records, mnesia:table_info(list_to_atom(Table), size), Limit, Offset).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
list (Table, 0) ->
    list(Table);

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
list (Table, Limit) ->
    {atomic, Records} = mnesia:transaction(fun() -> C = qlc:cursor(qlc:q([X||X<-mnesia:table(list_to_atom(Table))])), qlc:next_answers(C, Limit) end ),
    webnesia_response:encode_records(Records, mnesia:table_info(list_to_atom(Table), size), Limit, 0).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
list (Table) ->
    {atomic, Records} = mnesia:transaction(fun() -> mnesia:match_object(list_to_atom(Table), mnesia:table_info(list_to_atom(Table), wild_pattern), write) end),
    webnesia_response:encode_records(Records, mnesia:table_info(list_to_atom(Table), size), mnesia:table_info(list_to_atom(Table), size), 0).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
save (Table, Bert) ->
%%    <<_:8,Bert2/binary>> = Bert,
    try decode(Bert) of
        Data ->
            Record = list_to_tuple([list_to_atom(Table)] ++ [ Value || {_, Value} <- Data ]),
            webnesia_response:encode(tuple_to_list(mnesia:transaction(fun() -> mnesia:write(list_to_atom(Table), Record, write) end)))
    catch
        throw:Term -> Term;
        exit:Reason -> {'EXIT',Reason};
        error:Reason -> {'ERROR',{Reason,erlang:get_stacktrace()}}
    end.

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
read (Table, Key) ->
    {atomic, Records} = mnesia:transaction(fun() -> mnesia:read(list_to_atom(Table), mochijson2:decode(Key)) end),
    webnesia_response:encode_records(Records, mnesia:table_info(list_to_atom(Table), size), mnesia:table_info(list_to_atom(Table), size), 0).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
delete (Table, Key) ->
    {atomic, Response} = mnesia:transaction(fun() -> mnesia:delete({list_to_atom(Table), mochijson2:decode(Key)}) end),
    webnesia_response:encode(Response).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
decode(Data) ->
    <<_:8,Bert/binary>> = Data,
    bert:decode(Bert).


%%
%% Tests
%%
-include_lib("eunit/include/eunit.hrl").
-ifdef(TEST).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
%%create_table_test () ->
%%    ?assert(webnesia_db:create_table("test_table", "[\"test_key\",\"test_field\"]") =:= [34, "ok", 34]).

%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
%%delete_table_test () ->
%%    ?assert(webnesia_db:delete_table("test_table") =:= [34, "ok", 34]).

-endif.
