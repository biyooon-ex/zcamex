defmodule Zcamex.Sender do
  @type destination() :: :mec | :cloud
  @type payload() :: %{image: String.t()}
  @type image() :: String.t()
  @type message() :: String.t()

  @type pubsub() :: %{pub: String.t(), sub: String.t()}
  @type znodes() :: %{mec: pubsub(), cloud: pubsub()}

  @type pingpong() :: %{ping_topic: String.t(), pong_topic: String.t(), client_id: String.t()}
  @type mtopics() :: %{mec: pingpong(), cloud: pingpong()}

  @callback send(destination(), znodes(), mtopics(), payload()) ::
              {:ok, payload()} | {:error, message()}
end
