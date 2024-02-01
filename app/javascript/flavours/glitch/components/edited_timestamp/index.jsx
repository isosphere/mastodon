import PropTypes from 'prop-types';
import { PureComponent } from 'react';

import { FormattedMessage, injectIntl } from 'react-intl';

import { connect } from 'react-redux';


import ArrowDropDownIcon from '@/material-icons/400-24px/arrow_drop_down.svg?react';
import { openModal } from 'flavours/glitch/actions/modal';
import { Icon }  from 'flavours/glitch/components/icon';
import InlineAccount from 'flavours/glitch/components/inline_account';
import { RelativeTimestamp } from 'flavours/glitch/components/relative_timestamp';

import DropdownMenu from './containers/dropdown_menu_container';

const mapDispatchToProps = (dispatch, { statusId }) => ({

  onItemClick (index) {
    dispatch(openModal({
      modalType: 'COMPARE_HISTORY',
      modalProps: { index, statusId },
    }));
  },

});

class EditedTimestamp extends PureComponent {

  static propTypes = {
    statusId: PropTypes.string.isRequired,
    timestamp: PropTypes.string.isRequired,
    intl: PropTypes.object.isRequired,
    onItemClick: PropTypes.func.isRequired,
  };

  handleItemClick = (item, i) => {
    const { onItemClick } = this.props;
    onItemClick(i);
  };

  renderHeader = items => {
    return (
      <FormattedMessage id='status.edited_x_times' defaultMessage='Edited {count, plural, one {# time} other {# times}}' values={{ count: items.size - 1 }} />
    );
  };

  renderItem = (item, index, { onClick, onKeyPress }) => {
    const formattedDate = <RelativeTimestamp timestamp={item.get('created_at')} short={false} />;
    const formattedName = <InlineAccount accountId={item.get('account')} />;

    const label = item.get('original') ? (
      <FormattedMessage id='status.history.created' defaultMessage='{name} created {date}' values={{ name: formattedName, date: formattedDate }} />
    ) : (
      <FormattedMessage id='status.history.edited' defaultMessage='{name} edited {date}' values={{ name: formattedName, date: formattedDate }} />
    );

    return (
      <li className='dropdown-menu__item edited-timestamp__history__item' key={item.get('created_at')}>
        <button data-index={index} onClick={onClick} onKeyPress={onKeyPress}>{label}</button>
      </li>
    );
  };

  render () {
    const { timestamp, intl, statusId } = this.props;

    return (
      <DropdownMenu statusId={statusId} renderItem={this.renderItem} scrollable renderHeader={this.renderHeader} onItemClick={this.handleItemClick}>
        <button className='dropdown-menu__text-button'>
          <FormattedMessage id='status.edited' defaultMessage='Edited {date}' values={{ date: intl.formatDate(timestamp, { hour12: false, month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' }) }} /> <Icon id='caret-down' icon={ArrowDropDownIcon} />
        </button>
      </DropdownMenu>
    );
  }

}

export default connect(null, mapDispatchToProps)(injectIntl(EditedTimestamp));
