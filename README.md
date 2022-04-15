# Demo: "Configuring an already-compiled, static javascript single-page-app using environment variables"

## Clone, build & run in less than a minute

Requires Docker & Docker compose. The first time you call `docker compose`, it
will build the image.

```bash
git clone https://github.com/vovimayhem/env-vars-to-js-spa-demo.git \
&& cd env-vars-to-js-spa-demo \
&& docker compose up staging
```

Once it's running, visit [http://localhost:3000](http://localhost:3000) to see
the app running.

## Demo Environment Variables

This app is just a simple hello world VueJS app. The name of the person the app
is "saluting" is configured using the `VITE_APP_SALUTE_NAME` environment
variable, which defaults to "Francis" in the docker compose configuration.

You can override the default by creating a new `.env` file at the root of this
project, with the following contents:

```dotenv
VITE_APP_SALUTE_NAME=Leonidas
```

Once you've created this file, bring up the compose stack again:

```bash
docker compose up --force-recreate staging
```

## The relevant code

The two main problems requiring solving:
- Making the app read from a javascript global object - `window` being the most suitable.
- Manipulating the index.html so that it defines the variables inside the `window` object,
  both on "development" mode, as in "production" mode.

### The variables set inside `window`

Take a look at the [index.html file](https://github.com/vovimayhem/env-vars-to-js-spa-demo/blob/70277948095f1a1e41b64e80f9cfcfec014059f8/index.html#L8-L10):

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <script>
      window.VITE_APP_SALUTE_NAME = "<%= VITE_APP_SALUTE_NAME %>";
    </script>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
```

Notice the `script` tag. This is where we'll put the environment variables into
the `window` global object... notice also the `<%= VITE_APP_SALUTE_NAME %>` tag,
which is a placeholder for our real environment variables.

The [`HomeView.vue`](https://github.com/vovimayhem/env-vars-to-js-spa-demo/blob/70277948095f1a1e41b64e80f9cfcfec014059f8/src/views/HomeView.vue#L1-L10) file uses the `window` object to get the salute to render:

```javascript
const { VITE_APP_SALUTE_NAME } = window;
```

```html
<HelloWorld :name="VITE_APP_SALUTE_NAME" />
```

### Manipulating the `index.html` file in development & build phases

This was where I got stuck the most. There's a vite plugin ["vite-plugin-html-env"](https://github.com/lxs24sxl/vite-plugin-html-env) that I originally wanted to use, but didn't work, so I ended
up doing my own plugin instead - you can check it out at ["my-own-damn-html-env-plugin.js"](https://github.com/vovimayhem/env-vars-to-js-spa-demo/blob/70277948095f1a1e41b64e80f9cfcfec014059f8/my-own-damn-html-env-plugin.js#L1).

This plugin will replace the `<%= VITE_APP_SALUTE_NAME %>` tag with the actual
value of the `VITE_APP_SALUTE_NAME` environment variable when the development
server starts, *and* when the app gets compiled into it's final form, which
[happens when building the final image](https://github.com/vovimayhem/env-vars-to-js-spa-demo/blob/70277948095f1a1e41b64e80f9cfcfec014059f8/Dockerfile#L118-L132):

```Dockerfile
# Notice the escaped "$" sign:
ENV VITE_APP_SALUTE_NAME="\$VITE_APP_SALUTE_NAME"
COPY --chown=${DEVELOPER_UID} . /workspaces/env-vars-to-js-spa-demo/
RUN yarn build
```

### Manipulating the `index.html` file in "production" mode

The [`process-index-html.sh` file](https://github.com/vovimayhem/env-vars-to-js-spa-demo/blob/70277948095f1a1e41b64e80f9cfcfec014059f8/process-index-html.sh#L1-L9) leverages the fact that
the official nginx image contains the `envsubst` command, and that scripts can be copied
to it to run before the actual nginx process starts. It is copied in the [last stage
on the Dockerfile](https://github.com/vovimayhem/env-vars-to-js-spa-demo/blob/70277948095f1a1e41b64e80f9cfcfec014059f8/Dockerfile#L134-L141):

```Dockerfile
COPY process-index-html.sh /docker-entrypoint.d/40-process-index-html.sh
```

This script interpolates the environment variables into the `index.html` file.

## Development

Using Visual Studio with Remote Containers extension is recommended.
### Using plain docker compose

Run:

```bash
docker compose up -d development
```

Edit with your favorite editor.

### Using Visual Studio Code

With the ["Remote Containers"](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension,
open the cloned folder with Visual Studio Code. You'll be prompted to reopen the
folder to develop in a container - choose "Reopen in Container".

Once everything is set up, run the following command, in a new VSCode terminal:

```bash
yarn dev
```

Edit away :)
## Testing the releasable image locally

The `staging` service defined in the `docker-compose.yml` file has the configuration
required to 