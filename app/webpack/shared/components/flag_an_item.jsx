import _ from "lodash";
import React from "react";
import PropTypes from "prop-types";

class FlagAnItem extends React.Component {
  render( ) {
    const { config, item, itemTypeLabel, setFlaggingModalState, manageFlagsPath } = this.props;
    const loggedIn = config.currentUser;
    const unresolvedFlags = _.filter( item.flags || [], f => !f.resolved );
    if ( unresolvedFlags.length > 0 ) {
      const groupedFlags = _.groupBy( unresolvedFlags, f => ( f.flag ) );
      let flagQualifier;
      if ( groupedFlags.spam ) {
        flagQualifier = "spam";
      } else if ( groupedFlags.inappropriate ) {
        flagQualifier = "inappropriate";
      }
      const editLink = loggedIn ? (
        <a href={ manageFlagsPath } className="view">
          { I18n.t( "add_edit_flags" ) }
        </a> ) : null;
      const type = itemTypeLabel || item.constructor.name;
      return (
        <div className="FlagAnItem alert alert-danger">
          <i className="fa fa-flag" />
          { flagQualifier ?
            I18n.t( "x_flagged_as_flag", { x: type, flag: flagQualifier } ) :
            I18n.t( "x_flagged", { x: type } ) }
          { editLink }
        </div>
      );
    }

    const addFlagLink = loggedIn ?
      (
        <span
          className="linky"
          onClick={ ( ) => setFlaggingModalState( { item, show: true } ) }
        >
          { I18n.t( "flag_as_inappropriate" ) }
        </span>
      ) : (
        <a className="linky" href="/login">
          { I18n.t( "flag_as_inappropriate" ) }
        </a>
      );
    return (
      <div className="FlagAnItem">
        { I18n.t( "inappropriate_content" ) } { addFlagLink }
      </div>
    );
  }
}

FlagAnItem.propTypes = {
  config: PropTypes.object,
  setFlaggingModalState: PropTypes.func,
  manageFlagsPath: PropTypes.string,
  item: PropTypes.object,
  itemTypeLabel: PropTypes.string
};

export default FlagAnItem;
