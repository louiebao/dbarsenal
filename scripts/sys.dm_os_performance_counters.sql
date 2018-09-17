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

-- Raw 
select 
	  a.object_name
	, a.counter_name
	, a.instance_name
	, a.cntr_value          as 'formula'
    , a.cntr_value          as 'value'
from sys.dm_os_performance_counters a
where cntr_type = 65792

-- Ratio
select 
	  a.object_name
	, a.counter_name
	, b.counter_name
	, a.instance_name
	, concat(a.cntr_value, ' / ', b.cntr_value) as 'formula'
	, cast(a.cntr_value as decimal(28, 0)) / iif(b.cntr_value = 0, 1, b.cntr_value) as 'value'
from sys.dm_os_performance_counters a
join sys.dm_os_performance_counters b		on a.object_name = b.object_name
												and a.instance_name = b.instance_name
												and a.cntr_type = 537003264
												and b.cntr_type = 1073939712

-- Per interval
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

    from sys.dm_os_performance_counters a
    join sys.dm_os_performance_counters b           on a.object_name = b.object_name
                                                    and charindex(rtrim(replace(replace(replace(b.counter_name
                                                                            , ' Base', '')
                                                                            , ' base', '')
                                                                            , ' BS', '')), a.counter_name) > 0
                                                    and a.instance_name = b.instance_name
                                                    and a.cntr_type = 1073874176
                                                    and b.cntr_type = 1073939712

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

    from sys.dm_os_performance_counters a
    join sys.dm_os_performance_counters b           on a.object_name = b.object_name
                                                    and charindex(rtrim(replace(replace(replace(b.counter_name
                                                                            , ' Base', '')
                                                                            , ' base', '')
                                                                            , ' BS', '')), a.counter_name) > 0
                                                    and a.instance_name = b.instance_name
                                                    and a.cntr_type = 1073874176
                                                    and b.cntr_type = 1073939712
)
select
    i1.object_name
    , i1.counter_name
    , i1.counter_name_base
    , concat('(', i2.cntr_value, ' - ', i1.cntr_value, ') / (', i2.cntr_value_base, ' - ', i1.cntr_value_base, ')') as 'formula'
    , cast((i2.cntr_value - i1.cntr_value) as decimal(28, 0)) / iif(i2.cntr_value_base - i1.cntr_value_base = 0, 1, i2.cntr_value_base - i1.cntr_value_base) 'value'

from cte_interval_1 i1
join cte_interval_1 i2        on i1.object_name = i2.object_name
                            and i1.counter_name = i2.counter_name
                            and i1.counter_name_base = i2.counter_name_base
                            and i1.instance_name = i2.instance_name
                            
-- Per Sec
;with cte_interval_1
as
(   
    select 
          object_name
        , counter_name
        , instance_name
        , cntr_value              
        , sysdatetime()          as 'ts'
    from sys.dm_os_performance_counters
    where cntr_type = 272696576
)
, cte_interval_2
as
(
    select 
          object_name
        , counter_name
        , instance_name
        , cntr_value              
        , sysdatetime()          as 'ts'
    from sys.dm_os_performance_counters
    where cntr_type = 272696576
)
select
    i1.object_name
    , i1.counter_name
    , i1.instance_name
    , concat('(', i2.cntr_value, ' - ', i1.cntr_value, ') / datediff(second, ''', i1.ts, ''', ''', i2.ts, ''')') as 'formula'
    , cast((i2.cntr_value - i1.cntr_value) as decimal(28, 0)) / iif(datediff(second, i1.ts, i2.ts) = 0, 1, datediff(second, i1.ts, i2.ts)) 'value'

from cte_interval_1 i1
join cte_interval_1 i2        on i1.object_name = i2.object_name
                            and i1.counter_name = i2.counter_name
                            and i1.instance_name = i2.instance_name
