import { connect } from 'react-redux';

import { submitAccountNote } from 'flavours/glitch/actions/account_notes';

import AccountNote from '../components/account_note';

const mapStateToProps = (state, { account }) => ({
  value: account.getIn(['relationship', 'note']),
});

const mapDispatchToProps = (dispatch, { account }) => ({

  onSave (value) {
    dispatch(submitAccountNote({ id: account.get('id'), value}));
  },

});

export default connect(mapStateToProps, mapDispatchToProps)(AccountNote);
