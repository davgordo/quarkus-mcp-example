# Quarkus MCP Example

This repository demonstrates a simple **Model Context Protocol (MCP)** integration built with **Quarkus**. The goal is to provide a minimal but realistic example of using MCP tools from a Quarkus application to interact with external capabilities—in this case, a PostgreSQL-backed tool.

This project was built with a few specific goals in mind:

* **Prove MCP works on a fully open-source stack.**  
  Many MCP examples assume access to proprietary frontier models. This example intentionally avoids that requirement. The stack here uses open tooling end-to-end: Quarkus, PostgreSQL, and an open model served through **vLLM**.

* **Demonstrate MCP over `streamable-http`.**  
  The MCP server in this project uses the `streamable-http` transport rather than stdio or WebSocket transports. This makes the example closer to how MCP services are typically deployed in real systems (containerized services communicating over HTTP).

* **Show a model configuration that reliably handles MCP tool calls.**  
  Not every open model behaves well with heavy tool use. During development I encountered multiple models that produced malformed tool calls or parsing errors when used with MCP. The configuration in this repository uses a model that behaves consistently when invoked through **vLLM** and LangChain4j.

* **Make the example easy to run locally.**  
  In my environment the LLM is hosted on an **OpenShift lab cluster**, but nothing in this repository requires that setup. Readers can run the example locally by starting their own vLLM instance and adjusting a few configuration parameters. The included manifests and configuration values show the parameters used in my lab environment and can be used as a reference when setting up a local vLLM server.

The intent is not to provide a full production architecture, but rather a **clear, reproducible starting point** for experimenting with MCP using Quarkus and open-source components.

## Why MCP?

Traditional LLM tool integration typically requires the application developer to wire tools directly into the model runtime. In practice this means:

- tools must be defined inside the application that hosts the model
- tool APIs are tightly coupled to the LLM framework being used
- exposing tools across services requires custom glue code

The **Model Context Protocol (MCP)** introduces a simple standard interface that allows tools to be exposed as independent services. Instead of embedding tools inside the model runtime, MCP allows an application to call tools through a standard protocol. This separation keeps the tool implementation, the application logic, and the model runtime loosely coupled while still allowing the model to dynamically invoke external capabilities.

## Architecture

This example consists of the following components:

- **MCP Server** - a Quarkus service exposing a PostgreSQL query tool via MCP
- **Postgres Server Instance** - serves as the example database
- **MCP Client** - a Quarkus application using LangChain4j to call the MCP tool
- **LLM** - a vLLM-hosted model capable of generating MCP tool calls

The MCP server and MCP client are implemented as separate Quarkus applications within this repository.

## Prerequisites

You will need the following installed:

- Java 17+
- Maven
- Quarkus CLI
- Podman (or Docker)
- `psql` (PostgreSQL client)

Optional (only required for the OpenShift vLLM deployment):

- `oc` CLI
- Access to a GPU-enabled OpenShift cluster
- 24G vRAM recommended for the suggested Qwen model

You can also run a model locally and point the MCP client to a local URL with environment variables `OPENAI_BASE_URL` and `OPENAI_MODEL_NAME`.

## Setting up the database

Export environment variables for the database connection:

```bash
export DB_USER=demo
export DB_PASSWORD=demo
export DB_NAME=demo
```

Start a local PostgreSQL container:

```bash
podman run --replace \
  --name postgres-demo \
  -e POSTGRES_USER=$DB_USER \
  -e POSTGRES_PASSWORD=$DB_PASSWORD \
  -e POSTGRES_DB=$DB_NAME \
  -p 5432:5432 \
  -v pgdata-demo:/var/lib/postgresql/data \
  -d postgres:16
```

Wait a few seconds for the database to initialize.

Load the example schema and demo data:

```bash
psql postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME -f example-schema.sql
```

## Running the MCP server

Build the Quarkus app

```bash
mvn clean install
```

Ensure the database environment variables are still set:

```bash
export DB_USER=demo
export DB_PASSWORD=demo
export DB_NAME=demo
```

Run the MCP server

```bash
quarkus run
```

The MCP server will start on `http://localhost:8080`.

## Running the LLM in OpenShift

This example requires a model capable of reliably generating tool calls. The provided manifest deploys **Qwen2.5-14B-Instruct-AWQ**, which works well with MCP when served through vLLM.

Ensure the namespace exists:

```bash
oc create namespace llm
```

Export your Hugging Face token:

```bash
export HF_TOKEN=<your-huggingface-token>
```

Then create the secret in your namespace:

```bash
oc create secret generic huggingface-token --from-literal=token=$HF_TOKEN -n llm
```

Apply the manifest to a cluster with GPU-enabled nodes

```bash
oc apply -f qwen-25-14b-tools.yaml -n llm
```

You may need to wait up to 15 minutes for the LLM to start.

## Running the MCP client

Build the Quarkus app

```bash
mvn clean install
```

Export environment variables for the MCP server and LLM endpoint:

```bash
export MCP_PG_QUERY_URL=http://localhost:8080/mcp
export OPENAI_BASE_URL=https://qwen-llm.apps.cluster.example.com/v1
export OPENAI_MODEL_NAME=qwen25-14b-tools
```

Run the MCP client in Quarkus dev mode

```bash
quarkus dev
```

## Trying the example

Once both services are running (the MCP server and the chat client), you can interact with the model directly through the **Quarkus Dev UI**.

Open the chat interface in your browser:

```
http://localhost:8081/q/dev-ui/quarkus-langchain4j-core/chat
```

This page is provided by the `quarkus-langchain4j` extension and allows you to send prompts to the configured model while the application is running in **dev mode**.

The chat interface will invoke the model and allow it to call the MCP tool exposed by the server. In this example, the tool executes SQL queries against the PostgreSQL demo database.

You can try prompts such as:

```
List the projects in the system
```

```
Show the customers and their annual revenue
```

```
What invoices exist and what are their totals?
```

The model will decide when to call the MCP tool, execute the query, and incorporate the results into the response.

Below are examples of the chat interaction in the Dev UI.

### Chat Example

When the model determines that a database query is needed, it will call the MCP tool exposed by the server and incorporate the results into its response.

![Chat example](media/chat-1.png)

![Chat example scrolled](media/chat-2.png)