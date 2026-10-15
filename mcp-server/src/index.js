#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/server";
import { NodeStreamableHTTPServerTransport } from "@modelcontextprotocol/node";
import { searchFuneralNotices } from "./tools/search.js";
import { getFuneralNotice } from "./tools/get.js";
import { listFuneralNotices } from "./tools/list.js";
import { z } from "zod";
import express from 'express';
import cors from 'cors';
import { randomUUID } from 'node:crypto';

// Load environment variables
import dotenv from 'dotenv';
dotenv.config();

const app = express();
app.use(express.json());

// Add CORS middleware for browser-based clients
app.use(cors({
  origin: '*', // Configure appropriately for production
  exposedHeaders: ['Mcp-Session-Id'],
  allowedHeaders: ['Content-Type', 'mcp-session-id'],
}));

// Map to store transports by session ID
const transports = {};

// Handle POST requests for client-to-server communication
app.post('/mcp', async (req, res) => {
  // Check for existing session ID
  const sessionId = req.headers['mcp-session-id'];
  let transport;

  if (sessionId && transports[sessionId]) {
    // Reuse existing transport
    transport = transports[sessionId];
  } else {
    // New initialization request
    transport = new NodeStreamableHTTPServerTransport({
      sessionIdGenerator: () => randomUUID(),
      onsessioninitialized: (sessionId) => {
        // Store the transport by session ID
        transports[sessionId] = transport;
      },
      onsessionclosed: (sessionId) => {
        delete transports[sessionId];
      },
    });

    const server = new McpServer({
      name: "funeral-notices-mcp-server",
      version: "1.0.0"
    });

    // Register tools
    server.registerTool(
      "search_funeral_notices",
      {
        title: "Search Funeral Notices",
        description: "Search funeral notices using Elasticsearch full-text search",
        inputSchema: z.object({
          query: z.string().describe("Search query for full name or content"),
          date_from: z.string().optional().describe("Start date filter (YYYY-MM-DD format)"),
          date_to: z.string().optional().describe("End date filter (YYYY-MM-DD format)"),
          limit: z.number().optional().describe("Maximum number of results (default: 50, max: 500)")
        })
      },
      async (args) => {
        return await searchFuneralNotices(args);
      }
    );

    server.registerTool(
      "get_funeral_notice",
      {
        title: "Get Funeral Notice",
        description: "Retrieve a specific funeral notice by hash_id",
        inputSchema: z.object({
          hash_id: z.string().describe("The funeral notice hash_id")
        })
      },
      async (args) => {
        return await getFuneralNotice(args);
      }
    );

    server.registerTool(
      "list_funeral_notices",
      {
        title: "List Funeral Notices",
        description: "List funeral notices with pagination and filtering",
        inputSchema: z.object({
          page: z.number().optional().describe("Page number (default: 1)"),
          limit: z.number().optional().describe("Items per page (default: 50)"),
          date_from: z.string().optional().describe("Start date (YYYY-MM-DD)"),
          date_to: z.string().optional().describe("End date (YYYY-MM-DD)"),
          order_by: z.enum(["published_on", "full_name", "created_at"]).optional().describe("Sort field"),
          order_direction: z.enum(["asc", "desc"]).optional().describe("Sort direction")
        })
      },
      async (args) => {
        return await listFuneralNotices(args);
      }
    );

    // Connect to the MCP server
    await server.connect(transport);
  }

  // Handle the request
  await transport.handleRequest(req, res, req.body);
});

// Handle GET requests for server-to-client notifications via SSE
app.get('/mcp', async (req, res) => {
  const sessionId = req.headers['mcp-session-id'];
  if (!sessionId || !transports[sessionId]) {
    res.status(400).send('Invalid or missing session ID');
    return;
  }
  
  const transport = transports[sessionId];
  await transport.handleRequest(req, res);
});

// Handle DELETE requests for session termination
app.delete('/mcp', async (req, res) => {
  const sessionId = req.headers['mcp-session-id'];
  if (!sessionId || !transports[sessionId]) {
    res.status(400).send('Invalid or missing session ID');
    return;
  }
  
  const transport = transports[sessionId];
  await transport.handleRequest(req, res);
});

// Initialize database connections
import { initializeConnections } from './config/database.js';

// Initialize connections when server starts
initializeConnections().catch(error => {
  console.error('Failed to initialize database connections:', error);
  process.exit(1);
});

// Start the server
const PORT = process.env.MCP_PORT || 3001;
const HOST = process.env.MCP_HOST || '0.0.0.0';
app.listen(PORT, HOST, (error) => {
  if (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
  console.log(`Funeral Notices MCP Server listening on ${HOST}:${PORT}`);
  console.log(`Access the server at: http://${HOST}:${PORT}/mcp`);
}); 