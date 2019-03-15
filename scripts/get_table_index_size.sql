if object_id('dbo.get_table_index_size') is not null
begin
	print 'drop proc dbo.get_table_index_size'
    drop proc dbo.get_table_index_size
end

print 'create proc dbo.get_table_index_size'
go	
create proc dbo.get_table_index_size
	@database sysname
as
set nocount on
	
declare @sql varchar(max)
select @sql = 
'use ' + @database + 
';with cte_table
as
(
	select
		t.object_id
		, t.name
		, sum(a.data_pages * 8192) as size_byte
	from sys.tables t
	join sys.partitions p		on t.object_id = p.object_id
	join sys.allocation_units a on p.hobt_id = a.container_id
	where t.type_desc = ''USER_TABLE''
	group by t.object_id, t.name
)
, cte_index
as
(
	select
		i.object_id
		, i.name
		, i.index_id
		, sum(a.data_pages * 8192) as size_byte
	from sys.indexes i
	join sys.partitions p		on i.object_id = p.object_id and i.index_id = p.index_id
	join sys.allocation_units a on p.hobt_id = a.container_id
	where a.data_pages > 0
	group by i.object_id, i.name, i.index_id
)
select
	dense_rank() over (order by t.size_byte desc, t.name)	as ''rank''
	, t.name												as ''table_name''
	, p.rows												as ''table_rows''
	, t.size_byte											as ''table_size_byte''
	, convert(decimal(19, 2), t.size_byte / 1024. / 1024.)	as ''table_size_mb''
	, isnull(i.name, ''Heap'')								as ''index_name''
	, i.index_id											as ''index_id''
	, i.size_byte											as ''index_size_byte''
	, convert(decimal(19, 2), i.size_byte / 1024. / 1024.)	as ''index_size_mb''
from cte_table t
left join cte_index i on t.object_id = i.object_id
left join sys.partitions p on i.object_id = p.object_id and i.index_id = p.index_id
where t.size_byte > 0
order by 1, i.index_id'

create table #temp
(
	rank				int	not null
	, table_name		sysname	not null
	, table_rows		bigint	not null
	, table_size_byte	decimal(19, 2) not null
	, table_size_mb		decimal(19, 2) not null
	, index_name		sysname not null
	, index_id			int not null
	, index_size_byte	decimal(19, 2) not null
	, index_size_mb		decimal(19, 2) not null
)

insert #temp
exec(@sql)

select * from #temp

return 0
go

/*

exec get_table_index_size 'louie'

*/
