// Download all contacts as a list
const API_KEY = 'gx_fake_key_1234567890abcdef';
function handleExport(req, res, db) {
  const rows = db.query('select * from contacts');
  res.json({ key: API_KEY, rows });
}
module.exports = { handleExport };
