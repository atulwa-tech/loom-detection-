/**
 * LOOM MONITORING SYSTEM - BACKEND SERVER
 * 
 * Node.js/Express API server that communicates with ESP32
 * Provides REST API proxy and WebSocket real-time updates
 * 
 * Features:
 * - REST API endpoints (proxy to ESP32)
 * - WebSocket server for real-time data streaming
 * - SQLite database for logging and statistics
 * - Error handling and reconnection logic
 * - CORS support for Flutter frontend
 */

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const axios = require('axios');
const WebSocket = require('ws');
const http = require('http');
const morgan = require('morgan');
const helmet = require('helmet');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize WebSocket server
const wss = new WebSocket.Server({ server });

// ==================== CONFIGURATION ====================
const CONFIG = {
  PORT: process.env.PORT || 3000,
  ESP32_URL: process.env.ESP32_URL || 'http://192.168.1.100:8080',
  NODE_ENV: process.env.NODE_ENV || 'development',
  DB_PATH: process.env.DB_PATH || './data/loom.db',
};

console.log('╔════════════════════════════════════════╗');
console.log('║   LOOM MONITORING BACKEND SERVER       ║');
console.log('╠════════════════════════════════════════╣');
console.log(`║ Port: ${CONFIG.PORT.toString().padEnd(36)}║`);
console.log(`║ ESP32: ${CONFIG.ESP32_URL.padEnd(30)}║`);
console.log(`║ Mode: ${CONFIG.NODE_ENV.padEnd(34)}║`);
console.log('╚════════════════════════════════════════╝\n');

// ==================== MIDDLEWARE ====================

