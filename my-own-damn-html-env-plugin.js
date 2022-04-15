import { loadEnv } from "vite";

function MyOwnDamnHtmlEnvPlugin(config) {
  return {
    name: "rollup-plugin-html-env",

    transformIndexHtml(html, ctx) {
      config = config || {};

      const { mode } = (ctx.server || { config: { mode: "production" } }).config;
      let loadedEnv = loadEnv(mode, process.cwd()) || {};

      const reg = new RegExp("(<%=)\\s+(\\w+)\\s+(%>)", "g");
      return html.replace(reg, (...arg) => {
        const key = arg[2];
        return `${loadedEnv[key]}`;
      });
    },
  };
};

module.exports = MyOwnDamnHtmlEnvPlugin