module BunnySubscriber
  class Queue
    attr_reader :channel, :queue_consummer

    def initialize(channel)
      @channel = channel
    end

    def subscribe(consumer)
      queue = create_queue(consumer)
      @queue_consummer = queue.subscribe(
        manual_ack: true,
        block: false
      ) do |delivery_info, properties, payload|
        consumer.event_process_around_action(
          delivery_info, properties, payload
        )
      end
    end

    def unsubscribe
      return if @queue_consummer.cancel

      # If can cancel the consumer, try again
      sleep(1)
      unsubscribe
    end

    private

    def create_queue(consumer)
      if consumer.subscriber_options[:queue_name].nil?
        raise ArgumentError,
              '`queue_name` option is required'
      end

      options = { durable: true }
      if (dl_exchange = consumer.subscriber_options[:dead_letter_exchange])
        options[:arguments] = { 'x-dead-letter-exchange': dl_exchange }
      end

      queue = channel.queue(
        consumer.subscriber_options[:queue_name], options
      )

      queue_exchanges = create_exchanges(consumer, consumer.subscriber_options[:exchanges])
      queue.bind(queue_exchanges.last) if queue_exchanges.present?

      queue
    end

    def create_exchanges(_consumer, exchanges)
      return unless exchanges.present?

      previous_exchange = nil
      exchanges.map do |exchange|
        exchange_name = exchange.fetch(:name)
        exchange_type = exchange.fetch(:type, 'fanout')
        exchange_opts = exchange.fetch(:options, { durable: true })

        new_exchange = channel.send(exchange_type, exchange_name, exchange_opts)
        new_exchange.bind(previous_exchange) if previous_exchange
        previous_exchange = new_exchange

        new_exchange
      end
    end
  end
end