// Security headers
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: function(origin, callback) {
    // Allow requests from Flutter frontend and local development
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:8080',
      'http://localhost:5000',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:8080',
      'http://192.168.1.*',
      'chrome-extension://*'
    ];
    
    if (!origin || allowedOrigins.some(allowed => 
      allowed === origin || allowed.includes('*')
    )) {
      callback(null, true);
    } else {
      callback(new Error('CORS not allowed'), false);
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parser
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Logging
app.use(morgan(':method :url :status :response-time ms'));

// ==================== DATABASE ====================

const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database(CONFIG.DB_PATH, (err) => {
  if (err) {
    console.error('❌ Database connection error:', err);
  } else {
    console.log('✓ Database connected');
    initializeDatabase();
  }
});

function initializeDatabase() {
  // Create tables if they don't exist
  db.serialize(() => {
    // System logs table
    db.run(`
      CREATE TABLE IF NOT EXISTS system_logs (
        id TEXT PRIMARY KEY,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        endpoint TEXT,
        method TEXT,
        status_code INTEGER,
        response_time_ms INTEGER,
        esp32_status TEXT,
        error TEXT
      )
    `);

    // Sensor data table
    db.run(`
      CREATE TABLE IF NOT EXISTS sensor_data (
        id TEXT PRIMARY KEY,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        hall_sensors TEXT,
        temperature REAL,
        loom_length REAL,
        motors TEXT
      )
    `);

    // Events table
    db.run(`
      CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        event_type TEXT,
        event_data TEXT,
        severity TEXT
      )
    `);

    console.log('✓ Database tables initialized');
  });
}

// ==================== UTILITY FUNCTIONS ====================

/**
 * Make request to ESP32
 */
async function requestESP32(endpoint, method = 'GET', data = null) {
  const startTime = Date.now();
  const url = `${CONFIG.ESP32_URL}${endpoint}`;
  
  try {
    const config = {
      method,
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 5000,
    };
    
    if (data) {
      config.data = data;
    }
    
    const response = await axios(config);
    const responseTime = Date.now() - startTime;
    
    // Log successful request
    logRequest(endpoint, method, 200, responseTime, 'success', null);
    
    return {
      success: true,
      data: response.data,
      timestamp: new Date().toISOString(),
      responseTime,
    };
  } catch (error) {
    const responseTime = Date.now() - startTime;
    const errorMsg = error.response?.data?.error || error.message;
    
    // Log failed request
    logRequest(endpoint, method, error.response?.status || 500, responseTime, 'error', errorMsg);
    
    return {
      success: false,
      error: errorMsg,
      timestamp: new Date().toISOString(),
      responseTime,
    };
  }
}

/**
 * Log request to database
 */
function logRequest(endpoint, method, statusCode, responseTime, esp32Status, error) {
  const id = uuidv4();
  db.run(
    'INSERT INTO system_logs (id, endpoint, method, status_code, response_time_ms, esp32_status, error) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [id, endpoint, method, statusCode, responseTime, esp32Status, error || null],
    (err) => {
      if (err) console.error('Error logging request:', err);
    }
  );
}

/**
 * Log sensor data
 */
function logSensorData(data) {
  const id = uuidv4();
  db.run(
    'INSERT INTO sensor_data (id, hall_sensors, temperature, loom_length, motors) VALUES (?, ?, ?, ?, ?)',
    [
      id,
      JSON.stringify(data.hallSensors || []),
      data.temperature || 0,
      data.loomLength || 0,
      JSON.stringify(data.motors || []),
    ],
    (err) => {
      if (err) console.error('Error logging sensor data:', err);
    }
  );
}

/**
 * Broadcast to all WebSocket clients
 */
function broadcastToClients(type, data) {
  const message = JSON.stringify({
    type,
    data,
    timestamp: new Date().toISOString(),
  });
  
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

/**
 * Create event
 */
function createEvent(eventType, eventData, severity = 'info') {
  const id = uuidv4();
  db.run(
    'INSERT INTO events (id, event_type, event_data, severity) VALUES (?, ?, ?, ?)',
    [id, eventType, JSON.stringify(eventData), severity],
    (err) => {
      if (err) console.error('Error creating event:', err);
      
      // Broadcast event to all connected clients
      broadcastToClients('event', {
        id,
        eventType,
        eventData,
        severity,
        timestamp: new Date().toISOString(),
      });
    }
  );
}

// ==================== ROUTES ====================

// Health check
app.get('/health', async (req, res) => {
  try {
    const esp32Response = await requestESP32('/health');
    res.json({
      status: 'ok',
      backend: {
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        environment: CONFIG.NODE_ENV,
      },
      esp32: esp32Response.data,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      error: error.message,
    });
  }
});

// ========== API PROXY ENDPOINTS ==========

/**
 * GET /api/status
 * Fetch current system status from ESP32
 */
app.get('/api/status', async (req, res) => {
  const response = await requestESP32('/api/status');
  
  if (response.success) {
    // Log sensor data for analytics
    logSensorData(response.data);
    
    res.json({
      ...response.data,
      backend: {
        receivedAt: response.timestamp,
        responseTime: response.responseTime,
      },
    });
  } else {
    res.status(503).json({
      error: 'Unable to fetch status from ESP32',
      details: response.error,
      timestamp: response.timestamp,
    });
  }
});

/**
 * POST /api/motor/control
 * Control a specific motor
 * Body: { motorId: 0-9, state: true|false }
 */
app.post('/api/motor/control', async (req, res) => {
  const { motorId, state } = req.body;
  
  // Validate input
  if (motorId === undefined || state === undefined) {
    return res.status(400).json({
      error: 'Missing required fields: motorId, state',
    });
  }
  
  if (motorId < 0 || motorId > 9) {
    return res.status(400).json({
      error: 'Invalid motorId (must be 0-9)',
    });
  }
  
  const response = await requestESP32('/api/motor/control', 'POST', {
    motorId,
    state,
  });
  
  if (response.success) {
    // Create event for motor control
    createEvent('motor_control', { motorId, state, action: state ? 'ON' : 'OFF' });
    
    // Broadcast to WebSocket clients
    broadcastToClients('motor_control', {
      motorId,
      state,
      timestamp: response.timestamp,
    });
    
    res.json({
      success: true,
      motor: motorId,
      state,
      timestamp: response.timestamp,
      responseTime: response.responseTime,
    });
  } else {
    res.status(503).json({
      error: 'Unable to control motor',
      details: response.error,
      timestamp: response.timestamp,
    });
  }
});

/**
 * POST /api/loom/release
 * Release loom fabric for specified length
 * Body: { lengthCm: number }
 */
app.post('/api/loom/release', async (req, res) => {
  const { lengthCm } = req.body;
  
  // Validate input
  if (!lengthCm || lengthCm <= 0 || lengthCm > 50) {
    return res.status(400).json({
      error: 'Invalid lengthCm (must be between 0.1 and 50)',
    });
  }
  
  const response = await requestESP32('/api/loom/release', 'POST', {
    lengthCm,
  });
  
  if (response.success) {
    // Create event for loom release
    createEvent('loom_release', { lengthCm }, 'info');
    
    // Broadcast to WebSocket clients
    broadcastToClients('loom_release', {
      lengthCm,
      timestamp: response.timestamp,
    });
    
    res.json({
      success: true,
      lengthReleased: lengthCm,
      timestamp: response.timestamp,
      responseTime: response.responseTime,
    });
  } else {
    res.status(503).json({
      error: 'Unable to release loom',
      details: response.error,
      timestamp: response.timestamp,
    });
  }
});

/**
 * GET /api/history
 * Get system history and statistics
 */
app.get('/api/history', async (req, res) => {
  const response = await requestESP32('/api/history');
  
  if (response.success) {
    res.json({
      ...response.data,
      backend: {
        receivedAt: response.timestamp,
        responseTime: response.responseTime,
      },
    });
  } else {
    res.status(503).json({
      error: 'Unable to fetch history from ESP32',
      details: response.error,
      timestamp: response.timestamp,
    });
  }
});

// ========== DATABASE QUERY ENDPOINTS ==========

/**
 * GET /api/logs
 * Get recent system logs
 * Query: ?limit=100&offset=0
 */
app.get('/api/logs', (req, res) => {
  const limit = parseInt(req.query.limit) || 100;
  const offset = parseInt(req.query.offset) || 0;
  
  db.all(
    'SELECT * FROM system_logs ORDER BY timestamp DESC LIMIT ? OFFSET ?',
    [limit, offset],
    (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ logs: rows || [], count: rows.length });
    }
  );
});

