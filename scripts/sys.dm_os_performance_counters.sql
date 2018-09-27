/*
https://blogs.msdn.microsoft.com/psssql/2013/09/23/interpreting-the-counter-values-from-sys-dm_os_performance_counters/

PERF_COUNTER_LARGE_RAWCOUNT
65792

PERF_LARGE_RAW_FRACTION / PERF_LARGE_RAW_BASE
537003264 / 1073939712

(PERF_AVERAGE_BULK - PERF_AVERAGE_BULK) / (PERF_LARGE_RAW_BASE - PERF_LARGE_RAW_BASE)
(1073874176 - 1073874176) / (1073939712 - 1073939712)

(PERF_COUNTER_BULK_COUNT - PERF_COUNTER_BULK_COUNT) / seconds
(272696576 - 272696576) / seconds

*/

if object_id('tempdb.dbo.perf_counter') is null
begin
    -- drop table tempdb.dbo.perf_counter
    create table tempdb.dbo.perf_counter
    (
          object_name       sysname 
        , counter_name      sysname 
        , instance_name     sysname 
        , cntr_value        bigint 
        , cntr_type         sysname   
        , run_id            bigint
        , ts                datetime 
    )

    create index idx on tempdb.dbo.perf_counter (run_id)
end

declare @prev_run_id bigint = (select isnull(max(run_id), 0) from tempdb.dbo.perf_counter)
declare @run_id bigint = @prev_run_id + 1

-- Save the current snapshot to the tempdb
insert tempdb.dbo.perf_counter
(
      object_name
    , counter_name
    , instance_name
    , cntr_value
    , cntr_type
    , run_id
    , ts
)
select 
      object_name
    , counter_name
    , instance_name
    , cntr_value              
    , cntr_type
    , @run_id
    , sysutcdatetime()
from sys.dm_os_performance_counters

;with cte_interval_1
as
(
    select 
          a.object_name
        , a.counter_name
        , b.counter_name            as 'counter_name_base'
        , a.instance_name
        , a.cntr_value              
        , b.cntr_value              as 'cntr_value_base'

    from tempdb.dbo.perf_counter a
    join tempdb.dbo.perf_counter b           on a.run_id = b.run_id
                                            and a.object_name = b.object_name
                                            and charindex(rtrim(replace(replace(replace(b.counter_name
                                                                    , ' Base', '')
                                                                    , ' base', '')
                                                                    , ' BS', '')), a.counter_name) > 0
                                            and a.instance_name = b.instance_name
                                            and a.cntr_type = 1073874176
                                            and b.cntr_type = 1073939712

    where a.run_id = @prev_run_id
)
, cte_interval_2
as
(
    select 
          a.object_name
        , a.counter_name
        , b.counter_name            as 'counter_name_base'
        , a.instance_name
        , a.cntr_value              
        , b.cntr_value              as 'cntr_value_base'

    from tempdb.dbo.perf_counter a
    join tempdb.dbo.perf_counter b           on a.run_id = b.run_id
                                            and a.object_name = b.object_name
                                            and charindex(rtrim(replace(replace(replace(b.counter_name
                                                                    , ' Base', '')
                                                                    , ' base', '')
                                                                    , ' BS', '')), a.counter_name) > 0
                                            and a.instance_name = b.instance_name
                                            and a.cntr_type = 1073874176
                                            and b.cntr_type = 1073939712

    where a.run_id = @run_id
)
, cte_per_sec_1
as
(   
    select 
          object_name
        , counter_name
        , instance_name
        , cntr_value              
        , ts
    from tempdb.dbo.perf_counter
    where cntr_type = 272696576
    and run_id = @prev_run_id
)
, cte_per_sec_2
as
(
    select 
          object_name
        , counter_name
        , instance_name
        , cntr_value         
        , ts     
    from tempdb.dbo.perf_counter
    where cntr_type = 272696576
    and run_id = @run_id
)
-- Raw 
select 
	  a.object_name
	, a.counter_name
	, a.instance_name
    , a.cntr_value          as 'value'
from tempdb.dbo.perf_counter a
where cntr_type = 65792
and run_id = @run_id

union all

-- Ratio
select 
	  a.object_name
	, a.counter_name
	, a.instance_name
	, cast(a.cntr_value as decimal(28, 0)) / iif(b.cntr_value = 0, 1, b.cntr_value) as 'value'
from tempdb.dbo.perf_counter a
join tempdb.dbo.perf_counter b		on a.run_id = b.run_id
                                    and a.object_name = b.object_name
									and a.instance_name = b.instance_name
									and a.cntr_type = 537003264
									and b.cntr_type = 1073939712
where a.run_id = @run_id

union all

-- Per Interval
select
      i1.object_name
    , i1.counter_name
    , i1.instance_name
    , iif(i2.cntr_value_base - i1.cntr_value_base = 0, null, cast((i2.cntr_value - i1.cntr_value) as decimal(28, 0)) / (i2.cntr_value_base - i1.cntr_value_base)) 'value'
from cte_interval_1 i1
join cte_interval_2 i2        on i1.object_name      = i2.object_name
                            and i1.counter_name      = i2.counter_name
                            and i1.counter_name_base = i2.counter_name_base
                            and i1.instance_name     = i2.instance_name

union all                       

select
    i1.object_name
    , i1.counter_name
    , i1.instance_name
    , iif(datediff(second, i1.ts, i2.ts) = 0, null, cast((i2.cntr_value - i1.cntr_value) as decimal(28, 0)) / datediff(second, i1.ts, i2.ts)) 'value'

from cte_per_sec_1 i1
join cte_per_sec_2 i2       on i1.object_name = i2.object_name
                            and i1.counter_name = i2.counter_name
                            and i1.instance_name = i2.instance_name
