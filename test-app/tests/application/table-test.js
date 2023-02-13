import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { setComponentTemplate } from '@ember/component';
import Controller from '@ember/controller';
import { destroy } from '@ember/destroyable';
import { action } from '@ember/object';
import Route from '@ember/routing/route';
import { click, currentURL, visit } from '@ember/test-helpers';
import { hbs } from 'ember-cli-htmlbars';
import { module, test } from 'qunit';

import { headlessTable } from 'ember-headless-table';
import { ColumnResizing } from 'ember-headless-table/plugins/column-resizing';
import { RowSelection } from 'ember-headless-table/plugins/row-selection';
import { setupApplicationTest } from 'test-app/tests/helpers';

module('Acceptance | table', function (hooks) {
  setupApplicationTest(hooks);

  hooks.beforeEach(function () {
    class TableTestComponent extends Component {
      table = headlessTable(this, {
        columns: () => [{ name: 'Column A', key: 'A' }],
        data: () => [{ A: this.args.isNarrow ? 'App' : 'Apple' }],
        plugins: [
          ColumnResizing,
          RowSelection.with(() => {
            return {
              selection: [this.args.selected].filter(Boolean),
              onSelect: () => {},
              onDeselect: () => {},
            };
          }),
        ],
      });
    }
    setComponentTemplate(
      hbs`
        <div style="width: {{if @isNarrow "500" "1000"}}px" id="test-table-container" {{this.table.modifiers.container}} >
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
                <tr {{@table.modifiers.row row}}>
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
    this.owner.register(
      'controller:table-test',
      class extends Controller {
        @tracked isNarrow = false;
        @action toggleIsNarrow() {
          console.log('toggle');
          this.isNarrow = !this.isNarrow;
        }
        get selected() {
          if (this.isDestroyed || this.isDestroying) {
            throw new Error('destroyed!');
          }

          return this.isNarrow ? { A: 'App' } : { A: 'Apple' };
        }
      }
    );
    this.owner.register(
      'template:table-test',
      hbs`
        <div id="page">
          <button type="button" id="toggle" {{on "click" this.toggleIsNarrow}}>Toggle width</button>
          <TableTestComponent @selected={{this.selected}} @isNarrow={{this.isNarrow}} />
        </div>`
    );
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

    const button = document.getElementById('toggle');

    click(button); // this triggers the table resize

    // destroy the test context without waiting for async stuff to resolve
    // this *should* trigger the resizeObserver but appears not to
    destroy(this);
  });
});
