// Fake reporting module for a dry run. Figures for the dashboard.
function replyRate(days) {
  const contacted = days.reduce((a, d) => a + d.contacted, 0);
  const replies = days.reduce((a, d) => a + d.replies, 0);
  if (contacted === 0) return null; // no data, not zero
  return replies / contacted;
}
function bounceRate(days) {
  const sent = days.reduce((a, d) => a + d.sent, 0);
  const bounces = days.reduce((a, d) => a + (d.bounces || 0), 0);
  if (sent === 0) return null; // no data, not zero
  return bounces / sent;
}
module.exports = { replyRate, bounceRate };
