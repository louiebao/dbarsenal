-- Troubleshoot long running queries
select 
	s.session_id				as 'session_id'
	, s.status					as 'session_status'
	, r.status					as 'request_status'
	, s.last_request_start_time as 'last_request_start_time' -- This includes the currently executing request.
	, db_name(r.database_id)	as 'database_name'
	, t.text					as 'command'
	, substring (t.text
		, r.statement_start_offset/2+1
		, (iif(r.statement_end_offset = -1, len(convert(nvarchar(max), t.text)) * 2, r.statement_end_offset) - r.statement_start_offset)/2+1) as 'statement'
	, r.wait_type				as 'wait_type'
	, r.blocking_session_id		as 'blocking_session_id'
    , r.cpu_time                as 'cpu_time'
    , r.logical_reads           as 'logical_reads'
    , r.writes                  as 'writes'
    , s.open_transaction_count  as 'open_transaction_count'
	, s.login_name				as 'login_name'
	, s.host_name				as 'host_name'
	, s.program_name			as 'program_name'
	, xp.query_plan				as 'xml_query_plan' -- NULL may mean the plan exceeded max level of nested xml, check if text_query_plan is there
    , tp.query_plan				as 'text_query_plan' -- If not null then use powershell to export the text to get around the string character limitation
	, iif(tp.query_plan is null, null, concat('sqlcmd -S ', @@servername, ' -y0 -Q "set nocount on;select query_plan from sys.dm_exec_text_query_plan(', sys.fn_sqlvarbasetostr(r.plan_handle), ', ', r.statement_start_offset, ', ', r.statement_end_offset, ') a" -o"', s.session_id , '.', newid(), '.sqlplan"'))
    , r.percent_complete		as 'percent_complete'
from sys.dm_exec_sessions s
left join sys.dm_exec_requests r					on s.session_id = r.session_id
outer apply sys.dm_exec_sql_text(r.sql_handle) t
outer apply sys.dm_exec_query_plan(r.plan_handle) xp
outer apply sys.dm_exec_text_query_plan(r.plan_handle, r.statement_start_offset, r.statement_end_offset) tp
where s.is_user_process = 1 -- Do not rely on session_id > 50
and s.status = 'running' -- Currently running one or more requests
and s.session_id != @@SPID
order by logical_reads desc
