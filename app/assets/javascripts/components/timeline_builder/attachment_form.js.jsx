const TimelineBuilderAttachmentForm = createReactClass({
  propTypes: {
    currentForm: PropTypes.string,
    previousForm: PropTypes.string,
    addAttachmentCB: PropTypes.func,
    selectedDate: PropTypes.string,
    showSelectedFileError: PropTypes.bool,
    resetErrorsCB: PropTypes.func,
    hideFileForm: PropTypes.func
  },

  getInitialState: function() {
    return null;
  },

  componentDidUpdate: function() {
    if (this.props.previousForm != null) {
      // Slide up the old form.
      $(".js-" + this.props.previousForm + "-form").slideUp(
        300,
        this.displayNewForm
      );
    } else {
      this.displayNewForm();
    }
  },

  displayNewForm: function() {
    if (this.props.currentForm != null) {
      // Slide down the new form.
      $(".js-" + this.props.currentForm + "-form").slideDown(300);
    }
  },

  formVisible: function(type) {
    if (this.props.previousForm == type) {
      return {};
    } else {
      return { display: "none" };
    }
  },

  render: function() {
    return (
      <div>
        <div
          className="timeline-builder__attachment-form-container js-link-form"
          style={this.formVisible("link")}
        >
          <TimelineBuilderLinkForm
            addAttachmentCB={this.props.addAttachmentCB}
          />
        </div>

        <div
          className="timeline-builder__attachment-form-container js-file-form"
          style={this.formVisible("file")}
        >
          <TimelineBuilderFileForm
            addAttachmentCB={this.props.addAttachmentCB}
            resetErrorsCB={this.props.resetErrorsCB}
            showSelectedFileError={this.props.showSelectedFileError}
            hideFileForm={this.props.hideFileForm}
          />
        </div>

        <div
          className="timeline-builder__attachment-form-container js-date-form"
          style={this.formVisible("date")}
        >
          <TimelineBuilderDateForm
            addAttachmentCB={this.props.addAttachmentCB}
            selectedDate={this.props.selectedDate}
          />
        </div>
      </div>
    );
  }
});
