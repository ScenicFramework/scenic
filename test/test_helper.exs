# dynamically update the config to point to the test assets
Application.put_env(:scenic, :assets, module: Scenic.Test.Assets )

ExUnit.start()
