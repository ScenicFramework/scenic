# dynamically update the config to point to the test assets
Application.put_env(:scenic, :assets, module: Scenic.Test.Assets)

Application.put_env(:scenic, :themes, module: Scenic.Test.Themes)

ExUnit.start()
