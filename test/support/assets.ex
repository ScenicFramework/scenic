defmodule Scenic.Test.Assets do
  use Scenic.Assets.Static, otp_app: :scenic, directory: "test/assets"
end
