import { defineConfig } from "vite";
import { fileURLToPath, URL } from "url";
import MyOwnDamnHtmlEnvPlugin from "./my-own-damn-html-env-plugin";

import vue from "@vitejs/plugin-vue";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue(), MyOwnDamnHtmlEnvPlugin()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
});
