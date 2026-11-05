const test = require('node:test');
const assert = require('node:assert');
const { replyRate, bounceRate } = require('../app/metrics');
const days = require('../data/fake.json').days;
test('reply rate is summed replies over summed contacted', () => {
  assert.strictEqual(replyRate(days), 5 / 150);
});
test('no data gives no figure, not zero', () => {
  assert.strictEqual(replyRate([]), null);
});
test('bounce rate is summed bounces over summed sent', () => {
  assert.strictEqual(bounceRate([{ sent: 100, bounces: 2 }, { sent: 100, bounces: 4 }]), 6 / 200);
});
test('bounce rate with no data gives no figure', () => {
  assert.strictEqual(bounceRate([]), null);
});
