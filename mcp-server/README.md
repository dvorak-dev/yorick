# Funeral Notices MCP Server

A Model Context Protocol (MCP) server that provides access to funeral notices data through AI assistants.

## Features

- **Search Funeral Notices**: Full-text search using Elasticsearch
- **Get Specific Notice**: Retrieve individual funeral notices by ID
- **List Notices**: Paginated listing with filtering and sorting
- **Direct Database Access**: Fast queries to PostgreSQL and Elasticsearch

## Tools Available

### `search_funeral_notices`
Search funeral notices by name or notice text. A partial surname such as `Garc` matches García and Garcé, not Gari or Gara. One extra surname still returns the notice. Accents are ignored, and particles such as `de` and `vda` are ignored. Results include `hash_id` so `get_funeral_notice` can open one.

At least one of `query`, `full_name`, or `content` is required.

**Parameters:**
- `query` (optional): Search the name and the notice text. Ignored for the name when `full_name` is also sent.
- `full_name` (optional): Name search
- `content` (optional): Words from the notice text. `mosqueteras` does not match `mosqueteros`.
- `date_from` (optional): Start date (YYYY-MM-DD)
- `date_to` (optional): End date (YYYY-MM-DD)
- `page` (optional): Page number (default: 1)
- `limit` (optional): Results per page (default: 50, max: 50)

### `get_funeral_notice`
Retrieve a specific funeral notice by hash_id.

**Parameters:**
- `hash_id` (required): Funeral notice hash_id

### `list_funeral_notices`
List funeral notices with pagination and filtering.

**Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 50)
- `date_from` (optional): Start date (YYYY-MM-DD)
- `date_to` (optional): End date (YYYY-MM-DD)
- `order_by` (optional): Sort field (published_on, full_name, created_at)
- `order_direction` (optional): Sort direction (asc, desc)

## Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure environment:**
   ```bash
   cp env.example .env
   # Edit .env with your database credentials
   ```

3. **Start the server:**

   **Option 1: HTTP Transport (recommended for testing)**
   ```bash
   # Development mode with HTTP transport
   npm run dev:http
   ```
   Access at: `http://localhost:3001/mcp`

   **Option 2: Stdio Transport (for AI assistant integration)**
   ```bash
   # Development mode with auto-reload
   npm run dev
   
   # Production mode
   npm start
   ```

## Environment Variables

- `DATABASE_URL`: PostgreSQL connection string
- `ELASTICSEARCH_URL`: Elasticsearch endpoint
- `ELASTICSEARCH_USERNAME`: Elasticsearch username (optional)
- `ELASTICSEARCH_PASSWORD`: Elasticsearch password (optional)
- `ELASTICSEARCH_INDEX`: Elasticsearch index name (default: yorick_production_funeral_notices)
- `MCP_PORT`: HTTP server port (default: 3001)
- `NODE_ENV`: Environment (development/production)
- `LOG_LEVEL`: Logging level (info/debug/error)

## Usage

### With AI Assistants

The MCP server can be used with any AI assistant that supports the Model Context Protocol, such as:

- Claude Desktop
- Anthropic's Claude
- Other MCP-compatible tools

### With MCP Inspector

For testing and debugging:

1. Start the MCP Inspector:
   ```bash
   cd inspector && npm start
   ```

2. Open `http://localhost:3000` in your browser

3. Add your server:
   - Transport: **HTTP**
   - URL: `http://localhost:3001/mcp`

### Direct HTTP Access

The server exposes a REST API at `http://localhost:3001/mcp` for direct testing:

```bash
# Initialize a session
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {"tools": {}},
      "clientInfo": {"name": "test-client", "version": "1.0.0"}
    }
  }'
```

## Development

### Project Structure
```
src/
├── index.js          # Main server entry point
├── config/
│   └── database.js   # Database connections
└── tools/
    ├── search.js     # Search functionality
    ├── get.js        # Get specific notice
    └── list.js       # List notices with pagination
```

### Adding New Tools

1. Create a new tool file in `src/tools/`
2. Export the tool function
3. Register it in `src/index.js`
4. Update this README with tool documentation

## Production Deployment

### Docker Images

The MCP server supports both development and production Docker images:

- **Development**: `Dockerfile.dev` - Includes hot-reloading and development dependencies
- **Production**: `Dockerfile.prod` - Multi-stage build with minimal Alpine image

### GitHub Actions

Docker images are automatically built and pushed via GitHub Actions:

- **Registry**: `ghcr.io/{repository}-mcp`
- **Tags**: `pr-{number}`, commit SHA, `main`, `latest`
- **Build context**: `./mcp-server`
- **Production file**: `Dockerfile.prod`

### Health Checks

The production image includes health checks that verify the MCP server is responding correctly.

## Security

- Database connections use connection pooling
- Input validation on all parameters using Zod schemas
- Error handling with sanitized messages
- CORS configured for browser-based clients
- Session management for secure communication
- Non-root user execution in production containers

## License

MIT License - see LICENSE file for details. 