# AlloUI application library for Alloverse

> Nevyn Bengtsson, nevyn@alloverse.com, 2020-05-07

This Lua library lets you build spatial applications
for Alloverse using a high-level and easy to use UI library
that should feel familar to people coming from iOS, Android
or web development, rather than a game development background.

I'm still learning how to package lua code. At the moment,
this is how you create a new alloapp:

1. Install clang, cmake, luajit
2. Create your own repo, with a `src/main.lua`
3. Add submodules:

```
git submodule add --recursive https://github.com/alloverse/allonet.git lib/allonet
git submodule add --recursive https://github.com/alloverse/alloui-lua.git lib/alloui-lua
```

4. Compile liballonet.so and copy it to your `src` folder:

```
cd lib/allonet
mkdir build; cd build
cmake ..
make allonet
cp liballonet.so ../../../src/
echo "*.so" >> ../../../.gitignore
```

5. Use this skeleton in your main.lua:

```
local scriptPath = arg[0]
local srcDir = string.sub(scriptPath, 1, string.find(scriptPath, "main.lua")-2)
local libDir = srcDir.."/../lib"

package.cpath = string.format("%s;%s/?.so", package.cpath, srcDir)
package.path = string.format(
    "%s;%s/?.lua;%s/alloui-lua/lua/?.lua;%s/alloui-lua/lib/cpml/?.lua;%s/alloui-lua/lib/pl/lua/?.lua",
    package.path,
    srcDir,
    libDir,
    libDir,
    libDir
)

require("liballonet")
local Client = require("alloui.client")
local ui = require("alloui.ui")

local client = Client(
    arg[1], 
    "allo-jukebox"
)
local app = App(client)

local myAppView = ui.View()
... #configure your app's startup UI

app.mainView = myAppView
app:connect()
app:run()
```

6. Launch your app like this: 

    `luajit src/main.lua alloplace://nevyn.places.alloverse.com`

(substituting your own room URL)