/**
 * GET /api/events
 * Get recent events
 * Query: ?limit=100&offset=0&type=motor_control
 */
app.get('/api/events', (req, res) => {
  const limit = parseInt(req.query.limit) || 100;
  const offset = parseInt(req.query.offset) || 0;
  const type = req.query.type;
  
  let query = 'SELECT * FROM events';
  const params = [];
  
  if (type) {
    query += ' WHERE event_type = ?';
    params.push(type);
  }
  
  query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
  params.push(limit, offset);
  
  db.all(query, params, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ events: rows || [], count: rows.length });
  });
});

/**
 * GET /api/statistics
 * Get analytics and statistics
 */
app.get('/api/statistics', (req, res) => {
  db.serialize(() => {
    let stats = {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      averageResponseTime: 0,
      sensorReadings: 0,
      events: 0,
    };
    
    // Get total and successful requests
    db.get(
      'SELECT COUNT(*) as total, SUM(CASE WHEN esp32_status = "success" THEN 1 ELSE 0 END) as successful FROM system_logs',
      (err, row) => {
        if (!err && row) {
          stats.totalRequests = row.total;
          stats.successfulRequests = row.successful || 0;
          stats.failedRequests = row.total - (row.successful || 0);
        }
      }
    );
    
    // Get average response time
    db.get(
      'SELECT AVG(response_time_ms) as avg FROM system_logs WHERE esp32_status = "success"',
      (err, row) => {
        if (!err && row) {
          stats.averageResponseTime = Math.round(row.avg || 0);
        }
      }
    );
    
    // Get sensor readings count
    db.get(
      'SELECT COUNT(*) as count FROM sensor_data',
      (err, row) => {
        if (!err && row) {
          stats.sensorReadings = row.count;
        }
      }
    );
    
    // Get events count
    db.get(
      'SELECT COUNT(*) as count FROM events',
      (err, row) => {
        if (!err && row) {
          stats.events = row.count;
          res.json(stats);
        }
      }
    );
  });
});

