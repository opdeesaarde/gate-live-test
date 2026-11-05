const test = require('node:test');
const assert = require('node:assert');
const { replyRate } = require('../app/metrics');
const days = require('../data/fake.json').days;
test('reply rate is summed replies over summed contacted', () => {
  assert.strictEqual(replyRate(days), 5 / 180);
});
test('no data gives no figure, not zero', () => {
  assert.strictEqual(replyRate([]), null);
});
