const express = require('express');
const jwt = require('jsonwebtoken');
const app = express();
const PORT = process.env.PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET;

// Fail fast if JWT_SECRET is not provided
if (!JWT_SECRET) {
    console.error('FATAL: JWT_SECRET environment variable is not set');
    process.exit(1);
}

app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'healthy' });
});

app.post('/auth/login', (req, res) => {
    const { username, password } = req.body;

    // Mock validation — replace with real DB lookup
    if (username === 'admin' && password === 'admin123') {
        const token = jwt.sign({ username, role: 'admin' }, JWT_SECRET, { expiresIn: '1h' });
        return res.json({ token, expiresIn: 3600 });
    }

    res.status(401).json({ error: 'Invalid credentials' });
});

app.get('/auth/verify', (req, res) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        res.json({ valid: true, user: decoded });
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
    }
});

app.listen(PORT, () => {
    console.log(`Auth server listening on port ${PORT}`);
});