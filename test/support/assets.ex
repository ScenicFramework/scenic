defmodule Scenic.Test.Assets do
  use Scenic.Assets.Static,
    otp_app: :scenic,
    sources: [
      {:scenic, "assets"},
      {:test_assets, "test/assets"}
    ],
    alias: [
      parrot: {:test_assets, "images/parrot.png"}
    ]
end
