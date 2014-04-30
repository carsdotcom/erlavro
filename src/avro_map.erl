%%%-------------------------------------------------------------------
%%% @author Ilya Staheev <ilya.staheev@klarna.com>
%%% @doc Handling of Avro maps.
%%% Data are kept internally as a dict :: string() -> avro_value()
%%% @end
%%%-------------------------------------------------------------------
-module(avro_map).

%% API
-export([type/1]).
-export([get_items_type/1]).
-export([new/2]).
-export([to_dict/1]).
-export([cast/2]).

-include_lib("erlavro/include/erlavro.hrl").

%%%===================================================================
%%% API
%%%===================================================================

type(ItemsType) ->
  #avro_map_type{ type = ItemsType }.

get_items_type(#avro_map_type{ type = SubType }) ->
  SubType.

new(Type, Data) when ?AVRO_IS_MAP_TYPE(Type) ->
  case cast(Type, Data) of
    {ok, Value}  -> Value;
    {error, Err} -> erlang:error(Err)
  end.

to_dict(Value) when ?AVRO_IS_MAP_VALUE(Value) ->
  ?AVRO_VALUE_DATA(Value).

%% Value is other Avro map value or a proplist with string keys.
-spec cast(avro_type(), term()) -> {ok, avro_value()} | {error, term()}.

cast(Type, Value) when ?AVRO_IS_MAP_TYPE(Type) ->
  do_cast(Type, Value).

%%%===================================================================
%%% Internal functions
%%%===================================================================

do_cast(Type, Value) when ?AVRO_IS_MAP_VALUE(Value) ->
  %% Just cast data of the source map
  do_cast(Type, ?AVRO_VALUE_DATA(Value));
do_cast(Type, List) when is_list(List) ->
  %% Cast from a proplist :: [{string(), term()}]
  do_cast(Type, dict:from_list(List));
do_cast(Type, Dict) ->
  #avro_map_type{ type = ItemsType } = Type,
  case cast_from_dict(ItemsType, Dict) of
    {error, _} = Err -> Err;
    NewDict          -> {ok, ?AVRO_VALUE(Type, NewDict)}
  end.

cast_from_dict(ItemsType, Dict) ->
  dict:fold(
    fun(_Key, _Value, {error, _} = Acc) ->
        %% Ignore the rest after the first error
        Acc;
      (Key, Value, Acc) when is_list(Key) ->
        case avro:cast(ItemsType, Value) of
          {ok, CV} -> dict:store(Key, CV, Acc);
          Err      -> Err
        end;
      (Key, _Value, _Acc) ->
        %% If Key is not a string
        {error, {wrong_key_value, Key}}
    end,
    dict:new(),
    Dict).

%%%===================================================================
%%% Tests
%%%===================================================================

-include_lib("eunit/include/eunit.hrl").

-ifdef(EUNIT).

cast_test() ->
  Type = type(avro_primitive:int_type()),
  Value = cast(Type, [{"v1", 1}, {"v2", 2}, {"v3", 3}]),
  Expected = ?AVRO_VALUE(Type, dict:from_list(
                                 [{"v1", avro_primitive:int(1)}
                                 ,{"v2", avro_primitive:int(2)}
                                 ,{"v3", avro_primitive:int(3)}])),
  ?assertEqual({ok, Expected}, Value).

to_dict_test() ->
  Type = type(avro_primitive:int_type()),
  Value = new(Type, [{"v1", 1}, {"v2", 2}, {"v3", 3}]),
  Expected = dict:from_list(
               [{"v1", avro_primitive:int(1)}
               ,{"v2", avro_primitive:int(2)}
               ,{"v3", avro_primitive:int(3)}]),
  ?assertEqual(Expected,
               to_dict(Value)).

-endif.

%%%_* Emacs ============================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
