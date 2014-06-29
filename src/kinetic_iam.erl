-module(kinetic_iam).

-export([get_aws_keys/1, get_aws_keys/2]).

-include("kinetic.hrl").

get_aws_keys(MetaData) ->
    CurrentIAMRole = get_current_iam_role(MetaData),
    get_aws_keys(MetaData, CurrentIAMRole).


get_aws_keys(_MetaData, undefined) ->
    {error, no_profile_found};
get_aws_keys(MetaData, CurrentIAMRole) ->
    case kinetic_utils:fetch_and_return_url(MetaData ++ ?SECURITY_CREDENTIALS_PARTIAL_URL ++ CurrentIAMRole) of
        {ok, Body} ->
            case proplists:get_value(<<"Code">>, Body) of
                <<"Success">> ->
                    {ok, {proplists:get_value(<<"AccessKeyId">>, Body),
                          proplists:get_value(<<"SecretAccessKey">>, Body),
                          proplists:get_value(<<"Expiration">>, Body)}};

                _ ->
                    {error, no_credentials_found}
            end;
        {error, Error} ->
            {error, Error}
    end.

%% Internal

get_current_iam_role(MetaData) ->
    case kinetic_utils:fetch_and_return_url(MetaData ++ ?IAM_ROLE_URL) of
        {ok, Body} ->
            get_role_from_body(proplists:get_value(<<"Code">>, Body),
                               proplists:get_value(<<"InstanceProfileArn">>, Body));
        {error, Error} ->
            {error, Error}
    end.

% ProfileArn looks like this:
% <<"arn:aws:iam::ACCOUNT_NUMBER:instance-profile/ROLE">>
get_role_from_body(<<"Success">>, ProfileArn) ->
    binary:bin_to_list(lists:nth(2, binary:split(ProfileArn, <<"/">>)));
get_role_from_body(_, _) ->
    undefined.

