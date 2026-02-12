package demo.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.javalin.Javalin;
import io.javalin.http.Context;
import org.jooq.DSLContext;
import org.jooq.Field;
import org.jooq.SQLDialect;
import org.jooq.Table;
import org.jooq.impl.DSL;
import org.jooq.impl.SQLDataType;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.time.Instant;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ChatServer {
  // jOOQ table + columns
  private static final Table<?> MESSAGES = DSL.table("messages");
  private static final Field<Long> ID = DSL.field("id", Long.class);
  private static final Field<String> TEXT = DSL.field("text", String.class);
  private static final Field<String> CREATED_AT = DSL.field("created_at", String.class);
  private static final Field<String> POD_NAME = DSL.field("pod_name", String.class);
  private static final Field<String> NODE_NAME = DSL.field("node_name", String.class);
  private static final Field<String> COMMAND = DSL.field("command", String.class);
  private static final Field<String> COMMAND_OUTPUT = DSL.field("command_output", String.class);

  private final String podName;
  private final String nodeName;
  private final String jdbcUrl;
  private final Map<String, String> commands;

  public ChatServer(AppConfig config) {
    // Immutable runtime config
    this.podName = config.podName();
    this.nodeName = config.nodeName();
    this.jdbcUrl = config.jdbcUrl();
    this.commands = loadCommands(config.commandsFile());
  }

  public static void main(String[] args) throws Exception {
    // Bootstrap config + schema
    AppConfig appConfig = AppConfig.fromEnv();
    ChatServer server = new ChatServer(appConfig);
    server.ensureSchema();

    // HTTP server + routes
    Javalin app = Javalin.create(javalinConfig -> {
      javalinConfig.staticFiles.add("/static");
      javalinConfig.showJavalinBanner = false;
    });

    app.get("/", ctx -> ctx.redirect("/index.html"));
    app.get("/api/healthz", ctx -> ctx.json(Map.of("status", "ok")));
    app.get("/api/messages", server::handleMessages);
    app.post("/api/message", server::handleMessage);

    app.start(appConfig.port());
    System.out.println("Chat server listening on port " + appConfig.port());
  }

  private void handleMessages(Context ctx) {
    // Read latest messages
    try {
      List<Message> messages = withDsl(dsl ->
          dsl.select(ID, TEXT, CREATED_AT, POD_NAME, NODE_NAME, COMMAND, COMMAND_OUTPUT)
              .from(MESSAGES)
              .orderBy(ID.desc())
              .limit(50)
              .fetch(record -> new Message(
                  record.get(ID),
                  record.get(TEXT),
                  record.get(CREATED_AT),
                  record.get(POD_NAME),
                  record.get(NODE_NAME),
                  record.get(COMMAND),
                  record.get(COMMAND_OUTPUT)
              ))
      );

      Collections.reverse(messages);
      ctx.json(messages);
    } catch (Exception ex) {
      ctx.status(500).json(new ApiError("db_error", ex.getMessage()));
    }
  }

  private void handleMessage(Context ctx) {
    // Parse input payload
    IncomingMessage input;
    try {
      input = ctx.bodyAsClass(IncomingMessage.class);
    } catch (Exception ex) {
      ctx.status(400).json(new ApiError("bad_request", "Invalid JSON"));
      return;
    }

    String text = input.text() == null ? "" : input.text().trim();
    if (text.isEmpty()) {
      ctx.status(400).json(new ApiError("bad_request", "Message is empty"));
      return;
    }

    CommandResult commandResult = maybeExecuteCommand(text);
    String createdAt = Instant.now().toString();

    // Insert new message
    try {
      withDsl(dsl -> dsl.insertInto(MESSAGES)
          .columns(TEXT, CREATED_AT, POD_NAME, NODE_NAME, COMMAND, COMMAND_OUTPUT)
          .values(text, createdAt, podName, nodeName, commandResult.command(), commandResult.output())
          .execute()
      );
    } catch (Exception ex) {
      ctx.status(500).json(new ApiError("db_error", ex.getMessage()));
      return;
    }

    ctx.json(new Message(
        null,
        text,
        createdAt,
        podName,
        nodeName,
        commandResult.command(),
        commandResult.output()
    ));
  }

  private CommandResult maybeExecuteCommand(String text) {
    // Commands start with a slash
    if (!text.startsWith("/")) {
      return new CommandResult(null, null);
    }

    String withoutSlash = text.substring(1);
    String[] parts = withoutSlash.split("\\s+", 2);
    String commandName = parts[0].trim();
    String args = parts.length > 1 ? parts[1] : "";

    // Handle /help locally
    if ("help".equalsIgnoreCase(commandName)) {
      return buildHelpResult();
    }

    // Handle /clear locally
    if ("clear".equalsIgnoreCase(commandName)) {
      return clearDatabase();
    }

    String commandTemplate = commands.get(commandName);
    if (commandTemplate == null) {
      return new CommandResult(commandName, "Unknown command: /" + commandName + " (try /help)");
    }

    String resolved = commandTemplate
        .replace("${ARG}", escapeForShell(args))
        .replace("${POD_NAME}", escapeForShell(podName))
        .replace("${NODE_NAME}", escapeForShell(nodeName));

    try {
      Process process = new ProcessBuilder("/bin/sh", "-c", resolved).start();
      byte[] stdout = readAll(process.getInputStream());
      byte[] stderr = readAll(process.getErrorStream());
      int code = process.waitFor();

      String output = new String(stdout, StandardCharsets.UTF_8).trim();
      if (!output.isEmpty()) {
        return new CommandResult(commandName, output);
      }

      String err = new String(stderr, StandardCharsets.UTF_8).trim();
      if (!err.isEmpty()) {
        return new CommandResult(commandName, err);
      }

      return new CommandResult(commandName, "Exit code " + code);
    } catch (Exception ex) {
      return new CommandResult(commandName, "Command failed: " + ex.getMessage());
    }
  }

  private CommandResult buildHelpResult() {
    try {
      ObjectMapper mapper = new ObjectMapper();
      Map<String, String> podCmds = new HashMap<>();
      
      // Pod commands section only
      for (String cmd : commands.keySet()) {
        podCmds.put("/" + cmd, "Run '" + cmd + "' command");
      }
      
      String jsonOutput = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(podCmds);
      return new CommandResult("help", jsonOutput);
    } catch (Exception ex) {
      return new CommandResult("help", "Error generating help: " + ex.getMessage());
    }
  }

  private CommandResult clearDatabase() {
    try {
      withDslVoid(dsl -> dsl.deleteFrom(MESSAGES).execute());
      return new CommandResult("clear", "Database cleared successfully");
    } catch (Exception ex) {
      return new CommandResult("clear", "Error clearing database: " + ex.getMessage());
    }
  }

  private void ensureSchema() throws Exception {
    // Ensure the messages table exists
    withDslVoid(dsl -> dsl.createTableIfNotExists(MESSAGES)
      .column(ID, SQLDataType.BIGINT.identity(true))
      .column(TEXT, SQLDataType.VARCHAR(2048).nullable(false))
      .column(CREATED_AT, SQLDataType.VARCHAR(64).nullable(false))
      .column(POD_NAME, SQLDataType.VARCHAR(128).nullable(false))
      .column(NODE_NAME, SQLDataType.VARCHAR(128).nullable(false))
      .column(COMMAND, SQLDataType.VARCHAR(128))
      .column(COMMAND_OUTPUT, SQLDataType.CLOB)
      .constraints(DSL.constraint("pk_messages").primaryKey(ID))
      .execute()
    );
  }

  private <T> T withDsl(ThrowingFunction<DSLContext, T> block) throws Exception {
    try (Connection connection = DriverManager.getConnection(jdbcUrl)) {
      DSLContext dsl = DSL.using(connection, SQLDialect.SQLITE);
      return block.apply(dsl);
    }
  }

  private void withDslVoid(ThrowingConsumer<DSLContext> block) throws Exception {
    try (Connection connection = DriverManager.getConnection(jdbcUrl)) {
      DSLContext dsl = DSL.using(connection, SQLDialect.SQLITE);
      block.accept(dsl);
    }
  }

  private static String env(String key, String fallback) {
    String value = System.getenv(key);
    return (value == null || value.isBlank()) ? fallback : value;
  }

  private static Map<String, String> loadCommands(String filePath) {
    Path path = Path.of(filePath);
    if (!Files.exists(path)) {
      return new HashMap<>();
    }

    Map<String, String> map = new HashMap<>();
    try {
      for (String line : Files.readAllLines(path)) {
        String trimmed = line.trim();
        if (trimmed.isEmpty() || trimmed.startsWith("#")) {
          continue;
        }
        String[] parts = trimmed.split("=", 2);
        if (parts.length == 2) {
          map.put(parts[0].trim(), parts[1].trim());
        }
      }
    } catch (IOException ignored) {
      return new HashMap<>();
    }

    return map;
  }

  private static byte[] readAll(InputStream inputStream) throws IOException {
    try (inputStream) {
      return inputStream.readAllBytes();
    }
  }

  private static String escapeForShell(String value) {
    return value.replace("\"", "\\\"");
  }

  @FunctionalInterface
  private interface ThrowingFunction<T, R> {
    R apply(T value) throws Exception;
  }

  @FunctionalInterface
  private interface ThrowingConsumer<T> {
    void accept(T value) throws Exception;
  }

  record AppConfig(int port, String podName, String nodeName, String jdbcUrl, String commandsFile) {
    static AppConfig fromEnv() {
      return new AppConfig(
          Integer.parseInt(env("PORT", "8080")),
          env("POD_NAME", "unknown-pod"),
          env("NODE_NAME", "unknown-node"),
          env("RQLITE_JDBC_URL", "jdbc:rqlite:http://localhost:4001"),
          env("COMMANDS_FILE", "/config/commands.conf")
      );
    }
  }

  record IncomingMessage(String text) {}

  record Message(Long id, String text, String createdAt, String podName, String nodeName, String command, String commandOutput) {}

  record ApiError(String error, String message) {}

  record CommandResult(String command, String output) {}
}

