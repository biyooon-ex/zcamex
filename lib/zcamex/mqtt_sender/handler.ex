defmodule Zcamex.MQTTSender.Handler do
  use Tortoise311.Handler

  require Logger

  def init(args) do
    ping_topic = Keyword.fetch!(args, :ping_topic)
    pong_topic = Keyword.fetch!(args, :pong_topic)
    client_id = Keyword.fetch!(args, :client_id)
    Logger.info("Initializing handler")

    {:ok,
     %{
       ping_topic: ping_topic,
       pong_topic: pong_topic,
       client_id: client_id
     }}
  end

  def connection(:up, state) do
    Logger.info("Connection has been established")
    {:ok, state}
  end

  def connection(:down, state) do
    Logger.warning("Connection has been dropped")
    {:ok, state}
  end

  def connection(:terminating, state) do
    Logger.warning("Connection is terminating")
    {:ok, state}
  end

  def subscription(:up, topic, state) do
    Logger.info("Subscribed to #{topic}")
    {:ok, state}
  end

  def subscription({:warn, [requested: req, accepted: qos]}, topic, state) do
    Logger.warning("Subscribed to #{topic}; requested #{req} but got accepted with QoS #{qos}")
    {:ok, state}
  end

  def subscription({:error, reason}, topic, state) do
    Logger.error("Error subscribing to #{topic}; #{inspect(reason)}")
    {:ok, state}
  end

  def subscription(:down, topic, state) do
    Logger.info("Unsubscribed from #{topic}")
    {:ok, state}
  end

  def handle_message(topic, publish, state) do
    pong_topic = state.pong_topic

    topic_path = Enum.join(topic, "/")

    case topic_path do
      ^pong_topic ->
        # Logger.debug(inspect(publish))
        state = %{"image" => publish}
        {:ok, state}

      _ ->
        Logger.warning("Subscribed to wrong #{topic_path}")
        {:error, state}
    end
  end
end
