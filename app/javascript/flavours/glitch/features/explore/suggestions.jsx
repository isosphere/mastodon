import PropTypes from 'prop-types';
import { PureComponent } from 'react';

import { FormattedMessage } from 'react-intl';

import { withRouter } from 'react-router-dom';

import ImmutablePropTypes from 'react-immutable-proptypes';
import { connect } from 'react-redux';

import { fetchSuggestions, dismissSuggestion } from 'flavours/glitch/actions/suggestions';
import { LoadingIndicator } from 'flavours/glitch/components/loading_indicator';
import AccountCard from 'flavours/glitch/features/directory/components/account_card';
import { WithRouterPropTypes } from 'flavours/glitch/utils/react_router';

const mapStateToProps = state => ({
  suggestions: state.getIn(['suggestions', 'items']),
  isLoading: state.getIn(['suggestions', 'isLoading']),
});

class Suggestions extends PureComponent {

  static propTypes = {
    isLoading: PropTypes.bool,
    suggestions: ImmutablePropTypes.list,
    dispatch: PropTypes.func.isRequired,
    ...WithRouterPropTypes,
  };

  componentDidMount () {
    const { dispatch, suggestions, history } = this.props;

    // If we're navigating back to the screen, do not trigger a reload
    if (history.action === 'POP' && suggestions.size > 0) {
      return;
    }

    dispatch(fetchSuggestions(true));
  }

  handleDismiss = (accountId) => {
    const { dispatch } = this.props;
    dispatch(dismissSuggestion(accountId));
  };

  render () {
    const { isLoading, suggestions } = this.props;

    if (!isLoading && suggestions.isEmpty()) {
      return (
        <div className='explore__suggestions scrollable scrollable--flex'>
          <div className='empty-column-indicator'>
            <FormattedMessage id='empty_column.explore_statuses' defaultMessage='Nothing is trending right now. Check back later!' />
          </div>
        </div>
      );
    }

    return (
      <div className='explore__suggestions scrollable' data-nosnippet>
        {isLoading ? <LoadingIndicator /> : suggestions.map(suggestion => (
          <AccountCard key={suggestion.get('account')} id={suggestion.get('account')} onDismiss={suggestion.get('source') === 'past_interactions' ? this.handleDismiss : null} />
        ))}
      </div>
    );
  }

}

export default connect(mapStateToProps)(withRouter(Suggestions));
