require('dotenv').config(); 
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const summarizeRoutes = require('./src/routes/summarizeRoutes');
const errorHandler = require('./src/middlewares/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

// Rutele API expuse
app.use('/api/summarize', summarizeRoutes);

// Middleware pentru gestionarea erorilor
app.use(errorHandler);

app.listen(PORT, () => {
    console.log(`Serverul rulează pe portul ${PORT}`);
});
