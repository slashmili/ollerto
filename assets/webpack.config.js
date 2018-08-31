const path = require('path');

module.exports = function(env) {
  const production = process.env.NODE_ENV === 'production';
  return {
    devtool: production ? 'source-maps' : 'eval',
    entry: {
      app: ['./js/app.js'],
    },
    output: {
      path: path.resolve(__dirname, '../priv/static/js'),
      filename: '[name].js',
      publicPath: '/',
    },
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader',
          },
        },

        {
          test: /\.(css|scss)$/,
          use: [
            'style-loader',
            'css-loader',
          ]
        },

        {
          test:    /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          loader:  'elm-webpack-loader?verbose=true&debug=true',
        },

        {
          test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
          loader: 'url-loader?limit=10000&mimetype=application/font-woff',
        },

        {
          test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
          loader: 'file-loader',
        },
      ],
       noParse: /\.elm$/,
    },
    resolve: {
      modules: ['node_modules', path.resolve(__dirname, 'js')],
      extensions: ['.js'],
    },
  };
};
