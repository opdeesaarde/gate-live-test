// Fake reporting module for a dry run. Figures for the dashboard.
function replyRate(days) {
  const contacted = days.reduce((a, d) => a + d.contacted, 0);
  const replies = days.reduce((a, d) => a + d.replies, 0);
  if (contacted === 0) return null; // no data, not zero
  return replies / contacted;
}
function weeklyUniqueRepliers(days) {
  return days.reduce((a, d) => a + d.unique_repliers, 0);
}
module.exports = { replyRate, weeklyUniqueRepliers };
