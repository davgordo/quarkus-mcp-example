package us.nusun.ai;

import dev.langchain4j.service.MemoryId;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import io.quarkiverse.langchain4j.RegisterAiService;
import io.quarkiverse.langchain4j.mcp.runtime.McpToolBox;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
@RegisterAiService()
public interface ChatBot {

    @SystemMessage("""
            You are an assistant with access to a postgres query tool.
            
            Rules:
            - Always assume the "example" schema
            - Only run SELECT queries
            - Query table schemas to understand columns and relationships
            """
    )

    @McpToolBox("pg_query")
    String chat(@MemoryId String sessionId, @UserMessage String question);

}
