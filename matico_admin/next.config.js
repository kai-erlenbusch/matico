/** @type {import('next').NextConfig} */
const withPlugins = require("next-compose-plugins");
const optomizedImages = require("next-optimized-images");
const removeImports = require("next-remove-imports")(); // <--- NEW

const withTM = require("next-transpile-modules")(
  [
    "@adobe/react-spectrum",
    "@react-spectrum/color",
    "@maticoapp/matico_components",
    "@maticoapp/matico_charts",
    "react-mde",
  ],
  { resolveSymlinks: false }
);

// Added 'removeImports' to the list of plugins
module.exports = withPlugins([withTM, removeImports, optomizedImages], {
  reactStrictMode: true,
  webpack5: true,
  typescript: {
    ignoreBuildErrors: true,
  },
  experimental: {
    esmExternals: "loose",
    urlImports: ["http://localhost:8000/"],
  },
  webpack: (config, options) => {
    config.experiments = {
      ...config.experiments,
      asyncWebAssembly: true,
      syncWebAssembly: true,
      topLevelAwait: true,
    };

    config.module.rules.push(
      {
        test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
        use: [
          {
            loader: "file-loader",
            options: {
              outputPath: "static/webfonts/",
              publicPath: "../webfonts/",
              name: "[name].[ext]",
            },
          },
        ],
      },
      {
        test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
        use: [
          {
            loader: "file-loader",
            options: {
              outputPath: "static/media/",
              publicPath: "../media/",
              name: "[name].[ext]",
            },
          },
        ],
      }
    );

    return config;
  },
});