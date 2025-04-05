import request from 'supertest';
import express from 'express';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import path from 'path';
import { config } from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables
config({ path: path.join(__dirname, '../.env') });

// Create Express app
const app = express();

// Basic middleware
app.use(express.json());

// Basic route for testing
app.get('/', (req, res) => {
  res.status(200).json({ message: 'Server is running' });
});

describe('Server Tests', () => {
  test('Server should be running', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ message: 'Server is running' });
  });
}); 