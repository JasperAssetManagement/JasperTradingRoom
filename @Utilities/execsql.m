function execsql(conn,sql)
ping(conn);
exec(conn,sql);
close(conn);
end