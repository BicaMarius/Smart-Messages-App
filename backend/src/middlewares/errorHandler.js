const errorHandler = (err, req, res, next) => {
  console.error('Error occurred:', {
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    timestamp: new Date().toISOString()
  });

  // Handle specific error types
  if (err.response) {
    // API error response
    return res.status(err.response.status || 500).json({
      error: 'API Error',
      message: err.response.data?.message || err.message,
      details: err.response.data
    });
  }

  if (err.request) {
    // Request made but no response received
    return res.status(503).json({
      error: 'Service Unavailable',
      message: 'The external service is not responding'
    });
  }

  // Default error response
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message || 'An unexpected error occurred'
  });
};

module.exports = errorHandler;
