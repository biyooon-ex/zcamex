defmodule Zcamex.Sender do
  @type destination() :: :mec | :cloud
  @type payload() :: %{image: String.t()}
  @type image() :: String.t()
  @type message() :: String.t()

  @callback send(destination(), payload()) :: {:ok, payload()} | {:error, message()}
end
