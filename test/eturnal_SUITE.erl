%%% eturnal STUN/TURN server.
%%%
%%% Copyright (c) 2020 Holger Weiss <holger@zedat.fu-berlin.de>.
%%% Copyright (c) 2020 ProcessOne, SARL.
%%% All rights reserved.
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.

-module(eturnal_SUITE).
-compile(export_all).
-include_lib("common_test/include/ct.hrl").

-type info() :: ct_suite:ct_info().
-type config() :: ct_suite:ct_config().
-type test_def() :: ct_suite:ct_test_def().
-type test_name() :: ct_suite:ct_testname().
-type group_def() :: ct_suite:ct_group_def().
-type group_name() :: ct_suite:ct_groupname().

%% API.

-spec suite() -> [info()].
suite() ->
    [{timetrap, {seconds, 30}}].

-spec init_per_suite(config()) -> config().
init_per_suite(Config) ->
    Config.

-spec end_per_suite(config()) -> ok.
end_per_suite(_Config) ->
    ok.

-spec init_per_group(group_name(), config()) -> config().
init_per_group(_GroupName, Config) ->
    Config.

-spec end_per_group(group_name(), config()) -> ok.
end_per_group(_GroupName, _Config) ->
    ok.

-spec init_per_testcase(test_name(), config()) -> config().
init_per_testcase(start_eturnal, Config) ->
    DataDir = ?config(data_dir, Config),
    ConfFile = filename:join(DataDir, "eturnal.yml"),
    ok = application:set_env(conf, file, ConfFile),
    ok = application:set_env(conf, on_fail, stop),
    ok = application:set_env(eturnal, on_fail, exit),
    Config;
init_per_testcase(_TestCase, Config) ->
    Config.

-spec end_per_testcase(test_name(), config()) -> ok.
end_per_testcase(_TestCase, _Config) ->
    ok.

-spec groups() -> [group_def()].
groups() ->
    [].

-spec all() -> [test_def()] | {skip, term()}.
all() ->
    [start_eturnal,
     check_info,
     check_sessions,
     check_loglevel,
     check_version,
     reload,
     connect_tcp,
     connect_tls,
     stop_eturnal].

-spec start_eturnal(config()) -> any().
start_eturnal(_Config) ->
    {ok, _} = application:ensure_all_started(eturnal).

-spec check_info(config()) -> any().
check_info(_Config) ->
    {ok, Info} = eturnal_ctl:get_info(),
    true = is_list(Info).

-spec check_sessions(config()) -> any().
check_sessions(_Config) ->
    {ok, Sessions} = eturnal_ctl:get_version(),
    true = is_list(Sessions).

-spec check_loglevel(config()) -> any().
check_loglevel(_Config) ->
    {ok, Level} = eturnal_ctl:get_loglevel(),
    true = Level =:= "debug".

-spec check_version(config()) -> any().
check_version(_Config) ->
    {ok, Version} = eturnal_ctl:get_version(),
    match = re:run(Version, "^[0-9]+\\.[0-9]+\\.[0-9](\\+[0-9]+)?",
                   [{capture, none}]).

-spec reload(config()) -> any().
reload(_Config) ->
    ok = eturnal_ctl:reload().

-spec connect_tcp(config()) -> any().
connect_tcp(_Config) ->
    {ok, Addr} = inet:parse_address("127.0.0.1"),
    {ok, Sock} = gen_tcp:connect(Addr, 34780, []),
    ok = gen_tcp:close(Sock).

-spec connect_tls(config()) -> any().
connect_tls(_Config) ->
    {ok, Addr} = inet:parse_address("127.0.0.1"),
    {ok, TCPSock} = gen_tcp:connect(Addr, 53490, []),
    {ok, TLSSock} = fast_tls:tcp_to_tls(TCPSock, [connect]),
    ok = fast_tls:close(TLSSock).

-spec stop_eturnal(config()) -> any().
stop_eturnal(_Config) ->
    ok = application:stop(eturnal).
