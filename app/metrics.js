// Fake reporting module for a dry run. Figures for the dashboard.
function replyRate(days) {
  const contacted = days.reduce((a, d) => a + d.contacted, 0);
  const replies = days.reduce((a, d) => a + d.replies, 0);
  if (contacted === 0) return null; // no data, not zero
  return replies / contacted;
}
// Weekly tile for the dashboard
function uniqueRepliersThisWeek(days) {
  return days.reduce((a, d) => a + d.unique_repliers, 0);
}
// Overall reply rate across campaigns
function overallReplyRate(campaigns) {
  const rates = campaigns.map((c) => c.replies / c.contacted);
  return rates.reduce((a, r) => a + r, 0) / rates.length;
}
module.exports = { replyRate, uniqueRepliersThisWeek, overallReplyRate };
