select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'registros_demo'
order by ordinal_position;

select policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename = 'registros_demo'
order by policyname;