import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { setOwner } from '@ember/application';
import { assert, assert as debugAssert } from '@ember/debug';
// @ts-ignore
import { fn } from '@ember/helper';
// @ts-ignore
import { on } from '@ember/modifier';
import { click, findAll, render, find } from '@ember/test-helpers';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';

import { headlessTable } from 'ember-headless-table';
import { meta } from 'ember-headless-table/plugins';
import { DataSorting, SortDirection } from 'ember-headless-table/plugins/data-sorting';
import { ColumnVisibility } from 'ember-headless-table/plugins/column-visibility';
import { StickyColumns } from 'ember-headless-table/plugins/sticky-columns';
import { ColumnResizing } from 'ember-headless-table/plugins/column-resizing';
import { requestAnimationFrameSettled } from 'ember-headless-table/test-support';
import { DATA } from 'test-app/data';

const minWidth = () => ColumnResizing.forColumn(() => ({ minWidth: 200 }));
const leftSticky = () => StickyColumns.forColumn(() => ({ sticky: 'left' }));
const rightSticky = () => StickyColumns.forColumn(() => ({ sticky: 'right' }));

import type { Column } from 'ember-headless-table';
import type { SortItem } from 'ember-headless-table/plugins/data-sorting';

module('Plugins | StickyColumns', function (hooks) {
  setupRenderingTest(hooks);

  let ctx: Context;
  /**
    * note: scroll direction is the inverse of swipe direction
    */
  let scrollLeft = async (distance: number) => {
    let element = find('[data-container]');

    assert(`[data-container] not found`, element instanceof HTMLElement);

    element.scrollLeft -= distance;
    await requestAnimationFrameSettled();
  }
  let scrollRight = async (distance: number) => {
    let element = find('[data-container]');

    assert(`[data-container] not found`, element instanceof HTMLElement);

    element.scrollLeft += distance;
    await requestAnimationFrameSettled();
  }
  let isAbout = (testNumber: number, num: number, slop: number = 2) => {
    return (testNumber <= num + slop) &&  (testNumber >= num - slop);
  }

  let leftPositionOf = (key: string) => {
    let container = find('[data-container]');

    assert(`[data-container] not found`, container instanceof HTMLElement);

    let column = find(`[data-key=${key}]`);

    assert(`[data-key=${key}] not found`, column instanceof HTMLElement);

    let containerRect = container.getBoundingClientRect();
    let columnRect = column.getBoundingClientRect();

    let delta = columnRect.left - containerRect.left;

    return delta;
  }

  class Context {
    /**
      * All columns set to min-width of 200 for easier math
      * 7 columns @ 200px min is 1400px
      */
    columns = [
      { name: 'A', key: 'A', pluginOptions: [minWidth()] },
      { name: 'B', key: 'B', pluginOptions: [minWidth()] },
      { name: 'C', key: 'C', pluginOptions: [minWidth()] },
      { name: 'D', key: 'D', pluginOptions: [minWidth()] },
      { name: 'E', key: 'E', pluginOptions: [minWidth()] },
      { name: 'F', key: 'F', pluginOptions: [minWidth()] },
      { name: 'G', key: 'G', pluginOptions: [minWidth()] },
    ];

    table = headlessTable(this, {
      columns: () => this.columns,
      data: () => DATA,
      plugins: [ColumnVisibility, ColumnResizing, StickyColumns],
    });
  }

  const TestStyles = <template>
    <style>
      #ember-testing { width: initial; height: initial; transform: initial; }
      #ember-testing-container { width: 1000px; }

      table {
        border-collapse: collapse;
      }
    </style>
  </template>;

  class TestComponent extends Component<{ Args: { ctx: Context } }> {
    get table() {
      return this.args.ctx.table;
    }

    <template>
      {{! with min-column @ 200px, this is 4 columns }}
      <div data-container style="width: 800px; overflow: auto;" {{this.table.modifiers.container}}>
        <table>
          <thead>
            <tr class="relative">
              {{#each this.table.columns as |column|}}
                <th data-key={{column.key}} {{this.table.modifiers.columnHeader column}}>
                  <span class="name">{{column.name}}</span><br>
                </th>
              {{/each}}
            </tr>
          </thead>
          <tbody>
            {{#each this.table.rows as |row|}}
              <tr class="relative">
                {{#each this.table.columns as |column|}}
                  <td {{this.table.modifiers.columnHeader column}}>
                    {{column.getValueForRow row}}
                  </td>
                {{/each}}
              </tr>
            {{/each}}
          </tbody>
        </table>
      </div>
    </template>
  }

  module('with default options', function (hooks) {
    hooks.beforeEach(function() {
      ctx = new Context();
      setOwner(ctx, this.owner);
    });

    test('no columns are sticky', async function (assert) {
      await render(<template>
        <TestStyles />
        <TestComponent @ctx={{ctx}} />
      </template>);

      /**
        * If we haven't scrolled, the left column should share a left boundary at most within 1 pixel of
        * its container
        */
      let left = leftPositionOf('A');
      assert.ok(isAbout(left, 1), `A's left edge (@ ${left}) matches the left edge of the container`);

      await scrollRight(200);

      /**
        * Because we only scrolled the distance of one column for this test,
        * it doesn't make sense to check the other columns.
        */
      left = leftPositionOf('A');
      assert.ok(isAbout(left, -200), `A's left edge (@ ${left}) moved, so it's not sticky`);
    });
  });

  module('the left column can be sticky', function (hooks) {
    class LeftColumn extends Context {
      columns = [
        { name: 'column A', key: 'A', pluginOptions: [leftSticky(), minWidth()] },
        { name: 'column B', key: 'B', pluginOptions: [minWidth()] },
        { name: 'column C', key: 'C', pluginOptions: [minWidth()] },
        { name: 'column D', key: 'D', pluginOptions: [minWidth()] },
        { name: 'column E', key: 'E', pluginOptions: [minWidth()] },
        { name: 'column F', key: 'F', pluginOptions: [minWidth()] },
        { name: 'column G', key: 'G', pluginOptions: [minWidth()] },
      ]
    }

    hooks.beforeEach(function() {
      ctx = new LeftColumn();
      setOwner(ctx, this.owner);
    });

    test('the left column does not change position during scrolling', async function (assert) {
      await render(<template>
        <TestStyles />
        <TestComponent @ctx={{ctx}} />
      </template>);

      /**
        * If we haven't scrolled, the left column should share a left boundary at most within 1 pixel of
        * its container
        */
      let leftA = leftPositionOf('A');
      assert.ok(isAbout(leftA, 1), `A's left edge (@ ${leftA}) matches the left edge of the container`);

      let leftB = leftPositionOf('B');
      assert.ok(isAbout(leftB, 201), `B's left edge (@ ${leftB}) is one column's width right of A`);

      await scrollRight(200);

      leftA = leftPositionOf('A');
      assert.ok(isAbout(leftA, 0), `A's left edge (@ ${leftA}) is stuck to the left`);
      leftB = leftPositionOf('B');
      assert.ok(isAbout(leftB, 1), `B's left edge (@ ${leftB}) now shares an edge with A, due to scrolling`);
    });

  });

  module('the right column can be sticky', function () {
    test('the right column does not change position during scrolling', async function (assert) {

    });
  });

  module('2 left columns can be sticky', function (hooks) {
    class LeftColumn extends Context {
      columns = [
        { name: 'column A', key: 'A', pluginOptions: [leftSticky(), minWidth()] },
        { name: 'column B', key: 'B', pluginOptions: [leftSticky(), minWidth()] },
        { name: 'column C', key: 'C', pluginOptions: [minWidth()] },
        { name: 'column D', key: 'D', pluginOptions: [minWidth()] },
        { name: 'column E', key: 'E', pluginOptions: [minWidth()] },
        { name: 'column F', key: 'F', pluginOptions: [minWidth()] },
        { name: 'column G', key: 'G', pluginOptions: [minWidth()] },
      ]
    }

    hooks.beforeEach(function() {
      ctx = new LeftColumn();
      setOwner(ctx, this.owner);
    });

    test('the 2 left columns do not change position during scrolling', async function (assert) {
      await render(<template>
        <TestStyles />
        <TestComponent @ctx={{ctx}} />
      </template>);

      /**
        * If we haven't scrolled, the left column should share a left boundary at most within 1 pixel of
        * its container
        */
      let leftA = leftPositionOf('A');
      assert.ok(isAbout(leftA, 1), `A's left edge (@ ${leftA}) matches the left edge of the container`);

      let leftB = leftPositionOf('B');
      assert.ok(isAbout(leftB, 201), `B's left edge (@ ${leftB}) is one column's width right of A`);

      let leftC = leftPositionOf('C');
      assert.ok(isAbout(leftC, 403), `C's left edge (@ ${leftC}) is two column's width right of A`);

      let leftD = leftPositionOf('D');
      assert.ok(isAbout(leftD, 605), `D's left edge (@ ${leftD}) is three column's width right of A`);

      await scrollRight(200);

      leftA = leftPositionOf('A');
      assert.ok(isAbout(leftA, 0), `A's left edge (@ ${leftA}) is stuck to the left`);
      leftB = leftPositionOf('B');
      assert.ok(isAbout(leftB, 200), `B's left edge (@ ${leftB}) is stuck to the left, but right of A`);

      leftC = leftPositionOf('C');
      assert.ok(isAbout(leftC, 204), `C's left edge (@ ${leftC}) has almost scrolled all the way to A's right edge`);

      leftD = leftPositionOf('D');
      assert.ok(isAbout(leftD, 405), `D's left edge (@ ${leftD}) is now where C's left edge used to be`);

      await scrollRight(200);

      leftA = leftPositionOf('A');
      assert.ok(isAbout(leftA, 0), `A's left edge (@ ${leftA}) has not moved.`);
      leftB = leftPositionOf('B');
      assert.ok(isAbout(leftB, 200), `B's left edge (@ ${leftB}) has not moved.`);

      leftC = leftPositionOf('C');
      assert.ok(isAbout(leftC, 3), `C's left edge (@ ${leftC}) is almost as left as it can go`);

      leftD = leftPositionOf('D');
      assert.ok(isAbout(leftD, 205), `D's left edge (@ ${leftD}) is now where C's left edge used to be (again)`);
    });
  });

  module('2 right columns can be sticky', function () {
    test('the 2 right columns do not change position during scrolling', async function (assert) {});
  });

  module('columns on both ends can be sticky', function () {
    test('both sticky columns do not change position during scrolling', async function (assert) {});
  });
});
