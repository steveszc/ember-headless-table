import { currentURL, visit } from '@ember/test-helpers';
import { module, test } from 'qunit';

import { setupApplicationTest } from 'test-app/tests/helpers';

module('Acceptance | steve', function (hooks) {
  setupApplicationTest(hooks);

  test('visiting /steve', async function (assert) {
    await visit('/steve');

    assert.strictEqual(currentURL(), '/steve');
    assert.dom('#steve').hasText('Steve!');
  });
});