// ==================== WEBSOCKET ====================

wss.on('connection', (ws) => {
  const clientId = uuidv4();
  console.log(`✓ WebSocket client connected: ${clientId}`);
  
  // Send welcome message
  ws.send(JSON.stringify({
    type: 'connected',
    clientId,
    message: 'Connected to loom monitoring backend',
    timestamp: new Date().toISOString(),
  }));
  
  // Handle incoming messages
  ws.on('message', async (message) => {
    try {
      const request = JSON.parse(message);
      console.log(`📨 WebSocket message from ${clientId}:`, request.type);
      
      // Handle different request types
      switch (request.type) {
        case 'subscribe_status':
          // Client wants real-time status updates
          ws.send(JSON.stringify({
            type: 'subscribed',
            channel: 'status',
            message: 'Subscribed to status updates',
          }));
          break;
          
        case 'subscribe_events':
          ws.send(JSON.stringify({
            type: 'subscribed',
            channel: 'events',
            message: 'Subscribed to event updates',
          }));
          break;
          
        case 'ping':
          ws.send(JSON.stringify({
            type: 'pong',
            timestamp: new Date().toISOString(),
          }));
          break;
          
        default:
          ws.send(JSON.stringify({
            type: 'error',
            error: 'Unknown request type',
          }));
      }
    } catch (error) {
      ws.send(JSON.stringify({
        type: 'error',
        error: error.message,
      }));
    }
  });
  
  // Handle client disconnect
  ws.on('close', () => {
    console.log(`✗ WebSocket client disconnected: ${clientId}`);
  });
  
  // Handle errors
  ws.on('error', (error) => {
    console.error(`✗ WebSocket error for ${clientId}:`, error.message);
  });
});

// ==================== POLLING SERVICE ====================

/**
 * Poll ESP32 for status every 5 seconds and broadcast to WebSocket clients
 */
setInterval(async () => {
  const response = await requestESP32('/api/status');
  
  if (response.success) {
    // Log sensor data
    logSensorData(response.data);
    
    // Broadcast to all WebSocket clients
    broadcastToClients('status_update', response.data);
  }
}, 5000);

// ==================== ERROR HANDLING ====================

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: CONFIG.NODE_ENV === 'development' ? err.message : 'An error occurred',
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    path: req.path,
  });
});

// ==================== SERVER START ====================

server.listen(CONFIG.PORT, () => {
  console.log(`\n✓ Backend server running on http://localhost:${CONFIG.PORT}`);
  console.log(`✓ WebSocket server ready on ws://localhost:${CONFIG.PORT}`);
  console.log(`✓ Proxying to ESP32 at ${CONFIG.ESP32_URL}`);
  console.log('\nAvailable endpoints:');
  console.log('  GET    /health');
  console.log('  GET    /api/status');
  console.log('  POST   /api/motor/control');
  console.log('  POST   /api/loom/release');
  console.log('  GET    /api/history');
  console.log('  GET    /api/logs');
  console.log('  GET    /api/events');
  console.log('  GET    /api/statistics');
  console.log('  WS     /\n');
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\n✗ Shutting down server...');
  server.close(() => {
    console.log('✗ Server closed');
    db.close(() => {
      console.log('✗ Database closed');
      process.exit(0);
    });
  });
});

module.exports = app;
