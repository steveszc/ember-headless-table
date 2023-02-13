import Component from '@glimmer/component';
import { setComponentTemplate } from '@ember/component';
import { destroy } from '@ember/destroyable';
import Route from '@ember/routing/route';
import { currentURL, visit } from '@ember/test-helpers';
import { triggerEvent } from '@ember/test-helpers';
import { hbs } from 'ember-cli-htmlbars';
import { module, test } from 'qunit';

import { headlessTable } from 'ember-headless-table';
import { setupApplicationTest } from 'test-app/tests/helpers';

module('Acceptance | table', function (hooks) {
  setupApplicationTest(hooks);

  hooks.beforeEach(function () {
    class TableTestComponent extends Component {
      table = headlessTable(this, {
        columns: () => [{ name: 'Column A', key: 'A' }],
        data: () => [{ A: 'Apple' }],
      });
    }
    setComponentTemplate(
      hbs`
        <div id="test-table-container" {{this.table.modifiers.container}}>
          <table>
            <thead>
              <tr>
                {{#each this.table.columns as |column|}}
                  <th>{{column.name}}</th>
                {{/each}}
              </tr>
            </thead>
            <tbody>
              {{#each this.table.rows as |row|}}
                <tr>
                  {{#each this.table.columns as |column|}}
                    <td>{{column.getValueForRow row}}</td>
                  {{/each}}
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      `,
      TableTestComponent
    );

    this.owner.register('route:table-test', class extends Route {});
    this.owner.register('template:table-test', hbs`<TableTestComponent />`);
    this.owner.register('component:table-test-component', TableTestComponent);
  });

  test('visiting /table-test', async function (assert) {
    await visit('/table-test');

    assert.strictEqual(currentURL(), '/table-test');

    assert.dom('table thead tr').exists({ count: 1 }, 'Has a table thead tr');
    assert.dom('table thead tr th').exists({ count: 1 }, 'Has a table thead tr th');
    assert.dom('table thead tr th').hasText('Column A', 'Has correct column heading');
    assert.dom('table tbody tr').exists({ count: 1 }, 'Has a table tbody tr');
    assert.dom('table tbody tr td').exists({ count: 1 }, 'Has a table tbody tr td');
    assert.dom('table tbody tr td').hasText('Apple', 'Has correct cell content');

    destroy(this);

    await triggerEvent('#test-table-container', 'resize');
  });
});
