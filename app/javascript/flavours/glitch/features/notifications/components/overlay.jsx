/**
 * Notification overlay
 */

import PropTypes from 'prop-types';

import { defineMessages, injectIntl } from 'react-intl';

import ImmutablePropTypes from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';

import CheckIcon from '@/material-icons/400-24px/check.svg?react';
import { Icon } from 'flavours/glitch/components/icon';


const messages = defineMessages({
  markForDeletion: { id: 'notification.markForDeletion', defaultMessage: 'Mark for deletion' },
});

class NotificationOverlay extends ImmutablePureComponent {

  static propTypes = {
    notification    : ImmutablePropTypes.map.isRequired,
    onMarkForDelete : PropTypes.func.isRequired,
    show            : PropTypes.bool.isRequired,
    intl            : PropTypes.object.isRequired,
  };

  onToggleMark = () => {
    const mark = !this.props.notification.get('markedForDelete');
    const id = this.props.notification.get('id');
    this.props.onMarkForDelete(id, mark);
  };

  render () {
    const { notification, show, intl } = this.props;

    const active = notification.get('markedForDelete');
    const label = intl.formatMessage(messages.markForDeletion);

    return show ? (
      <div
        aria-label={label}
        role='checkbox'
        aria-checked={active}
        tabIndex={0}
        className={`notification__dismiss-overlay ${active ? 'active' : ''}`}
        onClick={this.onToggleMark}
      >
        <div className='wrappy'>
          <div className='ckbox' aria-hidden='true' title={label}>
            {active ? (<Icon id='check' icon={CheckIcon} />) : ''}
          </div>
        </div>
      </div>
    ) : null;
  }

}

export default injectIntl(NotificationOverlay);
