package us.nusun.ai;

import io.quarkiverse.mcp.server.McpLog;
import io.quarkiverse.mcp.server.Tool;
import io.quarkiverse.mcp.server.ToolArg;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.util.List;
import java.util.Map;

@ApplicationScoped
public class PostgresTools {

    @Inject
    PostgresService postgres;

    @Tool(
            name = "pg_query",
            description = "Run a read-only SELECT or WITH query against Postgres and return up to 100 rows."
    )
    public List<Map<String, Object>> query(
            @ToolArg(description = "SQL SELECT or WITH statement") String sql,
            McpLog log
    ) {
        try {
            log.info("%s", sql);
            return postgres.query(sql);
        } catch (Exception e) {
            throw new RuntimeException("pg_query error: " + e.getMessage(), e);
        }
    }
}