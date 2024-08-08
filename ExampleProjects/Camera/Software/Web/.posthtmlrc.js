// Configure PostHTML plugins with Parcel.
module.exports = {
  plugins: {
    'posthtml-include': {
      root: `${__dirname}/node_modules/@opalkelly/frontpanel-samples-common`
    },
    'posthtml-beautify': {
      blankLines: false
    }
  }
};
