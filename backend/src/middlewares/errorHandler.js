module.exports = (err, req, res, next) => {
    console.error(err);
    res.status(500).json({ error: 'A apărut o eroare internă. Te rugăm să încerci din nou.' });
};
