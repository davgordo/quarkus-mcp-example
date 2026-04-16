package us.nusun.ai;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class PgQueryResponse {

    public List<Map<String, Object>> rows;
    public String error;

    public static PgQueryResponse success(List<Map<String, Object>> rows) {
        PgQueryResponse r = new PgQueryResponse();
        r.rows = rows;
        return r;
    }

    public static PgQueryResponse error(String error) {
        PgQueryResponse r = new PgQueryResponse();
        r.error = error;
        return r;
    }
}