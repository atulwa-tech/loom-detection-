/**
 * LOOM BACKEND CLIENT - JavaScript/Node.js Example
 * 
 * Use this to understand how to integrate with the backend from your applications
 */

const axios = require('axios');
const WebSocket = require('ws');

class LoomBackendClient {
  constructor(baseUrl = 'http://localhost:3000') {
    this.baseUrl = baseUrl;
    this.ws = null;
    this.isConnected = false;
  }

  /**
   * Check backend health
   */
  async getHealth() {
    try {
      const response = await axios.get(`${this.baseUrl}/health`);
      return response.data;
    } catch (error) {
      console.error('Health check failed:', error.message);
      return null;
    }
  }

  /**
   * Get current system status
   */
  async getStatus() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/status`);
      return response.data;
    } catch (error) {
      console.error('Failed to get status:', error.message);
      return null;
    }
  }

  /**
   * Control a motor
   * motorId: 0-9
   * state: true (ON) or false (OFF)
   */
  async controlMotor(motorId, state) {
    try {
      const response = await axios.post(
        `${this.baseUrl}/api/motor/control`,
        { motorId, state }
      );
      return response.data;
    } catch (error) {
      console.error(`Failed to control motor ${motorId}:`, error.message);
      return null;
    }
  }

  /**
   * Release loom fabric
   * lengthCm: length in centimeters (0.1 - 50)
   */
  async releaseLoom(lengthCm) {
    try {
      const response = await axios.post(
        `${this.baseUrl}/api/loom/release`,
        { lengthCm }
      );
      return response.data;
    } catch (error) {
      console.error('Failed to release loom:', error.message);
      return null;
    }
  }

  /**
   * Get system history
   */
  async getHistory() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/history`);
      return response.data;
    } catch (error) {
      console.error('Failed to get history:', error.message);
      return null;
    }
  }

  /**
   * Get system logs
   * limit: number of records (default: 100)
   * offset: pagination offset (default: 0)
   */
  async getLogs(limit = 100, offset = 0) {
    try {
      const response = await axios.get(
        `${this.baseUrl}/api/logs?limit=${limit}&offset=${offset}`
      );
      return response.data;
    } catch (error) {
      console.error('Failed to get logs:', error.message);
      return null;
    }
  }

  /**
   * Get events
   * limit: number of records (default: 100)
   * offset: pagination offset (default: 0)
   * type: filter by event type (optional)
   */
  async getEvents(limit = 100, offset = 0, type = null) {
    try {
      let url = `${this.baseUrl}/api/events?limit=${limit}&offset=${offset}`;
      if (type) url += `&type=${type}`;
      
      const response = await axios.get(url);
      return response.data;
    } catch (error) {
      console.error('Failed to get events:', error.message);
      return null;
    }
  }

  /**
   * Get statistics
   */
  async getStatistics() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/statistics`);
      return response.data;
    } catch (error) {
      console.error('Failed to get statistics:', error.message);
      return null;
    }
  }

  /**
   * Connect to WebSocket for real-time updates
   */
  connectWebSocket(onMessage, onError = null, onClose = null) {
    const wsUrl = this.baseUrl.replace('http', 'ws');
    
    this.ws = new WebSocket(wsUrl);

    this.ws.addEventListener('open', () => {
      console.log('WebSocket connected');
      this.isConnected = true;
      
      // Request status updates
      this.ws.send(JSON.stringify({
        type: 'subscribe_status'
      }));
    });

    this.ws.addEventListener('message', (event) => {
      try {
        const data = JSON.parse(event.data);
        if (onMessage) {
          onMessage(data);
        }
      } catch (error) {
        console.error('Failed to parse WebSocket message:', error);
      }
    });

    this.ws.addEventListener('error', (error) => {
      console.error('WebSocket error:', error);
      if (onError) onError(error);
    });

    this.ws.addEventListener('close', () => {
      console.log('WebSocket disconnected');
      this.isConnected = false;
      if (onClose) onClose();
    });
  }

  /**
   * Disconnect WebSocket
   */
  disconnectWebSocket() {
    if (this.ws) {
      this.ws.close();
      this.isConnected = false;
    }
  }

  /**
   * Send WebSocket message
   */
  sendWebSocketMessage(message) {
    if (this.ws && this.isConnected) {
      this.ws.send(JSON.stringify(message));
    } else {
      console.error('WebSocket not connected');
    }
  }
}

// ==================== EXAMPLE USAGE ====================

async function exampleUsage() {
  const client = new LoomBackendClient('http://localhost:3000');

  // Check health
  console.log('Checking backend health...');
  const health = await client.getHealth();
  console.log('Health:', health);

  // Get current status
  console.log('\nGetting current status...');
  const status = await client.getStatus();
  console.log('Status:', status);

  // Control a motor
  console.log('\nTurning on Motor 0...');
  const motorResult = await client.controlMotor(0, true);
  console.log('Motor control result:', motorResult);

  // Release loom
  console.log('\nReleasing 4cm of loom...');
  const releaseResult = await client.releaseLoom(4.0);
  console.log('Release result:', releaseResult);

  // Get history
  console.log('\nGetting history...');
  const history = await client.getHistory();
  console.log('History:', history);

  // Get logs
  console.log('\nGetting recent logs...');
  const logs = await client.getLogs(10);
  console.log('Logs:', logs);

  // Get events
  console.log('\nGetting events...');
  const events = await client.getEvents(10, 0, 'motor_control');
  console.log('Events:', events);

  // Get statistics
  console.log('\nGetting statistics...');
  const stats = await client.getStatistics();
  console.log('Statistics:', stats);

  // Connect WebSocket for real-time updates
  console.log('\nConnecting WebSocket...');
  client.connectWebSocket(
    (data) => {
      console.log('📨 WebSocket message:', data.type, data.data);
    },
    (error) => {
      console.error('⚠️  WebSocket error:', error);
    },
    () => {
      console.log('WebSocket closed');
    }
  );

  // Keep the connection alive for 30 seconds
  await new Promise(resolve => setTimeout(resolve, 30000));

  // Disconnect
  client.disconnectWebSocket();
}

// Export for use as module
module.exports = LoomBackendClient;

// Run example if called directly
if (require.main === module) {
  exampleUsage().catch(console.error);
}
