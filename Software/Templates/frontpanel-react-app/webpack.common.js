const path = require('path');

const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
  entry: './src/index.tsx',
  plugins: [
    new HtmlWebpackPlugin({
      title: 'FrontPanel Application',
      template: path.resolve(__dirname, 'src/index.html'),
    }),
    new CopyWebpackPlugin({
      patterns: [
        { from: 'frontpanel-app.json', to: 'frontpanel-app.json' },
        { from: 'APP-INFO.md', to: 'assets/text' },
        // TODO: Specify the file to bundle as the app icon
        { from: 'assets/frontpanel-app-icon.svg', to: 'assets/images' }
      ],
    }),
  ],
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
      {
        test: /\.css$/i,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.(ico)$/i,
        type: 'asset/resource',
        generator: { 
          filename: 'assets/icons/[name][ext]'
        }
      },
      {
        test: /\.(png|svg|jpg|jpeg|gif)$/i,
        type: 'asset/resource',
        generator: { 
          filename: 'assets/images/[name][ext]'
        }
      },
      {
        test: /\.(woff|woff2|eot|ttf|otf)$/i,
        type: 'asset/resource',
        generator: { 
          filename: 'assets/fonts/[name][ext]'
        }
      },
      {
        test: /\.(bit)$/i,
        type: 'asset/resource',
        generator: {
          filename: (sourcePath) => {
            const productName = path.dirname(sourcePath.filename).split('/').pop();
            return `assets/bitfiles/${productName}/[name][ext]`;
          }
        }
      },
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
    modules: [path.resolve(__dirname, 'src'), path.resolve(__dirname, 'assets'), 'node_modules'],
  },
  output: {
    filename: '[name].bundle.js',
    path: path.resolve(__dirname, 'dist'),
    clean: true,
  },
};
