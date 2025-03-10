const { merge } = require('webpack-merge');
const common = require('./webpack.common.js');

module.exports = merge(common, {
  mode: 'development',
  devtool: 'inline-source-map',
  devServer: {
    static: './dist',
  },
  stats: {
    assets: true,
    modules: true,
    warnings: true,
    errors: true,
    errorDetails: true,
    children: true,
  },
});
