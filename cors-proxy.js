/**
 * CORS Proxy Server for Tiju's Academy
 * 
 * This simple Node.js server acts as a proxy between your local Flutter app
 * and the remote CRM API, bypassing CORS restrictions during local development.
 * 
 * How to use:
 * 1. Install Node.js if you don't have it already: https://nodejs.org/
 * 2. Run this server: `node cors-proxy.js`
 * 3. Update your API endpoints in the app to use http://localhost:3000/ instead of the remote URL
 * 
 * Example:
 * Instead of https://learn.tijusacademy.com/api/signup
 * Use http://localhost:3000/api/signup
 */

const http = require('http');
const https = require('https');
const url = require('url');

// Configuration
const PORT = 3000;
const TARGET_HOST = 'learn.tijusacademy.com';

const server = http.createServer((req, res) => {
  // Set CORS headers to allow requests from any origin
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  // Parse the request URL
  const reqUrl = url.parse(req.url);
  
  // Build options for the forwarded request
  const options = {
    hostname: TARGET_HOST,
    port: 443,  // HTTPS port
    path: reqUrl.path,
    method: req.method,
    headers: {
      ...req.headers,
      host: TARGET_HOST,
    },
  };
  
  console.log(`Proxying ${req.method} request to: https://${TARGET_HOST}${reqUrl.path}`);
  
  // Create the proxy request
  const proxyReq = https.request(options, (proxyRes) => {
    // Copy response headers
    Object.keys(proxyRes.headers).forEach(key => {
      res.setHeader(key, proxyRes.headers[key]);
    });
    
    // Make sure CORS headers are set (override any returned by the target)
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    // Set status code
    res.writeHead(proxyRes.statusCode);
    
    // Pipe the proxy response to the client response
    proxyRes.pipe(res, { end: true });
  });
  
  // Handle errors in the proxy request
  proxyReq.on('error', (error) => {
    console.error('Proxy request error:', error);
    res.writeHead(500);
    res.end(`Proxy Error: ${error.message}`);
  });
  
  // If it's a POST request, pipe the request body to the proxy request
  if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
    req.pipe(proxyReq, { end: true });
  } else {
    proxyReq.end();
  }
});

// Start the server
server.listen(PORT, () => {
  console.log(`CORS Proxy running at http://localhost:${PORT}/`);
  console.log(`Forwarding requests to https://${TARGET_HOST}/`);
  console.log(`\nHow to use:`);
  console.log(`1. In your CrmApiService.dart file, change the API URL to:`);
  console.log(`   Uri.parse('http://localhost:${PORT}/api/signup')`);
  console.log(`2. Run your Flutter app and the requests will be proxied without CORS issues`);
});

