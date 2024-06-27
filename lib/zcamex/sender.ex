defmodule Zcamex.Sender do
  @type destination() :: :mec | :cloud
  @type payload() :: %{image: String.t()}
  @type image() :: String.t()
  @type message() :: String.t()

  @type pubsub() :: %{pub: String.t(), sub: String.t()}
  @type znodes() :: %{mec: pubsub(), cloud: pubsub()}

  @callback send(destination(), znodes(), payload()) :: {:ok, payload()} | {:error, message()}
end
