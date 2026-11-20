-- Security advisor: pin search_path on the helper too.
alter function private.friend_request_daily_limit() set search_path = '';
