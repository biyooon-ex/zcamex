defmodule Zcamex.MQTTSender do
  require Logger
  @behaviour Zcamex.Sender

  @default_mec_backend "localhost"
  @default_cloud_backend "localhost"

  @ping_topic_mec "demo/mcam/ping/mec"
  @pong_topic_mec "demo/mcam/pong/mec"
  @client_id_mec "MQTTSendeMec"
  @ping_topic_cloud "demo/mcam/ping/cloud"
  @pong_topic_cloud "demo/mcam/pong/cloud"
  @client_id_cloud "MQTTSenderCloud"

  def create_mqtt_topics() do
    broker_mec = System.get_env("MEC_BACKEND", @default_mec_backend)
    broker_cloud = System.get_env("CLOUD_BACKEND", @default_cloud_backend)

    {:ok, pid_mec} =
      Tortoise311.Connection.start_link(
        client_id: @client_id_mec,
        server: {Tortoise311.Transport.Tcp, host: broker_mec, port: 1883},
        handler:
          {Zcamex.MQTTSender.Handler,
           [ping_topic: @ping_topic_mec, pong_topic: @pong_topic_mec, client_id: @client_id_mec]},
        subscriptions: [
          {@pong_topic_mec, 0}
        ]
      )

    {:ok, pid_cloud} =
      Tortoise311.Connection.start_link(
        client_id: @client_id_cloud,
        server: {Tortoise311.Transport.Tcp, host: broker_cloud, port: 1883},
        handler:
          {Zcamex.MQTTSender.Handler,
           [
             ping_topic: @ping_topic_cloud,
             pong_topic: @pong_topic_cloud,
             client_id: @client_id_cloud
           ]},
        subscriptions: [
          {@pong_topic_cloud, 0}
        ]
      )

    state = %{
      :pid_mec => pid_mec,
      :ping_topic_mec => @ping_topic_mec,
      :pong_topic_mec => @pong_topic_mec,
      :client_id_mec => @client_id_mec,
      :pid_cloud => pid_cloud,
      :ping_topic_cloud => @ping_topic_cloud,
      :pong_topic_cloud => @pong_topic_cloud,
      :client_id_cloud => @client_id_cloud
    }

    {:ok, state}
  end

  @impl true
  def send(destination, _znodes, _mtopic, payload) do
    ping_topic =
      case destination do
        :mec -> @ping_topic_mec
        :cloud -> @ping_topic_cloud
      end

    client_id =
      case destination do
        :mec -> @client_id_mec
        :cloud -> @client_id_cloud
      end

    image = payload |> Map.get("image")
    Tortoise311.publish(client_id, ping_topic, image, qos: 0)

    # case subscribe() do
    #  {:ok, received_image} -> {:ok, received_image}
    # end

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
