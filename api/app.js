const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

// Add a health check endpoint for Kubernetes probes
app.get('/health', (req, res) => {
  res.status(200).send({ status: 'healthy' });
});

// Our main API endpoint
app.get('/api/hello', (req, res) => {
  res.status(200).send('Hello!');
});

// Root path redirect to API
app.get('/', (req, res) => {
  res.status(200).send('Welcome to the API! Try /api/hello endpoint');
});

app.listen(port, () => {
  console.log(`API server listening on port ${port}`);
});
