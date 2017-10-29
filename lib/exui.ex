defmodule Exui do
#  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
#  def start(_type, _args) do
#    config_data = Application.get_env(:scenic, Exui)
#
#    driver = config_data[:driver]
#    view_ports = view_ports(config_data)
#
#    driver.start_link(view_ports)
#  end
#
#  #============================================================================
#  # helper functions
#
#  defp view_ports( opts ) when is_list(opts), do: view_ports( Enum.into(opts, %{}) )
#  defp view_ports( %{view_port: view_port} ), do: [view_port]
#  defp view_ports( %{view_ports: view_ports} ), do: view_ports
#  defp view_ports( _opts ), do: raise "Must set up at least one view_port."
end
