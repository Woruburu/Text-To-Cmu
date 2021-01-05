const path = require("path");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const webpack = require("webpack");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = (env) => {
  const isProd = env.production;
  var elmUse = [
    {
      loader: "elm-webpack-loader",
      options: {
        debug: false,
        optimize: isProd,
        pathToElm: "node_modules/.bin/elm",
      },
    },
  ];
  if (!isProd) {
    var hotLoader = [{ loader: "elm-hot-webpack-loader" }];
    elmUse = hotLoader.concat(elmUse);
  }
  return {
    entry: path.resolve(__dirname, "src", "index.js"),
    module: {
      rules: [
        {
          test: /\.m?js$/,
          exclude: /(node_modules|bower_components)/,
          use: {
            loader: "babel-loader",
            options: {
              presets: ["@babel/preset-env"],
            },
          },
        },
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: [
            { loader: "elm-hot-webpack-loader" },
            {
              loader: "elm-webpack-loader",
              options: {
                debug: false,
                optimize: isProd,
                pathToElm: "node_modules/.bin/elm",
              },
            },
          ],
        },
        {
          test: /\.css$/i,
          use: ["style-loader", "css-loader"],
        },
      ],
    },
    resolve: {
      extensions: [".js", ".elm", ".css"],
    },
    output: {
      filename: "[id].[hash].js",
      path: path.join(__dirname, "dist"),
    },
    devServer: {
      hot: true,
      watchOptions: {
        ignored: /node_modules/,
      },
    },
    mode: isProd ? "production" : "development",
    devtool: isProd ? "source-map" : "inline-source-map",
    plugins: [
      new CleanWebpackPlugin(),
      new webpack.ProgressPlugin(),
      new HtmlWebpackPlugin({
        template: path.resolve(__dirname, "static", "index.html"),
      }),
      new CopyWebpackPlugin({
        patterns: [{ from: "static" }],
      }),
    ],
  };
};
