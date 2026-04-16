package us.nusun.ai;

import io.quarkiverse.mcp.server.McpLog;
import io.quarkiverse.mcp.server.Tool;
import io.quarkiverse.mcp.server.ToolArg;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

@ApplicationScoped
public class PostgresTools {

    @Inject
    PostgresService postgres;

    @Tool(  name = "pg_query",
            description = "Run a read-only SELECT or WITH query against Postgres and return up to 100 rows.")
    public PgQueryResponse query(@ToolArg(description = "SQL SELECT or WITH statement") String sql, McpLog log) {
        log.info("%s", sql);
        try {
            return PgQueryResponse.success(postgres.query(sql));
        } catch (Exception e) {
            String msg = e.getMessage();
            log.error("%s", msg);
            return PgQueryResponse.error(msg);
        }
    }

}