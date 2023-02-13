import Component from '@glimmer/component';

import { headlessTable } from 'ember-headless-table';

export default class TestAppTableSteveComponent extends Component {
  table = headlessTable(this, {
    columns: () => [{ name: 'column A', key: 'A' }],
    data: () => [{ A: 'Apple' }],
  });
}
