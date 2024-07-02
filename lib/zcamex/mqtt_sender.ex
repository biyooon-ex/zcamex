defmodule Zcamex.MQTTSender do
  require Logger
  @behaviour Zcamex.Sender

  use GenServer

  @default_mec_backend "localhost"
  @default_cloud_backend "localhost"

  @prefix_ping_topic "demo/mcam/ping/"
  @prefix_pong_topic "demo/mcam/pong/"
  @prefix_client_id "MQTTSender_"

  def create_mqtt_topics(destination) do
    IO.inspect(destination)
    GenServer.start_link(__MODULE__, [destination], name: destination)
  end

  @impl true
  def init(args) do
    destination = hd(args)
    # Set topic names
    ping_topic = @prefix_ping_topic <> "#{destination}"
    pong_topic = @prefix_pong_topic <> "#{destination}"
    client_id = @prefix_client_id <> "#{destination}"

    # Set broker on the server
    broker =
      case destination do
        :mec -> System.get_env("MEC_BACKEND", @default_mec_backend)
        :cloud -> System.get_env("CLOUD_BACKEND", @default_cloud_backend)
      end

    Tortoise311.Connection.start_link(
      client_id: client_id,
      server: {Tortoise311.Transport.Tcp, host: broker, port: 1883},
      handler:
        {Zcamex.MQTTSender.Handler,
         [ping_topic: ping_topic, pong_topic: pong_topic, client_id: client_id]},
      subscriptions: [
        {pong_topic, 0}
      ]
    )

    state = %{:ping_topic => ping_topic, :pong_topic => pong_topic, :client_id => client_id}
    {:ok, state}
  end

  @impl true
  def send(destination, _znodes, mtopics, payload) do
    ping_topic = mtopics[destination] |> Map.get(:ping_topic)
    client_id = mtopics[destination] |> Map.get(:client_id)
    image = payload |> Map.get("image")
    Tortoise311.publish(client_id, ping_topic, image, qos: 0)

    """
    case subscribe() do
      {:ok, received_image} -> {:ok, received_image}
    end
    """

    {:ok, %{"image" => image}}
  end

  defp subscribe() do
    receive do
      {:ok, state} ->
        Logger.info("received")
        {:ok, state.image}
    end
  end
end
