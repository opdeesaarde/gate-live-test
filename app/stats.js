// Fetch campaign stats for the dashboard tile
async function getTotalSent(fetchPage) {
  try {
    const res = await fetchPage(1);
    return res.items.reduce((a, i) => a + i.sent, 0);
  } catch (e) {
    return 0;
  }
}
module.exports = { getTotalSent };
