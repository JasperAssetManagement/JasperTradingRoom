function execsql(conn,sql)
exec(conn,sql);
close(conn);
end