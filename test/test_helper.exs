# dynamically update the config to point to the test assets
Application.put_env(:scenic, :assets,
  module: Scenic.Test.Assets,
  alias: [
    roboto_mono: "fonts/roboto_mono.ttf",
    test_roboto: "fonts/roboto.ttf",
    test_parrot: "images/parrot.png"
  ]
)

ExUnit.start()
