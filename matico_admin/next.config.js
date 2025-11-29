/** @type {import('next').NextConfig} */
const withPlugins = require("next-compose-plugins");
const removeImports = require("next-remove-imports")();

const withTM = require("next-transpile-modules")(
  [
    "@adobe/react-spectrum",
    "@react-spectrum/provider",
    "@react-spectrum/theme-default",
    "react-aria",
    "react-stately",
    "react-aria-components",
    "@react-aria/color",
    "@react-aria/interactions",
    "@react-aria/focus",
    "@react-spectrum/actiongroup",
    "@react-spectrum/breadcrumbs",
    "@react-spectrum/button",
    "@react-spectrum/checkbox",
    "@react-spectrum/combobox",
    "@react-spectrum/dialog",
    "@react-spectrum/divider",
    "@react-spectrum/form",
    "@react-spectrum/icon",
    "@react-spectrum/image",
    "@react-spectrum/label",
    "@react-spectrum/layout",
    "@react-spectrum/link",
    "@react-spectrum/list",
    "@react-spectrum/menu",
    "@react-spectrum/picker",
    "@react-spectrum/progress",
    "@react-spectrum/radio",
    "@react-spectrum/searchfield",
    "@react-spectrum/statuslight",
    "@react-spectrum/switch",
    "@react-spectrum/table",
    "@react-spectrum/tabs",
    "@react-spectrum/text",
    "@react-spectrum/textfield",
    "@react-spectrum/toast",
    "@react-spectrum/tooltip",
    "@react-spectrum/view",
    "@react-spectrum/well",
    "@maticoapp/matico_components",
    "@maticoapp/matico_charts",
    "@maticoapp/matico_spec",
    "react-mde",
  ],
  { resolveSymlinks: false }
);

module.exports = withPlugins([withTM, removeImports], {
  reactStrictMode: true,
  webpack5: true,
  typescript: {
    ignoreBuildErrors: true,
  },
  experimental: {
    esmExternals: "loose",
  },
  webpack: (config) => {
    config.experiments = {
      ...config.experiments,
      asyncWebAssembly: true,
      syncWebAssembly: true,
      topLevelAwait: true,
    };
    config.module.rules.push({
      test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
      use: [{ loader: "file-loader", options: { outputPath: "static/webfonts/", publicPath: "../webfonts/", name: "[name].[ext]" } }],
    });
    return config;
  },
});
