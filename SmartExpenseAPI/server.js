const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

// Mock Routes
app.get('/transactions', (req, res) => {
    res.json([
        { id: 1, store_name: 'Apple Store', amount: -129.00, category: 'Shopping', date: '2026-03-16' },
        { id: 2, store_name: 'Starbucks', amount: -12.50, category: 'Food & Drink', date: '2026-03-16' }
    ]);
});

app.post('/transactions', (req, res) => {
    const transaction = req.body;
    console.log('Received transaction:', transaction);
    res.status(201).json({ message: 'Transaction saved', id: Math.floor(Math.random() * 1000) });
});

app.get('/budgets', (req, res) => {
    res.json([
        { category: 'Food & Drink', spent: 450, total: 600 },
        { category: 'Shopping', spent: 850, total: 1000 }
    ]);
});

app.post('/receipt-parse', (req, res) => {
    const { ocr_text } = req.body;
    console.log('Parsing OCR text:', ocr_text);
    
    // Simulate AI Extraction Logic
    res.json({
        store_name: 'Mock Store',
        date: '2026-03-16',
        total_amount: 15.00,
        category: 'Shopping'
    });
});

app.listen(PORT, () => {
    console.log(`SmartExpense AI Server running on port ${PORT}`);
});
