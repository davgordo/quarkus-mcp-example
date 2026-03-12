package us.nusun.ai;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.Date;


@ApplicationScoped
public class PostgresService {

    @Inject
    DataSource dataSource;

    public List<Map<String, Object>> query(String sql) throws Exception {
        final int maxRows = 100;

        if (sql == null || sql.isBlank()) {
            throw new IllegalArgumentException("Missing SQL.");
        }

        String normalized = sql.stripLeading()
                .toLowerCase(Locale.ROOT)
                .replace("\\\"", "\"");

        if (!(normalized.startsWith("select") || normalized.startsWith("with"))) {
            throw new IllegalArgumentException("Only SELECT/CTE queries are allowed.");
        }

        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setMaxRows(maxRows);

            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String, Object>> rows = new ArrayList<>();
                ResultSetMetaData md = rs.getMetaData();
                int cols = md.getColumnCount();

                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= cols; i++) {
                        String column = md.getColumnLabel(i);
                        Object value = rs.getObject(i);
                        row.put(column, toSafeValue(value));
                    }
                    rows.add(row);
                }

                return rows;
            }
        }
    }

    private Object toSafeValue(Object value) throws SQLException {
        if (value == null) {
            return null;
        }

        if (value instanceof String
                || value instanceof Integer
                || value instanceof Long
                || value instanceof Double
                || value instanceof Float
                || value instanceof Boolean
                || value instanceof BigDecimal
                || value instanceof Short
                || value instanceof Byte
                || value instanceof UUID) {
            return value;
        }

        if (value instanceof Timestamp ts) {
            return ts.toInstant().toString();
        }

        if (value instanceof Date d) {
            return d.toString();
        }

        if (value instanceof OffsetDateTime odt) {
            return odt.toString();
        }

        if (value instanceof LocalDateTime ldt) {
            return ldt.toString();
        }

        if (value instanceof LocalDate ld) {
            return ld.toString();
        }

        if (value instanceof LocalTime lt) {
            return lt.toString();
        }

        if (value instanceof Array array) {
            Object arr = array.getArray();
            if (arr instanceof Object[] objArray) {
                return Arrays.asList(objArray);
            }
            return String.valueOf(arr);
        }

        if (value instanceof SQLXML xml) {
            return xml.getString();
        }

        if (value instanceof Clob clob) {
            return clob.getSubString(1, (int) clob.length());
        }

        if (value instanceof Blob blob) {
            return Base64.getEncoder().encodeToString(blob.getBytes(1, (int) blob.length()));
        }

        return String.valueOf(value);
    }
}