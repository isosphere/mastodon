import PropTypes from 'prop-types';
import { PureComponent } from 'react';

import ImmutablePropTypes from 'react-immutable-proptypes';

export default class SettingText extends PureComponent {

  static propTypes = {
    settings: ImmutablePropTypes.map.isRequired,
    settingPath: PropTypes.array.isRequired,
    label: PropTypes.string.isRequired,
    onChange: PropTypes.func.isRequired,
  };

  handleChange = (e) => {
    this.props.onChange(this.props.settingPath, e.target.value);
  };

  render () {
    const { settings, settingPath, label } = this.props;

    return (
      <label>
        <span style={{ display: 'none' }}>{label}</span>
        <input
          className='glitch-setting-text'
          value={settings.getIn(settingPath)}
          onChange={this.handleChange}
          placeholder={label}
        />
      </label>
    );
  }

}
